//! Structural and spectral invariants for Meta-Relativity.
//!
//! Based on ADR-093: Meta-Relativity — Structural and Spectral Invariants.

use anyhow::{Result, anyhow};
use nalgebra::{DMatrix, Complex};
use std::collections::HashMap;

/// Multiplicity Functor: M(e) = ∏ p^e_p
pub trait MultiplicityFunctor {
    fn multiplicity(&self, signature: &HashMap<u64, i64>) -> i64;
}

/// Spectral Invariants check.
pub trait SpectralInvariants {
    fn spectrum(&self) -> Result<Vec<f64>>;
}

impl SpectralInvariants for DMatrix<f64> {
    fn spectrum(&self) -> Result<Vec<f64>> {
        if !self.is_square() {
            return Err(anyhow!("Matrix must be square to compute spectrum"));
        }
        let eigs = self.complex_eigenvalues();
        let mut eigs_vec: Vec<f64> = eigs.iter().map(|c: &Complex<f64>| c.re).collect();
        eigs_vec.sort_by(|a, b| a.partial_cmp(b).unwrap());
        Ok(eigs_vec)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_spectrum_invariance() {
        let mat = DMatrix::from_row_slice(2, 2, &[1.0, 0.0, 0.0, 2.0]);
        let spectrum = mat.spectrum().unwrap();
        assert_eq!(spectrum, vec![1.0, 2.0]);
    }
}
