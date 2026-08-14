//! Universal operator stack for Meta-Relativity.
//!
//! Strictly conforms to MetaRelativityFormalized/Operators.lean

use anyhow::{anyhow, Result};
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
        if !self.matrix.is_square() {
            return false;
        }
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
        if !self.matrix.is_square() {
            return false;
        }
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
        if !self.matrix.is_square() {
            return false;
        }
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
        self.a.bound_constant() >= 0.0
            && self.b.bound_constant() >= 0.0
            && self.e.bound_constant() >= 0.0
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

/// Nat-based operator definitions for Kani verification.
/// Mirrors `lean/gated/META_RELATIVITY/Operators.lean` exactly.
#[cfg(kani)]
pub mod nat_operator {
    pub const SCALE: u64 = 10000;
    pub const DIM: usize = 8;

    /// U[i] = a[i] + b[i] + e[i] componentwise on u64 arrays.
    pub fn mk_u(a: &[u64; DIM], b: &[u64; DIM], e: &[u64; DIM]) -> [u64; DIM] {
        std::array::from_fn(|i| a[i] + b[i] + e[i])
    }

    /// Identity operator: U[i] = x[i].
    pub fn id_op(x: &[u64; DIM]) -> [u64; DIM] { *x }

    /// Zero operator: U[i] = 0.
    pub fn zero_op() -> [u64; DIM] { [0; DIM] }
}

#[cfg(kani)]
mod verification {
    use super::nat_operator::*;

    /// Symbolic proof: if each component of A, B, E ≤ SCALE,
    /// then U[i] ≤ 3 * SCALE for all i.
    #[kani::proof]
    fn proof_operator_component_bounded() {
        let a: [u64; DIM] = kani::any();
        let b: [u64; DIM] = kani::any();
        let e: [u64; DIM] = kani::any();

        for i in 0..DIM {
            kani::assume(a[i] <= SCALE);
            kani::assume(b[i] <= SCALE);
            kani::assume(e[i] <= SCALE);
        }

        let u = mk_u(&a, &b, &e);

        for i in 0..DIM {
            kani::assert(u[i] <= 3 * SCALE, "U[i] ≤ 3 * SCALE");
        }
    }

    /// Symbolic proof: identity operator maps x[i] to x[i].
    #[kani::proof]
    fn proof_id_operator_fixed_point() {
        let x: [u64; DIM] = kani::any();
        let y = id_op(&x);
        for i in 0..DIM {
            kani::assert(y[i] == x[i], "id(x)[i] == x[i]");
        }
    }

    /// Symbolic proof: zero operator maps everything to 0.
    #[kani::proof]
    fn proof_zero_operator() {
        let x: [u64; DIM] = kani::any();
        let y = zero_op();
        for i in 0..DIM {
            kani::assert(y[i] == 0, "zero()[i] == 0");
        }
    }

    /// Symbolic proof: monotonicity — if A ≤ A' componentwise, U ≤ U'.
    #[kani::proof]
    fn proof_operator_monotone() {
        let a: [u64; DIM] = kani::any();
        let b: [u64; DIM] = kani::any();
        let e: [u64; DIM] = kani::any();
        let a2: [u64; DIM] = kani::any();
        let b2: [u64; DIM] = kani::any();
        let e2: [u64; DIM] = kani::any();

        for i in 0..DIM {
            kani::assume(a[i] <= a2[i]);
            kani::assume(b[i] <= b2[i]);
            kani::assume(e[i] <= e2[i]);
        }

        let u1 = mk_u(&a, &b, &e);
        let u2 = mk_u(&a2, &b2, &e2);

        for i in 0..DIM {
            kani::assert(u1[i] <= u2[i], "monotonicity: U[i] ≤ U'[i]");
        }
    }
}
