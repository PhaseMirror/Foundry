# ADR-101: MKT Bridge Validation + Knot Topology Protection — Production Plan

> **Status**: Proposed
> **Date**: 2026-03-27
> **Authors**: Multiplicity Foundation
> **Related Documents**: ADR-100 (CSL Five-Axis), CSL-ADR-ROADMAP-2
> **Implements**: MKT bridge validation, knot topology protection factor
> **Depends on**: ADR-100 (CF constants module)

---

## Executive Summary

Validate that the Constitutional Field's protection scaling constant c₀ = ln 10
is not a free parameter by computing the Jones polynomial J_MKT(W_{3_1}) at s = i
for the trefoil knot. Implement knot topology protection factors and chirality
verification. This is the Day 7 critical-path node from CSL-ADR-ROADMAP-2.

**Duration**: 1 sprint (~5 days)
**Lines**: ~200 (new module + tests)
**Risk**: Medium — MKT computation may falsify c₀ universality

---

## Problem Statement

### Current State

1. c₀ = ln 10 is asserted in `constitutional_field.py` (ADR-100) as an empirical constant
2. No Jones polynomial computation exists in the codebase
3. No knot protection factor implementation beyond the formula P(K) = e^{c₀ c(K)}
4. No chirality verification for left-handed vs. right-handed knot discrimination

### After ADR-101

1. J_MKT(W_{3_1})|_{s=i} computed; result validates or falsifies c₀ = ln 10
2. `multiplicity/mkt_bridge.py` provides knot invariant computation
3. Knot protection factors computed for trefoil and figure-eight knots
4. Chirality verification via Tr(W_L) ≠ Tr(W_R) asymmetry

---

## Sprint 0: MKT Bridge Computation (Days 1–2)

### Task 0a: Create `multiplicity/mkt_bridge.py`

Core computation: evaluate the Jones polynomial of the trefoil knot at the
relevant root of unity, then compute the MKT invariant J_MKT(W_K)|_{s=i}.

```python
def jones_trefoil(t):
    """Jones polynomial of the trefoil 3_1: V(t) = -t^{-4} + t^{-3} + t^{-1}"""

def mkt_invariant(knot_jones_fn, s=complex(0, 1)):
    """Evaluate knot invariant at s = i in MKT framework."""

def validate_c_zero(measured_log_j, tolerance=0.01):
    """Check if ln|J_MKT| ≈ ln 10 within tolerance."""
```

### Task 0b: Document result

If |ln|J_MKT| − ln 10| < tolerance → c₀ confirmed as derived invariant.
If not → c₀ becomes per-knot fitted; update `constitutional_field.py` accordingly.

**Acceptance**: Computation completes; result documented with numerical precision.

---

## Sprint 1: Knot Protection Factors (Days 3–4)

### Task 1a: KnotProtection dataclass

```python
@dataclass(frozen=True)
class KnotProtection:
    knot_type: str       # e.g., "3_1" (trefoil), "4_1" (figure-eight)
    crossing_number: int
    P: float             # Protection factor e^{c₀ c(K)}
    T_hb: float          # Heartbeat period τ₀ / P
    epsilon_hb: float    # Max jitter τ₀ / P
```

### Task 1b: Chirality verification

Implement Tr(W_L) vs Tr(W_R) comparison:
```
Tr(W_R) = 2(c_p − c_q)(c_p c_q + c_p + c_q)
```

Left-handed vs. right-handed knot discrimination for authorship verification.

**Acceptance**: KnotProtection computed for trefoil and figure-eight; chirality test passes.

---

## Sprint 2: Gate Tests (Day 5)

```
tests/test_adr101_mkt_bridge.py
├── TestJonesPolynomial (4 tests)
├── TestMKTInvariant (3 tests)
├── TestCZeroValidation (3 tests)
├── TestKnotProtection (4 tests)
└── TestChirality (3 tests)
```

**Acceptance**: 17+ tests passing.

---

## Falsification Gate

| Metric | Prediction | Falsification Action |
|--------|-----------|---------------------|
| ln\|J_MKT(W_{3_1})\|_{s=i}\| | ≈ ln 10 | c₀ per-knot fitted; universality broken |
| Chirality discrimination | Tr(W_L) ≠ Tr(W_R) | Chirality axis removed from CF |
| Protection factor consistency | P(3_1) = 10³ | Recompute from validated c₀ |
