//! Unbounded generators and sectorial extensions for Meta-Relativity.
//!
//! Based on ADR-100: Meta-Relativity — Unbounded Generators and Sectorial Extensions.

use nalgebra::DMatrix;

/// Trait to check if an operator is sectorial with angle phi.
pub trait SectorialCheck {
    fn is_sectorial(&self, phi: f64) -> bool;
}

impl SectorialCheck for DMatrix<f64> {
    fn is_sectorial(&self, phi: f64) -> bool {
        if !self.is_square() {
            return false;
        }
        let eigs = self.complex_eigenvalues();
        eigs.iter().all(|c| {
            let arg = c.arg().abs();
            arg <= phi
        })
    }
}

/// Check Kato–Rellich relative form-boundedness: ||K|| < bound * ||A0||
pub fn is_form_bounded(k_norm: f64, a0_norm: f64, bound: f64) -> bool {
    k_norm < bound * a0_norm
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sectorial() {
        // Eigenvalues are 1.0, 1.0. Angles are 0.
        let op = DMatrix::from_row_slice(2, 2, &[1.0, 0.0, 0.0, 1.0]);
        assert!(op.is_sectorial(0.1));
    }

    #[test]
    fn test_form_bounded() {
        assert!(is_form_bounded(0.1, 1.0, 0.5));
        assert!(!is_form_bounded(0.6, 1.0, 0.5));
    }
}
