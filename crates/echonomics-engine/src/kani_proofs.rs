//! # echonomics_engine::kani_proofs — ADR-0001 Kani Verification Harnesses
//!
//! Machine-checked (Kani model-checked) proofs for ADR-0001: Hundian Social
//! Physics Occupancy Governance. Each harness uses symbolic (`kani::any`)
//! inputs to discharge the property for all reachable values, not just
//! hand-picked examples.
//!
//! These harnesses verify the *pure, side-effect-free* decision functions
//! (`evaluate_pauli_gate_peq`, `calculate_multiplicity_peq`, etc.) which are
//! free of hashing/allocations so the model checker terminates. The stateful
//! `HundianState` engine delegates to these same functions (see `hundian.rs`),
//! so a verified pure core gives property guarantees to the imperative shell.
//!
//! Properties discharged:
//! 1. `verify_multiplicity_never_exceeds_d_plus_one` — M = n_unpaired + 1
//! 2. `verify_closed_shell_singlet`                 — M = 1 when n_unpaired = 0
//! 3. `verify_pauli_rejects_third`                  — occupants >= 2 -> RejPauli
//! 4. `verify_term_order_blocks_unpaired_remaining` — U > 0 on degenerate -> RejTermOrder
//! 5. `verify_term_order_allows_full_shell`         — U = 0 on degenerate -> OkPair(Beta)
//! 6. `verify_first_occupant_alpha`                 — empty degenerate -> OkSingle(Alpha)
//! 7. `verify_non_degenerate_hierarchy`             — non-degenerate -> OkHierarchy
//! 8. `verify_multiplicity_positive_and_gt_unpaired`— M >= 1 and M > n_unpaired
//!
//! The entire module is gated behind `#[cfg(kani)]`, so it is compiled and
//! discharged only by `cargo kani` — never in a normal `cargo build`/`test`.

#![cfg(kani)]

use crate::hundian::{
    calculate_multiplicity_peq, evaluate_pauli_gate_peq, GateResult, SpinTag,
};

/// Property 1: Multiplicity M = n_unpaired + 1 never exceeds |D| + 1
/// for any real-domain `n_unpaired <= |D|`.
///
/// Occupancy counts are bounded well below `usize::MAX` in production; the
/// `assume` guards exclude only the arithmetic-overflow boundary that the
/// unbounded Lean `Nat` model treats natively. The true invariant
/// "M <= |D| + 1" (assertion Check 3) holds for all non-overflowing inputs.
#[kani::proof]
pub fn verify_multiplicity_never_exceeds_d_plus_one() {
    let n_unpaired: usize = kani::any();
    let d_count: usize = kani::any();
    // Real-domain bounds: exclude the pure-overflow boundary only.
    kani::assume(n_unpaired < usize::MAX);
    kani::assume(d_count < usize::MAX);
    kani::assume(n_unpaired <= d_count);

    let m = calculate_multiplicity_peq(n_unpaired);
    assert!(m <= d_count + 1, "M must never exceed |D| + 1");
}

/// Property 2: A closed shell (n_unpaired = 0) is a singlet with M = 1.
#[kani::proof]
pub fn verify_closed_shell_singlet() {
    assert_eq!(calculate_multiplicity_peq(0), 1, "Closed shell is a singlet M = 1");
}

/// Property 3: Pauli exclusion — any slot at capacity (>= 2) rejects.
#[kani::proof]
pub fn verify_pauli_rejects_third() {
    let occupants: usize = kani::any();
    let empty: usize = kani::any();
    let deg: bool = kani::any();
    kani::assume(occupants >= 2);

    let res = evaluate_pauli_gate_peq(occupants, empty, deg);
    assert_eq!(res, GateResult::RejPauli, "Slot at capacity must reject third occupant");
}

/// Property 4: Term-order gate — with empty degenerate slots (U > 0), pairing
/// a half-filled degenerate slot is rejected.
#[kani::proof]
pub fn verify_term_order_blocks_unpaired_remaining() {
    let empty: usize = kani::any();
    kani::assume(empty > 0);

    let res = evaluate_pauli_gate_peq(1, empty, true);
    assert_eq!(res, GateResult::RejTermOrder, "U > 0 must block pairing on degenerate slot");
}

/// Property 5: Term-order gate — with no empty degenerate slots (U = 0),
/// pairing a half-filled degenerate slot is allowed as OkPair(Beta).
#[kani::proof]
pub fn verify_term_order_allows_full_shell() {
    let res = evaluate_pauli_gate_peq(1, 0, true);
    assert_eq!(res, GateResult::OkPair { sigma: SpinTag::Beta });
}

/// Property 6: The first occupant of a degenerate slot receives Alpha.
#[kani::proof]
pub fn verify_first_occupant_alpha() {
    let empty: usize = kani::any();
    let res = evaluate_pauli_gate_peq(0, empty, true);
    assert_eq!(res, GateResult::OkSingle { sigma: SpinTag::Alpha });
}

/// Property 7: Non-degenerate slots always grant hierarchy (never pair/single).
#[kani::proof]
pub fn verify_non_degenerate_hierarchy() {
    let occupants: usize = kani::any();
    let empty: usize = kani::any();
    kani::assume(occupants < 2);

    let res = evaluate_pauli_gate_peq(occupants, empty, false);
    assert_eq!(res, GateResult::OkHierarchy, "Non-degenerate must return OkHierarchy");
}

/// Property 8: The pure multiplicity function is always positive and strictly
/// greater than n_unpaired — mirroring the Lean `multiplicity_positive` and
/// `multiplicity_gt_unpaired` theorems.
///
/// The `assume` guard excludes only the `usize::MAX` overflow boundary; the
/// unbounded Lean `Nat` model proves these for all naturals.
#[kani::proof]
pub fn verify_multiplicity_positive_and_gt_unpaired() {
    let n_unpaired: usize = kani::any();
    kani::assume(n_unpaired < usize::MAX);

    let m = calculate_multiplicity_peq(n_unpaired);
    assert!(m >= 1, "Multiplicity is always positive");
    assert!(m > n_unpaired, "Multiplicity is strictly greater than n_unpaired");
}
