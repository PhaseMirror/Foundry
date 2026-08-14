# plst-rs: Prime-Indexed Layered Stability/Topology

Rust implementation of the Prime-Indexed Layered Stability/Topology (PLST) engine, providing core prime-encoding and state representation primitives for the Multiplicity substrate.

## Features
- **Prime Encoding**: Maps categorical states to prime-indexed canonical forms ($S \cong \prod p_i^{e_i}$).
- **Signature Analysis**: Generates human-readable prime-indexed signatures and supports numerical prime product computation.
- **Topological Invariants**: Implements L1 norm and normalized profile calculations for stability monitoring.
- **Type Safety**: Enforced state representation and prime-support validation.

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
Aligned with Multiplicity substrate prime-decomposition requirements for formal verification of state trajectories.
