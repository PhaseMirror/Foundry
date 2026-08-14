# ADR-002: Numerical Integration & Observables

## Status
Proposed

## Context
To validate the Zeta Phase Transistor, we must capture the evolution of the quantum state with high fidelity and define observables that can distinguish between "prime-ordered" and "random-ordered" dynamics.

## Decision
We will standardize on the following integration and analytical standards:

### 1. Integration Standard
- **Method**: `DOP853` (Dormand-Prince 8th order explicit Runge-Kutta).
- **Tolerances**: `rtol=1e-8`, `atol=1e-10` to prevent numerical phase drift.
- **Time Horizon ($T$m)**: Default $T=100$, $dt=0.05$, ensuring we capture at least 10-20 cycles of the primary zeta-zero frequencies.

### 2. Standard Observables
- **Circular Phase Variance ($V_{circ}$)**:
  $$V_{circ}(t) = 1 - \left| \frac{1}{N} \sum_{i=1}^N e^{i \theta_i(t)} \right|$$
  Measures the global phase synchronization across the prime chain.
- **Inverse Participation Ratio ($IPR$ / $L$)**:
  $$L(t) = \sum_{i=1}^N |c_i(t)|^4$$
  Measures state localization; $L \to 1$ implies localization in a single prime mode, $L \to 1/N$ implies uniform distribution.
- **Fidelity ($F$)**:
  $$F(t) = |\langle \psi(0) | \psi(t) \rangle|^2$$
  Tracks recurrence and global coherence preservation.

## Consequences
- **Precision**: High-order integration avoids false-positive "instabilities" caused by numerical noise.
- **Clarity**: Standardized metrics allow for direct comparison across different prime truncations ($N$).
