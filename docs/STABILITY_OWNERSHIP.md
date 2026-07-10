# Stability Ownership & Governance: pirtm-core-rs

This document defines the normative role of the `pirtm-core-rs` crate in the Phase Mirror stability lifecycle.

## 1. The Normative Ground Truth

Per **ADR-004 (pirtm MLIR Dialect)** and the **Sedona Spine Mandate**, this crate is the **sole normative implementation** for spectral stability verification (`spectral-small-gain`) in all production and CI/CD pipelines.

Any stability claim (e.g., `spectral_radius`, `stability_margin`) embedded in emitted MLIR or used to gate a binary release **MUST** be computed or verified by the `SpectralGovernor` in this crate.

## 2. Theoretical vs. Operational Ownership

| Layer | Responsibility | Implementation | Role |
| :--- | :--- | :--- | :--- |
| **Formal** | Theorem Provability | Lean 4 | **Logical Reference**: Justifies the algorithm. |
| **Operational** | Stability Enforcement | **pirtm-core-rs** | **Ground Truth**: Executes the verification gate. |
| **Authoring** | Design & Visualization | Python | **Research Tool**: Forbidden from issuing safety seals. |

## 3. Key Mandates

### 3.1 Zero Drift Policy
To prevent divergence between the theoretical model and the running system, the `SpectralGovernor` in this crate is the authoritative source for the spectral attributes encoded in `pirtm.session_graph`. Downstream tools (auditors, inspectors) read these attributes as ground truth without re-running analysis.

### 3.2 Gate K Hardening
The verifier in `src/spectral.rs` converts the `#pirtm.unresolved_coupling` sentinel into a hard failure. A binary cannot be "sealed" or "certified" if any unresolved or unstable couplings remain.

## 4. Contributor Contract

Any contributor or automated process modifying the stability-critical path MUST adhere to the following contract:

### 4.1 Required Actions for Semantic Changes
Any change to the `SpectralGovernor`, MLIR stability attributes, or `session_graph` semantics **MUST**:
1.  **Update ADR-004**: If the mathematical or structural semantics change, the ADR must be updated to reflect the new state.
2.  **Verify Invariants**: All tests in `src/tests.rs` must pass, and new test cases must be added for any new stability logic.
3.  **Preserve Invariant**: Rust is the **only** engine permitted to mark a build as "stable." No other layer (UI, Python, Agent) may override a "FAIL" from this crate.

### 4.2 Maintenance of Ground Truth
No "just-in-case" or "heuristic" stability logic is permitted outside this crate. All downstream components must treat the attributes produced by this crate as final and non-negotiable.

---
*Reference: [ADR-004: pirtm MLIR Dialect — Type System, Governance Architecture, and Two-Phase Compilation](../PIRTM-v1-Multiplicity/PIRTM-v1-Multiplicity/docs/adr/ADR-004-pirtm-mlir-dialect.md)*

<!-- LawfulRecursionVersion:1.0 -->
