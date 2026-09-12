# zrsd-rs: Zero-Residual Spectral Dynamics

High-frequency stability controller and quantum-like time-evolution engine.

## Features
- **Lindblad Dynamics**: $d\rho/dt = -i[H, \rho] + \sum \mathcal{D}[L_k](\rho)$.
- **Solvers**: RK4 and Euler time-evolution with trace-preservation.
- **Zeta Resonance**: Hamiltonian construction coupled to Riemann zeta zeros.
- **Observables**: Expectation values, purity, and von Neumann entropy.

## Verification
```bash
cargo test
```
