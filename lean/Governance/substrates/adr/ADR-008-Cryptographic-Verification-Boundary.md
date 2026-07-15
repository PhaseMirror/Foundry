# ADR-008: Isolation of the Cryptographic Verification Boundary (Rust-Hardened)

## Status
Proposed (Ratified by Security Infrastructure)

## Context and Problem Statement
Previous "HSM simulation" via Python scripts failed to provide true hardware isolation. Orchestration compromise could reach the verifier process if it shared the same runtime or execution environment. True isolation requires a hardware-isolated enclave (HSM) or an air-gapped verifier with private keys that never touch the orchestration layer.

## Decision Drivers
- **Physical Isolation:** Private keys must be unreachable from the orchestration host.
- **Syntactic and Structural Safety:** Move away from Python to Rust for all bridge and verifier components to eliminate large classes of memory and type safety bugs.
- **End-to-End Red-Team Validation:** Any proposed boundary must survive a red-team simulation where the orchestration layer is fully compromised.

## Decision Outcome
We replace the Python-based simulation with a **Rust-based hardware-isolated verifier binary**.

### Technical Specification

1.  **HSM-Isolated Signing Enclave (Rust Binary):**
    - The `moc-verifier` binary is the sole custodian of the (simulated) HSM signing keys.
    - In production, this binary interfaces with a physical HSM or an air-gapped vault.
    - Orchestration layers emit only unsigned manifests.
2.  **Rust Bridge Execution Boundary:**
    - The `moc-bridge` (Rust) acts as a stateless parser.
    - It enforces a mandatory external call to the `moc-verifier` binary.
    - AST emission is physically blocked unless the verifier returns a successful, hash-linked witness.
3.  **Inductive Type Enforcement (Lean 4):**
    - `MOC.Operator` and `MOC.PermittedPrime` constructors are dependently typed on a `MOC.ValidatedSchema` witness.
    - This witness can only be constructed if the `moc-verifier` has attested to the signature and sequence counter monotonicity.

## Pros and Cons

### Pros
- **Hardware-Grade Isolation:** Compromising the bridge or orchestration layer does not yield signing authority.
- **Language Safety:** Rust provides robust memory safety and a strong type system for the security boundary.
- **Replay-Proof:** Monotonic sequence counters are enforced at the hardware/verifier level.
- **Defense in Depth:** Perimeter compromise no longer leads to verification bypass.
- **Provenance:** HSM transaction IDs provide a permanent record of authorization.

### Cons
- **Binary Management:** Requires managing multiple compiled binaries in the CI/CD pipeline.
- **Inter-Process Latency:** External binary calls add minor overhead compared to in-process function calls.
- **Complexity:** Managing a 2-of-3 threshold protocol increases infrastructure overhead.

## Artifact Changes

- **`moc_v2/lean/MOC/Core.lean`:** Added `sequence` to `Schema` and updated `validate_schema`.
- **`moc_v2/rust/src/bridge.rs`:** Implemented Rust bridge that calls external verifier.
- **`moc_v2/rust/src/verifier.rs`:** Implemented Rust verifier (HSM simulation).
- **`moc_v2/core_schema.json`:** Initialized core schema with sequence attestation.

## Verification
The `Justfile` test-structural target and the Rust-based enclave simulation will verify that:
1. Unsigned or self-signed schemas are rejected by `moc-verifier`.
2. Schemas with non-increasing sequence numbers are rejected by `moc-verifier`.
3. Only authorized threshold signatures allow `moc-bridge` to emit Lean AST.

<!-- LawfulRecursionVersion:1.0 -->
