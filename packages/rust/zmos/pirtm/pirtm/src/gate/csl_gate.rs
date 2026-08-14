use ndarray::{Array1, Array2};
use crate::gate::rate_limiter::RateLimiter;

#[derive(Debug, Clone)]
pub struct CslGateParams {
    pub consent_threshold: f64,
    pub max_spectral_drift: f64,
    pub norm_budget: f64,
}

impl Default for CslGateParams {
    fn default() -> Self {
        CslGateParams {
            consent_threshold: 0.5,
            max_spectral_drift: 2.0,
            norm_budget: 5.0,
        }
    }
}

pub struct CslGate {
    pub params: CslGateParams,
    pub rate_limiter: Option<RateLimiter>,
}

impl CslGate {
    pub fn new(params: Option<CslGateParams>, rate_limiter: Option<RateLimiter>) -> Self {
        CslGate {
            params: params.unwrap_or_default(),
            rate_limiter,
        }
    }

    pub fn check(
        &mut self,
        x: &Array1<f64>,
        t: usize,
        sigma: &Array2<f64>,
        weights: &Array1<f64>,
    ) -> (bool, &'static str) {
        if !self.check_consent(weights) {
            return (false, "consent_quorum_not_met");
        }

        if !self.check_spectral_drift(x, sigma) {
            return (false, "spectral_drift_exceeded");
        }

        if !self.check_norm_budget(x) {
            if let Some(ref mut rl) = self.rate_limiter {
                if !rl.allow_step(t) {
                    return (false, "rollback_budget_exhausted");
                }
            }
            return (false, "norm_budget_exceeded");
        }

        (true, "pass")
    }

    fn check_consent(&self, weights: &Array1<f64>) -> bool {
        if weights.is_empty() {
            return false;
        }
        let consenting_count = weights.iter().filter(|&&w| w > self.params.consent_threshold).count();
        let ratio = consenting_count as f64 / weights.len() as f64;
        ratio >= self.params.consent_threshold
    }

    fn check_spectral_drift(&self, x: &Array1<f64>, sigma: &Array2<f64>) -> bool {
        // Simple approximation for eigvalsh max
        // In a real implementation, we'd use a proper eigensolver (e.g., from ndarray-linalg)
        // For now, let's use the same power iteration approach or similar.
        let lambda_max = crate::spectral_norm(sigma);
        let denom = lambda_max.max(1e-12);
        let norm_x = x.dot(x).sqrt();
        let drift = norm_x / denom;
        drift <= self.params.max_spectral_drift
    }

    fn check_norm_budget(&self, x: &Array1<f64>) -> bool {
        let norm_x = x.dot(x).sqrt();
        norm_x <= self.params.norm_budget
    }
}
