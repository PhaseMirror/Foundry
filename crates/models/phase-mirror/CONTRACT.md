# Phase Mirror Observatory — Contract Specification

## Purpose
This document specifies the Sedona Spine compliance contract for the Phase Mirror discrete state observatory.

## L0 Invariants

| Invariant | Requirement | Source |
|-----------|-------------|--------|
| Successor Predication | P_N(t+1) = σ(P_N(t)) must hold for all transitions | `lean/CPIRTM.lean` |
| Multiplicity Conservation | M(S) functor preserves structure across strata | `multiplicity/rust/src/strata.rs` |
| Rational64 Exactness | All rationals use ExactRat with certified bounds | `PhaseMirror.lean` |

## ContractivityReceipt Linking

Every state transition must carry a `ContractivityReceipt`:
```lean
structure ContractivityReceipt where
  witness_id : String
  action_id : String
  timestamp : Nat
  kernel_signature : String
```

## Dissonance Tags

When invariants cannot be satisfied:
- `DissonanceTag.None` — All invariants satisfied
- `DissonanceTag.Some(reason)` — Construction failed validation

@@invariant: successor_predication where P_N(t+1) = σ(P_N(t))
@@invariant: multiplicity_conservation where M(S) is preserved across strata transitions
@@invariant: rational_exactness where ExactRat.den > 0 for all rationals

## CI Gate

The Sedona Spine CI (`sedona_spine_ci.yml`) enforces:
1. Axiom-clean proofs (`lean/scripts/honesty_audit.sh`)
2. Front-matter invariant declarations
3. ContractivityReceipt linkage on all changes

---
*Governed by: ADR-044 Sedona Spine Front-Matter Hardening*
*LawfulRecursionVersion: 1.0*