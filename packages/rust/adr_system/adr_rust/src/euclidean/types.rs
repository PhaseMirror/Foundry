//! Types for Euclidean multiplicity.

use serde::{Deserialize, Serialize};

/// The Euclidean integer hierarchy (Section I of ADR-0004).
///
/// ```text
/// unit → number → prime → composite → product of primes
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum IntegerClass {
    /// The multiplicative identity: 1.
    Unit,
    /// Any integer > 1 that is not composite.
    Number,
    /// An integer p > 1 with no divisors in {1, p}.
    Prime,
    /// An integer n > 1 with a non-trivial factorization n = a·b.
    Composite,
}

/// Prime factorization: a multiset of (prime, exponent) pairs.
///
/// For n = 60 = 2²·3¹·5¹ the representation is:
/// `[(2, 2), (3, 1), (5, 1)]`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Factorization {
    pub factors: Vec<(u64, u64)>, // (prime, exponent)
}

impl Factorization {
    /// Construct a factorization from a vector of (prime, exponent) pairs.
    pub fn new(factors: Vec<(u64, u64)>) -> Self {
        Self { factors }
    }

    /// The value of the integer represented by this factorization.
    pub fn value(&self) -> u64 {
        self.factors.iter().map(|(p, a)| p.pow(*a as u32)).product()
    }

    /// Number of distinct prime factors: ω(n).
    pub fn omega(&self) -> usize {
        self.factors.len()
    }

    /// Total number of prime factors with multiplicity: Ω(n).
    pub fn big_omega(&self) -> u64 {
        self.factors.iter().map(|(_, a)| a).sum()
    }

    /// Divisor count: τ(n) = ∏ (a_i + 1).
    pub fn tau(&self) -> u64 {
        self.factors
            .iter()
            .map(|(_, a)| a + 1)
            .product()
    }

    /// Sum of divisors: σ(n) = ∏ (p_i^{a_i+1} - 1) / (p_i - 1).
    pub fn sigma(&self) -> u64 {
        self.factors
            .iter()
            .map(|(p, a)| {
                let mut sum = 1;
                let mut term = 1;
                for _ in 0..*a {
                    term *= p;
                    sum += term;
                }
                sum
            })
            .product()
    }
}

/// A node in the divisor poset D(n).
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct DivisorNode {
    pub value: u64,
    pub depth: usize, // distance from 1 in the Hasse diagram
}

/// The divisor poset D(n) = {d : d | n}, ordered by divisibility.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DivisorPoset {
    pub n: u64,
    pub nodes: Vec<DivisorNode>,
}

impl DivisorPoset {
    /// Construct D(n) for a given n.
    pub fn new(n: u64) -> Self {
        let mut nodes = Vec::new();
        let divisors: Vec<u64> = (1..=n).filter(|d| n % d == 0).collect();
        for &d in &divisors {
            // depth = number of prime factors in d (with multiplicity)
            let mut depth = 0usize;
            let mut temp = d;
            let mut p = 2u64;
            while p * p <= temp {
                while temp % p == 0 {
                    depth += 1;
                    temp /= p;
                }
                p += 1;
            }
            if temp > 1 {
                depth += 1;
            }
            nodes.push(DivisorNode { value: d, depth });
        }
        Self { n, nodes }
    }

    /// Number of nodes in the poset: |D(n)| = τ(n).
    pub fn len(&self) -> usize {
        self.nodes.len()
    }

    /// Whether the poset is empty (only possible for n = 0, which we exclude).
    pub fn is_empty(&self) -> bool {
        self.nodes.is_empty()
    }
}

/// The multiplicity profile of an integer n.
///
/// Bundles all standard arithmetic functions into one structure.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MultiplicityProfile {
    pub n: u64,
    pub class: IntegerClass,
    pub factorization: Factorization,
    pub divisor_poset: DivisorPoset,
    pub tau: u64,
    pub sigma: u64,
    pub omega: usize,
    pub big_omega: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn factorization_value() {
        let f = Factorization::new(vec![(2, 2), (3, 1), (5, 1)]);
        assert_eq!(f.value(), 60);
    }

    #[test]
    fn tau_formula() {
        let f = Factorization::new(vec![(2, 3), (3, 2), (5, 1)]);
        // τ(360) = (3+1)(2+1)(1+1) = 24
        assert_eq!(f.tau(), 24);
    }

    #[test]
    fn divisor_poset_size() {
        let poset = DivisorPoset::new(12);
        // D(12) = {1, 2, 3, 4, 6, 12}, |D(12)| = 6
        assert_eq!(poset.len(), 6);
    }

    #[test]
    fn multiplicity_profile_60() {
        let f = Factorization::new(vec![(2, 2), (3, 1), (5, 1)]);
        let poset = DivisorPoset::new(60);
        let profile = MultiplicityProfile {
            n: 60,
            class: IntegerClass::Composite,
            factorization: f.clone(),
            divisor_poset: poset,
            tau: f.tau(),
            sigma: f.sigma(),
            omega: f.omega(),
            big_omega: f.big_omega(),
        };
        assert_eq!(profile.tau, 12); // (2+1)(1+1)(1+1) = 12
        assert_eq!(profile.omega, 3);
    }
}
