//! Predictability horizon estimators and Lyapunov spectral radius monitoring (Conjecture C1)

/// Computes the local expansion rate estimate lambda_hat from observation history.
pub struct ExpansionEstimator {
    pub lambda_floor: f64,
    pub lambda_cap: f64,
}

impl ExpansionEstimator {
    pub fn new(lambda_floor: f64, lambda_cap: f64) -> Self {
        Self {
            lambda_floor,
            lambda_cap,
        }
    }

    /// Estimates the local Lyapunov expansion rate from output history using finite differences.
    pub fn estimate_lambda(&self, history: &[Vec<f64>]) -> f64 {
        if history.len() < 2 {
            return self.lambda_floor;
        }

        let mut max_rate: f64 = 0.0;
        for i in 1..history.len() {
            let prev = &history[i - 1];
            let curr = &history[i];
            let n = prev.len().min(curr.len());
            if n == 0 {
                continue;
            }

            let mut diff_sq = 0.0;
            let mut norm_prev_sq = 0.0;
            for j in 0..n {
                let d = curr[j] - prev[j];
                diff_sq += d * d;
                norm_prev_sq += prev[j] * prev[j];
            }

            let norm_diff = diff_sq.sqrt();
            let norm_prev = norm_prev_sq.sqrt().max(1e-6);
            let rate = norm_diff / norm_prev;
            if rate > max_rate {
                max_rate = rate;
            }
        }

        max_rate.max(self.lambda_floor)
    }

    /// Computes T_pred = (1 / lambda_hat) * ln(delta / eps0).
    pub fn compute_t_pred(&self, lambda_hat: f64, delta: f64, eps0: f64) -> f64 {
        if lambda_hat <= 0.0 || eps0 <= 0.0 || delta <= eps0 {
            return 0.0;
        }
        (1.0 / lambda_hat) * (delta / eps0).ln()
    }

    /// Evaluates if BURST mode must exit based on C1 criteria.
    pub fn should_exit_burst(
        &self,
        t_elapsed: f64,
        t_pred: f64,
        lambda_hat: f64,
        v_score: f64,
        v_min: f64,
        sandbox_ok: bool,
    ) -> bool {
        t_elapsed >= t_pred
            || lambda_hat > self.lambda_cap
            || v_score < v_min
            || !sandbox_ok
    }

    /// Consensus check over multiple independent expansion estimators.
    pub fn verify_consensus(&self, estimators: &[f64], tolerance: f64) -> bool {
        if estimators.is_empty() {
            return true;
        }
        let min_val = estimators.iter().cloned().fold(f64::INFINITY, f64::min);
        let max_val = estimators.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        (max_val - min_val) <= tolerance
    }
}
