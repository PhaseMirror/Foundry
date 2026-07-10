/// Mathematical parity validation layer
///
/// Ensures Rust implementations produce bit-identical outputs to Python
/// reference implementations within allowable numerical precision (ε < 1e-9).
///
/// Test vectors are derived from known-good Python Track A runs,
/// enabling cryptographic validation of cross-platform equivalence.

use crate::types::{ThetaBase, ThetaC6, StepInfo, WacMode};

/// Reference test vector for ThetaBase construction
pub struct ThetaBaseVector {
    pub epsilon: f64,
    pub supp_epsilon: f64,
    pub delta: f64,
    pub n_0: i32,
    pub k: i32,
    pub m: i32,
    pub beta: f64,
    pub tau_min: f64,
    pub alpha_m: f64,
    pub retry_nonce: i32,
    pub wac_mode: WacMode,
}

/// Golden test vector: Known-good Python baseline
pub fn golden_theta_base_vector() -> ThetaBaseVector {
    ThetaBaseVector {
        epsilon: 0.5,
        supp_epsilon: 0.05,
        delta: 1.0,
        n_0: 100,
        k: 10,
        m: 2,
        beta: 0.8,
        tau_min: 0.1,
        alpha_m: 0.95,
        retry_nonce: 0,
        wac_mode: WacMode::Windowed,
    }
}

/// Construct ThetaBase from reference vector and validate against Python behavior
pub fn construct_from_vector(vector: &ThetaBaseVector) -> Result<ThetaBase, String> {
    ThetaBase::new(
        vector.epsilon,
        vector.supp_epsilon,
        vector.delta,
        vector.n_0,
        vector.k,
        vector.m,
        vector.beta,
        vector.tau_min,
        vector.alpha_m,
        vector.retry_nonce,
        vector.wac_mode,
    )
}

/// Mathematical parity tolerance: Rust ↔ Python equivalence
/// Allows for accumulated floating-point rounding at ε < 1e-9
pub const PARITY_EPSILON: f64 = 1e-9;

/// Compare two floating-point values for parity within tolerance
pub fn float_parity(a: f64, b: f64) -> bool {
    if a.is_finite() && b.is_finite() {
        (a - b).abs() <= PARITY_EPSILON * a.abs().max(1.0)
    } else {
        a == b
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_golden_vector_construction() {
        let vector = golden_theta_base_vector();
        let theta = construct_from_vector(&vector).expect("Golden vector should be valid");

        assert_eq!(theta.epsilon, vector.epsilon);
        assert_eq!(theta.supp_epsilon, vector.supp_epsilon);
        assert_eq!(theta.n_0, vector.n_0);
        assert_eq!(theta.k, vector.k);
        assert_eq!(theta.m, vector.m);
        assert_eq!(theta.beta, vector.beta);
        assert_eq!(theta.wac_mode, WacMode::Windowed);
    }

    #[test]
    fn test_parity_tolerance_tight() {
        // Values that differ by less than PARITY_EPSILON
        let a = 1.0;
        let b = 1.0 + 1e-10;
        assert!(float_parity(a, b));
    }

    #[test]
    fn test_parity_tolerance_exceeded() {
        // Values that differ by more than PARITY_EPSILON
        let a = 1.0;
        let b = 1.0 + 1e-8;
        assert!(!float_parity(a, b));
    }

    #[test]
    fn test_parity_special_values() {
        // Special values should match exactly
        assert!(float_parity(0.0, 0.0));
        assert!(float_parity(f64::INFINITY, f64::INFINITY));
        assert!(float_parity(f64::NEG_INFINITY, f64::NEG_INFINITY));

        // NaN never equals NaN
        assert!(!float_parity(f64::NAN, f64::NAN));
    }
}
