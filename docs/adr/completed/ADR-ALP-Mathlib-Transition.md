# ADR: ALP Mathlib Transition and Hybrid Verification Boundary

## 1. Executive Summary
This ADR formally ratifies the "Rust Stub Exception" transitional policy for the `lean/ALP/` directory. While the Universal Atomic Calculator (UAC) math cores remain 100% verified and free of unproven axioms, the `ALP` agentic contracts currently require a hybrid boundary relying on `import Mathlib` and explicit `sorry` blocks.

## 2. Policy Enforcement & The Hybrid Boundary
- **Gated Exceptions:** The use of `sorry` within `lean/ALP/` is conditionally permitted *only* if each `sorry` is paired with an actionable Rust implementation stub in the corresponding `crates/alp/` module.
- **CI Constraint:** The CI pipeline enforces this via `scripts/honesty_audit.sh` and the governance test suite (`cargo test --test governance`). A `lean_sorry_count` metric is exported to track technical debt.

## 3. Implementation Plan
- **Phase 1 (Current):** Allow mapped `sorry`s. Track debt via Prometheus metrics (`lean_sorry_count`). A gated list of permitted `sorry`s will be defined in a JSON manifest (`alp_sorry_manifest.json`) that is parsed by a CI checker.
- **Phase 2:** Iterative proof completion for bounded `ALP` state machines, eliminating `sorry` blocks one by one and removing them from the JSON manifest.
- **Phase 3:** Total removal of `mathlib` dependency in favor of our native `ring` and algebraic formulations.

## 4. Acceptance Criteria
- Any unmapped `sorry` block introduced into `lean/ALP/` must fail the build.
- `cargo test --test governance` correctly executes every paired Rust stub corresponding to an `ALP` `sorry`.
