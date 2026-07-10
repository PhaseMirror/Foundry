# PIRTM Tensor-Recursive Kernels
## Prime-Indexed Recursive Tensor Mathematics – Formal Investigation

**Version 1.0 – 2026-07-05**  
**Status:** Exploratory ADR – definitions, theorems, and integration path proposed.

---

## 1. Motivation and Positioning

PIRTM (Prime-Indexed Recursive Tensor Mathematics) is the layer that adds **controlled recursion** to the prime-encoded tensor framework.

Previous layers provide:
- **PETC**: Syntax of signatures + multiplicity functor (conservation).
- **Prime Monomial Matrices (PMat)**: Computational content with graded monomials.
- **Compact-closed enrichment**: Diagrammatic language with cups, caps, yanking.

**PIRTM** introduces recursion *inside* this typed setting so that:
- Recursive tensor operators (kernels) can be defined whose structure is indexed or controlled by primes.
- Every recursive unfolding preserves the global prime signature (hence the value of \(M\)).
- Stability and certification (via CSC/ACE) extend to the recursive case.
- Duality (Phase Mirror) and resonance (CRMF) can act on recursive structures.

This completes the path from static signatures → matrices → diagrams → recursive constructions.

---

## 2. Core Definition: PIRTM Tensor-Recursive Kernel

**Definition 2.1 (PIRTM Kernel).**  
A **PIRTM tensor-recursive kernel** of type \(e \to f\) (where \(e, f \in \mathbf{Sig}\)) is a (possibly infinite) family of prime-monomial matrices

\[
K = \{ K_n : e_n \to f_n \}_{n \in \mathbb{N}}
\]

together with a **prime-indexed recursion rule** that generates the next stage from the previous, such that:

1. The signatures evolve by prime-multiplication: there exists a prime \(p_n\) (or finite set of primes) and exponent vector \(v_n\) with
   \[
   e_{n+1} = e_n + p_n^{v_n} \cdot \delta \quad \text{or a similar prime-gated update},
   \]
   ensuring the net change in every prime coordinate remains consistent with a valid morphism in PMat.

2. Each \(K_n\) is a well-typed prime-monomial matrix (grading condition of PMat satisfied).

3. The recursion is **prime-gated**: the choice of which prime controls the recursion step, the branching factor, or the depth is itself drawn from the prime factorization of a governing integer or from the current signature.

4. The entire family is **conservation-preserving**: for every finite unfolding, the global signature of the composite is independent of the number of recursion steps (i.e., \(M\) of the net signature is invariant).

The **kernel** is the rule that, given the current signature and a prime index, produces the next monomial matrix and the updated signature.

This is the direct generalization of ordinary tensor kernels to the recursive, prime-controlled setting.

---

## 3. Prime-Indexing Mechanisms (Proposed)

Several natural ways to index the recursion by primes:

| Mechanism                  | Description                                                                 | Signature Effect                          | Example Use Case                     |
|----------------------------|-----------------------------------------------------------------------------|-------------------------------------------|--------------------------------------|
| **Prime-step recursion**   | At step \(n\), multiply one coordinate by the \(n\)-th prime                | Adds \(v \cdot \log p_n\) to one axis     | Depth-controlled tensor networks     |
| **Prime-branching**        | Recursion tree branches according to the prime factors of a parameter       | Parallel copies whose signatures sum      | Prime-factorized feature expansion   |
| **Prime-gated contraction**| Contraction order or which axes to contract is chosen by prime index        | Preserves net signature (cancellation)    | Certified recursive contraction plans|
| **Prime-power exponentiation** | Each recursive application raises a block to a prime power             | Exponent vector scaled by \(p^k\)         | Prime-Power Stability extension      |
| **Hybrid (Goldilocks style)** | Recursion depth and branching jointly controlled by a prime tuple       | Balanced growth under \(\Lambda_m\) prior | Adaptive, stability-aware recursion  |

All of these are compatible with the grading condition of PMat and therefore inherit conservation under \(M\).

---

## 4. Key Theorems (Proposed)

**Theorem 4.1 (Recursive Prime-Power Stability).**  
If a PIRTM kernel is built from pure prime-power monomials and the recursion rule only multiplies existing exponents by primes (or adds prime-powered increments), then every finite unfolding remains a prime-power monomial matrix. Consequently, the numerical image under \(M\) is always a rational number whose prime factorization is completely determined by the net signature, independent of recursion depth.

**Theorem 4.2 (Conservation under Arbitrary Unfolding).**  
For any finite recursion depth \(N\), the composite morphism \(K_N \circ \cdots \circ K_1 : e_0 \to f_N\) satisfies
\[
M(f_N) = M(e_0) \cdot c
\]
where the scalar \(c \in \mathbb{Q}^\times\) depends only on the net signature change, not on \(N\) or the particular sequence of primes chosen (provided the recursion rule is signature-consistent).

**Theorem 4.3 (Compatibility with Compact-Closed Structure).**  
Cups, caps, and yanking extend to PIRTM kernels by applying them stage-wise. Because each stage preserves signatures, the diagrammatic equalities continue to hold after any number of recursive unfoldings.

These theorems ensure that ACE contraction planning and CSC spectral safety can be applied to recursive plans without losing certification.

---

## 5. Relation to Other Frameworks

- **CRMF (Resonance-Coupled Multiplicity Frameworks)**: Resonance terms can be realized as PIRTM kernels whose recursion couples different prime sectors (cross-terms between distinct primes). The prime-gating ensures resonance only occurs between compatible signatures.
- **Phase Mirror Governance**: Duality on a PIRTM kernel is negation of all exponents in every stage. The mirror operation commutes with recursion (because negation distributes over addition). Phase Mirror thus becomes a symmetry of the recursive structure.
- **ACE / CSC Controller**: The controller can now search over *recursive contraction plans*. Each candidate plan is a PIRTM kernel; the prime-gating invariant \(\Lambda_m\) and the spectral budgets become constraints on the allowed recursion rules. This yields stability-aware, recursively generated tensor networks.
- **PIRTM/MOC v5 integration** (from project history): The “Goldilocks kernel” mentioned in earlier work is likely a concrete instance of a hybrid prime-gated recursive kernel that balances growth (stress vs. capacity) while staying inside the viability kernel defined by \(\Lambda_m\).

---

## 6. Implementation Sketch (Python)

```python
from dataclasses import dataclass
from typing import Callable, List
from fractions import Fraction
from multiplicity import Signature, sig_add, multiplicity_Qx
from prime_monomial_matrices import PrimeMonomialMatrix   # from previous ADR

@dataclass
class PIRTMKernel:
    """A prime-indexed recursive tensor kernel."""
    initial_sig: Signature
    recursion_rule: Callable[[Signature, int], tuple[PrimeMonomialMatrix, Signature]]
    # recursion_rule(current_sig, prime_index) -> (next_matrix, next_sig)

    def unfold(self, primes: List[int]) -> List[PrimeMonomialMatrix]:
        """Unfold the kernel for a finite sequence of prime indices."""
        sig = self.initial_sig.copy()
        matrices = []
        for p in primes:
            K, sig = self.recursion_rule(sig, p)
            matrices.append(K)
        return matrices

    def net_signature(self, primes: List[int]) -> Signature:
        """Compute the net signature change after unfolding."""
        sig = self.initial_sig.copy()
        for p in primes:
            _, sig = self.recursion_rule(sig, p)
        return sig

    def conservation_ok(self, primes: List[int]) -> bool:
        """Check that M is preserved (up to the net change)."""
        # Implementation uses multiplicity_Qx on initial and final net sig
        ...
```

Hypothesis tests would generate random valid recursion rules (signature-consistent prime updates) and verify Theorems 4.1–4.3 on random finite unfoldings.

---

## 7. Lean Formalization Path

- Define `PIRTMKernel` as a structure containing an initial signature and a recursion function (dependent on the current signature and a prime).
- Prove `recursive_prime_power_stability` by induction on the length of the prime sequence.
- Prove that the functor `M` lifts to a functor from the category of PIRTM kernels to ordinary (possibly recursive) matrices over \(\mathbb{Q}\).
- Integrate with the existing `CompactClosedCategory` instance so that cups/caps on kernels are defined stage-wise.

---

## 8. Open Questions & Future Directions

1. **Full 2-categorical treatment**: Can PIRTM recursion be modeled cleanly as 2-cells in a 2-category whose 1-cells are PMat morphisms? This would give a native notion of “rewrite of recursive plans.”
2. **Infinite recursion & convergence**: Under what conditions does an infinite PIRTM unfolding converge in a suitable completion (e.g., formal power series over primes or p-adic tensors)?
3. **Learning / optimization of recursion rules**: Can the ACE controller not only choose contraction order but also *learn* good prime-gating recursion rules from data while preserving certification?
4. **Connection to existing code artifacts**: How do the “PIRTM/MOC v5”, “C-PIRTM”, and “Goldilocks kernel” implementations from the Intrinsica project map onto this formalization?
5. **Higher-order recursion**: PIRTM kernels that recurse on other PIRTM kernels (meta-recursion) while still preserving signatures.

---

## 9. Integration into the Layered Architecture

```
Free Compact-Closed Syntax (diagrams)
          │
          ▼
Prime Monomial Matrices (computational content)
          │
          ▼
PIRTM Tensor-Recursive Kernels   <── NEW LAYER
   (prime-indexed recursion + preservation)
          │
          ▼
ACE / CSC / Phase Mirror / CRMF
   (planning, stability, governance, resonance on recursive structures)
          │
          ▼
Numerical Semantics (M functor) + Certified Execution
```

This layer turns the static prime-encoded framework into a fully recursive, certifiably stable computational substrate — exactly what is needed for the next generation of Multiplicity Theory applications (recursive tensor networks, adaptive governance, prime-controlled consciousness interfaces, etc.).

---

**End of ADR**

*References to prior layers: Layered_Foundations.md, Prime_Monomial_Matrices.md, Free_CompactClosed_Category.md, Compact_Closed_Enrichment.md, Unified_Foundations_Outline.md*
