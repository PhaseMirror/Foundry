# Knot-in-Time Core

This crate provides the Rust implementation of the core `KnotHamiltonian` and `InvariantRegistry` from the original Helix-Hamiltonian system. It focuses on the constitutional architectural primitives required for sovereign AI governance.

## Overview
The library provides mathematical primitives for defining the Hamiltonian landscape of an AI interaction and enforces non-negotiable jurisdictional invariants.

## Key Features
- **Knot Hamiltonian Construction:** Facade for $H_{\mathrm{knot}} = H_{\mathrm{free}} + H_{\mathrm{fold}} + \lambda H_{\mathrm{topo}}(K)$.
- **Invariant Drift Auditing:** Terminal audit against the 0.17 drift constant, with jurisdictional sensitivity multipliers.
- **Constitutional Compliance:** Implements mandatory fail-closed behavior for FACT-form interactions.

## Implementation Details
- Uses `ndarray` and `num-complex` for Hamiltonian matrix construction.
- Includes jurisdictional guards to ensure authority compliance.

## Development
```bash
cd knot-in-time-core
cargo build
cargo test
```
