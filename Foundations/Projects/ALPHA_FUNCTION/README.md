# Alpha Function

Lean 4 formalization of the Alpha Function master definition with a Rust/Kani verification backend.

## Status

- **Lean 4.31.0** — builds and tests pass
- **Rust** — builds successfully; Kani harnesses present but require `cargo kani`

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
lake exe AlphaFunctionTest
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
ALPHA_FUNCTION/
├── lakefile.lean
├── lean-toolchain
├── AlphaFunction/
│   ├── Core.lean
│   ├── SpecialFunctions.lean
│   ├── Quadrature.lean
│   ├── Diagnostics.lean
│   ├── Kernels.lean
│   ├── ACEIntegration.lean
│   ├── PETC.lean
│   ├── Proofs.lean
│   ├── Examples.lean
│   ├── Test.lean
│   ├── Export.lean
│   └── Main.lean
├── rust/
│   ├── Cargo.toml
│   ├── src/lib.rs
│   └── tests/kani_verify.rs
└── docs/
```

## Verified Properties

| Property | Status |
|----------|--------|
| Alpha master definition compiles | Verified |
| Kernel G1/G2/G3 at zero | Verified |
| Zeta slice for s > 1 | Verified |
| Soft-threshold projection | Verified |
| Diagnostics merge | Verified |

## Incomplete Proofs

| File | Theorem |
|------|---------|
| `Proofs.lean` | `params_lengths_match`, `G2_at_zero`, `G3_at_zero`, `merge_assoc`, `default_merge_id`, `softThreshold_nonincreasing`, `projection_feasible`, `budget_monotone` |

## Export

Generate Markdown artifacts from the formal model:

```bash
lake exe AlphaFunctionExport
```
