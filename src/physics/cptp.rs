// src/physics/cptp.rs

use nalgebra::{DMatrix, DVector};
use std::f64::consts::PI;
use argmin::core::{CostFunction, Executor, Gradient, Hessian, State};
use argmin::solver::gradientdescent::SteepestDescent;
use argmin::solver::linesearch::MoreThuenteLineSearch;

// ---------- CPTP Generator Parameters ----------
#[derive(Clone, Debug)]
pub struct CPTPGenerator {
    pub alpha: f64,               // linear damping (common)
    pub beta: f64,                // constant offset (common)
    pub gamma: f64,               // coupling strength (common)
    pub eta: f64,                 // quadratic damping (common)
    pub lambda: Vec<f64>,         // time‑dependent adiabatic parameter (values at time points)
    pub xi: Vec<f64>,             // time‑dependent stochastic source (values at time points)
    pub A: Vec<f64>,              // oscillatory amplitudes (for each drive)
    pub omega: Vec<f64>,          // oscillatory frequencies
    pub phi: Vec<f64>,            // oscillatory phases
    pub T: DMatrix<f64>,          // coupling matrix (dimension d × d)
    // Feedback operators (pre‑computed functions)
    pub Omega_B: fn(&DMatrix<f64>) -> DMatrix<f64>,
    pub Omega_FS: fn(&DMatrix<f64>) -> DMatrix<f64>,
}

impl Default for CPTPGenerator {
    fn default() -> Self {
        Self {
            alpha: 0.1,
            beta: 0.0,
            gamma: 0.05,
            eta: 0.01,
            lambda: vec![0.0],
            xi: vec![0.0],
            A: vec![0.5],
            omega: vec![1.0],
            phi: vec![0.0],
            T: DMatrix::identity(9, 9),
            Omega_B: |_| DMatrix::zeros(9, 9),
            Omega_FS: |_| DMatrix::zeros(9, 9),
        }
    }
}

// ---------- Helper Functions ----------
fn commutator(a: &DMatrix<f64>, b: &DMatrix<f64>) -> DMatrix<f64> {
    a * b - b * a
}

fn anticommutator(a: &DMatrix<f64>, b: &DMatrix<f64>) -> DMatrix<f64> {
    a * b + b * a
}

// ---------- CPTP Generator Evolution ----------
pub fn compute_drho_dt(
    rho: &DMatrix<f64>,
    t: f64,
    params: &CPTPGenerator,
    time_index: usize,
) -> DMatrix<f64> {
    let d = rho.nrows();
    let mut drho = DMatrix::zeros(d, d);

    // 1. Hamiltonian part (coherent evolution)
    let mut h_eff = DMatrix::zeros(d, d);
    for i in 0..d {
        h_eff[(i, i)] += params.alpha * rho[(i, i)] + params.beta;
    }
    h_eff += params.gamma * params.T.clone() * rho;
    let omega_b = (params.Omega_B)(rho);
    let omega_fs = (params.Omega_FS)(rho);
    let lambda_t = if time_index < params.lambda.len() {
        params.lambda[time_index]
    } else {
        *params.lambda.last().unwrap_or(&0.0)
    };
    h_eff += lambda_t * (omega_b + omega_fs);
    let comm = commutator(&h_eff, rho);
    drho += -0.5 * (comm + comm.transpose());

    // 2. Simplified Lindblad terms using eta
    for i in 0..d {
        let mut l = DMatrix::zeros(d, d);
        l[(i, i)] = 1.0;
        let l_i = params.eta.sqrt() * rho[(i, i)];
        let term = l_i * l_i * (rho.clone() - 0.5 * (l.clone() * l.clone().transpose() * rho + rho * l.clone() * l.clone().transpose()));
        drho += term;
    }

    // 3. Oscillatory commutator terms
    for i in 0..params.A.len() {
        let amp = params.A[i];
        let freq = *params.omega.get(i).unwrap_or(&0.0);
        let phase = *params.phi.get(i).unwrap_or(&0.0);
        let val = amp * (freq * t + phase).sin();
        let commut = commutator(rho, &params.T);
        drho += val * commut;
    }

    // 4. Stochastic source (xi)
    let xi_t = if time_index < params.xi.len() { params.xi[time_index] } else { *params.xi.last().unwrap_or(&0.0) };
    if xi_t > 0.0 {
        drho += xi_t * DMatrix::identity(d, d);
    }
    drho
}

// ---------- ODE Solver: RK4 ----------
pub fn rk4_step(
    rho: &DMatrix<f64>,
    t: f64,
    dt: f64,
    params: &CPTPGenerator,
    time_index: usize,
) -> DMatrix<f64> {
    let k1 = compute_drho_dt(rho, t, params, time_index);
    let rho2 = rho + 0.5 * dt * &k1;
    let k2 = compute_drho_dt(&rho2, t + 0.5 * dt, params, time_index);
    let rho3 = rho + 0.5 * dt * &k2;
    let k3 = compute_drho_dt(&rho3, t + 0.5 * dt, params, time_index);
    let rho4 = rho + dt * &k3;
    let k4 = compute_drho_dt(&rho4, t + dt, params, time_index + 1);
    rho + (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
}

pub fn evolve(
    rho0: &DMatrix<f64>,
    t_span: (f64, f64),
    dt: f64,
    params: &CPTPGenerator,
) -> Vec<(f64, DMatrix<f64>)> {
    let steps = ((t_span.1 - t_span.0) / dt) as usize;
    let mut traj = Vec::with_capacity(steps + 1);
    let mut rho = rho0.clone();
    let mut t = t_span.0;
    let mut idx = 0usize;
    traj.push((t, rho.clone()));
    for _ in 0..steps {
        rho = rk4_step(&rho, t, dt, params, idx);
        t += dt;
        idx += 1;
        rho = (&rho + rho.transpose()) / 2.0;
        let tr = rho.trace();
        if tr != 0.0 { rho /= tr; }
        traj.push((t, rho.clone()));
    }
    traj
}

// ---------- Reverse‑Model Inversion ----------
pub struct FitProblem {
    pub observed: Vec<(f64, DMatrix<f64>)>,
    pub params_initial: CPTPGenerator,
}

impl CostFunction for FitProblem {
    type Param = Vec<f64>;
    type Output = f64;

    fn cost(&self, p: &Self::Param) -> Result<Self::Output, argmin::core::Error> {
        let mut params = self.params_initial.clone();
        params.alpha = p[0];
        params.beta = p[1];
        params.gamma = p[2];
        params.eta = p[3];
        if !params.A.is_empty() { params.A[0] = p[4]; }
        if !params.omega.is_empty() { params.omega[0] = p[5]; }
        if !params.phi.is_empty() { params.phi[0] = p[6]; }
        if !params.lambda.is_empty() { params.lambda[0] = p[7]; }
        if !params.xi.is_empty() { params.xi[0] = p[8]; }
        let rho0 = self.observed[0].1.clone();
        let t0 = self.observed[0].0;
        let t1 = self.observed.last().unwrap().0;
        let dt = 0.01;
        let sim = evolve(&rho0, (t0, t1), dt, &params);
        let mut err = 0.0;
        for (ot, orho) in &self.observed {
            let idx = ((ot - t0) / dt) as usize;
            let srho = &sim[idx].1;
            let diff = srho - orho;
            err += diff.norm_squared();
        }
        Ok(err)
    }
}

pub fn fit_parameters(
    observed: Vec<(f64, DMatrix<f64>)>,
    init: &CPTPGenerator,
) -> CPTPGenerator {
    let problem = FitProblem { observed, params_initial: init.clone() };
    let init_vec = vec![
        init.alpha,
        init.beta,
        init.gamma,
        init.eta,
        *init.A.get(0).unwrap_or(&0.5),
        *init.omega.get(0).unwrap_or(&1.0),
        *init.phi.get(0).unwrap_or(&0.0),
        *init.lambda.get(0).unwrap_or(&0.0),
        *init.xi.get(0).unwrap_or(&0.0),
    ];
    let solver = SteepestDescent::new().with_tolerance(1e-6).with_max_iters(1000);
    let exec = Executor::new(problem, solver).configure(|s| s.param(init_vec).max_iters(1000));
    let res = exec.run().expect("Optimization failed");
    let best = res.state().best_param.expect("No best param");
    let mut fitted = init.clone();
    fitted.alpha = best[0];
    fitted.beta = best[1];
    fitted.gamma = best[2];
    fitted.eta = best[3];
    if !fitted.A.is_empty() { fitted.A[0] = best[4]; }
    if !fitted.omega.is_empty() { fitted.omega[0] = best[5]; }
    if !fitted.phi.is_empty() { fitted.phi[0] = best[6]; }
    if !fitted.lambda.is_empty() { fitted.lambda[0] = best[7]; }
    if !fitted.xi.is_empty() { fitted.xi[0] = best[8]; }
    fitted
}

// ---------- Tests ----------
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_reverse_model() {
        let mut params = CPTPGenerator::default();
        params.alpha = 0.2;
        params.beta = 0.1;
        params.gamma = 0.05;
        params.eta = 0.01;
        params.A = vec![0.8];
        params.omega = vec![1.5];
        params.phi = vec![0.5];
        params.lambda = vec![0.1];
        params.xi = vec![0.02];
        let d = 9;
        let mut diag = vec![0.8; d];
        let rho0 = DMatrix::from_diagonal(&DVector::from_vec(diag));
        let traj = evolve(&rho0, (0.0, 10.0), 0.1, &params);
        let observed: Vec<_> = traj.iter().step_by(5).map(|(t, r)| (*t, r.clone())).collect();
        let fitted = fit_parameters(observed, &CPTPGenerator::default());
        assert!((fitted.alpha - params.alpha).abs() < 0.05);
        assert!((fitted.beta - params.beta).abs() < 0.05);
        assert!((fitted.gamma - params.gamma).abs() < 0.05);
        assert!((fitted.eta - params.eta).abs() < 0.05);
        assert!((fitted.A[0] - params.A[0]).abs() < 0.05);
        assert!((fitted.omega[0] - params.omega[0]).abs() < 0.05);
        assert!((fitted.phi[0] - params.phi[0]).abs() < 0.05);
        assert!((fitted.lambda[0] - params.lambda[0]).abs() < 0.05);
        assert!((fitted.xi[0] - params.xi[0]).abs() < 0.05);
    }
}
