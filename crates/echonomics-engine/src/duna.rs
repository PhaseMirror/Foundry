use serde::{Deserialize, Serialize};

/// Minimal, zero-membership DUNA voting record.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DunaVotes {
    pub votes_for: usize,
    pub votes_against: usize,
}

/// Canonical outcomes of the DUNA constitutional gate (mirrors Lean
/// `ConstitutionalDecision`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConstitutionalDecision {
    Pass,
    RejQuorum,
    RejMajority,
    RejInvalid,
}

/// Well-formed DUNA record:
///   votes cast never exceed total membership.
/// (The quorum-threshold bound is enforced at construction in
/// `DunaGovernance::new`.)
#[inline]
pub const fn is_well_formed(total_members: usize, votes_for: usize, votes_against: usize) -> bool {
    votes_for + votes_against <= total_members
}

/// Quorum reached: total votes cast meet or exceed the threshold.
#[inline]
pub const fn is_quorum_reached(votes_for: usize, votes_against: usize, quorum_threshold: usize) -> bool {
    votes_for + votes_against >= quorum_threshold
}

/// Strict majority: more votes for than against.
#[inline]
pub const fn is_strict_majority(votes_for: usize, votes_against: usize) -> bool {
    votes_for > votes_against
}

/// Proposal passes exactly when quorum is reached AND there is a strict
/// majority in favor.
#[inline]
pub const fn is_proposal_passed(
    votes_for: usize,
    votes_against: usize,
    quorum_threshold: usize,
) -> bool {
    is_quorum_reached(votes_for, votes_against, quorum_threshold)
        && is_strict_majority(votes_for, votes_against)
}

/// The single constitutional gate. Fails closed on any invalid state.
///
/// This is a pure, side-effect-free function over `usize`/`bool` only, so it
/// can be discharged symbolically by Kani without hashing or allocation.
#[inline]
pub const fn evaluate_constitutional_gate(
    total_members: usize,
    quorum_threshold: usize,
    votes_for: usize,
    votes_against: usize,
) -> ConstitutionalDecision {
    if !is_well_formed(total_members, votes_for, votes_against) {
        ConstitutionalDecision::RejInvalid
    } else if !is_quorum_reached(votes_for, votes_against, quorum_threshold) {
        ConstitutionalDecision::RejQuorum
    } else if !is_strict_majority(votes_for, votes_against) {
        ConstitutionalDecision::RejMajority
    } else {
        ConstitutionalDecision::Pass
    }
}

/// Stateful engine that delegates to the pure gate. Used by the application;
/// Kani verifies the pure core.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DunaGovernance {
    pub total_members: usize,
    pub quorum_threshold: usize,
    pub votes_for: usize,
    pub votes_against: usize,
}

impl DunaGovernance {
    /// Construct a governance record, clamping the quorum threshold to total
    /// membership so the well-formedness invariant can be maintained.
    pub fn new(total_members: usize, quorum_threshold: usize) -> Self {
        let threshold = quorum_threshold.min(total_members);
        Self {
            total_members,
            quorum_threshold: threshold,
            votes_for: 0,
            votes_against: 0,
        }
    }

    pub fn cast_vote(&mut self, approve: bool) {
        if self.total_votes() < self.total_members {
            if approve {
                self.votes_for += 1;
            } else {
                self.votes_against += 1;
            }
        }
    }

    pub fn total_votes(&self) -> usize {
        self.votes_for + self.votes_against
    }

    pub fn is_strict_majority(&self) -> bool {
        is_strict_majority(self.votes_for, self.votes_against)
    }

    pub fn is_quorum_reached(&self) -> bool {
        is_quorum_reached(self.votes_for, self.votes_against, self.quorum_threshold)
    }

    pub fn is_proposal_passed(&self) -> bool {
        is_proposal_passed(self.votes_for, self.votes_against, self.quorum_threshold)
    }

    pub fn evaluate_gate(&self) -> ConstitutionalDecision {
        evaluate_constitutional_gate(
            self.total_members,
            self.quorum_threshold,
            self.votes_for,
            self.votes_against,
        )
    }

    pub fn is_well_formed(&self) -> bool {
        is_well_formed(self.total_members, self.votes_for, self.votes_against)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_duna_governance_pass() {
        let mut gov = DunaGovernance::new(10, 6);
        for _ in 0..7 {
            gov.cast_vote(true);
        }
        assert!(gov.is_proposal_passed());
        assert_eq!(gov.evaluate_gate(), ConstitutionalDecision::Pass);
    }

    #[test]
    fn test_quorum_fail_closed() {
        // 7 members, threshold 6, only 3 votes cast -> no quorum -> rej.
        let mut gov = DunaGovernance::new(10, 6);
        for _ in 0..3 {
            gov.cast_vote(true);
        }
        assert!(!gov.is_quorum_reached());
        assert!(!gov.is_proposal_passed());
        assert_eq!(gov.evaluate_gate(), ConstitutionalDecision::RejQuorum);
    }

    #[test]
    fn test_tie_rejected() {
        // Quorum reached with a 5-5 tie -> must not pass.
        let mut gov = DunaGovernance::new(10, 6);
        for _ in 0..5 {
            gov.cast_vote(true);
            gov.cast_vote(false);
        }
        assert!(gov.is_quorum_reached());
        assert!(!gov.is_proposal_passed());
        assert_eq!(gov.evaluate_gate(), ConstitutionalDecision::RejMajority);
    }

    #[test]
    fn test_minority_rejected() {
        let mut gov = DunaGovernance::new(10, 6);
        for _ in 0..2 {
            gov.cast_vote(true);
        }
        for _ in 0..5 {
            gov.cast_vote(false);
        }
        assert!(gov.is_quorum_reached());
        assert!(!gov.is_proposal_passed());
        assert_eq!(gov.evaluate_gate(), ConstitutionalDecision::RejMajority);
    }

    #[test]
    fn test_majority_subquorum_blocked() {
        // 4-1 majority but below 6-vote quorum.
        let mut gov = DunaGovernance::new(10, 6);
        for _ in 0..4 {
            gov.cast_vote(true);
        }
        gov.cast_vote(false);
        assert!(gov.is_strict_majority());
        assert!(!gov.is_proposal_passed());
        assert_eq!(gov.evaluate_gate(), ConstitutionalDecision::RejQuorum);
    }

    #[test]
    fn test_invalid_state_fails_closed() {
        // votes exceeding membership -> RejInvalid (pure function).
        let d = evaluate_constitutional_gate(5, 3, 4, 4);
        assert_eq!(d, ConstitutionalDecision::RejInvalid);
    }

    #[test]
    fn test_pure_matches_engine() {
        let mut gov = DunaGovernance::new(10, 6);
        for _ in 0..6 {
            gov.cast_vote(true);
        }
        assert_eq!(
            evaluate_constitutional_gate(10, 6, 6, 0),
            ConstitutionalDecision::Pass
        );
        assert_eq!(gov.evaluate_gate(), ConstitutionalDecision::Pass);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    // Fail-closed quorum: below quorum, the gate never passes.
    #[kani::proof]
    fn verify_subquorum_fails_closed() {
        let total: usize = kani::any();
        let q: usize = kani::any();
        let a: usize = kani::any();
        let f: usize = kani::any();
        // Individual bounds guarantee f + a never overflows.
        kani::assume(f <= usize::MAX / 2);
        kani::assume(a <= usize::MAX / 2);
        kani::assume(f + a < q);

        let d = evaluate_constitutional_gate(total, q, f, a);
        kani::assert(d != ConstitutionalDecision::Pass, "Sub-quorum proposal must fail closed");
    }

    // A tie never passes: votes_for == votes_against makes a strict majority
    // impossible, so the Pass verdict is unreachable for any quorum/total.
    #[kani::proof]
    fn verify_tie_never_passes() {
        let n: usize = kani::any();
        let q: usize = kani::any();
        let total: usize = kani::any();
        kani::assume(n <= usize::MAX / 2); // avoid 2n overflow in the quorum sum
        let d = evaluate_constitutional_gate(total, q, n, n);
        kani::assert(d != ConstitutionalDecision::Pass, "A tie must never pass");
    }

    // Pass requires quorum AND strict majority (soundness: pass -> both hold).
    #[kani::proof]
    fn verify_pass_implies_quorum() {
        let f: usize = kani::any();
        let a: usize = kani::any();
        let q: usize = kani::any();
        // Individual bounds guarantee f + a never overflows.
        kani::assume(f <= usize::MAX / 2);
        kani::assume(a <= usize::MAX / 2);
        let d = evaluate_constitutional_gate(f + a + 1, q, f, a);
        kani::assume(d == ConstitutionalDecision::Pass);
        kani::assert(
            f + a >= q,
            "A passing proposal must have reached quorum",
        );
    }

    // A passed proposal always has a strict majority.
    #[kani::proof]
    fn verify_pass_implies_majority() {
        let f: usize = kani::any();
        let a: usize = kani::any();
        let q: usize = kani::any();
        // Individual bounds guarantee f + a never overflows.
        kani::assume(f <= usize::MAX / 2);
        kani::assume(a <= usize::MAX / 2);
        let d = evaluate_constitutional_gate(f + a, q, f, a);
        kani::assume(d == ConstitutionalDecision::Pass);
        kani::assert(f > a, "A passing proposal must have a strict majority");
    }

    // Invalid (over-voted) state is always rejected.
    #[kani::proof]
    fn verify_over_vote_rejected() {
        let f: usize = kani::any();
        let a: usize = kani::any();
        let q: usize = kani::any();
        // Individual bounds guarantee f + a never overflows.
        kani::assume(f <= usize::MAX / 2);
        kani::assume(a <= usize::MAX / 2);
        kani::assume(f + a > 0);
        kani::assume(q <= f + a);
        // total membership strictly smaller than f + a
        let total = f + a - 1;
        let d = evaluate_constitutional_gate(total, q, f, a);
        kani::assert(d == ConstitutionalDecision::RejInvalid, "Over-voted state must be invalid");
    }
}
