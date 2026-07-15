# ADR-010: Sealed Rust Extraction Pipeline

## Status
Ratified (Operational)

## Context
The MOC v2 architecture mandates a "Lean-First" specification, where PIRTM transitions, stability proofs, and resonance gates are formal theorems in Lean 4. To bridge the gap to high-performance execution, we implement a **Sealed Extraction Pipeline** that cryptographically binds Rust binaries to Lean stability proofs.

## Decision
All Rust-based PIRTM runtime artifacts must embed a `ProofHash` constant and enforce a **Proof-Carrying Runtime Gate** that validates this hash against the incoming schema manifest before executing any transition.

### Mechanism

1.  **Proof-Term Attestation:** The Lean 4 compiler generates a `ProofHash` (the hash of the proof-term `StabilityCertificate`).
2.  **Rust Extraction Bridge:** The `moc-bridge` is updated to generate a Rust source file (`proof_attestation.rs`) embedding the `ProofHash` as a `const`.
3.  **Binary Binding:** The Rust runtime (`pirtm-runtime`) includes `proof_attestation.rs` at compile-time.
4.  **Runtime Integrity (`verify_witness`):** 
    - At startup, `pirtm-runtime` extracts the `ValidatedSchema` manifest.
    - It verifies that the `proof_hash` embedded in its own binary matches the `proof_hash` in the manifest.
    - Any mismatch results in a fatal `PermissionError`, halting execution.

## Verification
- CI/CD build scripts enforce that the binary is only compiled if the attestation file is present.
- Rust runtimes without matching embedded `ProofHash` and manifest data are rejected at the runtime gate.
- PIRTM transition integrity is guaranteed by the chain: Lean Proof $\to$ Bridge Attestation $\to$ Compiled Binary $\to$ Runtime Hash-Verify.

<!-- LawfulRecursionVersion:1.0 -->
