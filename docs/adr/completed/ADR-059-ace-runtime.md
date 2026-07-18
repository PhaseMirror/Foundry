# ADR 0005: Attested Convergence Envelope (ACE) Runtime

## Status
Proposed

## Context
Extracted from `publications/ACE Runtime Certification Stack/`. The system requires a standalone enforcement layer to guarantee computation budget limits and invariant preservation, as outlined in Phase C of the Governance-as-Compilation roadmap.

## Decision
Implement ACE invariant checks directly inside the Rust Engine (`Sedona Spine`), bound by hardware-level memory boundaries and Kani verification.

## Consequences
- **Positive**: 
  - Achieves zero-drift risk modeling natively.
  - Ensures computation complies perfectly with Phase C constraints.
- **Negative**:
  - High computational overhead due to constant budget assertions and envelope boundaries.

## Compliance
Provides the mandatory verifiable ledger anchor from `Engine (Rust)` to `CompilationResult`.
