//! Dissipative regimes for Meta-Relativity.
//!
//! Strictly conforms to MetaRelativityFormalized/Dissipative.lean

use nalgebra::DMatrix;
use crate::operators::OperatorBlock;

/// Trait to check if an operator satisfies Positivity
pub trait Positivity {
    fn is_positive_a(&self) -> bool;
    fn is_positive_b(&self) -> bool;
    fn is_positive_e(&self) -> bool;
}

/// Simplified PositivityCheck on a matrix level
pub trait PositivityCheck {
    fn is_positive_semidefinite(&self) -> bool;
}

impl PositivityCheck for DMatrix<f64> {
    fn is_positive_semidefinite(&self) -> bool {
        if !self.is_square() {
            return false;
        }
        match self.complex_eigenvalues().iter().map(|c| c.re).min_by(|a, b| a.partial_cmp(b).unwrap()) {
            Some(min_eig) => min_eig >= -1e-9,
            None => false,
        }
    }
}

/// ACE-style dominance condition: gamma >= 0
/// Mirrors the Lean class Dominance explicitly.
pub fn ace_dominance_condition(gamma: f64) -> bool {
    gamma >= 0.0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_positivity() {
        let pos_mat = DMatrix::from_row_slice(2, 2, &[1.0, 0.0, 0.0, 1.0]);
        let neg_mat = DMatrix::from_row_slice(2, 2, &[1.0, 0.0, 0.0, -1.0]);
        
        assert!(pos_mat.is_positive_semidefinite());
        assert!(!neg_mat.is_positive_semidefinite());
    }

    #[test]
    fn test_dominance() {
        assert!(ace_dominance_condition(1.0));
        assert!(!ace_dominance_condition(-1.0));
    }
}
