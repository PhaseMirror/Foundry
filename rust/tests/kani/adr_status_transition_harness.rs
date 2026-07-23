//! Kani harness for ADR status transition invariants.
//!
//! Verifies:
//! 1. No re-entrant acceptance: an ADR cannot transition from Accepted → Proposed.
//! 2. Status transitions are deterministic and respect the allowed-transition matrix.

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum AdrStatus {
    Proposed = 0,
    Accepted = 1,
    Deprecated = 2,
    Superseded = 3,
}

pub fn can_transition(old: AdrStatus, new: AdrStatus) -> bool {
    match (old, new) {
        (AdrStatus::Proposed, AdrStatus::Accepted) => true,
        (AdrStatus::Proposed, AdrStatus::Deprecated) => true,
        (AdrStatus::Accepted, AdrStatus::Deprecated) => true,
        (AdrStatus::Accepted, AdrStatus::Superseded) => true,
        (AdrStatus::Deprecated, AdrStatus::Superseded) => true,
        _ => false,
    }
}

#[kani::proof]
fn adr_no_reentrant_acceptance() {
    let old = AdrStatus::Accepted;
    let new = AdrStatus::Proposed;
    let allowed = can_transition(old, new);
    kani::assert(!allowed, "Accepted → Proposed transition must be disallowed");
}

#[kani::proof]
fn adr_allowed_transitions_are_deterministic() {
    let transitions = [
        (AdrStatus::Proposed, AdrStatus::Accepted, true),
        (AdrStatus::Proposed, AdrStatus::Deprecated, true),
        (AdrStatus::Accepted, AdrStatus::Deprecated, true),
        (AdrStatus::Accepted, AdrStatus::Superseded, true),
        (AdrStatus::Deprecated, AdrStatus::Superseded, true),
    ];
    for &(old, new, expected) in &transitions {
        let result = can_transition(old, new);
        kani::assert(result == expected, "Transition must match expected allowance");
    }
}

#[kani::proof]
fn adr_no_unknown_transitions_allowed() {
    let all_states = [
        AdrStatus::Proposed,
        AdrStatus::Accepted,
        AdrStatus::Deprecated,
        AdrStatus::Superseded,
    ];
    for &old in &all_states {
        for &new in &all_states {
            let allowed = can_transition(old, new);
            let is_known = matches!(
                (old, new),
                (AdrStatus::Proposed, AdrStatus::Accepted)
                    | (AdrStatus::Proposed, AdrStatus::Deprecated)
                    | (AdrStatus::Accepted, AdrStatus::Deprecated)
                    | (AdrStatus::Accepted, AdrStatus::Superseded)
                    | (AdrStatus::Deprecated, AdrStatus::Superseded)
            );
            kani::assert(allowed == is_known, "Only known transitions are allowed");
        }
    }
}
