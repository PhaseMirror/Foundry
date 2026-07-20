# Complex-Kappa Production Implementation: Usage Guide

## Overview

This guide walks through setting up, building, and verifying the Complex Gravitational Coupling production implementation. The system consists of:

- **Rust crate `complex-kappa`**: Computational kernels with Kani bounded model checking
- **Lean 4 modules `ComplexKappa.*`**: Mathematical specification and theorem scaffolding
- **CI/CD**: Zero-sorry enforcement, Lean build, Rust test, Kani verification

## Prerequisites

```bash
# Lean 4
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
elan default leanprover/lean4:v4.32.0-rc1

# Rust (nightly for Kani)
rustup install nightly
rustup default nightly

# Kani
cargo install kani-verifier

# provable-contracts (optional, for YAML-driven stub generation)
cargo install provable-contracts-cli
```

## Build Commands

### Rust

```bash
# Check compilation
cargo check -p complex-kappa

# Run unit tests
cargo test -p complex-kappa

# Run property tests (proptest)
cargo test -p complex-kappa -- --ignored

# Run Kani bounded model checking
cargo kani -p complex-kappa

# Clippy
cargo clippy -p complex-kappa -- -D warnings
```

### Lean 4

```bash
# Build all modules
lake build

# Run tests
lake test

# Zero-sorry check
bash scripts/check_complex_kappa_sorry.sh
```

### Docker (reproducible)

```bash
docker build -f Dockerfile.complex-kappa -t complex-kappa-builder .
docker run -it -v $(pwd):/workspace complex-kappa-builder bash
# Inside container:
lake build && cargo test -p complex-kappa && cargo kani -p complex-kappa
```

## Module Structure

```
src/ComplexKappa/
├── Core.lean              -- Types, definitions, ADR record
├── HilbertTransform.lean  -- PV, Hilbert transform, self-invertibility
├── Distributions.lean     -- PV(1/x), Dirac delta, Sokhotski-Plemelj
├── KramersKronig.lean     -- KK relations for causal response functions
├── WardIdentity.lean      -- Ward identity, Bianchi preservation
├── EffectiveCoupling.lean -- κ_eff formula, KK constraint
├── Zeta.lean              -- Riemann zeta, nontrivial zeros, γ_n
├── ZetaComb.lean          -- Noise kernel, convergence, amplitudes
├── GUE.lean               -- GUE pair correlation, beat spectrum
├── MainTheorem.lean       -- Master theorem assembly
└── Test.lean              -- Test harness, sorry checks

crates/complex-kappa/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   └── kernels/
│       ├── zeta_zeros.rs
│       ├── hilbert_transform.rs
│       ├── effective_coupling.rs
│       └── pair_correlation.rs
└── tests/
    └── kani_verification.rs
```

## Adding a New Theorem

1. **Lean side**: Add the theorem to the appropriate `ComplexKappa.*` module. Ensure it compiles with `lake build`.
2. **Rust side**: Add the computational kernel to `crates/complex-kappa/src/kernels/` with `#[cfg(kani)]` verification.
3. **Test side**: Add a Kani proof harness in `tests/kani_verification.rs` and/or a `#[cfg(test)]` property test.
4. **CI side**: The workflow automatically picks up changes.

## Zero-Sorry Policy

- All Lean modules must compile with **zero `sorry`** and **zero `admit`**.
- The CI job `sorry-check` enforces this via `grep`.
- If a proof requires Mathlib, move it to `lean/Core/f1_square/` (which has Mathlib) or prove it in Rust/Kani first, then lift to Lean.

## Refinement Gates

Every theorem in Lean must have a corresponding Rust kernel:

| Lean Theorem | Rust Kernel | Verification |
|--------------|-------------|--------------|
| `hilbert_self_invertible` | `hilbert_transform::hilbert_transform` | Kani + proptest |
| `kk_relation_1/2` | `hilbert_transform::hilbert_transform` | Kani |
| `ward_identity` | N/A (structural) | Lean proof only |
| `complex_kappa_theorem` | `effective_coupling::complex_kappa_eff` | Integration test |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `lake build` fails with "unknown identifier `Real`" | Ensure `lean-toolchain` is `v4.32.0-rc1`; `Real` is in core Lean 4 |
| `cargo kani` fails with "unsupported feature" | Use nightly toolchain; Kani requires nightly Rust |
| `sorry` found in CI | Remove `sorry` or move theorem to Mathlib-backed module |
| Kani times out | Reduce `#[kani::unwind(N)]` or split proof into smaller harnesses |

## Extending the Scaffolding

To add a new physics module (e.g., `ComplexKappa.Bootstrap`):

1. Create `src/ComplexKappa/Bootstrap.lean`
2. Add `ComplexKappa.Bootstrap` to `roots` in `lakefile.lean`
3. Add Rust kernels in `crates/complex-kappa/src/kernels/bootstrap.rs`
4. Add Kani harnesses in `tests/kani_verification.rs`
5. Update CI workflow if new tools are needed
