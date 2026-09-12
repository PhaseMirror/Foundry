// umc_pgf.rs
// Prime-Graded Functorial (PGF) Formulation of the Multiplicity Constant (\Lambda_m)

/// Represents a spectral operator state for Rayleigh quotient and norm evaluations
#[derive(Debug, Clone)]
pub struct PGFSpatialState {
    pub norm_s: f64,    // ||S||, operator norm of S
    pub r_t: f64,       // r(T), Rayleigh quotient at state T
}

impl PGFSpatialState {
    pub fn new(norm_s: f64, r_t: f64) -> Self {
        Self { norm_s, r_t }
    }

    /// Global Certified Scale: \Lambda_glob(\gamma) = \gamma / ||S||
    pub fn lambda_glob(&self, gamma: f64) -> f64 {
        gamma / self.norm_s
    }

    /// Local Gate Scale: \Lambda_loc(\gamma; T) = \gamma / r(T)
    pub fn lambda_loc(&self, gamma: f64) -> Option<f64> {
        if self.r_t <= 0.0 {
            None
        } else {
            Some(gamma / self.r_t)
        }
    }

    /// Hybrid Policy: \min(\Lambda_glob, \Lambda_loc)
    pub fn lambda_hyb(&self, gamma: f64) -> f64 {
        let l_glob = self.lambda_glob(gamma);
        if let Some(l_loc) = self.lambda_loc(gamma) {
            if l_loc < l_glob {
                return l_loc;
            }
        }
        l_glob
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    /// Theorem: Global certified stability.
    /// \Lambda_glob * ||S|| = \gamma.
    #[kani::proof]
    fn verify_global_stability() {
        let norm_s: f64 = kani::any();
        let gamma: f64 = kani::any();

        kani::assume(norm_s > 0.0 && norm_s < 1000.0);
        kani::assume(gamma > 0.0 && gamma < 1.0);

        let state = PGFSpatialState::new(norm_s, 0.5); // r_t arbitrary here
        let l_glob = state.lambda_glob(gamma);

        let contractive_factor = l_glob * norm_s;
        
        // Assert \Lambda_glob * ||S|| == \gamma ensuring strict contractivity
        kani::assert(
            (contractive_factor - gamma).abs() < 1e-9,
            r"Global certified stability violated: contractive factor exceeds \gamma",
        );
    }

    /// Theorem: Hybrid safety.
    /// The hybrid policy \Lambda_hyb never exceeds \Lambda_glob, ensuring global safety is maintained.
    #[kani::proof]
    fn verify_hybrid_safety() {
        let norm_s: f64 = kani::any();
        let r_t: f64 = kani::any();
        let gamma: f64 = kani::any();

        kani::assume(norm_s > 0.0 && norm_s < 1000.0);
        kani::assume(r_t > 0.0 && r_t < 1000.0);
        kani::assume(gamma > 0.0 && gamma < 1.0);

        let state = PGFSpatialState::new(norm_s, r_t);
        let l_glob = state.lambda_glob(gamma);
        let l_hyb = state.lambda_hyb(gamma);

        // Proposition 6: Hybrid safety
        kani::assert(
            l_hyb <= l_glob,
            r"Hybrid safety violated: \Lambda_hyb exceeds \Lambda_glob fence",
        );
    }
}
