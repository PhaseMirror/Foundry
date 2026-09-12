# pirtm-rs: Prime-Indexed Recursive Tensor Machine

High-performance Rust implementation of the PIRTM core recurrence engine.

## Core Features
- **Recurrence Loop**: Implements $X_{t+1} = (1 - \lambda_m)X_t + \lambda_m P(\Xi_t X_t + \Lambda_t T(X_t) + G_t)$.
- **Prime-Recursive Engine**: Formal engine with spectral radius approximation over prime truncations.
- **PREP-2026 Compliance**: Built-in conformance runner and invariant enforcement (I1-I4).
- **Multiplicity Functor**: Verified additive mapping from prime operators to spectral coordinates.

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```

### Conformance Check
```bash
cargo run --bin prep_conform -- --out-dir ./evidence
```
