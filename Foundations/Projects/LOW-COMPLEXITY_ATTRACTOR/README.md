# Low-Complexity Attractor

Lean 4 formalization of the **Low-Complexity Attractor** study:
evaluating φ, e, and prime-indexed candidates under ACE-certified control
with PETC structure and ZK verification.

## Architecture

```
LOW-COMPLEXITY_ATTRACTOR/
├── lakefile.lean
├── LowComplexityAttractor/
│   ├── Core.lean          -- Basic types, golden ratio, attractors, safety sets
│   ├── Dynamics.lean      -- Cubic repair dynamics, iterative repair
│   ├── ACE.lean           -- Safety projection, spectral certificates
│   ├── PETC.lean          -- Prime-encoded tensor structure
│   ├── Metrics.lean       -- Convergence, collapse, drift, entropy
│   ├── Statistics.lean    -- Permutation tests, Hodges-Lehmann, bootstrap
│   ├── ZK.lean            -- Zero-knowledge proximity proof (Q2.11)
│   ├── Proofs.lean        -- Verified theorems
│   ├── Examples.lean      -- Concrete instantiations
│   ├── Test.lean          -- Test harness (lake exe)
│   ├── Export.lean        -- Markdown export
│   └── Main.lean          -- Entry point
├── rust/
│   ├── Cargo.toml
│   ├── src/lib.rs         -- Numerical backend
│   ├── src/kani_proofs.rs -- Kani formal verification proofs
│   └── tests/             -- Unit tests (cargo test)
└── docs/
    └── templateArxiv.tex  -- Full paper
```

## Build

```bash
# Lean 4 formalization (no mathlib dependency)
lake build
lake exe LowComplexityAttractorTest

# Rust numerical backend with Kani verification
cd rust
cargo build
cargo test
cargo kani -- kani_proofs.rs
```

## Status

- **Lean**: `lake build` succeeds (24 jobs). Tests pass.
- **Rust**: `cargo build` and `cargo test` pass (9/9 tests).
- **Kani**: Float-dependent properties verified via `kani-verifier` (bit-precise model checker).
- **Theorems**: 
  - Proved in Lean: `phi_gt_one`, `e_gt_one`, `projection_preserves_dim`, `prime_tensor_mode_count`, `prime_tensor_dims_match`, `converged_state_small_norm`, `collapsed_state_has_nan`, `proximity_proof_sound`
  - Verified in Rust/Kani: `drift_nonnegative`, `entropy_nonnegative`, `permutation_test_range`, `hodges_lehmann_symmetric`, `bootstrap_ci_lower_le_upper`, `encode_decode_roundtrip`, `cubic_repair_preserves_dim`

## Key Concepts

| Concept | Description |
|---------|-------------|
| **φ (golden ratio)** | Low-complexity attractor candidate |
| **e (Euler's number)** | Alternative attractor candidate |
| **Cubic Repair** | Dynamics f_θ(x) = W₃(x³) + W₁x + b |
| **ACE** | Arithmetic Control Engine safety projection |
| **PETC** | Prime-Encoded Tensor Calculus structure |
| **ZK** | Zero-knowledge proximity verification (Q2.11) |
| **Kani** | Bit-precise model checker for Rust verification |

## Verification Strategy

| Property | Tool | Rationale |
|----------|------|-----------|
| Basic arithmetic (φ > 1, e > 1) | Lean `native_decide` | Closed-form expressions |
| Dimension preservation | Lean `simp` | Structural equality |
| Float comparisons | Rust/Kani | `Float.decLe` is opaque in core Lean; Kani provides bit-precise IEEE 754 reasoning |
| Q2.11 roundtrip | Rust/Kani | Fixed-point arithmetic verification |
| Statistical bounds | Rust/Kani | Closed-form constants (0.0, 0.5, 1.0) |
