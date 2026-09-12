//! Prime-indexed tensor field operations.
//!
//! Implements tensor structures over prime-indexed dimensions with
//! verified coefficient bounds and contraction properties.

use crate::error::{Error, Result};

/// Tensor coefficient with prime index metadata.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TensorCoeff {
    /// Prime index p_i.
    pub prime_index: u64,
    /// Coefficient value (bounded).
    pub value: i32,
}

impl TensorCoeff {
    /// Create a new tensor coefficient.
    pub fn new(prime_index: u64, value: i32) -> Self {
        Self { prime_index, value }
    }

    /// Get the prime index.
    pub fn prime_index(&self) -> u64 {
        self.prime_index
    }

    /// Get the coefficient value.
    pub fn value(&self) -> i32 {
        self.value
    }
}

/// Prime-indexed tensor field T_Λm(p_i).
///
/// Represents a tensor field over the first N primes with
/// bounded coefficients.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TensorField {
    coefficients: Vec<TensorCoeff>,
    max_coeff: i32,
}

impl TensorField {
    /// Create a new tensor field with bounded coefficients.
    pub fn new(coefficients: Vec<TensorCoeff>, max_coeff: i32) -> Self {
        Self {
            coefficients,
            max_coeff,
        }
    }

    /// Get the number of tensor components.
    pub fn len(&self) -> usize {
        self.coefficients.len()
    }

    /// Check if empty.
    pub fn is_empty(&self) -> bool {
        self.coefficients.is_empty()
    }

    /// Get coefficient at index.
    pub fn get(&self, index: usize) -> Option<&TensorCoeff> {
        self.coefficients.get(index)
    }

    /// Compute the contraction sum Σ T(p_i) * p_i^β.
    ///
    /// # Errors
    ///
    /// Returns error if β <= 0 (non-convergent).
    pub fn contract(&self, beta: f64) -> Result<f64> {
        if beta <= 0.0 {
            return Err(Error::tensor_invariant(
                "beta must be > 0 for convergence",
            ));
        }
        let mut sum = 0.0;
        for coeff in &self.coefficients {
            let term = (coeff.value() as f64) * (coeff.prime_index() as f64).powf(-beta);
            sum += term;
        }
        Ok(sum)
    }

    /// Verify coefficient bound: |T(p_i)| <= C.
    pub fn verify_bounds(&self) -> bool {
        self.coefficients
            .iter()
            .all(|c| c.value().abs() <= self.max_coeff)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tensor_field_creation() {
        let coeffs = vec![TensorCoeff::new(2, 1), TensorCoeff::new(3, -1)];
        let field = TensorField::new(coeffs, 10);
        assert_eq!(field.len(), 2);
    }

    #[test]
    fn test_tensor_contract() {
        let coeffs = vec![TensorCoeff::new(2, 1), TensorCoeff::new(3, 1)];
        let field = TensorField::new(coeffs, 10);
        let sum = field.contract(2.0).unwrap();
        assert!(sum > 0.0);
    }

    #[test]
    fn test_tensor_contract_beta_zero_fails() {
        let coeffs = vec![TensorCoeff::new(2, 1)];
        let field = TensorField::new(coeffs, 10);
        assert!(field.contract(0.0).is_err());
    }

    #[test]
    fn test_tensor_verify_bounds() {
        let coeffs = vec![TensorCoeff::new(2, 5), TensorCoeff::new(3, 3)];
        let field = TensorField::new(coeffs, 5);
        assert!(field.verify_bounds());
    }
}
