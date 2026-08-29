# Elastic Tether

Lean 4 formalization of the **Physics-Based Elastic Tether Protocol (ETP)** with Rust/Kani numerical verification backend.

## Architecture

```
ElasticTether/
├── ElasticTether/
│   ├── Core.lean          -- Core types (SafetyParams, AgentState, CMT basics)
│   ├── CMT.lean           -- Coherent Multiset Tensor, gap reduction theorems
│   ├── ETP.lean           -- Protocol dynamics, tether potential, velocity law
│   ├── Axioms.lean        -- A1-A7 verification stubs
│   ├── Validation.lean    -- Protocol 1/2/3 + Phase 4 pass criteria
│   ├── Applications.lean  -- Black-Scholes, PIRTM, Phase Mirror Dissonance
│   ├── Examples.lean      -- Concrete instantiations
│   ├── Proofs.lean        -- Aggregated verified theorems
│   ├── Test.lean          -- Test harness (lake exe)
│   └── Main.lean          -- Entry point
├── rust/
│   ├── Cargo.toml
│   ├── src/lib.rs         -- Numerical backend
│   └── tests/kani_harnesses.rs -- Kani verification harnesses
└── docs/
    └── templateArxiv.tex  -- Full paper
```

## Build

```bash
# Lean 4 formalization
lake build
lake exe ElasticTetherTest

# Rust numerical backend
cd rust
cargo build
cargo kani  # Requires Kani installation
```

## Status

- **Lean**: `lake build` succeeds (24 jobs). Tests pass.
- **Rust**: `cargo build` succeeds. `cargo kani` requires Kani installation.
- **Theorems**: Most core theorems are `sorry` skeletons; verified lemmas marked with `native_decide`.
