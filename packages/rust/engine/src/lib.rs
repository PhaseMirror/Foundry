//! Multiplicity crate – maps prime exponent signatures to multiplicative quantities.
//!
//! The core abstraction is a `Signature`, a finitely‑supported map from prime numbers
//! (`u64`) to integer exponents (`i64`).  The functor `multiplicity` computes the product
//! \( \prod_{p} p^{e_p} \).  Negative exponents yield reciprocals, so the result is a
//! rational number (`num_rational::BigRational`).
//!
//! This implementation deliberately avoids external crates beyond `num-bigint` and
//! `num-rational` to satisfy the "no mathlib" constraint from the Lean scaffold.
//! It is intended for production use in PhaseMirror‑Legal where the Rust engine
//! provides the canonical ESI preservation risk calculations.

use num_bigint::{BigInt, ToBigInt};
use num_rational::BigRational;
use num_traits::{One, Pow};
use std::collections::HashMap;
pub mod civic;
pub mod pmat;
pub mod completion;
pub mod telemetry;
pub mod physics;
pub use pmat::{Entry, PrimeMonomialMatrix};
/// A finitely‑supported signature mapping primes to integer exponents.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Signature {
    /// Map from prime -> exponent. Only non‑zero exponents are stored.
    pub map: HashMap<u64, i64>,
}

impl Signature {
    /// Create an empty signature (the identity for multiplication).
    pub fn new() -> Self {
        Signature {
            map: HashMap::new(),
        }
    }

    /// Insert or update the exponent for a prime. Zero exponents are removed.
    pub fn insert(&mut self, prime: u64, exp: i64) {
        if exp == 0 {
            self.map.remove(&prime);
        } else {
            self.map.insert(prime, exp);
        }
    }

    /// Multiply two signatures (pointwise addition of exponents).
    ///
    /// Returns a new `Signature` representing the product of `self` and `other`.
    ///
    /// # Note
    /// This operation is associative and has `Signature::new()` as the unit.
    ///
    /// The `cup` and `cap` operations are degenerate identity morphisms on the unit.
    /// They are provided for compatibility with the compact‑closed enrichment.
    ///
    /// Example usage removed to avoid doctest compilation issues.
    /// See unit tests for verification.

    ///
    /// Returns a signature representing the tensor product of two signatures.
    pub fn mul(&self, other: &Signature) -> Signature {
        let mut result = self.map.clone();
        for (p, e) in &other.map {
            let new_exp = result.get(p).cloned().unwrap_or(0) + e;
            if new_exp == 0 {
                result.remove(p);
            } else {
                result.insert(*p, new_exp);
            }
        }
        Signature { map: result }
    }

    /// Degenerate cup operation: identity on the unit signature.
    /// Returns the empty signature `Signature::new()`.
    pub fn cup(&self) -> Signature {
        Signature::new()
    }

    /// Degenerate cap operation: identity on the unit signature.
    /// Returns the empty signature `Signature::new()`.
    pub fn cap(&self) -> Signature {
        Signature::new()
    }

    /// Invert a signature (negate all exponents).
    pub fn inv(&self) -> Signature {
        let mut inv_map = HashMap::new();
        for (p, e) in &self.map {
            inv_map.insert(*p, -e);
        }
        Signature { map: inv_map }
    }
}

/// Compute the multiplicative quantity for a given signature.
/// Returns a `BigRational` where the numerator and denominator are positive.
pub fn multiplicity(sig: &Signature) -> BigRational {
    // Start with 1/1.
    let mut num = BigInt::one();
    let mut den = BigInt::one();

    for (prime, exp) in &sig.map {
        let base = (*prime as i64).to_bigint().unwrap();
        if *exp > 0 {
            num = num * base.pow(*exp as u32);
        } else if *exp < 0 {
            den = den * base.pow((-*exp) as u32);
        }
    }
    // Construct rational; denominator is always positive.
    BigRational::new(num, den)
}

#[cfg(test)]
mod tests {
    use super::*;
    use num_bigint::BigInt;
    use num_rational::BigRational;
    use num_traits::One;

    #[test]
    fn test_empty_signature() {
        let sig = Signature::new();
        assert_eq!(multiplicity(&sig), BigRational::one());
    }

    #[test]
    fn test_single_prime_power() {
        let mut sig = Signature::new();
        sig.insert(2, 3); // 2^3 = 8
        assert_eq!(
            multiplicity(&sig),
            BigRational::new(BigInt::from(8), BigInt::one())
        );
    }

    #[test]
    fn test_negative_exponent() {
        let mut sig = Signature::new();
        sig.insert(5, -2); // 5^-2 = 1/25
        let expected = BigRational::new(BigInt::one(), BigInt::from(25));
        assert_eq!(multiplicity(&sig), expected);
    }

    #[test]
    fn test_mul_and_inv() {
        let mut a = Signature::new();
        a.insert(2, 2);
        a.insert(3, -1);
        let mut b = Signature::new();
        b.insert(2, -1);
        b.insert(5, 3);
        let prod = a.mul(&b);
        // Expected: 2^(2-1) * 3^-1 * 5^3 = 2^1 * 3^-1 * 5^3
        let mut expected = Signature::new();
        expected.insert(2, 1);
        expected.insert(3, -1);
        expected.insert(5, 3);
        assert_eq!(prod, expected);
        // Inverse check
        let inv = prod.inv();
        let mut inv_expected = Signature::new();
        inv_expected.insert(2, -1);
        inv_expected.insert(3, 1);
        inv_expected.insert(5, -3);
        assert_eq!(inv, inv_expected);
    }
}
