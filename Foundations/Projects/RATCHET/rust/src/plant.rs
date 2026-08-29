//! Toy Chaotic Plant Interface (ADR-0038 §3 & Table 1)

use crate::types::PlantState;

/// Toy discrete chaotic system modeling nonlinear plant dynamics.
pub struct ChaoticPlant {
    pub state: PlantState,
    pub dt: f64,
    pub sigma: f64,
    pub rho: f64,
    pub beta: f64,
}

impl ChaoticPlant {
    pub fn new() -> Self {
        Self {
            state: PlantState {
                x: vec![1.0, 1.0, 1.0],
                u: vec![0.0, 0.0, 0.0],
                y: vec![1.0, 1.0, 1.0],
                theta: vec![0.5, 0.5],
                t: 0,
                burst_id: 1,
                snapshot_id: 0,
            },
            dt: 0.01,
            sigma: 10.0,
            rho: 28.0,
            beta: 8.0 / 3.0,
        }
    }

    /// Step the chaotic plant forward by dt under control action u.
    pub fn step(&mut self, u: &[f64]) {
        self.state.t += 1;
        self.state.u = u.to_vec();

        let x = self.state.x[0];
        let y = self.state.x[1];
        let z = self.state.x[2];

        let u0 = if !u.is_empty() { u[0] } else { 0.0 };
        let u1 = if u.len() > 1 { u[1] } else { 0.0 };
        let u2 = if u.len() > 2 { u[2] } else { 0.0 };

        // Discrete Lorenz equations with actuator coupling
        let dx = (self.sigma * (y - x) + u0) * self.dt;
        let dy = (x * (self.rho - z) - y + u1) * self.dt;
        let dz = (x * y - self.beta * z + u2) * self.dt;

        self.state.x[0] += dx;
        self.state.x[1] += dy;
        self.state.x[2] += dz;

        // Output sensor measurements y = x + process_noise_estimate
        self.state.y = self.state.x.clone();
    }
}
