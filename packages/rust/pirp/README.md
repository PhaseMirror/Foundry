# pirp: Prime-Indexed Reasoning Primitives

Core algebraic primitives for prime-indexed reasoning in the Multiplicity substrate.

## Features
- **ACFL Operators**: Approximate Compensatory Fuzzy Logic primitives (conjunction, disjunction, negation).
- **Algebraic Invariants**: Idempotency, boundary absorption, and Lipschitz continuity validation.
- **Weight Analysis**: Metrics for weight concentration, entropy, and effective input dimension.
- **Type Safety**: Enforced arity and range constraints ($arity \ge 2$, $value \in [0, 1]$).

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```

## Alignment
Aligned with **ADR-091: L1 Grapheme Decomposition** and compensatory fuzzy logic primitives.
