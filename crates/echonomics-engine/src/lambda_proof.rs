//! # echonomics_engine::lambda_proof — ADR-0006: Lambda-Proof Smart Contracts & ZK Circuits
//!
//! Formal, fail-closed binding of the Lambda identity commitment and the
//! on-tree Circom ZK circuit predicates (see `circuits/`):
//!
//! - **PrimeCheck.circom**: accepts `n` as a "prime candidate" when `n` is odd
//!   and greater than three. Documented limitation (mirrored here): the demo
//!   circuit accepts composites such as `9, 15, 21`; production deployments
//!   use Miller–Rabin. `is_prime_candidate` implements exactly the circuit.
//! - **DriftBound.circom**: enforces `10·δ ≤ 3·ξ` (equiv. `δ ≤ 0.3·ξ`,
//!   `ε = 0.3`), the in-circuit realization of ADR-0005 Lawful Recursion.
//!   `satisfies_drift_bound` uses `u128` products to avoid overflow.
//! - **Composite LambdaProof**: verifies iff the identity is lawful, the drift
//!   is circuit-bounded, the seat log is anchored (non-zero hash), and a ZK
//!   attestation is present. Fail-closed: any missing ingredient denies.
//!
//! `u128` products keep the drift predicate total and Kani-dischargeable with
//! no overflow guards; all other arithmetic is pure `u64`/`bool`.

use serde::{Deserialize, Serialize};

/// A Lambda identity commitment. `prime_salt` is the prime candidate; `is_verified`
/// records whether it has been vetted.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct LambdaIdentityCommitment {
    pub identity_id: u64,
    pub prime_salt: u64,
    pub is_verified: bool,
}

impl LambdaIdentityCommitment {
    pub fn new(identity_id: u64, prime_salt: u64, is_verified: bool) -> Self {
        Self { identity_id, prime_salt, is_verified }
    }
}

/// PrimeCheck.circom LSB check: `n` is odd.
#[inline]
pub const fn is_odd(n: u64) -> bool {
    n % 2 == 1
}

/// PrimeCheck.circom: `isPrime = gt3.out * isOdd`, i.e. `n > 3` and `n` odd.
///
/// ⚠️ Documented limitation (mirrors the circuit): NOT cryptographically secure;
/// composites such as `9, 15, 21` pass. Production uses Miller–Rabin.
#[inline]
pub const fn is_prime_candidate(n: u64) -> bool {
    n > 3 && is_odd(n)
}

/// DriftBound.circom: `10·δ ≤ 3·ξ` (equiv. `δ ≤ 0.3·ξ`, `ε = 0.3`). Uses `u128`
/// products so the predicate is total and Kani-dischargeable without overflow.
#[inline]
pub const fn satisfies_drift_bound(delta: u64, xi: u64) -> bool {
    (10u128 * delta as u128) <= (3u128 * xi as u128)
}

/// A certified Lambda identity must be vetted and carry a PrimeCheck-valid salt.
#[inline]
pub const fn is_identity_lawful(idc: &LambdaIdentityCommitment) -> bool {
    idc.is_verified && is_prime_candidate(idc.prime_salt)
}

/// A composite Lambda proof: identity commitment, drift pair feeding DriftBound,
/// seat-log hash anchored to an EVM anchor, and a ZK attestation flag.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct LambdaProof {
    pub identity: LambdaIdentityCommitment,
    pub drift_delta: u64,
    pub drift_xi: u64,
    pub seat_log_hash: u64,
    pub zk_attested: bool,
}

impl LambdaProof {
    pub const fn new(
        identity: LambdaIdentityCommitment,
        drift_delta: u64,
        drift_xi: u64,
        seat_log_hash: u64,
        zk_attested: bool,
    ) -> Self {
        Self { identity, drift_delta, drift_xi, seat_log_hash, zk_attested }
    }

    /// Verifies iff the identity is lawful, the drift is bounded, the seat log
    /// is anchored (non-zero hash), and a ZK attestation is present.
    #[inline]
    pub const fn is_verified(&self) -> bool {
        is_identity_lawful(&self.identity)
            && satisfies_drift_bound(self.drift_delta, self.drift_xi)
            && self.seat_log_hash > 0
            && self.zk_attested
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn clean_identity() -> LambdaIdentityCommitment {
        LambdaIdentityCommitment::new(42, 1009, true)
    }

    #[test]
    fn test_prime_candidate_odd_and_gt3() {
        assert!(is_prime_candidate(1009));
        assert!(is_prime_candidate(9)); // documented: demo circuit accepts odd composites
        assert!(!is_prime_candidate(4)); // even -> rejected
        assert!(!is_prime_candidate(2)); // even -> rejected
        assert!(!is_prime_candidate(0));
    }

    #[test]
    fn test_prime_candidate_small_rejected() {
        for n in [0u64, 1, 2, 3] {
            assert!(!is_prime_candidate(n), "n={n} must be rejected");
        }
    }

    #[test]
    fn test_drift_bound_linear() {
        assert!(satisfies_drift_bound(1, 10)); // 10 <= 30
        assert!(!satisfies_drift_bound(5, 2)); // 50 > 6
        assert!(satisfies_drift_bound(100, 400)); // 1000 <= 1200
    }

    #[test]
    fn test_identity_lawful_requires_verified_and_prime_salt() {
        assert!(is_identity_lawful(&clean_identity()));
        let unverified = LambdaIdentityCommitment::new(42, 1009, false);
        assert!(!is_identity_lawful(&unverified));
        let even_salt = LambdaIdentityCommitment::new(42, 1008, true);
        assert!(!is_identity_lawful(&even_salt));
    }

    #[test]
    fn test_lambda_proof_verified_when_all_present() {
        let pf = LambdaProof::new(clean_identity(), 1, 10, 42, true);
        assert!(pf.is_verified());
    }

    #[test]
    fn test_lambda_proof_fail_closed_on_each_ingredient() {
        let base = LambdaProof::new(clean_identity(), 1, 10, 42, true);
        assert!(base.is_verified());

        let unverified = LambdaProof::new(LambdaIdentityCommitment::new(42, 1009, false), 1, 10, 42, true);
        assert!(!unverified.is_verified());

        let drift_violation = LambdaProof::new(clean_identity(), 5, 2, 42, true);
        assert!(!drift_violation.is_verified());

        let no_seat_log = LambdaProof::new(clean_identity(), 1, 10, 0, true);
        assert!(!no_seat_log.is_verified());

        let no_zk = LambdaProof::new(clean_identity(), 1, 10, 42, false);
        assert!(!no_zk.is_verified());
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    // PrimeCheck fail-closed: a value at most three is never a candidate.
    #[kani::proof]
    fn verify_prime_candidate_rejects_small() {
        let n: u64 = kani::any();
        kani::assume(n <= 3);
        kani::assert(!is_prime_candidate(n), "values <= 3 are never prime candidates");
    }

    // PrimeCheck fail-closed: an even value is never a candidate.
    #[kani::proof]
    fn verify_prime_candidate_rejects_even() {
        let n: u64 = kani::any();
        kani::assume(n % 2 == 0);
        kani::assert(!is_prime_candidate(n), "even values are never prime candidates");
    }

    // PrimeCheck soundness: a passing candidate is odd and greater than three.
    #[kani::proof]
    fn verify_prime_candidate_sound() {
        let n: u64 = kani::any();
        kani::assume(is_prime_candidate(n));
        kani::assert(n > 3, "passing candidate is greater than 3");
        kani::assert(n % 2 == 1, "passing candidate is odd");
    }

    // DriftBound fail-closed: a drift violating 10·δ ≤ 3·ξ is rejected.
    #[kani::proof]
    fn verify_drift_bound_fail_closed() {
        let delta: u64 = kani::any();
        let xi: u64 = kani::any();
        kani::assume((3u128 * xi as u128) < (10u128 * delta as u128));
        kani::assert(!satisfies_drift_bound(delta, xi), "violated drift bound is rejected");
    }

    // DriftBound completeness: an in-bound drift is accepted.
    #[kani::proof]
    fn verify_drift_bound_complete() {
        let delta: u64 = kani::any();
        let xi: u64 = kani::any();
        kani::assume(10u128 * delta as u128 <= 3u128 * xi as u128);
        kani::assert(satisfies_drift_bound(delta, xi), "in-bound drift is accepted");
    }

    // Composite proof fail-closed: an unverified identity always denies.
    #[kani::proof]
    fn verify_lambda_proof_denied_on_unverified_identity() {
        let id = LambdaIdentityCommitment::new(kani::any(), kani::any(), false);
        let pf = LambdaProof::new(id, kani::any(), kani::any(), kani::any(), kani::any());
        kani::assert(!pf.is_verified(), "unverified identity denies the lambda proof");
    }

    // Composite proof fail-closed: a missing ZK attestation always denies,
    // regardless of every other input.
    #[kani::proof]
    fn verify_lambda_proof_denied_without_zk() {
        let id = LambdaIdentityCommitment::new(kani::any(), kani::any(), kani::any());
        let pf = LambdaProof::new(id, kani::any(), kani::any(), kani::any(), false);
        kani::assert(!pf.is_verified(), "missing ZK attestation denies the lambda proof");
    }

    fn clean() -> LambdaIdentityCommitment {
        LambdaIdentityCommitment::new(1, kani::any(), true)
    }
}
