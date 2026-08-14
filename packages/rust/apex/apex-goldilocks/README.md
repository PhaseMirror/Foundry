# Hologram APEX (Goldilocks)

A high-performance, math-first compute stack that turns symmetry, invariants, and positive geometry into **executable proofs** and **verifiable computation**.

> **Status**: This project is now a standalone Rust workspace, integrating the Sedona Spine mandate and PIRTM-lang roadmap (Phases A, B, and C). It provides runnable, proof-carrying kernels (AEPs), a certified schedule (C768), and a high-performance Rust port of the $\pi$-kernel.

---

## 1. Core Modules

- **Atlas → E8 Core**: Canonical 96-class combinatorial object with machine-checked embeddings.
- **PIRTM-lang Compiler**: Formal governance-as-compilation.
    - **Phase A**: Grammar enforcement via `tree-sitter`.
    - **Phase B**: Multiplicity Functor implementation via the `Sig` library.
    - **Phase C**: ACE stability invariant checks.
- **$\pi$-kernel (Rust)**: High-performance, projection-first kernel with weighted $\ell_1$-ball safety (ACE), contraction certificates, and PETC ledger.
- **Multiplicity Runtime**: Prime-graded channel runtime with explicit contraction margins and cryptographic audit trails (SHA-256/Poseidon).
- **Hologram Desktop**: A Tauri/React-based interface featuring an ACE Stability Dashboard and PIRTM Source Validator.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      Hologram APEX Rust Workspace                        │
├──────────────┬──────────────────────────┬─────────────────────────────────┤
│   Models     │      Kernels (apex-π)    │    Runtime (multiplicity)       │
│ (Atlas/E8)   │  ACE Projection (L1),    │  Prime-graded channels, ACE     │
│              │  Contraction Certificates│  safety set, PETC Ledger, MUB   │
├──────────────┴─────────────┬────────────┴─────────────────────────────────┤
│    PIRTM-lang Compiler (tree-sitter) + Sig (Multiplicity Functor)        │
├────────────────────────────┴──────────────────────────────────────────────┤
│               Hologram Desktop (Tauri + React + WASM)                    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Implementation Progress

- [x] **Standalone Transformation**: All core dependencies (`goldilocks`, `pirtm-compiler`, `apex-pikernel`) are now internalized within the workspace.
- [x] **$\pi$-kernel Rust Port**: Full parity with reference Python implementation, optimized for `ndarray`.
- [x] **ACE Stability**: Phase C implementation for strictly non-inflationary contractivity checks.
- [x] **PETC Ledger**: Integrated SHA-256 and Poseidon (BN254) commitment schemes.
- [x] **MUB Audit**: Walsh-Hadamard based energy concentration detection.
- [x] **Stability Dashboard**: Real-time visualization and verification of operator stability in the desktop app.

---

## 4. Quick Start

### Prerequisites
- Rust 1.75+
- Node.js 18+ (for Desktop UI)

### Build the Workspace
```bash
# Build all Rust crates (core, cli, wasm, pikernel, compiler)
cargo build --workspace

# Build the Frontend
npm install
npm run build
```

### Run Tests
```bash
# Execute comprehensive math and stability tests
cargo test --workspace
```

### Run CLI Tools
```bash
# Verify Boundary Lattice invariants
cargo run -p apex-goldilocks-cli -- audit-lattice

# Validate PIRTM source code (Phase A/B)
cargo run -p apex-goldilocks-cli -- validate-pirtm --source "op(prime_index=7);"

# Check ACE Stability (Phase C)
cargo run -p apex-goldilocks-cli -- verify-stability --total-norm 800000
```

---

## 5. Mathematical Guarantees

### Contraction Certificate
Verified via the iteration matrix $A = \text{diag}(1-\alpha) + \text{diag}(\alpha)|K|$.
- **SlopeUB** $= \|A\|_\infty \le 0.9$
- **GapLB** $= 1 - \text{SlopeUB} > 0$

### ACE Safety
Projection onto $S_t = \{x : \sum w_i|x_i| \le \tau\}$ ensures bounded energy and stability. KKT-optimized bisection provides exact certificates for $\ell_1$ compliance.

---

## 6. Project Structure

- `crates/`: Standalone core logic and Internalized libraries.
    - `apex-goldilocks-core`: The Atlas/E8 foundation.
    - `apex-pikernel`: The $\pi$-kernel Rust port.
    - `pirtm-compiler`: PIRTM-lang implementation.
- `packages/`: Domain-specific extensions and integrations.
- `src/`: React frontend source (Tauri app).
- `src-tauri/`: Tauri backend and command routing.

---

## 7. Documentation & Governance
- **Architecture**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Validation Report**: [docs/VALIDATION_REPORT.md](docs/VALIDATION_REPORT.md)
- **Governance (Ξ-Constitution)**: [docs/governance/Ξ-Constitution.md](docs/governance/Ξ-Constitution.md)
- **Agent Guidelines**: [AGENTS.md](AGENTS.md)

---

## 8. License

Released by Citizen Gardens, UOR Foundation and collaborators under the Prime Materia Commons License - Cite Atlas→E8, AEP/ISA, rhythm C768, Π‑kernel, and Sedona Spine as appropriate.
