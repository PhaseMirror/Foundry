# FZS-MK Engine

The FZS-MK (Functorial Zeno Sheaf with Memory Kernel) engine is the core Hamiltonian protection layer of the Multiplicity Knot architecture, responsible for enforcing constitutional invariants via a Non-Markovian master equation.

## Overview
The engine prevents drift beyond the critical threshold ($\delta_{crit} = 0.17$) and employs a Zeno-Ward projection gradient for constitutional enforcement.

## Key Features
- **Non-Markovian Master Equation:** Implements complex dynamics with a Riemann zeta-based memory kernel.
- **Constitutional Invariant Protection:** Enforces a hard floor on drift ($\delta_{crit} = 0.17$).
- **Tiered Response System:** Automated responses ranging from GICD blocking to full system halts upon detected violations.

## Implementation Details
- Uses `ndarray` for tensor operations.
- Integrates pre-calculated Riemann zeta zeros as the physical constants for the kernel.
- State-machine driven (NucleationState).

## Development
```bash
cd fzs-mk-engine
cargo build
cargo test
```
