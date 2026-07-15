# Math-First Glossary: Canonical Definitions

This glossary defines the foundational terms of Multiplicity Theory as they are used across the `agi-os` documentation, ADRs, and implementation.

## <a name="multiplicity-space"></a>1. Multiplicity Space
The mathematical domain where identities are represented as operators on a prime-indexed field. In this space, an entity is defined not by a static ID, but by its composite prime value and its operator interaction with other primes.

## <a name="prime-indexed-interaction"></a>2. Prime-Indexed Interaction
An interaction between two entities where the underlying operation is defined by the relationship between their respective prime indices. This ensures uniqueness (Fundamental Theorem of Arithmetic) and prevents identity collisions or masquerading.

## <a name="recursive-feedback-loop"></a>3. Recursive Feedback Loop
A process where the output of a module is fed back into itself or a parent module. In Multiplicity, these loops must be proven **contractive** (Lipschitz constant < 1) to ensure the system does not enter a divergent, unstable state.

## <a name="l0-invariant"></a>4. L0 Invariant
A non-negotiable, substrate-level mathematical constraint (e.g., spectral radius < 1, schema hash integrity, prime-indexed uniqueness). L0 invariants are checked at sub-nanosecond speeds and result in immediate "Silence" (fail-closed) if violated.

## <a name="spectral-governance"></a>5. Spectral Governance
The practice of controlling system behavior by monitoring and constraining the spectral radius ($\rho$) of the operator matrix. If $\rho \ge 1$, the system is mathematically unstable and execution is denied by the StabilityGate.

## <a name="drift-bound"></a>6. Drift Bound ($\delta$)
A parameter measuring the divergence of a state transition from its lawful specification. The Ξ-Constitution mandates $\delta < 0.3 \xi$ (where $\xi$ is the norm of the state operator) to prevent cumulative "semantic drift" that could lead to lawlessness.

## <a name="ethical-manifold"></a>7. Ethical Manifold
A lower-dimensional subspace within the Multiplicity Space that represents "admissible" or "ethical" configurations. Governed loops (ZRSD) are designed to refine system parameters such that they converge toward this manifold.

## <a name="mtpi"></a>8. Meta-Theorem of Prime Identity (MTPI)
The core theorem stating that any lawful identity can be uniquely decomposed into a product of primes, and that this decomposition is invariant under lawful state transitions.

---
*Use these terms consistently to maintain semantic coherence across the substrate.*
