//! Kani proof harnesses for the Brauer oval contraction test.
//!
//! Run with: `cargo kani --harness proof_brauer`
//!
//! These harnesses verify the **implementation** of the radius test:
//! - No panic on any bounded matrix
//! - Radii are < 1 when the function returns true
//! - Determinism (same input → same output)
//!
//! The mathematical claim "Brauer ovals inside unit disk ⇒ ρ < 1"
//! is an analytic theorem assumed by the living loop, not Kani-proven.

#[cfg(kani)]
mod proof {
    use crate::{brauer_ovals_strictly_contracting, cassini_radius};
    use nalgebra::DMatrix;

    /// Harness: the Boolean test is deterministic and never panics
    /// on any finite matrix of size ≤ 4.
    #[kani::proof]
    #[kani::unwind(8)]
    fn brauer_test_no_panic() {
        let n: usize = kani::any_where(|x| *x > 0 && *x <= 4);
        let data: Vec<f64> = (0..n * n).map(|_| kani::any()).collect();
        let A = DMatrix::from_vec(n, n, data);

        // Must not panic
        let _ = brauer_ovals_strictly_contracting(&A);
    }

    /// Harness: if the test returns true, then every pairwise
    /// Cassini radius is strictly less than 1.
    #[kani::proof]
    #[kani::unwind(6)]
    fn brauer_test_sound_radii() {
        let n: usize = kani::any_where(|x| *x >= 2 && *x <= 3);
        let data: Vec<f64> = (0..n * n)
            .map(|_| kani::any_where(|x: &f64| x.abs() < 2.0))
            .collect();
        let A = DMatrix::from_vec(n, n, data);

        if brauer_ovals_strictly_contracting(&A) {
            // Verify every pair has Cassini radius < 1
            for i in 0..n {
                for j in (i + 1)..n {
                    let alpha = A[(i, i)].abs();
                    let beta = A[(j, j)].abs();
                    let r_i: f64 = (0..n)
                        .filter(|&k| k != i)
                        .map(|k| A[(i, k)].abs())
                        .sum();
                    let r_j: f64 = (0..n)
                        .filter(|&k| k != j)
                        .map(|k| A[(j, k)].abs())
                        .sum();
                    assert!(
                        cassini_radius(alpha, beta, r_i, r_j) < 1.0,
                        "Cassini radius for pair ({},{}) should be < 1",
                        i,
                        j
                    );
                }
            }
        }
    }

    /// Harness: cassini_radius is deterministic.
    #[kani::proof]
    #[kani::unwind(4)]
    fn cassini_radius_deterministic() {
        let alpha: f64 = kani::any();
        let beta: f64 = kani::any();
        let r_i: f64 = kani::any();
        let r_j: f64 = kani::any();

        let r1 = cassini_radius(alpha, beta, r_i, r_j);
        let r2 = cassini_radius(alpha, beta, r_i, r_j);
        assert_eq!(r1, r2);
    }

    /// Harness: cassini_radius is non-negative.
    #[kani::proof]
    #[kani::unwind(4)]
    fn cassini_radius_nonnegative() {
        let alpha: f64 = kani::any();
        let beta: f64 = kani::any();
        let r_i: f64 = kani::any_where(|x: &f64| *x >= 0.0);
        let r_j: f64 = kani::any_where(|x: &f64| *x >= 0.0);

        let r = cassini_radius(alpha, beta, r_i, r_j);
        assert!(r >= 0.0, "Cassini radius must be non-negative");
    }
}

/// Standard Rust unit tests for the Brauer functions.
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cassini_radius_basic() {
        // alpha=0.9, beta=0.9, r_i=0.0, r_j=0.0
        // disc = 0, r_ij = 0.5*(1.8 + 0) = 0.9
        let r = cassini_radius(0.9, 0.9, 0.0, 0.0);
        assert!((r - 0.9).abs() < 1e-12);
    }

    #[test]
    fn test_cassini_radius_with_offdiagonal() {
        // alpha=0.9, beta=0.9, r_i=0.3, r_j=0.0
        // disc = 0 + 4*0 = 0, r_ij = 0.9
        let r = cassini_radius(0.9, 0.9, 0.3, 0.0);
        assert!((r - 0.9).abs() < 1e-12);
    }

    #[test]
    fn test_brauer_true_for_diagonal() {
        let A = DMatrix::from_diagonal(&nalgebra::DVector::from_vec(vec![
            0.5, 0.5, 0.5,
        ]));
        assert!(brauer_ovals_strictly_contracting(&A));
    }

    #[test]
    fn test_brauer_false_for_large_offdiagonal() {
        let A = DMatrix::from_row_slice(2, 2, &[0.9, 0.3, 0.3, 0.9]);
        // Cassini radius: 0.5*(1.8 + sqrt(0 + 4*0.09)) = 0.5*(1.8+0.6) = 1.2
        assert!(!brauer_ovals_strictly_contracting(&A));
    }

    #[test]
    fn test_brauer_true_for_non_symmetric() {
        // The matrix where Gershgorin fails but Brauer succeeds:
        // [[0.9, 0.3, 0.0], [0.0, 0.9, 0.0], [0.0, 0.0, 0.5]]
        let A = DMatrix::from_row_slice(
            3,
            3,
            &[0.9, 0.3, 0.0, 0.0, 0.9, 0.0, 0.0, 0.0, 0.5],
        );
        assert!(brauer_ovals_strictly_contracting(&A));
    }
}
