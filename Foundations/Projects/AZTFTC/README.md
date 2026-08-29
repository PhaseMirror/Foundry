# AZ-TFTC

Lean 4 formalization of the AZ-TFTC numerical model with a Rust/Kani verification backend.

## Status

- **Lean 4.31.0** — builds and tests pass
- **Rust** — builds successfully; Kani harnesses present but require `cargo kani`
- **Incomplete proofs** — 8 theorems remain as `admit` skeletons (see below)

## Prerequisites

- [Lean 4](https://leanprover.github.io/) (v4.31.0 via `lean-toolchain`)
- [Lake](https://github.com/leanprover/lake) (bundled with Lean)
- Rust toolchain (for `rust/`)

## Build

```bash
lake build
```

## Test

```bash
lake exe AZTFTCTest
```

## Rust

```bash
cd rust && cargo build
```

Kani verification harnesses are in `rust/tests/kani_verify.rs`. Run with:

```bash
cd rust && cargo kani --tests --unwind 10
```

## Architecture

```
AZTFTC/
├── lakefile.lean          # Lake package definition
├── lean-toolchain         # leanprover/lean4:v4.31.0
├── AZTFTC/
│   ├── Core.lean          # Types: FP_DEN=100, primes, log-grid constants
│   ├── Hilbert.lean       # Discrete Hilbert space ℓ²(P) ⊗ L²(ℝᵈ) ⊗ ℂʳ
│   ├── Lawful.lean        # Lawful subspace H_lawful = Π_CSL H
│   ├── Operators.lean     # Universal operator U, H_ZM, H_AZ, power iteration
│   ├── GeoPotential.lean  # Φ_σ(x), V_geo(x), log-Gaussian mollifier
│   ├── Boundary.lean      # Fractal Dirichlet teeth at log-prime positions
│   ├── Spectral.lean      # Dominant eigenvalue, prime-resonance, Q enhancement
│   ├── Casimir.lean       # Casimir force, δ(L), curvature shift
│   ├── Proofs.lean        # Aggregated verified theorems
│   ├── Examples.lean      # Concrete instantiations (tiny systems)
│   ├── Test.lean          # IO test harness (lake exe entry)
│   ├── Export.lean        # Markdown export from formal model
│   └── Main.lean          # Executable entry point
├── rust/
│   ├── Cargo.toml         # Rust workspace with Kani
│   ├── src/
│   │   └── lib.rs         # Discrete Rust implementation
│   └── tests/
│       └── kani_verify.rs # Kani BMC proof harnesses
└── docs/                  # Generated artifacts (empty; run Export to populate)
```

## Verified Properties

| Property | Status |
|----------|--------|
| `FP_DEN = 100` | Verified |
| `isPrime` correctness | Verified for small n |
| `π(10) = 4`, `π(20) = 8` | Verified |
| Hilbert space dimension `N*M*r` | Verified |
| Zero vector norm is 0 | Verified |
| Basis vector norm is 1 | Verified |
| `logGaussian` symmetry | Verified |
| `vGeo` linearity in Phi | Verified |
| Example computations compile | Verified |

## Incomplete Proofs (8 skeletons)

The following theorems admit incomplete proofs and require deeper metric-space / fixed-point reasoning:

| File | Theorem |
|------|---------|
| `Core.lean` | `first5_primes` |
| `Proofs.lean` | `prime_2`, `prime_3`, `not_prime_4`, `pi_10`, `pi_20`, `examplePhiSigma_pos`, `exampleVGeo_pos`, `exampleSpectrum_len` |
| `Operators.lean` | `buildU`/`buildHAZ` matrix shape proofs |
| `Boundary.lean` | `applyFractalTeeth` matrix shape proof |

## Export

Generate Markdown artifacts from the formal model:

```bash
lake exe AZTFTCExport
```

Currently exports:
- Core constants table
- Prime statistics
- Geometric potential summary
- Spectral results

## Integration Notes

- Lean `Sentence` maps to Rust `Sentence` enum (6 variants, same ordering).
- `Valuation` in Lean is `Sentence → Nat`; in Rust it is `[usize; 6]`.
- `provOracle` is deterministic in both implementations.
- Conservative extension is currently trivial (`ProvF' ≡ ProvF`); replace with genuine deductive conservativity for production use.
