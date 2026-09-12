# MEA — Monodial Ensemble Aggregation

Production-grade Rust framework for monoidal ensemble aggregation with formally verified algebraic laws.

## Architecture

```
MONODIAL_ENSEMBLE_AGGREGATION/
├── .github/workflows/ci.yml  -- GitHub Actions CI
├── docs/                     -- Documentation
├── formalization.lean        -- Lean 4 placeholder
├── lakefile.lean             -- Lean 4 placeholder
├── README.md
├── references.bib
└── rust/
    ├── Cargo.toml
    ├── Cargo.lock
    ├── README.md
    ├── src/
    │   ├── lib.rs
    │   ├── main.rs
    │   ├── error.rs
    │   ├── monodial.rs
    │   ├── ensemble.rs
    │   ├── aggregate.rs
    │   ├── verify.rs
    │   ├── codec.rs
    │   └── kani_proofs.rs
    └── tests/
        └── integration.rs
```

## Build

```bash
cd rust
cargo build
cargo test
cargo build --features kani
```

## Verification Strategy

| Layer | Tool | Scope |
|-------|------|-------|
| Unit tests | `cargo test` | Functional correctness |
| Proofs | `cargo kani` | Bit-precision, algebraic laws |
| CI | GitHub Actions | Multi-OS testing, clippy |

## Key Concepts

| Concept | Description |
|---------|-------------|
| **MonoidalObject** | Object in monoidal category |
| **MonoidalMorphism** | Morphism between objects |
| **MonoidalCategory** | Category with ⊗ and I |
| **Ensemble** | Weighted collection of elements |
| **AggregateOp** | Sum, product, weighted average, max, min |
| **AlgebraicLaw** | Associativity, identity, commutativity, distributivity |

## Status

- **Build**: `cargo build` succeeds
- **Tests**: `cargo test` passes (24 lib + 14 integration tests)
- **Kani**: 8 formal verification proofs
- **No mathlib dependency**: Pure Rust/Kani
