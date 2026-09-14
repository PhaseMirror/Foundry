//! Serde model of `basis_factors.json` — mirrors the exact schema emitted by
//! `export_basis.py`:
//!
//! ```json
//! {"primes": [..], "max_exp": N, "basis": [{"n": N, "exponents": [..]}, ..]}
//! ```

use serde::{Deserialize, Serialize};

/// One basis element: an integer `n` and its exponent vector.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct BasisEntry {
    /// The basis integer `n`.
    pub n: u64,
    /// Valuations aligned with `primes`.
    pub exponents: Vec<u64>,
}

/// The full `basis_factors.json` document.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct BasisData {
    /// The primes generating the basis.
    pub primes: Vec<u64>,
    /// Maximum exponent per prime.
    pub max_exp: u64,
    /// Basis integers in ascending order.
    pub basis: Vec<BasisEntry>,
}

impl BasisData {
    /// Build `BasisData` from generated numbers and valuations.
    pub fn new(primes: Vec<u64>, max_exp: u64, numbers: &[u64], valuations: &[Vec<u64>]) -> Self {
        let basis = numbers
            .iter()
            .zip(valuations.iter())
            .map(|(&n, exponents)| BasisEntry {
                n,
                exponents: exponents.clone(),
            })
            .collect();
        BasisData {
            primes,
            max_exp,
            basis,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips_through_serde() {
        let data = BasisData {
            primes: vec![2, 3],
            max_exp: 1,
            basis: vec![
                BasisEntry { n: 1, exponents: vec![0, 0] },
                BasisEntry { n: 6, exponents: vec![1, 1] },
            ],
        };
        let json = serde_json::to_string(&data).unwrap();
        let back: BasisData = serde_json::from_str(&json).unwrap();
        assert_eq!(data, back);
    }
}