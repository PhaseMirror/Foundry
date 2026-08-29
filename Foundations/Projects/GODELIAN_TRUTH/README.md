# Godelian Truth

Lean 4 (Lake) + Rust/Kani formalization of a fixed-point semantics for Gödel sentences with prime-sieved variants.

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
lake exe GodelianTruthTest
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
GODELIAN_TRUTH/
├── lakefile.lean          # Lake package definition
├── lean-toolchain         # leanprover/lean4:v4.31.0
├── GodelianTruth/
│   ├── Core.lean          # Types: Sentence, Valuation, FP_DEN=100, λ=60, α=30, supNorm, validFP
│   ├── Gamma.lean         # Grounded operator Γ, strong Kleene connectives (skNeg, skAnd, skOr, skImpl), provOracle
│   ├── Contraction.lean   # Φ_{α,c}, T_λ, Lipschitz bound, Picard iteration, fixpointTLambda
│   ├── Godel.lean         # SoundnessF, Gödel coordinate theorem, scalar recursion, meta-consistency
│   ├── PrimeSieved.lean   # isPrime, primesUpTo, π(n), prime-sieved iteration
│   ├── LawfulSchedules.lean # LawfulSchedule σ, lawfulIterate, convergence/rate theorems
│   ├── Conservative.lean  # CauchyName, LimitSchema, UniquenessSchema, ConservativeExtension
│   ├── Proofs.lean        # Aggregated verified theorems
│   ├── Examples.lean      # Concrete instantiations (exZeroV, exTLambdaZero, etc.)
│   ├── Test.lean          # IO test harness (lake exe entry)
│   ├── Export.lean        # Markdown export from formal model
│   └── Main.lean          # Executable entry point
├── rust/
│   ├── Cargo.toml         # Workspace + local Kani path dep
│   └── src/
│       ├── lib.rs         # Discrete Rust implementation (constants, Γ, Φ, T_λ, primes, soundness, conservative)
│       └── tests/
│           └── kani_verify.rs  # Kani BMC proof harnesses
└── docs/                  # Generated artifacts (empty; run Export to populate)
```

## Verified Properties

| Property | Status |
|----------|--------|
| `FP_DEN = 100`, `0 < λ < 100`, `0 < α < 100` | Verified (`native_decide`) |
| `contractionFactor < FP_DEN` | Verified (`native_decide`) |
| `Γ` well-defined (`validFP`) | Verified (requires `∀ φ, validFP (v φ)`) |
| Strong Kleene bounds | Verified (`omega`) |
| `π(10) = 4`, `π(20) = 8` | Verified |
| `isPrime` correctness | Verified for 2, 3, 4 |
| `lipschitzBound λ α < FP_DEN` (default params) | Verified |
| Conservative extension `ProvF ↔ ProvF'` | Verified (definitional equality) |

## Incomplete Proofs (8 skeletons)

The following theorems admit incomplete proofs and require deeper metric-space / fixed-point reasoning:

| File | Theorem |
|------|---------|
| `Contraction.lean:40` | `lipschitz_bound_strict` (general `lam * a >= FP_DEN` case) |
| `Contraction.lean:55` | `fixpoint_invariant` (`T_λ(v*) = v*` for the 10-iteration fixed point) |
| `Contraction.lean:61` | `banach_fixed_point_exists` (Banach existence) |
| `Godel.lean:31` | `godel_scalar_recursion` (explicit scalar expansion of `T_λ` on atomG) |
| `Godel.lean:39` | `godel_meta_consistent` (`v*(G) = FP_DEN` under soundness + bias `c(G)=1`) |
| `PrimeSieved.lean:47` | `prime_sieved_convergence` (rate `‖v_k - v*‖ ≤ ‖v_0 - v*‖`) |
| `LawfulSchedules.lean:32` | `lawful_convergence` (convergence under arbitrary lawful schedule) |
| `LawfulSchedules.lean:40` | `lawful_rate_bound` (rate bound after `m` effective updates) |

## Export

Generate Markdown artifacts from the formal model:

```bash
lake exe GodelianTruthExport
```

Currently exports:
- Core constants table
- Fixed-point valuation table
- Gödel coordinate theorem statement
- Prime-sieved convergence rate formula

## Integration Notes

- Lean `Sentence` maps to Rust `Sentence` enum (6 variants, same ordering).
- `Valuation` in Lean is `Sentence → Nat`; in Rust it is `[usize; 6]`.
- `provOracle` is deterministic in both implementations.
- Conservative extension is currently trivial (`ProvF' ≡ ProvF`); replace with genuine deductive conservativity for production use.
