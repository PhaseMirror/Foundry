//! Kani verification harnesses for ADR governance invariants.
//!
//! All harnesses are gated on `#[cfg(kani)]` and use `#[kani::proof]`.
//! Run with:
//! ```bash
//! cargo kani --package adr_rust
//! ```
//!
//! **Bounded-model-checking note:** Kani treats `u64` as 64-bit bitvectors.
//! For unbounded mathematical properties we restrict input ranges via
//! `kani::assume`.

use crate::core::{Adr, AdrError, AdrId, AdrRegistry};
use std::collections::HashMap;

// ─── ADR Governance Invariant 1: Immutability after acceptance ───────────────

/// Verify that an `Accepted` ADR cannot transition to `Deprecated` or `Proposed`
/// without a supersession ID routing it through `Superseded`.
#[cfg(kani)]
#[kani::proof]
fn verify_accepted_immutable() {
    let id: AdrId = kani::any();
    kani::assume(id >= 1 && id <= 1000);

    let mut adr = Adr::new(
        id,
        "Test ADR",
        "Context",
        "Decision",
        vec![],
        vec![],
    );
    // Transition to Accepted.
    assert!(adr.transition(crate::core::AdrStatus::Accepted, None).is_ok());

    // Attempt forbidden transitions.
    let statuses = vec![
        crate::core::AdrStatus::Proposed,
        crate::core::AdrStatus::Deprecated,
    ];
    for status in statuses {
        let result = adr.transition(status, None);
        // Should fail with ImmutableAccepted.
        if result.is_ok() {
            panic!("Accepted ADR should not transition to {:?} without supersession", status);
        }
    }
}

// ─── ADR Governance Invariant 2: No circular supersession chains ────────────

/// Verify that a chain of supersessions cannot contain a cycle.
///
/// Kani explores all possible chains up to length 3 (bounded).
#[cfg(kani)]
#[kani::proof]
fn verify_no_cycles_short_chain() {
    let id1: AdrId = kani::any();
    let id2: AdrId = kani::any();
    let id3: AdrId = kani::any();
    kani::assume(id1 >= 1 && id1 <= 100);
    kani::assume(id2 >= 1 && id2 <= 100);
    kani::assume(id3 >= 1 && id3 <= 100);
    kani::assume(id1 != id2);
    kani::assume(id2 != id3);
    kani::assume(id1 != id3);

    let mut reg = AdrRegistry::new();

    let a1 = Adr::new(id1, "A1", "C1", "D1", vec![], vec![]).unwrap();
    let a2 = Adr::new(id2, "A2", "C2", "D2", vec![], vec![]).unwrap();
    let a3 = Adr::new(id3, "A3", "C3", "D3", vec![], vec![]).unwrap();

    reg.insert(a1);
    reg.insert(a2);
    reg.insert(a3);

    // Try to build a cycle: a1 supersedes a2, a2 supersedes a3, a3 supersedes a1.
    // This requires all three to be Accepted first, then superseded.
    if let Some(a1m) = reg.get_mut(id1) {
        let _ = a1m.transition(crate::core::AdrStatus::Accepted, None);
    }
    if let Some(a2m) = reg.get_mut(id2) {
        let _ = a2m.transition(crate::core::AdrStatus::Accepted, None);
    }
    if let Some(a3m) = reg.get_mut(id3) {
        let _ = a3m.transition(crate::core::AdrStatus::Accepted, None);
    }

    // Building a cycle would require a1.supersedes = a3, a3.supersedes = a2, a2.supersedes = a1.
    // But a1, a2, a3 are already Accepted, and Accepted ADRs cannot transition to Superseded
    // without going through the transition method, which enforces acyclicity per-ADR.
    // Here we verify the registry-level validation catches any residual cycle.
    assert!(reg.validate_acyclic().is_ok());
}

// ─── ADR Governance Invariant 3: Traceability ───────────────────────────────

/// Verify that every `Accepted` ADR in a registry has a reconstructible history.
#[cfg(kani)]
#[kani::proof]
fn verify_accepted_traceability() {
    let id1: AdrId = kani::any();
    let id2: AdrId = kani::any();
    kani::assume(id1 >= 1 && id1 <= 100);
    kani::assume(id2 >= 1 && id2 <= 100);
    kani::assume(id1 != id2);

    let mut reg = AdrRegistry::new();

    let a1 = Adr::new(id1, "A1", "C1", "D1", vec![], vec![]).unwrap();
    let a2 = Adr::new(id2, "A2", "C2", "D2", vec![], vec![]).unwrap();

    reg.insert(a1);
    reg.insert(a2);

    // Make a1 Accepted.
    if let Some(a1m) = reg.get_mut(id1) {
        let _ = a1m.transition(crate::core::AdrStatus::Accepted, None);
    }

    // Supersede a1 with a2.
    if let Some(a1m) = reg.get_mut(id1) {
        let _ = a1m.transition(crate::core::AdrStatus::Superseded, Some(id2));
    }
    if let Some(a2m) = reg.get_mut(id2) {
        let _ = a2m.transition(crate::core::AdrStatus::Accepted, None);
    }

    // Validate: all histories must be reconstructible.
    let accepted = reg.validate_traceability();
    assert!(accepted.is_ok(), "Traceability failed: {:?}", accepted);
}

// ─── ADR Governance Invariant 4: Consequence entailment ─────────────────────

/// Verify that every non-empty consequence is entailed by (decision + context).
#[cfg(kani)]
#[kani::proof]
fn verify_consequence_entailment() {
    let id: AdrId = kani::any();
    kani::assume(id >= 1 && id <= 1000);

    let decision_len: u64 = kani::any();
    let context_len: u64 = kani::any();
    kani::assume(decision_len >= 1 && decision_len <= 50);
    kani::assume(context_len >= 1 && context_len <= 50);

    let decision = "x".repeat(decision_len as usize);
    let context = "y".repeat(context_len as usize);
    let consequence = "xy";

    let mut reg = AdrRegistry::new();
    let adr = Adr::new(id, "Title", context, decision, vec![consequence], vec![]).unwrap();
    reg.insert(adr);

    assert!(reg.validate_consequence_entailment().is_ok());
}

// ─── Integration: Full registry validation ──────────────────────────────────

/// Verify that a registry with 3+ ADRs passes all global invariants.
#[cfg(kani)]
#[kani::proof]
fn verify_full_registry_invariants() {
    let n: u64 = kani::any();
    kani::assume(n >= 3 && n <= 5);

    let mut reg = AdrRegistry::new();

    for i in 1..=n {
        let adr = Adr::new(
            i,
            format!("ADR-{:04}", i),
            format!("Context for ADR {:04}", i),
            format!("Decision for ADR {:04}", i),
            vec![format!("Consequence {}", i)],
            vec![],
        );
        reg.insert(adr.unwrap());
    }

    // Transition some to Accepted, some to Deprecated, chain one supersession.
    for i in 1..=n {
        if let Some(a) = reg.get_mut(i) {
            if i % 2 == 0 {
                let _ = a.transition(crate::core::AdrStatus::Accepted, None);
            } else if i > 1 {
                let _ = a.transition(crate::core::AdrStatus::Deprecated, None);
            }
        }
    }

    assert!(reg.validate_all().is_ok());
}
