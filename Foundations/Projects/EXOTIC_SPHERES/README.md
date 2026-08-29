# Exotic Spheres

Lean 4 formalization of **prime-indexed multiplicity invariants for Brieskorn spheres**, including plumbing canonicalization, smooth-sensitive kernels, p-adic graded pieces, and prime-tier invariants.

## Architecture

```
EXOTIC_SPHERES/
├── lakefile.lean
├── ExoticSpheres/
│   ├── Core.lean          -- Primes, p-adic valuation, basic types
│   ├── Plumbing.lean      -- Star-shaped plumbing graphs, Mode A canonicalization
│   ├── Brieskorn.lean     -- Σ(2,3,r) data, Eells–Kuiper invariant
│   ├── Kernel.lean        -- Smooth-sensitive kernel K_Σ
│   ├── Multiplicity.lean  -- Prime-weighted multiplicity matrix M_Σ
│   ├── Graded.lean        -- p-adic graded pieces G_{p^r}
│   ├── Invariants.lean    -- Prime-tier invariants (traces, char poly)
│   ├── Knots.lean         -- Jones polynomial, braids, skein relations
│   ├── Proofs.lean        -- Aggregated verified theorems
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
lake exe ExoticSpheresTest

# Rust numerical backend
cd rust
cargo build
cargo test
```

## Status

- **Lean**: `lake build` succeeds (28 jobs). Tests pass.
- **Rust**: `cargo build` and `cargo test` pass (12/12 tests).
- **Theorems**: Core theorems are `sorry` skeletons; verified lemmas marked with `native_decide`.

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Brieskorn Sphere** | Σ(2,3,r) homology sphere from link of singularity |
| **Plumbing** | Star-shaped graph with intersection form Q |
| **CMT** | Coherent Multiset Tensor reducing prime gaps |
| **K_Σ** | Smooth-sensitive kernel combining Q + Eells–Kuiper invariant |
| **M_Σ** | Prime-weighted multiplicity matrix: `p_i^{μ_i} p_j^{μ_j} K_Σ(i,j)` |
| **Graded Piece** | G_{p^r}(Σ): p-adic layer of M_Σ reduced mod p |
| **Prime-Tier Invariant** | Traces and characteristic polynomials from G_{p^r}(Σ) |
