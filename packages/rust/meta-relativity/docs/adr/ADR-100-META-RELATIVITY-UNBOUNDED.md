---
slug: adr-100-meta-relativity-unbounded
status: draft
created: '2026-03-31'
updated: '2026-03-31'
version: 0.1.0
tags:
- meta-relativity
- adr
- unbounded
---

# ADR-100: Meta-Relativity — Unbounded Generators and Sectorial Extensions

## Purpose
This ADR specifies the extension of the Meta-Relativity (MR) framework to unbounded generators and sectorial/non-self-adjoint cases. It provides mathematical and engineering requirements for handling more general operator classes, broadening the applicability of MR to advanced physical and mathematical models.

---

## 1. Unbounded Generators via Form Methods
- **Definition:**
  - Allow $A_0$ to be an essentially self-adjoint unbounded diagonal (e.g., polynomial growth) on $\ell^2(P)$
  - $K$ is $A_0$-form-bounded with relative bound < 1
  - $C$ defined via real symbol $m(\omega)$ with suitable growth
  - $U := A_0 + K \otimes I \otimes I + I \otimes C \otimes I + I \otimes I \otimes \Xi$
- **Engineering Implication:**
  - Operator construction must support domain management, form sums, and self-adjointness checks
  - Certification/test suites must verify Kato–Rellich hypotheses and domain invariance

---

## 2. Sectorial and Non-Self-Adjoint Extensions
- **Definition:**
  - Allow $C$ to be a nonnegative multiplier $m(\omega) \geq 0$ with complex phase $|\arg m(\omega)| \leq \varphi < \pi/2$
  - $C$ is sectorial and generates a bounded analytic semigroup
  - If $A$ is self-adjoint (or $m$-accretive) and $\Xi$ is normal with $\Re \Xi \succeq 0$, then $A := -U$ is $m$-accretive (Lumer–Phillips)
- **Engineering Implication:**
  - Operator code must support sectorial calculus, analytic semigroups, and accretive generator checks
  - Certification/test suites must verify sectoriality, analyticity, and contractivity

---

## 3. Certification and Testing
- All unbounded and sectorial logic must be modular and testable
- Certification artifacts must document domain, form, and sectorial properties
- Test suites must simulate unbounded growth, sectorial perturbations, and analytic semigroup evolution

---

## 4. Traceability and Audit
- All MR artifacts using unbounded or sectorial extensions must reference this ADR
- Changes to unbounded/sectorial logic must trigger ADR revision and recertification

---

## 5. References
- ADR-090-META-RELATIVITY-AXIOMS.md
- ADR-091-META-RELATIVITY-SPACE.md
- ADR-092-META-RELATIVITY-OPERATORS.md
- ADR-093-META-RELATIVITY-INVARIANTS.md
- ADR-094-META-RELATIVITY-CERTIFICATION.md
- ADR-095-META-RELATIVITY-DISSIPATIVE-REGIMES.md
- ADR-096-META-RELATIVITY-SECURITY.md
- ADR-097-META-RELATIVITY-IMPLEMENTATION.md
- ADR-098-META-RELATIVITY-EXEMPLARS.md
- ADR-099-META-RELATIVITY-TESTING.md
- Meta-Relativity Framework: Operational Manual
- Meta‑relativity (revised)_ Axioms, Operators, Invariants, And Certification.md

---

## Appendix: Example Code/Type Patterns

```python
# Example: Check if operator is sectorial
import numpy as np

def is_sectorial(matrix, phi):
    eigs = np.linalg.eigvals(matrix)
    return np.all(np.abs(np.angle(eigs)) <= phi)

# Example: Kato–Rellich form-boundedness check

def is_form_bounded(K, A0, bound):
    # K, A0: matrices; bound: float < 1
    # This is a simplified proxy for demonstration
    return np.linalg.norm(K) < bound * np.linalg.norm(A0)
```

---

## Status
- Draft (2026-03-31): Initial engineering-grade specification of unbounded and sectorial extensions for Meta-Relativity.
