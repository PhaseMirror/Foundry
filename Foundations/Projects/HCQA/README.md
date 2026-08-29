# HCQA — Universal Atomic Calculator

Lean 4 formalization of the **Universal Atomic Calculator (UAC)**:
a hybrid classical-quantum architecture for atomic self-simulation.

## Architecture

```
HCQA/
├── lakefile.lean
├── HCQA/
│   ├── Core.lean          -- Qudit types, subspaces, atom species
│   ├── Qudit.lean         -- Qudit Compression Theorem, basis states
│   ├── MAVQE.lean         -- Multiplicity-Adaptive VQE algorithm
│   ├── HSEC.lean          -- Hyperfine Subspace Error Correction
│   ├── QCFI.lean          -- Qudit-Classical Feedback Interface
│   ├── M3A.lean           -- Multi-Manifold Modular Array
│   ├── Hardware.lean      -- Neutral-atom hardware specifications
│   ├── Proofs.lean        -- Verified theorems
│   ├── Examples.lean      -- Concrete instantiations
│   ├── Test.lean          -- Test harness (lake exe)
│   ├── Export.lean        -- Markdown export
│   └── Main.lean          -- Entry point
├── rust/
│   ├── Cargo.toml
│   ├── src/lib.rs         -- Numerical backend
│   └── tests/             -- Unit tests (cargo test)
└── docs/
    └── templateArxiv.tex  -- Full paper
```

## Build

```bash
# Lean 4 formalization
lake build
lake exe HCQATest

# Rust numerical backend
cd rust
cargo build
cargo test
```

## Status

- **Lean**: `lake build` succeeds (26 jobs). Tests pass.
- **Rust**: `cargo build` and `cargo test` pass (7/7 tests).
- **Theorems**: Core theorems are `sorry` skeletons; verified lemmas marked with `native_decide` where applicable.

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Qudit** | d-dimensional quantum system, d = 2(2I+1) |
| **MA-VQE** | Multiplicity-Adaptive Variational Quantum Eigensolver |
| **HSEC** | Hyperfine Subspace Error Correction |
| **QCFI** | Qudit-Classical Feedback Interface |
| **M³A** | Multi-Manifold Modular Array |
| **UAC** | Universal Atomic Calculator |
