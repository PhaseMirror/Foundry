//! Adaptation Rate Limiter and Self-Edit Manifest Verification (Conjecture C2)

use crate::types::{AccessMode, WriteManifest};

/// Adaptation rate cap limiter enforcing || d_theta / dt || < eps_star / (M_unif * tau_react).
pub struct RateCapLimiter {
    pub eps_star: f64,
    pub m_unif: f64,
    pub tau_react: f64,
}

impl RateCapLimiter {
    pub fn new(eps_star: f64, m_unif: f64, tau_react: f64) -> Self {
        Self {
            eps_star,
            m_unif,
            tau_react,
        }
    }

    /// Maximum allowed parameter adaptation rate.
    pub fn max_allowed_rate(&self) -> f64 {
        self.eps_star / (self.m_unif * self.tau_react).max(1e-6)
    }

    /// Clamps parameter velocity vector d_theta to satisfy C2 rate cap.
    pub fn enforce_rate_cap(&self, d_theta: &[f64]) -> (Vec<f64>, bool) {
        let max_rate = self.max_allowed_rate();
        let norm_sq: f64 = d_theta.iter().map(|&x| x * x).sum();
        let norm = norm_sq.sqrt();

        if norm > max_rate && norm > 1e-9 {
            let scale_factor = max_rate / norm;
            let clamped: Vec<f64> = d_theta.iter().map(|&x| x * scale_factor).collect();
            (clamped, true)
        } else {
            (d_theta.to_vec(), false)
        }
    }

    /// Validates that every runtime write path into theta is registered in the complete manifest.
    pub fn verify_manifest_completeness(
        manifest: &WriteManifest,
        runtime_accessed_paths: &[String],
    ) -> bool {
        if !manifest.complete {
            return false;
        }

        for path in runtime_accessed_paths {
            let registered = manifest.paths.iter().any(|wp| {
                wp.handle == *path && (wp.access == AccessMode::Write || wp.access == AccessMode::Execute)
            });
            if !registered {
                return false;
            }
        }

        true
    }
}
