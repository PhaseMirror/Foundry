//! # echonomics_engine::uor_geometry — ADR-0003: UOR Healthcare Nexus & L0 Prime Geometry
//!
//! Prime-locked geometry and exact rational conservation bounds for UOR
//! Healthcare Nexus asset transfers.
//!
//! The ADR mandates: `prime_factor_sum <= conservation_bound`.
//!
//! Pure, side-effect-free functions (`is_conserved`,
//! `evaluate_conservation_gate`, `is_prime`) are kept free of hashing and
//! allocation so Kani can discharge them symbolically. The stateful
//! `PrimeGeometry` engine delegates to the same pure core.

use serde::{Deserialize, Serialize};

/// Canonical outcomes of the UOR conservation gate (mirrors Lean
/// `ConservationDecision`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConservationDecision {
    Seal,
    RejOverBound,
}

/// ADR Decision 1: conservation holds exactly when the prime factor sum does
/// not exceed the conservation bound.
#[inline]
pub const fn is_conserved(prime_factor_sum: u64, conservation_bound: u64) -> bool {
    prime_factor_sum <= conservation_bound
}

/// Exact conservation: factor sum equals the bound.
#[inline]
pub const fn is_exact_conservation(prime_factor_sum: u64, conservation_bound: u64) -> bool {
    prime_factor_sum == conservation_bound
}

/// The single conservation gate (mirrors Lean `evaluateConservationGate`).
/// Seals exactly when conservation holds; otherwise fails closed.
#[inline]
pub const fn evaluate_conservation_gate(
    prime_factor_sum: u64,
    conservation_bound: u64,
) -> ConservationDecision {
    if is_conserved(prime_factor_sum, conservation_bound) {
        ConservationDecision::Seal
    } else {
        ConservationDecision::RejOverBound
    }
}

/// Trial-division primality over a bounded `u16` domain. Deterministic and
/// side-effect free.
pub fn is_prime(n: u16) -> bool {
    if n < 2 {
        return false;
    }
    // Only need to test divisors up to sqrt(n) for efficiency; for a bounded
    // u16 domain we test all d in [2, n-1], which is exact.
    let mut d: u16 = 2;
    while d < n {
        if n % d == 0 {
            return false;
        }
        d += 1;
    }
    true
}

/// A state is prime-locked when its factor sum is prime.
pub fn is_prime_locked(prime_factor_sum: u64) -> bool {
    // Only sums representable in u16 are considered for primality on the
    // locked geometry.
    if prime_factor_sum > u16::MAX as u64 {
        return false;
    }
    is_prime(prime_factor_sum as u16)
}

/// Stateful engine that delegates to the pure conservation core.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeGeometry {
    pub prime_factor_sum: u64,
    pub conservation_bound: u64,
}

impl PrimeGeometry {
    pub fn new(prime_factor_sum: u64, conservation_bound: u64) -> Self {
        Self {
            prime_factor_sum,
            conservation_bound,
        }
    }

    pub fn is_conserved(&self) -> bool {
        is_conserved(self.prime_factor_sum, self.conservation_bound)
    }

    pub fn evaluate_gate(&self) -> ConservationDecision {
        evaluate_conservation_gate(self.prime_factor_sum, self.conservation_bound)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_geometry_conservation() {
        let pg = PrimeGeometry::new(12, 20);
        assert!(pg.is_conserved());
        assert_eq!(pg.evaluate_gate(), ConservationDecision::Seal);
    }

    #[test]
    fn test_over_bound_rejected() {
        let pg = PrimeGeometry::new(25, 20);
        assert!(!pg.is_conserved());
        assert_eq!(pg.evaluate_gate(), ConservationDecision::RejOverBound);
    }

    #[test]
    fn test_exact_conservation_seals() {
        assert!(is_exact_conservation(20, 20));
        assert_eq!(evaluate_conservation_gate(20, 20), ConservationDecision::Seal);
    }

    #[test]
    fn test_monotone_in_bound() {
        // if conserved at b, then also conserved at any larger bound
        assert!(is_conserved(12, 20));
        assert!(is_conserved(12, 30));
        assert!(is_conserved(12, u64::MAX));
    }

    #[test]
    fn test_zero_bound_rejects_positive() {
        assert!(!is_conserved(5, 0));
        assert_eq!(evaluate_conservation_gate(5, 0), ConservationDecision::RejOverBound);
    }

    #[test]
    fn test_is_prime() {
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(is_prime(5));
        assert!(is_prime(7));
        assert!(!is_prime(1));
        assert!(!is_prime(0));
        assert!(!is_prime(4));
        assert!(!is_prime(9));
        assert!(!is_prime(15));
    }

    #[test]
    fn test_prime_locked() {
        // prime factor sum 2 is prime-locked
        assert!(is_prime_locked(2));
        // prime factor sum 4 is not prime-locked
        assert!(!is_prime_locked(4));
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    // Over-bound factor sum always fails closed.
    #[kani::proof]
    fn verify_over_bound_fails_closed() {
        let sum: u64 = kani::any();
        let bound: u64 = kani::any();
        kani::assume(bound < sum);
        let d = evaluate_conservation_gate(sum, bound);
        kani::assert(d == ConservationDecision::RejOverBound, "Over-bound must be rejected");
    }

    // Seal is sound: a sealed transfer is conserved.
    #[kani::proof]
    fn verify_seal_implies_conserved() {
        let sum: u64 = kani::any();
        let bound: u64 = kani::any();
        let d = evaluate_conservation_gate(sum, bound);
        kani::assume(d == ConservationDecision::Seal);
        kani::assert(is_conserved(sum, bound), "A sealed transfer must be conserved");
    }

    // Completeness: a conserved transfer is sealed.
    #[kani::proof]
    fn verify_conserved_implies_seal() {
        let sum: u64 = kani::any();
        let bound: u64 = kani::any();
        kani::assume(is_conserved(sum, bound));
        let d = evaluate_conservation_gate(sum, bound);
        kani::assert(d == ConservationDecision::Seal, "A conserved transfer must be sealed");
    }

    // Zero bound rejects any positive factor sum.
    #[kani::proof]
    fn verify_zero_bound_rejects_positive() {
        let sum: u64 = kani::any();
        kani::assume(sum > 0);
        let d = evaluate_conservation_gate(sum, 0);
        kani::assert(d == ConservationDecision::RejOverBound, "Zero bound rejects positive sum");
    }

    // Exact conservation (sum == bound) always seals.
    #[kani::proof]
    fn verify_exact_conservation_seals() {
        let n: u64 = kani::any();
        let d = evaluate_conservation_gate(n, n);
        kani::assert(d == ConservationDecision::Seal, "Exact conservation seals");
    }

    // Monotonicity in bound: if conserved at b, conserved at any larger bound.
    #[kani::proof]
    fn verify_monotone_in_bound() {
        let sum: u64 = kani::any();
        let b1: u64 = kani::any();
        let b2: u64 = kani::any();
        kani::assume(is_conserved(sum, b1));
        kani::assume(b1 <= b2);
        kani::assert(
            is_conserved(sum, b2),
            "Conservation is monotone in the bound",
        );
    }

    // Small primality facts (concrete, bounded — no unbounded unrolling).
    #[kani::proof]
    fn verify_small_primes() {
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(!is_prime(4));
        assert!(is_prime(5));
        assert!(!is_prime(1));
        assert!(!is_prime(0));
    }
}
