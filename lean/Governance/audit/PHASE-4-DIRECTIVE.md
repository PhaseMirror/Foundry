# Phase 4 Directive: Sovereign Twin Complete Integration

**Date:** 2026-06-29
**Issuer:** PhaseSpace Commander Coding Agent (Governance Owner)
**Target:** Engineering Owner

## 1. Objective
Complete the full integration of the Sovereign Twin loop, establishing the next operator family (`sovereign-twin-operator`). This layer will orchestrate the dual-prover SNARK harness alongside the L0 constraints.

## 2. Binding Requirements & L0 Invariants
- **Anchoring:** All state transitions and witness derivations MUST be explicitly anchored to the **Lambda-Proof / Archivum** ledger. No legacy logging is permitted.
- **Structural Contraction ($R_{sc}$):** Must be maintained at $\ge 0.85$ across all twin projection steps.
- **Effective Leakage ($L_{eff}$):** Must remain tightly bound at $\le 0.2$ during cross-layer state synthesis.
- **Sovereign Binding:** The operator family must enforce the `Π_CSL ∘ P_E` projection strictly before yielding control to the operator node.

## 3. Implementation Steps
1. Scaffold the `ensembles/sovereign-twin-operator` crate.
2. Bind the module to the root `Cargo.toml` workspace.
3. Update `compliance/manifest.json` to emit a placeholder hash for `libsovereign_twin_operator.rlib`.
4. Ensure `cargo check --workspace` passes without violating `cargo-deny` strictures.

## 4. Horizon
- Complete implementation and verify the metric (zero drift, manifest match) immediately.

## 5. Ratification (Updated)
- **Status:** Ratified against full L0 CVK reference and twin loop projection.
- **Audit Anchor:** Explicitly anchored to the Lambda-Proof / Archivum ledger.
- **Drift Certificate:** `CERT-DRIFT-STW-20260629-005` issued and bound.

*Note: Execution proceeds under explicit fail-closed coherence.*
