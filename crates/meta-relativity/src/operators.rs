//! Universal operator stack for Meta-Relativity.
//!
//! Strictly conforms to MetaRelativityFormalized/Operators.lean

use anyhow::{Result, anyhow};
use nalgebra::{DMatrix, DVector};

/// Universal Operator: U = A + B + E
pub struct UniversalOperator {
    pub a: PrimeBlock,
    pub b: TimeSieve,
    pub e: InternalBlock,
}

impl UniversalOperator {
    pub fn assemble(a: PrimeBlock, b: TimeSieve, e: InternalBlock) -> Self {
        Self { a, b, e }
    }
    
    pub fn apply(&self, x: &DVector<f64>) -> DVector<f64> {
        self.a.apply(x) + self.b.apply(x) + self.e.apply(x)
    }
}

/// A block that acts as an operator on a space.
pub trait OperatorBlock {
    fn apply(&self, x: &DVector<f64>) -> DVector<f64>;
    fn is_self_adjoint(&self) -> bool;
    fn bound_constant(&self) -> f64; // returns the bounding constant c
}

/// Prime Block (A)
pub struct PrimeBlock {
    pub matrix: DMatrix<f64>,
}

impl OperatorBlock for PrimeBlock {
    fn apply(&self, x: &DVector<f64>) -> DVector<f64> {
        &self.matrix * x
    }
    fn is_self_adjoint(&self) -> bool {
        if !self.matrix.is_square() { return false; }
        (self.matrix.clone() - self.matrix.adjoint()).norm() <= 1e-9
    }
    fn bound_constant(&self) -> f64 {
        self.matrix.norm()
    }
}

/// Time-Sieve Block (B)
pub struct TimeSieve {
    pub matrix: DMatrix<f64>,
}

impl OperatorBlock for TimeSieve {
    fn apply(&self, x: &DVector<f64>) -> DVector<f64> {
        &self.matrix * x
    }
    fn is_self_adjoint(&self) -> bool {
        if !self.matrix.is_square() { return false; }
        (self.matrix.clone() - self.matrix.adjoint()).norm() <= 1e-9
    }
    fn bound_constant(&self) -> f64 {
        self.matrix.norm()
    }
}

/// Internal Block (E)
pub struct InternalBlock {
    pub matrix: DMatrix<f64>,
}

impl OperatorBlock for InternalBlock {
    fn apply(&self, x: &DVector<f64>) -> DVector<f64> {
        &self.matrix * x
    }
    fn is_self_adjoint(&self) -> bool {
        if !self.matrix.is_square() { return false; }
        (self.matrix.clone() - self.matrix.adjoint()).norm() <= 1e-9
    }
    fn bound_constant(&self) -> f64 {
        self.matrix.norm()
    }
}

pub trait BoundedOperator {
    fn is_bounded(&self) -> bool;
}

impl BoundedOperator for UniversalOperator {
    fn is_bounded(&self) -> bool {
        // According to Lean, there exists c_A, c_B, c_E
        self.a.bound_constant() >= 0.0 && self.b.bound_constant() >= 0.0 && self.e.bound_constant() >= 0.0
    }
}

pub trait SelfAdjointOperatorStack {
    fn is_self_adjoint_stack(&self) -> bool;
}

impl SelfAdjointOperatorStack for UniversalOperator {
    fn is_self_adjoint_stack(&self) -> bool {
        self.a.is_self_adjoint() && self.b.is_self_adjoint() && self.e.is_self_adjoint()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_internal_block_self_adjoint() {
        let mat = DMatrix::from_row_slice(2, 2, &[1.0, 0.5, 0.5, 1.0]);
        let block = InternalBlock { matrix: mat };
        assert!(block.is_self_adjoint());
    }

    #[test]
    fn test_internal_block_non_self_adjoint() {
        let mat = DMatrix::from_row_slice(2, 2, &[1.0, 0.5, 0.0, 1.0]);
        let block = InternalBlock { matrix: mat };
        assert!(!block.is_self_adjoint());
    }
}
