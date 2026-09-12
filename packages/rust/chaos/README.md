# chaOS-RS: Rust Implementation of Poly-Ontological Resonance

This project is a high-performance Rust port of the research engine `chaOS` from the PhaseMirror-HQ program. It implements the Λₘ-Lawfulness contract to stabilize heavy-tailed innovation across physical, social, and neural strata.

## Project Status

- **Core Stability:** Spectral Admissibility and Lyapunov stability checkers implemented and formally verified in Lean 4.
- **Stochastic Harness:** Gaussian and Cauchy innovation generators operational.
- **MPW-FL:** Multiplicity-Prime Weighted Fuzzy Logic engine implemented.
- **Fiber Modeling:** Physical Fiber (3-cycle Laplacian) implemented.

## Project Structure

- `chaos-core/`: Core Rust library containing invariants, engines, and ontological fibers.
- `chaos-proof/`: Lean 4 project for formal verification of stability axioms.

## Development

Build the Rust project:
```bash
cd chaOS-rs/chaos-core
cargo build
```

Verify formal proofs:
```bash
cd chaOS-proof
lake build
```
