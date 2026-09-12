# ADR-003: Null Model Architecture & Validation Strategy

## Status
Proposed

## Context
A positive result in a zeta simulation is only meaningful if it outperforms a non-prime baseline. We need a rigorous method to isolate the effect of "prime structural order."

## Decision
We will implement a **Shuffled-Gap Null Ensemble** as the primary validator.

### 1. Shuffled-Gap Control
- **Mechanism**: For a given set of first $N$ primes, we extract the sequence of normalized gaps $\tilde{g} = (\tilde{g}_1, \dots, \tilde{g}_{N-1})$.
- **Ensemble**: Generate $R=200$ realizations where the order of $\tilde{g}$ is randomly permuted.
- **Identity**: The $H_{prime}$ terms and zeta-zero frequencies remain identical; only the coupling topology is scrambled.

### 2. Statistical Thresholds
- **Metric**: Time-averaged observables ($\bar{V}, \bar{L}, \bar{F}$).
- **Significance**: The "Prime Advantage" is defined as a z-score where $|z| > 2$ for the true sequence relative to the null ensemble distribution.
- **P-Value**: A one-sample test where $p < 0.05$ indicates that prime structural order is dynamically relevant.

## Consequences
- **Rigour**: Prevents "overfitting" to a specific zeta-zero drive by showing that the specific prime-gap sequence is critical to the result.
- **Robustness**: If the effect persists across multiple random phase initializations ($\phi_n$), the claim of "Prime Lawfulness" is strengthened.
