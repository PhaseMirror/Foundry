//! Hyperfine Subspace Error Correction (HSEC)
//!
//! Evaluates the auxiliary subspace using SnapKitty's Von Neumann entropy.

use crate::bounds::ENTROPY_H_MAX_SCALED;

pub struct HsecProtocol;

impl HsecProtocol {
    /// Leakage is mathematically quantified as entropy.
    /// Error correction only proceeds if S(rho) <= H_max (6.0 bits).
    pub fn can_error_correct(s_rho_scaled: u64) -> bool {
        s_rho_scaled <= ENTROPY_H_MAX_SCALED
    }
}
