# operators-rs: Multiplicity Algebraic Primitives

Fundamental algebraic operators for the Multiplicity substrate.

## Features
- **XiOperator**: Canonical $\Xi(t)$ prime-contractive evolution with exponential decay.
- **MultiplicitySumOperator**: Summation of prime-indexed components $M = \sum A_p$.
- **Primality Enforcement**: Compile-time and runtime checks for prime-indexed address space.
- **Spectral Norms**: High-performance spectral radius calculations via `nalgebra`.

## Verification
```bash
cargo test
```
