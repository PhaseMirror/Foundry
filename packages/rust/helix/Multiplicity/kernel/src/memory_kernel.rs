use ndarray::{Array1, Array2, Axis};
use std::f64::consts::PI;

pub struct MemoryKernel {
    pub alpha: f64,
    pub omega: f64,
    pub phi: f64,
    pub time_scale: f64,
}

impl MemoryKernel {
    pub fn new(alpha: f64, omega: f64, phi: f64, time_scale: f64) -> Self {
        Self {
            alpha,
            omega,
            phi,
            time_scale,
        }
    }

    pub fn convolve(&self, t: f64, history: &Array2<f64>) -> Array1<f64> {
        let n_timesteps = history.nrows();
        let state_dim = history.ncols();

        let mut weights = Array1::zeros(n_timesteps);

        // Compute kernel weights for each historical timestep
        let t_steps = Array1::linspace(0.1, t, n_timesteps);
        for i in 0..n_timesteps {
            let tau = t_steps[i];
            let log_ratio = (t / tau).ln();
            weights[i] =
                (-self.alpha * log_ratio).exp() * (self.omega * log_ratio + self.phi).cos();
        }

        // Normalize weights
        let sum_abs = weights.mapv(|w| w.abs()).sum();
        weights /= (sum_abs + 1e-8);

        // Apply convolution
        let mut result = Array1::zeros(state_dim);
        for i in 0..n_timesteps {
            result += &(history.row(i).to_owned() * weights[i]);
        }

        result
    }
}
