//! Prime-indexed contractive operators (2×2 building block).
//!
//! Mirrors the `ap(p, cutoff)` construction from `core::hilbert_polya` for the
//! smallest non-trivial case (`cutoff = 2`), kept in this crate so Kani can
//! verify the Schur condition on the exact operator used in the paper.
//!
//! In a truncated 2-dim Fock space, `a + a† = [[0,1],[1,0]]`, so
//! `A_p = (1/√p) · [[0,1],[1,0]]`. This matrix is nonnegative and symmetric.

use ndarray::Array2;

/// Returns the 2×2 matrix A_p for a single prime with cutoff = 2.
/// A_p = (1/√p) · [[0,1],[1,0]], which is nonnegative and symmetric.
pub fn single_prime_operator_2x2(p: u64) -> Array2<f64> {
    let scale = 1.0 / (p as f64).sqrt();
    let mut a = Array2::zeros((2, 2));
    a[[0, 1]] = scale;
    a[[1, 0]] = scale;
    a
}
