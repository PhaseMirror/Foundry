# Conscious Symbol Calculus & Log-Floquet Temporal Bridge

This document details the symbolic resonance equations and temporal integration mechanics for PIRTM/DRMM 2.0.

---

## 1. Conscious Symbol Calculus (CSC)

### Definition & Invariants
A symbol is a 5-tuple $\sigma = (\text{tok}, \pi, \rho, a, \kappa)$ with:
- Prime anchor $\pi \in \PP$
- Prime-power resonance profile $\rho(\pi^k) \in \mathbb{C}$
- Amplitude $a \in \mathbb{C}$
- Lawfulness weight $\kappa \in [0, 1]$

The Coherence Norm is defined as:
$$\|\sigma\|_{\text{coh}}^2 = \sum_{k \ge 1} \kappa \frac{k}{\log \pi} |\rho(\pi^k)|^2$$

### Gauge Transformations
- **Phase Gauge:** $\rho(\pi^k) \mapsto e^{i \theta_k} \rho(\pi^k)$ leaves $\|\sigma\|_{\text{coh}}$ invariant.
- **Moonshine Gauge:** Modular actions permuting $(\pi, k)$ along orbits preserve total norm when orbit weights are uniform.

---

## 2. Log-Floquet Temporal Interoperability

### Temporal Coordinate Transformation
To bridge Western linear time $t \in [0, \infty)$ with Eastern seasonal/cyclic time $\phi \in [0, 2\pi)$, we employ the logarithmic time coordinate:
$$\tau = \log t$$
and integrate the skew-Hermitian generator $A(\phi + \Omega s, s)$ where $A^* = -A$.

### Monodromy & Seasonal Monodromy
The closed-loop cyclic monodromy operator is:
$$U_{\circlearrowleft}(t) = \mathcal{T}(\phi + 2\pi, t) \mathcal{T}(\phi, t)^*$$
Evaluating $U_{\circlearrowleft}(t)$ verifies that cyclical state returns are exact up to the seasonal drift envelope $\varepsilon \log t$.
