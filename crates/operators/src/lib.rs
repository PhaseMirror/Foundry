use serde::{Deserialize, Serialize};
use ndarray::Array1;
use nalgebra::{DMatrix, DVector};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum OperatorError {
    #[error("Not a prime index: {0}")]
    NotPrime(u64),
    #[error("Dimension mismatch: expected {expected}, found {found}")]
    DimensionMismatch { expected: usize, found: usize },
}

pub const UNIVERSAL_CONSTANT_U: f64 = 1.0;

/// The canonical Ξ(t) operator for PIRTM.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XiOperator {
    modulus: u64,
    u: f64,
}

impl XiOperator {
    pub fn new(modulus: u64) -> Result<Self, OperatorError> {
        if !is_prime(modulus) {
            return Err(OperatorError::NotPrime(modulus));
        }
        Ok(XiOperator {
            modulus,
            u: UNIVERSAL_CONSTANT_U,
        })
    }

    pub fn modulus(&self) -> u64 {
        self.modulus
    }

    pub fn u(&self) -> f64 {
        self.u
    }

    /// Apply Ξ(t) to state vector ψ on prime fiber p.
    /// A_p(t) = exp(-U · log(p) · t) · I
    pub fn evolve(&self, psi: &DVector<f64>, t: f64) -> DVector<f64> {
        let decay = (-self.u * (self.modulus as f64).ln() * t).exp();
        psi * decay
    }

    /// The spectral norm ||Ξ(t)||.
    pub fn norm(&self, t: f64) -> f64 {
        (-self.u * (self.modulus as f64).ln() * t).exp()
    }
}

/// Multiplicity Operator M = Σ A_p
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicitySumOperator {
    moduli: Vec<u64>,
    operators: Vec<XiOperator>,
}

impl MultiplicitySumOperator {
    pub fn new(moduli: Vec<u64>) -> Result<Self, OperatorError> {
        let mut sorted_moduli = moduli;
        sorted_moduli.sort_unstable();
        
        let mut operators = Vec::with_capacity(sorted_moduli.len());
        for &m in &sorted_moduli {
            operators.push(XiOperator::new(m)?);
        }
        
        Ok(MultiplicitySumOperator {
            moduli: sorted_moduli,
            operators,
        })
    }

    pub fn moduli(&self) -> &[u64] {
        &self.moduli
    }

    /// Apply M(t) = Σ Ξ_p(t) to the state vector psi.
    pub fn evolve(&self, psi: &DVector<f64>, t: f64) -> DVector<f64> {
        let total_decay: f64 = self.operators.iter().map(|op| op.norm(t)).sum();
        psi * total_decay
    }

    /// Return the diagonal matrix representation of M(t) for a given dimension.
    pub fn get_matrix(&self, dim: usize, t: f64) -> DMatrix<f64> {
        let total_decay: f64 = self.operators.iter().map(|op| op.norm(t)).sum();
        DMatrix::from_diagonal(&DVector::from_element(dim, total_decay))
    }

    /// The spectral norm ||M(t)||.
    pub fn operator_norm(&self, t: f64) -> f64 {
        self.operators.iter().map(|op| op.norm(t)).sum()
    }
}

fn is_prime(n: u64) -> bool {
    if n < 2 { return false; }
    if n == 2 || n == 3 { return true; }
    if n % 2 == 0 || n % 3 == 0 { return false; }
    let mut i = 5;
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 { return false; }
        i += 6;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_xi_operator_new() {
        assert!(XiOperator::new(13).is_ok());
        assert!(XiOperator::new(14).is_err());
    }

    #[test]
    fn test_xi_evolve() {
        let op = XiOperator::new(2).unwrap();
        let psi = DVector::from_vec(vec![1.0, 1.0]);
        let t = 1.0;
        let evolved = op.evolve(&psi, t);
        let expected_decay = (-1.0 * (2.0f64).ln() * 1.0).exp();
        assert!((evolved[0] - expected_decay).abs() < 1e-10);
    }

    #[test]
    fn test_multiplicity_sum_operator() {
        let op = MultiplicitySumOperator::new(vec![2, 3]).unwrap();
        let psi = DVector::from_vec(vec![1.0]);
        let evolved = op.evolve(&psi, 1.0);
        let expected = (-1.0 * 2.0f64.ln()).exp() + (-1.0 * 3.0f64.ln()).exp();
        assert!((evolved[0] - expected).abs() < 1e-10);
    }
}
