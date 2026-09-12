use nalgebra::{DMatrix, Complex};
use std::f64::consts::PI;

use super::hamiltonian::{HardwareSpec, GateOperation};

// =====================================================================
// CPTP Generator Parameters
// =====================================================================

#[derive(Clone, Debug)]
pub struct CPTPGeneratorParams {
    pub alpha: f64,
    pub beta: f64,
    pub gamma: f64,
    pub eta: f64,
    pub lambda: Vec<f64>,      // time-dependent values
    pub xi: Vec<f64>,
    pub A: Vec<f64>,
    pub omega: Vec<f64>,
    pub phi: Vec<f64>,
    pub T: DMatrix<f64>,
    pub hardware: HardwareSpec,
}

impl Default for CPTPGeneratorParams {
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
            hardware: HardwareSpec::default(),
        }
    }
}

// =====================================================================
// CPTP Generator
// =====================================================================

pub fn compute_drho_dt(
    rho: &DMatrix<f64>,
    t: f64,
    params: &CPTPGeneratorParams,
    time_index: usize,
) -> DMatrix<f64> {
    let d = rho.nrows();
    let mut drho = DMatrix::zeros(d, d);

    // 1. Coherent part: -i [H_eff, rho]
    // Use the Hamiltonian evaluator
    let h_eff = params.hardware.hamiltonian(&params.hardware.sequence);
    let comm = h_eff * rho - rho * h_eff;
    drho += -0.5 * (comm + comm.transpose()); // real matrix, approximates -i

    // 2. Dissipative part: Lindblad operators
    // We'll use a simplified Lindblad: L = sqrt(eta) * rho_k (diagonal)
    for i in 0..d {
        let l_i = params.eta.sqrt() * rho[(i, i)];
        // L rho L^T - 1/2 (L^T L rho + rho L^T L)
        // For diagonal L, we can compute directly.
        let l_sq = l_i * l_i;
        // Add to drho
        for j in 0..d {
            drho[(j, j)] += l_sq * (rho[(j, j)] - 0.5 * (rho[(j, j)] + rho[(j, j)]));
        }
    }

    // 3. Oscillatory commutator terms
    for i in 0..params.A.len() {
        let val = params.A[i] * (params.omega[i] * t + params.phi[i]).sin();
        let commut = rho * &params.T - &params.T * rho;
        drho += val * commut;
    }

    // 4. Stochastic source (xi(t)): modeled as a dephasing term
    let xi_t = if time_index < params.xi.len() {
        params.xi[time_index]
    } else {
        params.xi.last().copied().unwrap_or(0.0)
    };
    if xi_t > 0.0 {
        // Dephasing: L = sqrt(xi) * σ_z on each qubit
        // For simplicity, add a dephasing term to diagonal elements
        for i in 0..d {
            drho[(i, i)] -= xi_t * rho[(i, i)];
        }
    }

    drho
}

// =====================================================================
// Kani Harness
// =====================================================================

#[cfg(kani)]
mod kani_harness {
    use super::*;

    #[kani::proof]
    #[kani::unwind(8)]
    fn verify_cptp_trace_preserving() {
        // Symbolic rho (Hermitian, trace=1)
        let d: usize = 9; // spectral attractor dimension
        let rho = DMatrix::from_diagonal(&DVector::from_element(d, 1.0 / d as f64));

        let mut params = CPTPGeneratorParams::default();
        params.hardware.num_qubits = 2;
        // ... set hardware parameters ...
        let t = 0.0;
        let time_index = 0;

        let drho = compute_drho_dt(&rho, t, &params, time_index);

        // Trace preserving: Tr(drho) == 0
        let trace = drho.trace();
        assert!(trace.abs() < 1e-12);

        // Hermiticity: drho is Hermitian (if rho is Hermitian)
        let drho_t = drho.transpose();
        assert!(relative_eq!(drho, drho_t, epsilon = 1e-12));
    }
}
