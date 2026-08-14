# ADR-001: Hamiltonian Specification (v2.0)

## Status
Proposed

## Context
The project requires a physically implementable and numerically stable Hamiltonian to simulate the "Prime-Encoded Zeta Phase Transistor." Previous conceptual drafts included ill-defined infinite products and time-derivatives within the operator, which are unsuitable for standard quantum simulation tools (e.g., QuTiP, SciPy). We need a specification that respects the Meta-Relativity framework while being compatible with Schrödinger evolution.

## Decision
We will adopt the following finite-dimensional, time-dependent Hamiltonian $H(t)$ acting on a Hilbert space $\mathcal{H}_N$ spanned by the first $N$ primes:

$$
H(t) = H_{\text{prime}} + \lambda(t) H_{\text{gap}}
$$

### 1. Prime-Encoded Phase Carrier ($H_{\text{prime}}$)
A static diagonal operator that establishes the "prime frequencies" for the phase carrier:
$$
H_{\text{prime}} = \alpha \sum_{i=1}^N \frac{1}{p_i} |p_i\rangle\langle p_i|
$$
*   **$p_i$**: The $i$-th prime number.
*   **$\alpha$**: Global scaling constant (energy scale).
*   **Rationale**: Implements the inverse-prime weighting derived from the zeta function's Euler product.

### 2. Prime-Gap Modulated Hopping ($H_{\text{gap}}$)
A static tridiagonal operator coupling adjacent primes in the "prime chain":
$$
H_{\text{gap}} = \eta \sum_{i=1}^{N-1} \tilde{g}_i \big( |p_i\rangle\langle p_{i+1}| + |p_{i+1}\rangle\langle p_i| \big)
$$
*   **$\tilde{g}_i$**: Normalized prime gap $g_i = p_{i+1} - p_i$. Normalization: $\tilde{g}_i = \log(1+g_i) / \log(1+g_{\max})$.
*   **$\eta$**: Coupling strength.
*   **Rationale**: Encodes the structural information of prime distributions directly into the hopping dynamics.

### 3. Zeta-Zero Driven Modulation ($\lambda(t)$)
A time-dependent scalar coefficient that modulates the coupling strength based on nontrivial zeta zeros:
$$
\lambda(t) = 1 + \sum_{n=1}^K \gamma_n \cos(t_n t + \phi_n)
$$
*   **$t_n$**: Imaginary part of the $n$-th nontrivial zeta zero ($\rho_n = 1/2 + i t_n$).
*   **$\gamma_n$**: Amplitude envelope, typically $\gamma_n = \gamma_0 / \sqrt{n}$.
*   **$\phi_n$**: Random phase offset to prevent artificial synchronization.
*   **Rationale**: Integrates the "spectral" information of the zeta function as a dynamical control signal.

## Consequences
- **Stability**: The Hamiltonian is Hermitian and finite, ensuring norm conservation during integration.
- **Falsifiability**: Allows for clear "Null Model" comparison by shuffling the $\tilde{g}_i$ sequence.
- **Observables**: Dynamics will manifest in phase variance $V(t)$, IPR $L(t)$, and fidelity $F(t)$, which are sensitive to the specific ordering of $p_i$ and $g_i$.
- **Regularization**: Infinite product forms are replaced by a sum-based exponential equivalent in the simulation logic where necessary (v2.1 extension).
