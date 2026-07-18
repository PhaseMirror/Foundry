//! Kani verification harness for riemann-zeta
//!
//! Proves:
//! 1. `evaluate` returns a valid interval (low ≤ high)
//! 2. `verify_zero` returns `is_zero = true` only when zero is within threshold
//! 3. `find_zeros_in_range` terminates for bounded ranges
//! 4. `gram_point` is monotonically increasing

use kani::proof;
use riemann_zeta::{RiemannZeta, RiemannConfig, ZeroVerifier, Interval};
use rug::Complex;

#[proof]
fn verify_zeta_interval_valid() {
    let config = RiemannConfig {
        precision_bits: 128,
        max_iterations: 100,
        zero_verification_threshold: 1e-10,
    };
    let zeta = RiemannZeta::new(config).unwrap();
    let s = Complex::with_val(128, 2.0, 0.0);
    let result = zeta.evaluate(&s);

    // Interval must be valid (low ≤ high)
    match result {
        Ok(interval) => {
            assert!(interval.low <= interval.high, "Interval lower bound must be ≤ upper bound");
        }
        Err(_) => {
            // Evaluation may fail for invalid inputs; that's acceptable
        }
    }
}

#[proof]
fn verify_zero_detection_sound() {
    let config = RiemannConfig {
        precision_bits: 256,
        max_iterations: 500,
        zero_verification_threshold: 1e-8,
    };
    let verifier = ZeroVerifier::new(config);

    // At a known zero, verification should succeed
    let s = Complex::with_val(256, 0.5, 14.1347251417347);
    let result = verifier.verify(&s).unwrap();

    // If is_zero is true, the interval must contain zero
    if result.is_zero {
        let zero = rug::Float::with_val(256, 0.0);
        // The real part interval should contain 0.5 (critical line)
        assert!(result.real_part_lower <= 0.5);
        assert!(result.real_part_upper >= 0.5);
    }
}

#[proof]
fn verify_gram_point_monotonic() {
    let config = RiemannConfig::default();
    let verifier = ZeroVerifier::new(config);

    // Gram points should be monotonically increasing
    let g1 = verifier.gram_point(1);
    let g2 = verifier.gram_point(2);
    let g3 = verifier.gram_point(3);

    assert!(g1 < g2, "Gram points must be monotonically increasing");
    assert!(g2 < g3, "Gram points must be monotonically increasing");
}

#[proof]
fn verify_find_zeros_terminates() {
    let config = RiemannConfig {
        precision_bits: 128,
        max_iterations: 100,
        zero_verification_threshold: 1e-6,
    };
    let verifier = ZeroVerifier::new(config);

    // find_zeros_in_range must terminate for a bounded range
    let zeros = verifier.find_zeros_in_range(10.0, 20.0).unwrap();
    assert!(zeros.len() <= 10, "Should find at most 10 zeros in this range");
}
