# ADR-011: Sovereign Boundary Enforcement

## Status
Proposed

## Context
MOC v2 transitions are now dependently-typed, formally verified, and cryptographically anchored to their Lean proof-terms (ADR-010). To achieve Phase Mirror-style dissonance immunity, we must elevate the transition admissibility logic from "stable" to "sovereign". 

## Decision
All PIRTM transitions must be executed within an explicitly defined `SovereignBoundary`.

### Mechanism

1.  **Sovereign Invariants:** Every PIRTM transition must carry a `SovereignBoundary` proof-term asserting:
    - **Stability Certificate:** ACE dominance and resonance bounds ($R \ge (0.7, 0.0, 0.5)$) validated in Lean.
    - **Non-Expansion:** Transition codomain dimension is strictly bounded by the `MOC.apply_len_word` morphism property.
    - **Schema Monotonicity:** Transition schema sequence $seq > last\_verified\_seq$ (enforced by type-level witness).
    - **Boundary Predicate:** `is_sovereign` predicate is true for all admitted transitions.

2.  **Runtime Enforcement:** 
    - The `pirtm-runtime` (Rust) is updated to include a `verify_sovereign` check, rejecting any transition that lacks a matching boundary attestation.

3.  **Governance:** 
    - The CI/CD pipeline enforces that all Rust artifacts are generated only from transitions satisfying `SovereignBoundary`.

## Verification
- Admissibility of a transition is a type-checking failure if the sovereign invariants are not met.
- No drift possible between mathematical model and deployment.

<!-- LawfulRecursionVersion:1.0 -->
