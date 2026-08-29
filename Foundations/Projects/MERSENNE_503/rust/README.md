# MERSENNE_503 Rust Crate

Formal verification framework for Mersenne-503 mathematical structures.

## Modules

- `mersenne` — Mersenne prime M503 field arithmetic
- `leech` — Leech lattice Λ_24 and Golay code
- `tensor` — Prime-indexed tensor fields
- `psl2r` — PSL(2,R) group dynamics
- `ads` — AdS geometric structures
- `bayesian` — Crystallization and entropy operators
- `crypto` — Zeno locks and PIRTM hash
- `codec` — Serialization with round-trip proofs
- `kani_proofs` — Kani formal verification proofs

## Usage

```rust
use mersenne_503::{Mersenne503, LeechLattice, TensorField};

// Mersenne field arithmetic
let a = Mersenne503::new(42);
let b = Mersenne503::new(100);
let c = a.add(&b);

// Leech lattice
let coords = [2i32; 24];
let lattice = LeechLattice::new(coords);
assert!(lattice.is_valid());

// Tensor contraction
let coeffs = vec![TensorCoeff::new(2, 1), TensorCoeff::new(3, 1)];
let field = TensorField::new(coeffs, 10);
let sum = field.contract(2.0).unwrap();
```

## Verification

```bash
cargo test
cargo kani -- kani_proofs.rs
```
