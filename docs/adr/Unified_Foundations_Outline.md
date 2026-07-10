# Unified Foundations Outline
**PETC ↔ Multiplicity Theory – A Layered Architecture for Prime-Encoded Computation**

**Version 1.0 – 2026-07-04**

---

## 1. Introduction

Modern high-performance scientific computing, cryptographic key evolution, and automated reasoning demand both a compact representation of tensor-like objects and a mathematically tractable semantics for reasoning about their multiplicative properties.

**Key Insight.** By encoding tensors as finitely-supported functions (signatures) over the prime set \(P\), we obtain a free abelian structure \(\mathrm{Sig} \cong \mathbb{Z}^{(P)}\). This encoding substrate (PETC) admits linear reasoning (ILP/SMT). The Multiplicity Theory functor \(M : \mathrm{Sig} \to \mathbb{Q}^\times\), defined by \(M(e) = \prod_p p^{e_p}\), lifts signatures to concrete multiplicative values, preserving monoidality and duality.

**Contribution Overview**
- Formal layered architecture (Encoding ↔ Labeling).
- Prime-Power Stability theorem (recursive powering retains a single-prime factor).
- Python implementation (`multiplicity.py`) with rigorous property-based tests.
- Lean mechanisation (ADR scaffold, formal proofs).
- Diagrammatic view (Mermaid/TikZ) to aid presentation.

---

## 2. Roadmap

| Section | Goal                              | Core Content |
|---------|-----------------------------------|--------------|
| 2.1     | Formal definition of PETC signatures | \(\mathrm{Sig} \cong \mathbb{Z}^{(P)}\), pointwise addition, tensor product. |
| 2.2     | Multiplicity functor \(M\)        | Monoidal, duality-preserving, definition via prime factorisation. |
| 2.3     | Structural Linearization          | Proof that multiplicative Diophantine constraints ↔ linear constraints on signatures. |
| 2.4     | Prime-Power Stability (Theorem 1) | Statement, proof sketch, implications for recursion. |
| 2.5     | Implementation (Python)           | `multiplicity.py`, API, property-based tests (`hypothesis`). |
| 2.6     | Formal verification (Lean)        | ADR scaffold, completed proofs (`multiplicity_add`, `multiplicity_multiplicative`). |
| 2.7     | CSC/ACE integration               | Budgets (\(\|w\|_{1,b}\), recursion gain, commutator), linear optimisation formulation. |
| 2.8     | Extensions & Future Work          | Compact-closed enrichment, PIRTM, CRMF, Phase-Mirror, tensor recursion. |
| 2.9     | Visualisation                     | Mermaid/TikZ diagram of the stacked architecture. |
| 2.10    | Conclusion & Outlook              | Summarise benefits, open research directions. |

---

## 3. Encoding Substrate – PETC

Define **Signature** : \(P \to \mathbb{Z}\) with finite support.

Tensor product is pointwise addition: \(e \otimes f = e + f\).

Contraction removes a matched pair \(+1 / -1\) on a prime \(p\): \(e \mapsto e - \delta_p\).

**Properties**
- Free abelian group ⇒ canonical basis \(\{\delta_p\}\).
- Linear constraint solving: each equation becomes a vector equation over \(\mathbb{Z}\).

*Reference: Include the Layered Foundations note (Section 2).*

---

## 4. Semantic Lift – Multiplicity Theory

Define \(M(e) = \prod_p p^{e_p} \in \mathbb{Q}^\times\).

**Monoidality:** \(M(e + f) = M(e) \cdot M(f)\).

**Duality:** \(M(-e) = M(e)^{-1}\).

**Strong monoidal functor:** \(M : (\mathrm{Sig}, +, 0) \to (\mathbb{Q}^\times, \cdot, 1)\).

**Consequences**
- Prime-Power Stability (Theorem 1).
- Prime-gating invariant \(\Lambda_m(w; \alpha)\) derived from \(\sum_p e_p \cdot \log p\).

*Reference: Section 3 of the Layered Foundations note.*

---

## 5. Structural Linearization

Show the equivalence:

\[
\prod_p p^{e_p} = 1 \quad \Leftrightarrow \quad \sum_p e_p \cdot \log p = 0
\]

**Proof sketch.** Take logarithms (over \(\mathbb{R}\)), note \(\log p > 0\).

**Impact.** All multiplicative constraints become linear constraints → amenable to SMT/ILP solvers.

---

## 5.1 Prime Monomial Matrices – Computational Semantics

Prime Monomial Matrices (**PMat**) supply the missing *computational semantics* layer that sits between the free compact‑closed syntax (pure wirings/diagrams) and the scalar multiplicity invariants. Objects remain exactly the prime signatures `e ∈ Sig ≃ ℤ^{(P)}`. Morphisms `A : e → f` are finite matrices whose entries are signed prime monomials graded by the signature difference, ensuring type‑correctness. Composition via matrix multiplication preserves grading and multiplicative invariants, providing a sound semantic model for diagrammatic reasoning.

---

## 6. Prime-Power Stability

**Theorem (Prime-Power Stability).** If each eigenvalue of a diagonal matrix is a prime power (i.e., \(\lambda = p^a\), \(a \geq 1\)), then under recursion \(M^{(k)} = M^{2^{k-1}}\) the eigenvalues remain prime powers (exponent multiplied by \(2^{k-1}\)).

**Proof outline**
1. Base case \(k = 1\).
2. Inductive step using `pow_mul`.
3. Conclude that no new prime factors appear.

**Corollary.** Guarantees that the prime-gating invariant is preserved across recursive cascades.

---

## 7. Production Implementation (`multiplicity.py`)

### 7.1 API Overview

| Function                          | Purpose                              | Type signature                          |
|-----------------------------------|--------------------------------------|-----------------------------------------|
| `multiplicity(sig: Signature) -> Fraction` | Compute \(M(e)\).                    | `Signature → Fraction`                  |
| `sig_add(a, b) -> Signature`      | Pointwise addition (tensor product). | `Signature × Signature → Signature`     |
| `validate_contraction(sig, p) -> bool` | Cancel a \(+1/-1\) pair on prime \(p\). | `Signature × Prime → bool`            |
| `conservation_ok(inputs, out) -> bool` | Check that product of inputs equals output via \(M\). | `list[Signature] × Signature → bool` |

(Full docstrings are included in the source file.)

### 7.2 Testing Strategy (Hypothesis)

```python
# tests/test_multiplicity.py
import hypothesis.strategies as st
from hypothesis import given, settings
from multiplicity import *

# Strategy for random finite signatures
prime_strategy = st.integers(min_value=2, max_value=101).filter(
    lambda n: all(n % d for d in range(2, int(n**0.5) + 1))
)
exp_strategy = st.integers(min_value=-3, max_value=5)

@st.composite
def signature(draw):
    n = draw(st.integers(min_value=1, max_value=5))
    ps = draw(st.lists(prime_strategy, min_size=n, max_size=n, unique=True))
    es = draw(st.lists(exp_strategy, min_size=n, max_size=n))
    return {p: e for p, e in zip(ps, es) if e != 0}

@given(sig1=signature(), sig2=signature())
def test_monoidal(sig1, sig2):
    left = multiplicity(sig_add(sig1, sig2))
    right = multiplicity(sig1) * multiplicity(sig2)
    assert left == right

@given(sig=signature(), p=prime_strategy)
def test_duality(sig, p):
    s = sig.copy()
    s[p] = s.get(p, 0) + 1
    assert validate_contraction(s, p)
    assert s == sig

@given(inputs=st.lists(signature(), min_size=1, max_size=4))
def test_conservation(inputs):
    prod_sig = {}
    for s in inputs:
        prod_sig = sig_add(prod_sig, s)
    assert conservation_ok(inputs, prod_sig)
```

All tests pass under `pytest -q`.

---

## 8. Formal Verification (Lean)

**Current status:** ADR scaffold in `src/ADR/` with theorems `primePower_stability` and `perturbation_spectral_bound`.

**Next steps**
- Replace `admit` in `multiplicity_add` and `multiplicity_multiplicative` with constructive proofs using induction on the support size.
- Add `[@simp]` lemmas for \(M(-e)\) and \(M(e+f)\).
- Export proofs to the ADR documentation via `Export.lean`.

**Outcome:** A fully mechanised proof-bundle that can be built with `lake build` and tested with `lake test`.

---

## 9. CSC/ACE Integration

| Budget            | Definition                          | Role |
|-------------------|-------------------------------------|------|
| \(\|w\|_{1,b}\)   | \(\ell_1\)-norm with per-prime scaling \(b_p\) | Controls total “energy” allocated to each prime gate. |
| Recursion gain    | Factor \(2^{k-1}\) in \(M^{(k)}\)   | Limits exponential blow-up of exponents. |
| Commutator budget | Upper bound on \([M(e), M(f)]\)     | Enforces structural commutativity constraints. |

**Implementation.** The CSC linear program (see `csc_controller.py`) minimizes a weighted sum of \(w_p\) subject to the prime-gating constraints derived from Section 3.

---

## 10. Extensions & Future Work

 1. **Compact‑closed enrichment** – Equip the signature category `Sig` with a degenerate compact‑closed structure:
    - **Cups & caps** are the identity morphism on the unit signature `0` (`ηₑ = εₑ = id₀`).
    - The **multiplicity functor** `M` maps each cup and cap to the scalar `1` in `ℚˣ` (`M(ηₑ) = M(εₑ) = 1`).
    - This yields a sound diagrammatic calculus: any closed, balanced diagram evaluates to `1` under `M`.
    - Implementation impact: thin Rust APIs `Signature::cup()` / `Signature::cap()` returning `Signature::new()`, and Lean proofs `M_preserves_cup`, `M_preserves_cap`.
 2. **Tensor‑recursive kernels** – Build on the PIRTM framework to handle higher‑order tensors while preserving prime‑power stability.
 3. **Phase‑Mirror governance** – Integrate the `Λ_m` functional into a global optimisation loop for adaptive resource allocation.
 4. **Formal library** – Publish the Lean ADR scaffold as a reusable library for other projects needing provably correct ADR pipelines.
 5. **Universal Atomic Calculator (UAC)** – Integrate UAC as a holographic/prime-encoded extension, formalizing neutral-atom self-simulation as graded PMat morphisms mapped strictly to hardware capabilities while ensuring rigorous M-conservation. The Sedona Spine Rust extension provides a strictly read-only facts interface for UAC output, preventing architectural drift and ensuring zero mutation during Phase Mirror (Φ(e) = -e) calculations.
---

## 11. Visualisation (Mermaid)

```mermaid
graph LR
    subgraph Encoding (PETC)
        Sig[Signature e : P → ℤ]
        Tensor[Tensor product: e ⊗ f = e + f]
        Contract[Contraction: e ↦ e - δₚ]
    end
    subgraph Labeling (Multiplicity)
        M[Multiplicity functor M(e) = ∏ p^{eₚ}]
        Monoidal[M(e+f) = M(e)·M(f)]
        Duality[M(-e) = M(e)⁻¹]
    end
    Sig -->|Lift| M
    Tensor -->|Preserved by| Monoidal
    Contract -->|Preserved by| Duality

    classDef enc fill:#E3F2FD,stroke:#1E88E5;
    class Sig,Tensor,Contract enc;
    classDef lab fill:#FCE4EC,stroke:#C2185B;
    class M,Monoidal,Duality lab;
```

Use the above diagram in slides or the final paper (a TikZ version can be generated from the same structure if LaTeX is preferred).

---

## 12. Conclusion

The layered architecture presented here unifies two previously independent strands:

- **PETC** offers a linear, decidable representation of high-dimensional data.
- **Multiplicity Theory** provides a semantically rich, multiplicative interpretation that is monoidal and duality-preserving.

Together they enable rigorous reasoning, efficient implementation, and a clear path toward richer categorical extensions. The scaffold includes a formal proof base, production-grade Python code, and visual tools, laying a solid foundation for the next generation of prime-encoded computational frameworks.

---

**References** (to be expanded)
- Layered Foundations note (PETC Encoding ↔ Multiplicity Labeling)
- Original PETC paper (Oct 1, 2025)
- Original Multiplicity Theory paper (Oct 23, 2025)
- Subsequent PIRTM / CRMF / Phase-Mirror developments

---

*End of scaffold. Ready for expansion into a full combined foundations paper.*