# archemedian-rs: ACFL Operators

High-performance Rust implementation of Forward ACFL (ArchemedianCompensatory Fuzzy Logic) operators.

## Features
- **Standard Conjunction**: Geometric mean based fuzzy conjunction.
- **Standard Disjunction**: De Morgan dual of conjunction.
- **Standard Negation**: Linear negation within [0, 1].
- **Type Safety**: Enforced arity and range constraints ($arity \ge 2$, $value \in [0, 1]$).
- **Error Handling**: Explicit `ArchemedianError` types for domain violations.

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
