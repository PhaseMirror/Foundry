# ADR-046: De-Quarantine and Substrate Migration of ALP and Commons

**Status:** Ratified (Governance De-Quarantine Directive)
**Date:** 2026-06-30
**Owner:** L0 Substrate + Formal Methods Team

## 1. Context
The system is currently operating under a strict maintenance freeze (`is_sealed` terminal boundary). However, an architectural audit has identified physical drift between the Lean 4 formalisms in `substrates/lean/ALP/` and their respective Rust implementations in the `ensembles/` workspace.

Specifically:
1. **Type Dissonance:** The `TrustLevel` enum is redundantly defined in both `ensembles/alp/src/lib.rs` and `ensembles/commons/src/types.rs`.
2. **Serialization Gap:** `ensembles/alp` defines `AdmissibilityReport`, but it fails to derive the `JsonSchema` trait required by the orchestration loop in `ensembles/commander-core`.

To honor the "Governance-as-Compilation" roadmap, these core execution layers must be mathematically verified and migrated to the immutable `substrates/` directory.

## 2. Decision
We authorize a targeted 7-day De-Quarantine Directive to rectify the type dissonance, ensure Lean 4 mathematical equivalence, and migrate the `alp` and `commons` crates to the `substrates/` boundary.

## 3. Production-Grade Implementation Plan

### Phase 1: Code Remediation (Days 1–2)
**Owner:** Core Engineering
- **De-duplication:** Eradicate the redundant `TrustLevel` definition from `ensembles/alp`. Anchor the enum exclusively within the `multiplicity-common` (commons) library to restore the single-source-of-truth invariant.
- **Serialization Restoration:** Append `#[derive(JsonSchema)]` (and any requisite dependencies like `schemars`) to the `AdmissibilityReport` struct in `ensembles/alp`. 
- **Metric:** `cargo check` and `cargo test -p alp -p multiplicity-common -p commander-core` complete successfully with zero type-mismatch errors.

### Phase 2: Formal Audit (Days 3–5)
**Owner:** Formal Methods
- **Re-extraction:** Re-extract and audit the updated Rust types against the existing Lean 4 modules in `substrates/lean/ALP/Types/`.
- **Equivalence Verification:** Guarantee zero-`sorry` mathematical equivalence between the Rust structural changes and the canonical Lean definitions.
- **Metric:** Lean validation suite executes successfully with no missing proofs.

### Phase 3: Migration & Lockdown (Days 6–7)
**Owner:** L0 Substrate Maintainers
- **Physical Relocation:** Move `ensembles/alp` to `substrates/alp`. Move `ensembles/commons` to `substrates/common`.
- **Workspace Anchoring:** Update the root `Cargo.toml` to reflect the new `substrates/` membership and update relative dependency paths in downstream crates (`sigma`, `commander-core`, `sovereign-twin-operator`, etc.).
- **Re-sealing:** Run the full integration suite. Upon success, revoke the De-Quarantine Directive and re-seal the repository under Maintenance Mode.
- **Metric:** Full workspace compiles. `is_sealed` invariants remain active. All pipelines return to green.
