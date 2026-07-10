# Governance-RS: Multiplicity Governance Core (Rust)

High-performance, type-safe implementation of Phase Mirror governance runtime. This crate provides the production-ready destination for all governance logic in the PhaseSpace ecosystem.

## 🏗️ Structure

- **`src/constitution`**: L0 invariant enforcement and constitutional state validation.
- **`src/ledger`**: Audit ledger with hash-chaining and immutable root commits.
- **`src/proof_anchor`**: Proof anchor normalization and validation.
- **`src/self_modification`**: Four-phase execution engine for autonomous system modification.
  - `daemon`: Orchestrates the modification protocol.
  - `lobian_guard`: Prevents self-referential verification loops.
  - `kill_switch`: Independent safety override.
  - `watchdog`: Post-execution spectral verification.
  - `gate_p`: Sandboxed simulation for source code changes.
- **`src/interop`**: Category-theoretic framework for cross-stack governance interoperability.
  - `category_model`: Objects (obligations) and morphisms (refinements).
  - `policy_functor`: Monotone mapping between different governance frameworks.
  - `compliance_verifier`: Gap detection and remediation proposals.
  - `dcgf_integration`: Live state binding and continuous monitoring.
- **`src/witnesses`**: Execution trajectory to AIR witness adapters.
  - `pweh`: Prime-Weighted Execution Hashing to ACE-ZK witness.
  - `humoe`: Human Oversight (HOX) audit log and review queue.
- **`src/coupling`**: Redis-backed coupling bus for resonance cascade prevention.
- **`src/quorum`**: Governance quorum validator for council-signed decisions.
- **`src/lattice`**: Topological metrics (Euler characteristic, Gurau degree) for governance graphs.

## 🚀 Features

- **Constitutional Integrity**: Port of `constitution.py` using strict Rust types.
- **Audit Persistence**: Port of `ledger.py` with serializable state and Merkle root tracking.
- **Governed Self-Modification**: Formal protocol for safe, recursive system updates.
- **Cross-Framework Compliance**: Automated mapping between EU AI Act, NIST RMF, ISO 42001, and DCGF.
- **Verification Support**: Integration-ready for ZK-circuits and formal verification SDKs.

## ⚖️ Constitutional Mapping

- **L0-1**: State norm finite and positive.
- **L0-2**: Ethical drift rate < Λm.
- **L0-3**: All 10 critique gates passed.
- **L0-4**: Prime-gated action values are prime.
- **L0-5**: Lipschitz contractivity (0, 1].
- **L0-6**: Kill-switch compliance.
- **L0-7**: Circuit breaker enforcement.
- **L0-8**: Proof-anchor format validation.
- **L0-9**: Active anchor recognition.

## 🚀 Usage

### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```
