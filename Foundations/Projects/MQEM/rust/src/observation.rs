//! Observation Likelihood Models (M³EM §3.2)

/// Observation distribution types for ecological measurements.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ObservationModel {
    BernoulliOccupancy { detection_probability: f64 },
    PoissonCount { scaling: f64 },
    GaussianIndex { std_dev: f64 },
}

impl ObservationModel {
    /// Compute log-likelihood of observation y given latent ecological state x: ln p(y | x).
    pub fn log_likelihood(&self, y: f64, x: f64) -> f64 {
        match self {
            ObservationModel::BernoulliOccupancy { detection_probability } => {
                // Latent occupancy probability psi = 1.0 - exp(-x)
                let psi = (1.0 - (-x.max(0.0)).exp()).clamp(1e-6, 1.0 - 1e-6);
                let p_detect = (psi * detection_probability).clamp(1e-6, 1.0 - 1e-6);
                if y > 0.5 {
                    p_detect.ln()
                } else {
                    (1.0 - p_detect).ln()
                }
            }

            ObservationModel::PoissonCount { scaling } => {
                let lambda = (x * scaling).max(1e-6);
                let k = y.round() as u64;
                // ln (lambda^k * exp(-lambda) / k!)
                let mut log_fact = 0.0;
                for i in 2..=k {
                    log_fact += (i as f64).ln();
                }
                (k as f64) * lambda.ln() - lambda - log_fact
            }

            ObservationModel::GaussianIndex { std_dev } => {
                let s = std_dev.max(1e-6);
                let diff = y - x;
                -0.5 * (2.0 * std::f64::consts::PI).ln() - s.ln() - (diff * diff) / (2.0 * s * s)
            }
        }
    }
}
