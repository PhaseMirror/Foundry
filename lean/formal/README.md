# PIRTM-Formal: Lean 4 Certification Library

Production-grade formal verification for PhaseSpace Multiplicity Theory components.

## Components

- **PIRTM** - Prime-indexed Recursive Tensor Mechanics convergence theorems
- **PARM** - Prime-indexed Recurrence Multi-dimensional Extremal Ordering
- **Multiplicity** - Functor laws for prime signature multiplicities
- **PWEH** - Prime-Weighted Execution Hashing for order-commitment

## Quick Start

```bash
lake build
```

All proofs must check without `sorry`. The `AllTests.lean` harness verifies key theorems.

## Architecture

```
PIRTM-Formal/
├── lakefile.lean      # Lake build configuration
├── lean-toolchain     # Lean 4 stable toolchain
├── src/PIRTM/
│   ├── Init.lean      # Core helpers
│   ├── Signatures.lean  # Prime signature structure
│   ├── Multiplicity.lean  # Functor laws
│   └── PARM.lean      # Extremal ordering
├── tests/
│   └── AllTests.lean  # Master harness
└── docs/ADRs/        # Decision records
```

## License

MIT