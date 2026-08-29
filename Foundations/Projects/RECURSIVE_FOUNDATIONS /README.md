# RECURSIVE FOUNDATIONS

Production-grade formal verification framework for recursive foundations.

## Structure

```
RECURSIVE_FOUNDATIONS/
├── docs/
│   └── templateArxiv.tex
├── lean/
│   └── Foundations/Recursive/
│       ├── Core.lean
│       ├── FixedPoint.lean
│       ├── Induction.lean
│       ├── Coinduction.lean
│       ├── WellFounded.lean
│       ├── Examples.lean
│       └── Tests.lean
├── rust/
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs
│   │   ├── error.rs
│   │   ├── recursive.rs
│   │   └── kani_proofs.rs
│   └── tests/
│       └── integration.rs
├── lakefile.lean
├── lake-manifest.json
└── lean-toolchain
```

## Lean 4 Build

```bash
cd /home/citizen/Multiplicity/Foundry/Projects/RECURSIVE_FOUNDATIONS\ /
lake build
```

## Rust/Kani Build

```bash
cd /home/citizen/Multiplicity/Foundry/Projects/RECURSIVE_FOUNDATIONS\ /rust
cargo build
cargo test
cargo build --features kani
```

## Modules

| Module | Description |
|--------|-------------|
| `Core` | Peano Nat, List, Tree, basic recursion |
| `FixedPoint` | Y combinator, Knaster-Tarski, Kleene iteration |
| `Induction` | Nat, list, tree, strong, complete, double induction |
| `Coinduction` | Streams, lazy lists, corecursion, bisimulation |
| `WellFounded` | Acc, well-founded recursion, termination |
| `Examples` | Fact, fib, GCD, reverse, mirror, even/odd |
| `Tests` | Comprehensive test suite |
