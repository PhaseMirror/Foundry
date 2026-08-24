use crate::ward_monitor::WardMonitor;
use ndarray::Array1;

pub struct ZenoProjector {
    pub ward_monitor: WardMonitor,
    pub epsilon: f64,
    pub max_iterations: usize,
    pub tolerance: f64,
}

impl ZenoProjector {
    pub fn new(
        ward_monitor: WardMonitor,
        epsilon: f64,
        max_iterations: usize,
        tolerance: f64,
    ) -> Self {
        Self {
            ward_monitor,
            epsilon,
            max_iterations,
            tolerance,
        }
    }

    pub fn project_state(&mut self, current_state: &Array1<f64>) -> Array1<f64> {
        let mut rho_prime = current_state.clone();

        for _ in 0..self.max_iterations {
            let grad = self.compute_gradient(&rho_prime, current_state);

            // Simple gradient descent
            let step_size = 0.01;
            rho_prime -= &(grad.clone() * step_size);

            // Project to simplex (sum to 1, >= 0)
            rho_prime = self.project_to_simplex(&rho_prime);

            if grad.mapv(|x| x.abs()).sum() < self.tolerance {
                break;
            }
        }

        rho_prime
    }

    fn compute_gradient(&mut self, state: &Array1<f64>, current: &Array1<f64>) -> Array1<f64> {
        let eps = 1e-6;
        let mut grad = Array1::zeros(state.len());

        let base_residual = self.ward_monitor.compute_residual(state);

        for i in 0..state.len() {
            let mut state_pert = state.clone();
            state_pert[i] += eps;
            let pert_residual = self.ward_monitor.compute_residual(&state_pert);

            let grad_distance = 2.0 * (state[i] - current[i]);
            let grad_residual = (pert_residual - base_residual) / eps;

            grad[i] = grad_distance + self.epsilon * grad_residual;
        }
        grad
    }

    fn project_to_simplex(&self, v: &Array1<f64>) -> Array1<f64> {
        let v = v.mapv(|x| x.max(0.0));
        let total: f64 = v.sum();
        if total > 0.0 {
            &v / total
        } else {
            Array1::from_elem(v.len(), 1.0 / v.len() as f64)
        }
    }
}
