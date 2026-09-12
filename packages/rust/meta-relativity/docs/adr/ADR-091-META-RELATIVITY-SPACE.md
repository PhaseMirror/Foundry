---
slug: adr-091-meta-relativity-space
status: draft
created: '2026-03-31'
updated: '2026-03-31'
version: 0.1.0
tags:
- meta-relativity
- adr
- space
---

# ADR-091: Meta-Relativity — Ambient Space & Frames

## Purpose
This ADR defines the ambient Hilbert space, lawful subspace, and frame structure for the Meta-Relativity (MR) framework. It provides a precise mathematical and engineering specification for all state, operator, and transformation logic in MR-compliant systems.

---

## 1. Ambient Hilbert Space
- **Definition:**
  - Let P be the set of primes and d ∈ ℕ.
  - The ambient Hilbert space is:
    $$ H := \ell^2(P) \otimes L^2(\mathbb{R}) \otimes \mathbb{C}^d $$
  - **Prime sector:** $\ell^2(P)$ encodes arithmetic structure.
  - **Time/frequency sector:** $L^2(\mathbb{R})$ encodes temporal and spectral information.
  - **Internal sector:** $\mathbb{C}^d$ encodes internal degrees of freedom (e.g., spin, symmetry).
- **Engineering Implication:**
  - All state vectors, operators, and transformations must be defined on this tensor product space.
  - Data structures must encode sector membership and support efficient tensor operations.

---

## 2. Lawful Subspace
- **Definition:**
  - The lawful subspace $H_{lawful} \subset H$ consists of vectors supported on the prime sector and fixed by the internal recursion operator $\Xi$.
  - Formally:
    $$ H_{lawful} := \{ \psi \in H : \psi_p \in \mathrm{Fix}(\Xi) \ \forall p \in P \} $$
  - The lawfulness projector is $P_{CSL} := (s\text{-}lim \sum \Pi_p) \wedge P_{Fix(\Xi)}$.
- **Engineering Implication:**
  - Initialization and runtime logic must restrict all evolution to $H_{lawful}$.
  - APIs must expose lawfulness checks and projectors.

---

## 3. Frames and Frame Transformations
- **Definition:**
  - A frame $F = (H, O, \rho)$ consists of:
    - $H$: the ambient Hilbert space
    - $O$: a set of operators acting on $H$
    - $\rho$: a representation mapping physical quantities to $O$
  - **Frame transformation:** A unitary $U: H \to H$ that preserves the prime sector, lawfulness constraints, and operator structure.
- **Engineering Implication:**
  - All APIs and data structures must track frame context.
  - Transformations must be implemented as unitary maps with explicit invariance checks.
  - Certification/test suites must verify invariance of key quantities (spectra, invariants) under lawful frame changes.

---

## 4. Implementation Guidelines
- All state and operator types must encode sector membership (prime, time, internal).
- Projectors and frame transformations must be implemented as explicit, testable objects.
- Lawfulness and frame invariance must be enforced at all API boundaries.

---

## 5. Traceability and Audit
- All MR artifacts must document their ambient space and frame context.
- Certification artifacts must reference this ADR and its version.
- All changes to space/frame definitions must trigger a new ADR revision and recertification.

---

## 6. References
- ADR-090-META-RELATIVITY-AXIOMS.md
- Meta-Relativity: Core Mathematical Theory
- Meta-Relativity Framework: Operational Manual
- Meta‑relativity (revised)_ Axioms, Operators, Invariants, And Certification.md

---

## Appendix: Example Code/Type Patterns

```python
# Example: State vector in ambient Hilbert space
import numpy as np

class MRState:
    def __init__(self, prime_vec, time_vec, internal_vec):
        self.prime_vec = prime_vec  # e.g., np.array, indices = primes
        self.time_vec = time_vec    # e.g., np.array, L2(R) discretization
        self.internal_vec = internal_vec  # e.g., np.array, shape (d,)

# Example: Lawfulness projector

def lawfulness_projector(state, Xi):
    # Project internal_vec onto Fix(Xi)
    eigvals, eigvecs = np.linalg.eigh(Xi)
    fixed_mask = np.isclose(eigvals, 1.0)
    fixed_subspace = eigvecs[:, fixed_mask]
    projected_internal = fixed_subspace @ (fixed_subspace.T @ state.internal_vec)
    return MRState(state.prime_vec, state.time_vec, projected_internal)
```

---

## Status
- Draft (2026-03-31): Initial engineering-grade specification of ambient space, lawful subspace, and frames for Meta-Relativity.
