use ndarray::Array1;
use statrs::statistics::Statistics;

pub struct WardMonitor {
    pub reference_state: Option<Array1<f64>>,
    pub delta_operational: f64,
    pub smoothing_window: usize,
    pub residual_history: Vec<f64>,
}

impl WardMonitor {
    pub fn new(
        reference_state: Option<Array1<f64>>,
        delta_operational: f64,
        smoothing_window: usize,
    ) -> Self {
        Self {
            reference_state,
            delta_operational,
            smoothing_window,
            residual_history: Vec::new(),
        }
    }

    pub fn compute_residual(&mut self, current_state: &Array1<f64>) -> f64 {
        let rho = self.normalize_to_distribution(current_state);
        let rho0 = match &self.reference_state {
            Some(ref_state) => self.normalize_to_distribution(ref_state),
            None => rho.clone(), // Initial reference
        };

        if self.reference_state.is_none() {
            self.reference_state = Some(rho.clone());
        }

        // KL Divergence: Σ ρ_i log(ρ_i / ρ0_i)
        let residual: f64 = rho
            .iter()
            .zip(rho0.iter())
            .map(|(&p, &q)| {
                if p > 0.0 && q > 0.0 {
                    p * (p / q).ln()
                } else {
                    0.0
                }
            })
            .sum();

        self.residual_history.push(residual);

        // Simple moving average for smoothing
        if self.residual_history.len() >= self.smoothing_window {
            let start = self.residual_history.len() - self.smoothing_window;
            let window = &self.residual_history[start..];
            window.iter().sum::<f64>() / self.smoothing_window as f64
        } else {
            residual
        }
    }

    fn normalize_to_distribution(&self, state: &Array1<f64>) -> Array1<f64> {
        let state = state.mapv(|x| x.max(0.0));
        let total: f64 = state.sum();
        if total > 0.0 {
            &state / total
        } else {
            Array1::from_elem(state.len(), 1.0 / state.len() as f64)
        }
    }

    pub fn is_drift_detected(&self) -> bool {
        match self.residual_history.last() {
            Some(&last) => last > self.delta_operational,
            None => false,
        }
    }
}
