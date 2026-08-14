# moonshine-rs: Multiplicity Moonshine Validation Engine

High-performance Rust implementation of the Moonshine validation engine, focusing on exact rational arithmetic and formal verification.

## Core Features
- **Prime-Word Grading**: Immutable prime-indexed state representation with Ω-grading.
- **Fixed-Point Core**: Generic fixed-point iteration engine with rational lift and certification.
- **Hecke Algebra**: Hecke operator construction and algebraic verification (commutativity, multiplicativity).
- **Formal Verification**: Includes a `lean4` proof of fixed-point convergence (Banach theorem) for contractive maps.

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```

## Formal Proof
The core convergence property is formalized in `proofs/Moonshine.lean` using Lean 4 and Mathlib.
