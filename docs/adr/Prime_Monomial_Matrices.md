# Prime Monomial Matrices
## Adding Computational Content to the Free Compact-Closed PETC Structure

**Version 1.0 – 2026-07-04**  
**Status:** Exploratory ADR – builds directly on `Free_CompactClosed_Category.md` and `Compact_Closed_Enrichment.md`

---

## 1. Motivation: From Wiring to Computation

The free compact-closed category on the set of primes \(P\) (i.e., our discrete category \(\mathbf{Sig}\)) gives us:

- Perfect structural invariants (prime signatures are preserved by all rewrites).
- A sound diagrammatic calculus (string diagrams with cups, caps, yanking).
- The multiplicity functor \(M : \mathbf{Sig} \to \mathbb{Q}^\times\) that sends every closed diagram to the scalar \(1\).

**Limitation**: Only identity morphisms exist. We cannot yet express *actual linear-algebraic operations* (non-trivial matrices, contractions with coefficients, learned operators, etc.).

**Goal of this note**: Define a category **PMat** of *Prime Monomial Matrices* whose:
- Objects are still prime signatures (same as PETC).
- Morphisms carry concrete computational content (matrices with monomial entries).
- All structural invariants (signature preservation, \(M\)-conservation) remain enforced by construction.
- The multiplicity functor \(M\) extends to a strong monoidal functor into a category of numerical matrices.

This supplies the missing “computational semantics” layer while keeping the free compact-closed syntax as the type system.

---

## 2. Definition of the Category PMat

### 2.1 Objects
Objects are exactly the prime signatures of PETC:
\[
\mathrm{Ob}(\mathbf{PMat}) = \mathbf{Sig} := \{ e : P \to \mathbb{Z} \mid \operatorname{supp}(e) \text{ finite} \}.
\]

### 2.2 Morphisms (Prime Monomial Matrices)

A morphism \(A : e \to f\) in \(\mathbf{PMat}\) consists of:

1. A choice of finite bases for the “domain” and “codomain” whose signatures aggregate to \(e\) and \(f\) respectively.
   - Domain basis: vectors \(v_1, \dots, v_m\) with individual signatures \(g_1, \dots, g_m\) such that \(\sum_i g_i = e\) (multiset sum).
   - Codomain basis: vectors \(w_1, \dots, w_n\) with signatures \(h_1, \dots, h_n\) such that \(\sum_j h_j = f\).

2. An \(m \times n\) matrix whose entry \(A_{ij}\) is a **signed prime monomial**
   \[
   A_{ij} = c_{ij} \cdot \prod_{p \in P} p^{k_{ij,p}}, \quad c_{ij} \in \{\pm 1\}, \quad k_{ij} \in \mathbb{Z}^{(P)} \text{ finite support},
   \]
   satisfying the **grading condition** (type correctness):
   \[
   k_{ij} = h_j - g_i \qquad \text{(componentwise in } \mathbb{Z}^P\text{)}.
   \]

In other words, every matrix entry that “connects” a basis vector of signature \(g_i\) to one of signature \(h_j\) must carry exactly the prime-mass difference \(h_j - g_i\) as its exponent vector.

**Special case – discrete / wiring morphisms**: When all \(|c_{ij}| = 0\) or \(1\) and the monomials are exactly the identity monomials (\(k_{ij} = 0\) when \(i\) connects to a matching dual pair), we recover the identity morphisms and the cups/caps of the free compact-closed category.

### 2.3 Composition
Matrix multiplication is defined in the usual way, but with monomial arithmetic:
- Product of two monomials is the monomial with summed exponents.
- The grading condition is preserved under multiplication because
  \[
  (h_j - g_i) + (h'_k - h_j) = h'_k - g_i.
  \]

### 2.4 Identities, Duals, Cups, Caps
- Identity on \(e\): diagonal matrix with entries \(1\) (valuation \(0 = g_i - g_i\)).
- Dual of \(e\) is \(-e\) (negation of all exponents).
- Cup \(\eta_e : I \to e^\vee \otimes e\) and cap \(\varepsilon_e : e \otimes e^\vee \to I\) are the obvious “pairing” matrices whose only non-zero entries are the identity monomials \(1\) on the matching prime pairs (valuation exactly cancels).

All compact-closed axioms (yanking, naturality of duality, etc.) hold by the same algebraic identities as in the discrete case; the extra monomial coefficients simply travel along the wires.

---

## 3. The Extended Multiplicity Functor \(M : \mathbf{PMat} \to \mathbf{Mat}_\mathbb{Q}\)

Define the functor on objects exactly as before:
\[
M(e) := \prod_p p^{e_p} \in \mathbb{Q}^\times.
\]

On a morphism \(A : e \to f\), \(M(A)\) is the numerical matrix obtained by replacing every monomial entry \(A_{ij}\) by the rational number
\[
M(A_{ij}) = c_{ij} \cdot M(h_j - g_i) = c_{ij} \cdot \frac{M(h_j)}{M(g_i)}.
\]

**Theorem (Functoriality & Preservation)**  
\(M\) is a strong symmetric monoidal functor that strictly preserves duals, cups, and caps. Consequently:

- Every well-typed prime-monomial matrix satisfies the global conservation law
  \[
  M(f) = M(e) \cdot \det(M(A)) \quad \text{(up to sign from the } c_{ij}\text{)}.
  \]
- Any string diagram built from cups, caps, contractions, and prime-monomial matrices evaluates under \(M\) to a scalar (or matrix) whose prime factorization is completely determined by the net signature of the diagram.

This is the precise categorical justification for “prime-mass conservation certificates” even when actual numerical linear algebra is performed.

---

## 4. Key Properties & Benefits

| Property                        | Discrete Case (Free CC)          | Prime Monomial Matrices (PMat)                  | Practical Payoff |
|--------------------------------|----------------------------------|--------------------------------------------------|------------------|
| Morphisms                      | Only identities                  | Arbitrary graded monomial matrices               | Real linear algebra |
| Conservation via \(M\)         | Trivial (always 1)               | Automatic for well-typed matrices                | Certified contractions |
| Diagrammatic calculus          | Pure wiring                      | Wiring + coefficients that travel correctly      | Visual certified algorithms |
| Spectral control (CSC/ACE)     | Not applicable                   | Eigenvalues of \(M(A)\) inherit prime-gating bounds | Stability-aware learning |
| Connection to PIRTM / CRMF     | Syntax only                      | Natural home for recursive tensor operators      | Executable multiplicity theory |
| Phase Mirror governance        | Negation of signatures           | Adjoint operation flips all exponents            | Duality as matrix adjoint |

**Prime-Power Stability** lifts immediately: if a matrix is built from prime-power monomials (single prime per entry), recursive powering or iteration never introduces new prime factors in the valuations.

---

## 5. Concrete Examples

### 5.1 Simple “Prime Shift” Operator
Object \(e = \delta_2\) (one copy of prime 2).  
Object \(f = \delta_3\) (one copy of prime 3).  
A morphism \(A : e \to f\) can be the \(1 \times 1\) matrix whose single entry is the monomial \( \frac{3}{2} = 3^1 \cdot 2^{-1} \), which has valuation exactly \( \delta_3 - \delta_2 \).  
Applying \(M\) yields the numerical map multiplication by \( \frac{3}{2} \).

### 5.2 Certified Contraction (Matrix Multiplication)
Two matrices \(A : e \to g\) and \(B : g \to f\) whose shared middle signature \(g\) cancels under contraction. The composite monomial matrix has entries whose valuations automatically satisfy the outer signatures \(e\) and \(f\). The numerical matrix \(M(A B) = M(A) M(B)\) (after appropriate scaling by the middle \(M(g)\)).

### 5.3 Phase-Mirror Dual
The dual morphism \(A^\vee : f^\vee \to e^\vee\) is obtained by transposing and replacing every monomial by its reciprocal (i.e., negate all exponents). This is exactly the categorical dual in the compact-closed structure and corresponds to the adjoint (with sign flip) in the numerical semantics.

---

## 6. Implementation Sketches

### Python (lightweight)
```python
from dataclasses import dataclass
from fractions import Fraction
from typing import Dict, List, Tuple
import numpy as np

Signature = Dict[int, int]          # prime -> exponent
Monomial = Tuple[int, Signature]    # (sign, exponents)

@dataclass
class PrimeMonomialMatrix:
    domain_sig: Signature
    codomain_sig: Signature
    # list of (i, j, sign, exponent_dict) for non-zero entries
    entries: List[Tuple[int, int, int, Signature]]

    def to_numerical(self) -> np.ndarray:
        # Convert each monomial to its M-value (Fraction)
        ...

    def compose(self, other: 'PrimeMonomialMatrix') -> 'PrimeMonomialMatrix':
        # Monomial matrix multiplication with automatic grading check
        ...
```

Property-based tests (Hypothesis) can generate random well-typed monomial matrices and verify that `conservation_ok` still holds after composition and contraction.

### Lean
Formalize matrices over the graded ring \(\mathbb{Z}[P^{\pm 1}]\) with grading by signatures. The grading condition becomes a type-class or dependent type that is checked at composition time. The functor \(M\) becomes a functor into matrices over \(\mathbb{Q}\).

---

## 7. Relation to the Layered Architecture

```
Free Compact-Closed Syntax  (diagrams / wirings)
          │
          ▼  (add coefficients + grading)
Prime Monomial Matrices     (computational content + linear algebra)
          │
          ▼  (apply M entrywise)
Numerical / Scalar Semantics (M : PMat → Mat_ℚ  or  ℚ^× for scalars)
          │
          ▼  (certificates)
ACE / CSC / Phase Mirror    (stability, governance, optimization)
```

This is the natural “encoding + computational lift” layer that sits between the pure free compact-closed syntax and the scalar multiplicity invariants.

It directly enables executable versions of PIRTM (recursive tensor operators become matrices in PMat), CRMF resonance terms, and Phase Mirror duality (adjoint with exponent negation).

---

## 8. Open Questions & Future Directions

1. ** richer coefficients**: Allow polynomial (not just monomial) entries while preserving total valuation per prime across each row/column.
2. **2-categorical enrichment**: Add 2-cells for rewrites / homotopies between monomial matrices. This gives a native home for “proofs of equivalence” of contraction plans.
3. **Quantum / probabilistic lift**: Replace \(\mathbb{Z}\) coefficients by complex amplitudes or density operators while keeping the prime grading. Possible bridge to quantum circuits with prime-encoded qubits.
4. **Efficient representation**: Sparse monomial matrices + fast factorization for large prime sets.
5. **Integration with existing codebases**: Extend the current `multiplicity.py` with a `PrimeMonomialMatrix` class and wire it into the ACE contraction planner.

---

## 9. Conclusion

Prime Monomial Matrices supply the missing computational semantics for the PETC / Multiplicity Theory stack. They turn the elegant but rigid free compact-closed wiring language into a full-fledged category of typed linear operators whose every operation is automatically certified by the multiplicity functor \(M\).

All downstream machinery (ACE contraction planning, CSC spectral safety, Phase Mirror governance, PIRTM recursion) can now operate on objects that carry both structural guarantees *and* concrete numerical content.

This layer completes the “encoding underneath, labeling + computation on top” principle and provides a clear, implementable path toward production-grade prime-encoded tensor calculus.

---

**References to related ADRs**
- `Free_CompactClosed_Category.md` – the discrete syntax layer
- `Compact_Closed_Enrichment.md` – why the discrete case is already compact-closed
- `Layered_Foundations.md` – overall stack picture
- `Unified_Foundations_Outline.md` – where this material slots into Section 10 (Extensions)

**Next deliverable suggestions**
- Production Python implementation of `PrimeMonomialMatrix` + Hypothesis tests
- Lean formalization of the graded matrix category
- Integration of PMat into the ACE controller prototype
- TikZ string-diagram examples showing monomial coefficients traveling along wires

---

*End of ADR note*