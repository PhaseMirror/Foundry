//! Prime Monomial Matrices (PMat)
//!
//! This module provides a Rust implementation of graded monomial matrices
//! used as the computational semantics layer between the free compact‑closed
//! syntax and scalar multiplicity invariants.  All public items are re‑exported
//! from the crate root (`pub mod pmat;`).
//!
//! # Public API
//! * `PrimeMonomialMatrix` – the matrix type.
//! * `Entry` – a signed monomial entry.
//! * `example_pmat()` – a tiny helper constructing a demonstrative matrix.
//!
//! The module is deliberately lightweight and depends only on `num-bigint`
//! and `num-rational`, matching the constraints of the surrounding project.

use std::collections::HashMap;
use num_bigint::BigInt;
use num_rational::BigRational;
use num_traits::{One, Zero};
use crate::{Signature, multiplicity};

/// Sparse representation of a signed monomial entry.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Entry {
    /// Coefficient sign: +1 or -1.
    pub sign: i8,
    /// The monomial signature (exponent vector).
    pub monomial: Signature,
}

/// Prime Monomial Matrix.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrimeMonomialMatrix {
    /// Number of rows (source objects).
    pub rows: usize,
    /// Number of columns (target objects).
    pub cols: usize,
    /// Source signatures for each row.
    pub src_sigs: Vec<Signature>,
    /// Target signatures for each column.
    pub tgt_sigs: Vec<Signature>,
    /// Sparse map: (row, col) -> Entry.
    pub entries: HashMap<(usize, usize), Entry>,
}

impl PrimeMonomialMatrix {
    /// Create an empty matrix with given source and target signature vectors.
    /// All entries are implicitly zero (i.e. absent from the map).
    pub fn new(src_sigs: Vec<Signature>, tgt_sigs: Vec<Signature>) -> Self {
        let rows = src_sigs.len();
        let cols = tgt_sigs.len();
        PrimeMonomialMatrix {
            rows,
            cols,
            src_sigs,
            tgt_sigs,
            entries: HashMap::new(),
        }
    }

    /// Insert a signed monomial entry at `(row, col)`.
    /// The function verifies the grading condition and returns an error if it
    /// is violated.
    pub fn insert(
        &mut self,
        row: usize,
        col: usize,
        sign: i8,
        monomial: Signature,
    ) -> Result<(), String> {
        if row >= self.rows || col >= self.cols {
            return Err("Row or column out of bounds".into());
        }
        if sign != 1 && sign != -1 {
            return Err("Sign must be +1 or -1".into());
        }
        // Expected grading: tgt_sigs[col] - src_sigs[row]
        let expected = self.tgt_sigs[col].mul(&self.src_sigs[row].inv());
        if monomial != expected {
            return Err(format!(
                "Grading violation at ({}, {}): expected {:?}, got {:?}",
                row, col, expected, monomial
            ));
        }
        self.entries.insert((row, col), Entry { sign, monomial });
        Ok(())
    }

    /// Validate that *all* stored entries satisfy the grading condition.
    pub fn validate(&self) -> Result<(), String> {
        for ((row, col), entry) in &self.entries {
            let expected = self.tgt_sigs[*col].mul(&self.src_sigs[*row].inv());
            if entry.monomial != expected {
                return Err(format!(
                    "Invalid entry at ({}, {}): expected {:?}, found {:?}",
                    row, col, expected, entry.monomial
                ));
            }
            if entry.sign != 1 && entry.sign != -1 {
                return Err("Entry sign must be +1 or -1".into());
            }
        }
        Ok(())
    }

    /// Compose two PMat matrices `self : A -> B` and `other : B -> C`.
    /// The dimensions must line up (`self.cols == other.rows`). The result
    /// carries the source signatures of `self` and the target signatures of
    /// `other`.
    pub fn compose(&self, other: &PrimeMonomialMatrix) -> Result<PrimeMonomialMatrix, String> {
        if self.cols != other.rows {
            return Err("Incompatible dimensions for composition".into());
        }
        // Ensure intermediate signatures match.
        for i in 0..self.cols {
            if self.tgt_sigs[i] != other.src_sigs[i] {
                return Err("Intermediate signatures do not align".into());
            }
        }
        let mut result = PrimeMonomialMatrix::new(self.src_sigs.clone(), other.tgt_sigs.clone());
        // Sparse matrix multiplication respecting signs.
        for i in 0..self.rows {
            for k in 0..self.cols {
                let a_entry = match self.entries.get(&(i, k)) {
                    Some(e) => e,
                    None => continue,
                };
                for j in 0..other.cols {
                    let b_entry = match other.entries.get(&(k, j)) {
                        Some(e) => e,
                        None => continue,
                    };
                    // Multiply signs and add signatures (exponent vectors).
                    let new_sign = a_entry.sign * b_entry.sign;
                    let new_mono = a_entry.monomial.mul(&b_entry.monomial);
                    // Insert or replace existing entry.
                    let pos = (i, j);
                    match result.entries.get_mut(&pos) {
                        Some(existing) => {
                            // Replace with the new term (coefficients are ±1).
                            existing.sign = new_sign;
                            existing.monomial = new_mono;
                        }
                        None => {
                            result.entries.insert(pos, Entry { sign: new_sign, monomial: new_mono });
                        }
                    }
                }
            }
        }
        // Validate grading of the resulting matrix.
        result.validate()?;
        Ok(result)
    }

    /// Convert the sparse PMat into a dense matrix of `BigRational` values.
    pub fn to_rational_matrix(&self) -> Vec<Vec<BigRational>> {
        let mut dense = vec![vec![BigRational::zero(); self.cols]; self.rows];
        for ((i, j), entry) in &self.entries {
            let sign_r = if entry.sign == 1 { BigRational::one() } else { -BigRational::one() };
            let val = multiplicity(&entry.monomial);
            dense[*i][*j] = sign_r * val;
        }
        dense
    }

    /// Global conservation check: product of all entry values equals the ratio
    /// of total target multiplicity to total source multiplicity.
    pub fn conservation_ok(&self) -> bool {
        let mut prod = BigRational::one();
        for entry in self.entries.values() {
            let sign_r = if entry.sign == 1 { BigRational::one() } else { -BigRational::one() };
            prod = prod * sign_r * multiplicity(&entry.monomial);
        }
        let src_total: BigRational = self.src_sigs.iter().map(|s| multiplicity(s)).product();
        let tgt_total: BigRational = self.tgt_sigs.iter().map(|s| multiplicity(s)).product();
        prod == tgt_total / src_total
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Signature;
    use num_rational::BigRational;
    use num_bigint::BigInt;
    use num_traits::One;

    fn simple_sig(p: u64, e: i64) -> Signature {
        let mut s = Signature::new();
        s.insert(p, e);
        s
    }

    #[test]
    fn test_insert_and_validate() {
        let src = vec![simple_sig(2, 1), simple_sig(3, 0)];
        let tgt = vec![simple_sig(2, 2), simple_sig(5, 1)];
        let mut m = PrimeMonomialMatrix::new(src.clone(), tgt.clone());
        // Expected monomial for (0,0): tgt[0] - src[0]
        let expected = tgt[0].mul(&src[0].inv());
        m.insert(0, 0, 1, expected.clone()).unwrap();
        assert!(m.validate().is_ok());
        // Wrong grading should error
        let bad = simple_sig(7, 1);
        assert!(m.insert(0, 1, 1, bad).is_err());
    }

    #[test]
    fn test_compose() {
        // A : X -> Y
        let src_a = vec![simple_sig(2, 1)];
        let tgt_a = vec![simple_sig(3, 1)];
        let mut a = PrimeMonomialMatrix::new(src_a.clone(), tgt_a.clone());
        a.insert(0, 0, 1, tgt_a[0].mul(&src_a[0].inv())).unwrap();
        // B : Y -> Z
        let src_b = tgt_a.clone();
        let tgt_b = vec![simple_sig(5, 2)];
        let mut b = PrimeMonomialMatrix::new(src_b.clone(), tgt_b.clone());
        b.insert(0, 0, -1, tgt_b[0].mul(&src_b[0].inv())).unwrap();
        // Compose
        let c = a.compose(&b).unwrap();
        // Expected monomial: (3^1 * 2^-1) * (5^2 * 3^-1) = 2^-1 * 5^2
        let expected_mono = tgt_b[0].mul(&src_a[0].inv());
        let entry = c.entries.get(&(0, 0)).unwrap();
        assert_eq!(entry.sign, -1);
        assert_eq!(entry.monomial, expected_mono);
    }

    #[test]
    fn test_to_rational_matrix() {
        let src = vec![simple_sig(2, 1)];
        let tgt = vec![simple_sig(2, 2)];
        let mut m = PrimeMonomialMatrix::new(src, tgt);
        let mono = m.tgt_sigs[0].mul(&m.src_sigs[0].inv());
        m.insert(0, 0, 1, mono).unwrap();
        let dense = m.to_rational_matrix();
        let expected = BigRational::new(BigInt::from(2), BigInt::one());
        assert_eq!(dense[0][0], expected);
    }
}
