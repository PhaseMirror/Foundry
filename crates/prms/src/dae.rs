// prms/src/dae.rs

#[derive(Debug, Clone, Copy)]
pub struct DAEConfig {
    pub m1: f64,
    pub m2: f64,
    pub omega1_sq: f64,
    pub omega2_sq: f64,
    pub beta: f64,
    pub gamma: f64,
    pub c0: f64,
    pub sigma: f64,
}

#[derive(Debug, Clone)]
pub struct SimulationState {
    pub q1: f64,
    pub p1: f64,
    pub q2: f64,
    pub p2: f64,
    pub kappa: f64,
}

#[derive(Debug, Clone)]
pub struct TelemetryFrame {
    pub t: f64,
    pub q1: f64,
    pub p1: f64,
    pub q2: f64,
    pub p2: f64,
    pub kappa: f64,
    pub delta: f64,
    pub multiplicity: f64,
    pub damping: f64,
    pub cond_number: f64,
}

#[derive(Debug, Clone, Copy)]
pub struct TwoOscillatorEngine {
    config: DAEConfig,
}

impl TwoOscillatorEngine {
    pub fn new(config: DAEConfig) -> Self {
        Self { config }
    }

    pub fn compute_gap(&self, kappa: f64) -> f64 {
        ((self.config.m1 - self.config.m2).powi(2) + 4.0 * kappa.powi(2)).sqrt()
    }

    pub fn compute_multiplicity(&self, delta: f64) -> f64 {
        1.0 + (-delta.powi(2) / (2.0 * self.config.sigma.powi(2))).exp()
    }

    pub fn compute_dm_dt(&self, kappa: f64, delta: f64) -> f64 {
        if delta <= 1e-12 { return 0.0; }
        let dm_ddelta = (delta / self.config.sigma.powi(2)) 
            * (-delta.powi(2) / (2.0 * self.config.sigma.powi(2))).exp();
        let ddelta_dkappa = 4.0 * kappa / delta;
        let dkappa_dt = -4.0 * self.config.beta * kappa;
        dm_ddelta * ddelta_dkappa * dkappa_dt
    }

    pub fn invert_mass_block(&self, kappa: f64, p1: f64, p2: f64) -> ((f64, f64), f64) {
        let det = self.config.m1 * self.config.m2 - kappa.powi(2);
        let trace = self.config.m1 + self.config.m2;
        let disc = ((self.config.m1 - self.config.m2).powi(2) + 4.0 * kappa.powi(2)).sqrt();
        let lambda_plus = 0.5 * (trace + disc);
        let lambda_minus = 0.5 * (trace - disc);
        let cond = lambda_plus.abs() / lambda_minus.abs();

        if det.abs() <= 1e-12 {
            let denom = self.config.m1 + self.config.m2;
            let factor = (p1 + p2) / denom;
            ((factor, factor), cond)
        } else {
            let inv_det = 1.0 / det;
            let v1 = inv_det * (self.config.m2 * p1 - kappa * p2);
            let v2 = inv_det * (-kappa * p1 + self.config.m1 * p2);
            ((v1, v2), cond)
        }
    }

    pub fn step(&self, state: &SimulationState, dt: f64, t_current: f64) -> TelemetryFrame {
        let delta = self.compute_gap(state.kappa);
        let m_val = self.compute_multiplicity(delta);
        let dm_val = self.compute_dm_dt(state.kappa, delta);
        let dynamic_damping = self.config.c0 + self.config.gamma * dm_val.abs();

        let kappa_fixed = state.kappa;
        let c_fixed = dynamic_damping;

        let derivatives = |y: &[f64; 4]| -> [f64; 4] {
            let q1 = y[0]; let p1 = y[1];
            let q2 = y[2]; let p2 = y[3];
            let ((v1, v2), _) = self.invert_mass_block(kappa_fixed, p1, p2);
            let dp1 = -(self.config.omega1_sq * q1 + kappa_fixed * (q1 - q2)) - c_fixed * (v1 - v2);
            let dp2 = -(self.config.omega2_sq * q2 + kappa_fixed * (q2 - q1)) - c_fixed * (v2 - v1);
            [v1, dp1, v2, dp2]
        };

        let y_0 = [state.q1, state.p1, state.q2, state.p2];
        let k1 = derivatives(&y_0);
        let y_k2 = [y_0[0] + 0.5 * dt * k1[0], y_0[1] + 0.5 * dt * k1[1], y_0[2] + 0.5 * dt * k1[2], y_0[3] + 0.5 * dt * k1[3]];
        let k2 = derivatives(&y_k2);
        let y_k3 = [y_0[0] + 0.5 * dt * k2[0], y_0[1] + 0.5 * dt * k2[1], y_0[2] + 0.5 * dt * k2[2], y_0[3] + 0.5 * dt * k2[3]];
        let k3 = derivatives(&y_k3);
        let y_k4 = [y_0[0] + dt * k3[0], y_0[1] + dt * k3[1], y_0[2] + dt * k3[2], y_0[3] + dt * k3[3]];
        let k4 = derivatives(&y_k4);

        let q1_next = y_0[0] + (dt / 6.0) * (k1[0] + 2.0 * k2[0] + 2.0 * k3[0] + k4[0]);
        let p1_next = y_0[1] + (dt / 6.0) * (k1[1] + 2.0 * k2[1] + 2.0 * k3[1] + k4[1]);
        let q2_next = y_0[2] + (dt / 6.0) * (k1[2] + 2.0 * k2[2] + 2.0 * k3[2] + k4[2]);
        let p2_next = y_0[3] + (dt / 6.0) * (k1[3] + 2.0 * k2[3] + 2.0 * k3[3] + k4[3]);

        let kappa_next = state.kappa - dt * 4.0 * self.config.beta * state.kappa;
        let (_, cond_number) = self.invert_mass_block(state.kappa, state.p1, state.p2);

        TelemetryFrame {
            t: t_current + dt, q1: q1_next, p1: p1_next, q2: q2_next, p2: p2_next,
            kappa: kappa_next, delta, multiplicity: m_val, damping: dynamic_damping, cond_number,
        }
    }
}
