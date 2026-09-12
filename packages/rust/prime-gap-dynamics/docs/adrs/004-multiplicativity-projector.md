# ADR-004: Multiplicativity Projector (Pi_lawful)

## Status
Proposed

## Context
Multiplicity Theory posits that structural identity is preserved via prime-factorizable interaction patterns. In the simulator, this corresponds to the state's "Multiplicative Integrity."

## Decision
We will define and implement a measure of **Multiplicative Integrity** on an extended basis.

### 1. Extended Basis ($H_{\mathbb{N}}$)
- While core dynamics occur on primes, we monitor "leakage" into composite states.
- **Lawfulness Constraint**: A state's amplitudes $c_n$ must satisfy $c_{ab} = c_a c_b$ for coprime $a, b$.

### 2. Multiplicativity Error Functional ($E_{mult}$)
Instead of a full projection (which is computationally expensive), we use:
$$E_{mult}(t) = \frac{1}{|\mathcal{S}|} \sum_{(a,b) \in \mathcal{S}} |c_{ab}(t) - c_a(t)c_b(t)|^2$$
- **$\mathcal{S}$**: A fixed subset of coprime pairs $\{a, b\}$ whose product $ab \le P_{max}$.
- **Diagnostic**: If $E_{mult}$ remains near zero, the system is evolving "lawfully" according to Multiplicity Theory.

## Consequences
- **Ontological Link**: Directly tests the "Prime-Lawful Invariant" claim.
- **Identity Tracking**: Provides a metric for how well the "Zeta Transistor" preserves its structural coherence over recursive cycles.
