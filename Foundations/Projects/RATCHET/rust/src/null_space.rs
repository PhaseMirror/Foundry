//! Null-Space Coordinate Initialization and Post-Use Monitoring (Conjecture C3)

/// Null-space initialization tester and post-allocation probation gate.
pub struct NullSpaceGate {
    pub tolerance: f64,
    pub margin: f64,
}

impl NullSpaceGate {
    pub fn new(tolerance: f64, margin: f64) -> Self {
        Self { tolerance, margin }
    }

    /// Instantaneous linear orthogonality check: |dot(grad_phi, z_new)| < tol * ||grad_phi|| * ||z_new||.
    pub fn test_nullspace(&self, grad_phi: &[f64], z_new: &[f64]) -> bool {
        if grad_phi.len() != z_new.len() || grad_phi.is_empty() {
            return false;
        }

        let mut dot = 0.0;
        let mut norm_g_sq = 0.0;
        let mut norm_z_sq = 0.0;

        for i in 0..grad_phi.len() {
            dot += grad_phi[i] * z_new[i];
            norm_g_sq += grad_phi[i] * grad_phi[i];
            norm_z_sq += z_new[i] * z_new[i];
        }

        let norm_g = norm_g_sq.sqrt();
        let norm_z = norm_z_sq.sqrt();

        if norm_g < 1e-9 || norm_z < 1e-9 {
            return true;
        }

        dot.abs() <= self.tolerance * norm_g * norm_z
    }

    /// Post-use audit check on coordinate contribution after consolidation.
    pub fn post_use_check(
        &self,
        phi_before: f64,
        phi_after: f64,
        z_contribution: f64,
    ) -> bool {
        phi_after >= self.margin
            && z_contribution >= -self.margin
            && (phi_after - phi_before) >= -self.margin
    }
}
