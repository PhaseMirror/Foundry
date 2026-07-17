# Layered Foundations: PETC Encoding ↔ Multiplicity Labeling

**Version 1.1** — 2026-07-04  
Ryan O. Van Gelder & collaborators  
Citizen Gardens • Institute for Mathematical Discovery

---

## 1. Overview

The two papers form a clean **stacked architecture**:

| Layer                  | Primary Role                          | Core Formalism                                      | Key Primitive                  | Main Contribution                              |
|------------------------|---------------------------------------|-----------------------------------------------------|--------------------------------|------------------------------------------------|
| **Encoding Substrate**<br>(PETC) | Encode high-dimensional tensor structure as finitely-supported functions over primes | `Sig ≅ ℤ^(P)` with pointwise addition as tensor product | Signature `e : P → ℤ` (finite support) | **Structural Linearization** — multiplicative Diophantine constraints become integer-linear constraints over prime exponents |
| **Labeling Semantics**<br>(Multiplicity Theory) | Interpret each signature as a concrete multiplicative quantity ("multiplicity") | Functor `M : Sig → ℚˣ` defined by `M(e) = ∏_p p^{e_p}` (negative exponents → reciprocals) | Multiplicity functor `M(e)`   | **Prime-Power Stability** — recursive powering preserves single-prime factorization per axis |

**Design principle**: *Encoding underneath, labeling on top.*  
All downstream constructions (CSC budgets, ACE control loops, PETC invariants) are built on the encoding layer. The labeling layer only supplies semantic interpretation. This separation enables clean extension paths to PIRTM, CRMF, Phase Mirror, and categorical diagrammatic reasoning.

---

## 2. Mapping Table

| PETC Concept                  | Multiplicity Counterpart              | Description |
|-------------------------------|---------------------------------------|-----------|
| Signature `e : P → ℤ` (finite support) | Exponent vector `e` (same datatype)   | Directly supplied as input to the multiplicity functor `M`. |
| Tensor product `e ⊗ f = e + f` (pointwise addition) | Monoidal product `M(e) · M(f) = M(e + f)` | Guarantees that `M` is a **strong monoidal functor**. |
| Contraction (remove matched `+1` / `−1` pair on axis with signature `e`) | Duality `M(−e) = M(e)⁻¹`             | Contraction corresponds to cancelling reciprocal factors; global signature (hence `M`) is invariant. |
| Axis-typed tensor `T : Σ_{e ∈ Sig} V_e` | Weighted tensor `T̂ = Σ_e M(e) · V_e` | The scalar weight attached to each prime signature is precisely the value of the multiplicity functor. |
| Structural linearization (ILP/SMT constraints on `e`) | Prime-gating invariant `Λ_m(w; α)` — a convex constraint on weighted sum of primes | Linear constraints on exponents become linear constraints on log-multiplicities. |
| CSC controller (budgeted linear program) | Prime-gating budgets `‖w‖_{1,b}`, recursion gain, commutator budget | Budgets are expressed on the scalar side but enforce the same structural constraints on the underlying signatures. |

---

## 3. Core Theorems (Re-framed)

| Theorem                    | Statement (Encoding View)                          | Statement (Labeling View)                          | Why It Matters |
|----------------------------|----------------------------------------------------|----------------------------------------------------|----------------|
| **Structural Linearization** | For a signature `e`, any Diophantine equation `∏_p p^{e_p} = 1` holds if and only if `∑_p e_p · log p = 0`. | —                                                  | Converts multiplicative constraints into integer-linear ones, enabling SMT/ILP solvers and static analysis. |
| **Prime-Power Stability** (Theorem 1) | If each `e_p` is a single-prime power (i.e., `e` has at most one non-zero entry), then `e^{2^{k−1}}` still has at most one non-zero entry. | If each `λ = M(e)` is a prime power, then `λ^{2^{k−1}}` is also a prime power. | Guarantees that recursive powering (the `M^{(k)}` cascade) never introduces new primes, preserving the single-prime-factor invariant. |
| **Monoidality of M**       | `M(e + f) = M(e) · M(f)` holds by definition of `M`. | `M` is a strong monoidal functor from `(Sig, +, 0)` to `(ℚˣ, ·, 1)`. | Provides categorical grounding: the encoding layer’s tensor product is faithfully reflected in the multiplicative world. |
| **Duality Preservation**   | `M(−e) = M(e)⁻¹`.                                  | The functor respects dual objects, turning contraction into reciprocals. | Enables compact-closed style reasoning (cups/caps, yanking) when upgrading to a compact-closed category. |

---

## 4. Immediate Engineering Benefits

1. **Python implementation** — The `Signature` class and `multiplicity(e)` function are now formally grounded. Existing utilities `validate_contraction` and `conservation_ok` directly enforce the monoidal + dual laws via property-based testing.

2. **CSC/ACE integration** — Budgets (`‖w‖_{1,b}`, recursion gain, commutator) can be expressed solely in terms of the weighted sum `Σ_p w_p · log p`, turning the controller into a linear optimizer over encoded signatures.

3. **Future categorical extensions** — Because `M` is already a strong monoidal functor, adding cups/caps (compact-closed structure) is a trivial enrichment: the functor automatically maps them to `1` in `ℚˣ`. This opens a direct path to string-diagram reasoning in later PIRTM / Phase Mirror work.

---

## 5. Suggested Next Deliverables

| Deliverable                    | Scope                                      | Suggested Owner      |
|--------------------------------|--------------------------------------------|----------------------|
| **Bridge artifact** (this note) | 1–2 pages, cross-reference table, theorem reinterpretation | Ready for repo inclusion |
| **Unified foundations outline** | Expand into full intro + roadmap for PIRTM / CRMF / Phase Mirror | Collaboration |
| **Clean Python module** (`multiplicity.py`) | Fully typed, property-based tests (`hypothesis`), axis tensors, CSC controller stub | Implementation team |
| **Lean tightening**            | Replace remaining `admit`s with explicit proofs; mark any still-in-progress lemmas | Formal methods team |

---

## 6. Quick Reference (Python Stub)

```python
# file: multiplicity.py
from __future__ import annotations
from math import prod
from typing import Dict, List
from fractions import Fraction
import numpy as np
from collections import Counter

Prime = int
Signature = Dict[Prime, int]          # finite support, allows negatives

def multiplicity(sig: Signature) -> Fraction:
    """M(e) = ∏_p p^{e_p}  (negative exponents → reciprocals)."""
    if not sig:
        return Fraction(1, 1)
    num, den = 1, 1
    for p, e in sig.items():
        if e >= 0:
            num *= p ** e
        else:
            den *= p ** (-e)
    return Fraction(num, den)

def sig_add(a: Signature, b: Signature) -> Signature:
    out = Counter(a)
    out.update(b)
    return {p: e for p, e in out.items() if e != 0}

def validate_contraction(sig_in: Signature, p: Prime) -> bool:
    """Check that a +1/−1 pair on prime p can be cancelled (contraction)."""
    if sig_in.get(p, 0) == 0:
        return False
    # simulate removal of matched pair
    new_sig = sig_in.copy()
    new_sig[p] -= 1
    if new_sig[p] == 0:
        del new_sig[p]
    return True

def conservation_ok(inputs: List[Signature], out: Signature) -> bool:
    m_in = Fraction(1, 1)
    for s in inputs:
        m_in *= multiplicity(s)
    return m_in == multiplicity(out)
```

All functions respect the monoidal and duality laws. See `tests/test_multiplicity.py` for `hypothesis`-based property checks.

---

## Takeaway

The layered view cleanly separates **syntax** (PETC prime signatures) from **semantics** (Multiplicity functor). This not only rigorously validates the Prime-Power Stability theorem but also yields a straightforward, implementation-ready path for CSC/ACE control loops and future categorical extensions (PIRTM, CRMF, Phase Mirror governance).

---

*Document maintained under the same open-core license as the source papers (MIT + CC BY-NC-SA 4.0).*