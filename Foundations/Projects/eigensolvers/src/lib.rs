//! EigenSolvers – minimal linear‑algebra utilities with Kani proofs.
//!
//! This crate provides very small helper functions for 2×2 matrices.
//! It is deliberately simple because the surrounding Lean file is only a placeholder.
//!
//! The implementation uses `nalgebra::Matrix2<f64>` for convenience, but the
//! functions are pure arithmetic and therefore easy for Kani to verify.

use nalgebra::Matrix2;

/// Construct a 2×2 matrix from its four entries.
pub fn matrix2(a: f64, b: f64, c: f64, d: f64) -> Matrix2<f64> {
    Matrix2::new(a, b, c, d)
}

/// Compute the trace of a 2×2 matrix: `a + d`.
pub fn trace(m: &Matrix2<f64>) -> f64 {
    m[(0, 0)] + m[(1, 1)]
}

/// Compute the determinant of a 2×2 matrix: `a*d - b*c`.
pub fn determinant(m: &Matrix2<f64>) -> f64 {
    m[(0, 0)] * m[(1, 1)] - m[(0, 1)] * m[(1, 0)]
}

#[cfg(test)]
mod tests {
    use super::*;
    use kani::proof;

    #[proof]
    fn test_trace() {
        // arbitrary concrete values – Kani can reason about them concretely.
        let m = matrix2(1.0, 2.0, 3.0, 4.0);
        let tr = trace(&m);
        assert!(tr == 5.0);
    }

    #[proof]
    fn test_determinant() {
        let m = matrix2(1.0, 2.0, 3.0, 4.0);
        let det = determinant(&m);
        // 1*4 - 2*3 = 4 - 6 = -2
        assert!(det == -2.0);
    }
}

