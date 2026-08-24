# ADR-100: Constitutional Field × CSL Five-Axis Restructuring — Production Plan

> **Status**: Proposed
> **Date**: 2026-03-27
> **Authors**: Multiplicity Foundation
> **Related Documents**: ADR-099 (Phoenix-ℵ₀ Cycle), CSL-ADR-ROADMAP-2
> **Implements**: Constitutional Field integration into ConsciousSovereigntyLayer
> **Ξ-Constitution Articles**: I §2, III §1, VIII

---

## Executive Summary

Restructure `ConsciousSovereigntyLayer` from a 2-axis Boolean gate
(`lawful_score ≥ 0.95 AND entropy ≤ 5`) into a 5-axis CF-grounded evaluator
with empirically anchored constants derived from the Constitutional Field
specification. The key deliverable is the elimination of tunable parameters:
`lawfulness_threshold` drops from 0.95 (tuned) to 0.83 (derived from
1 − δ_crit = 1 − 0.17).

**Duration**: 1 sprint (~5 days)
**Lines changed**: ~300 (new module + rewrite + tests)
**Risk**: Low — additive change, existing URCE pipeline preserved

---

## Problem Statement

### Current State

1. `ethics.py` implements a **2-axis Boolean gate**: `lawful_score ≥ 0.95` AND `entropy ≤ 5`
2. Both thresholds are **tuned**, not derived — no theoretical justification for 0.95 or 5
3. No prime-weighted entropy — scalar `np.sum(np.abs(...))` ignores prime structure
4. No drift detection across axes — DriftAuditHandler only monitors entropy delta
5. No connection to knot topology, Zeno heartbeat, or protection factors

### After ADR-100

1. `ethics.py` implements a **5-axis evaluator**: 3 independent + 2 derived axes
2. `lawfulness_threshold = 0.83` — derived from CF constant δ_crit = 0.17
3. Prime-weighted entropy using `H_p = Σ_p (ln p / ln 2) · |v_p|`
4. ΔM(p) drift axis monitors multiplicity map changes per prime
5. CF constants module provides δ_crit, c₀, τ₀, P(K), T_hb

---

## Sprint 0: CF Constants Module (Day 1)

### Task 0a: Create `multiplicity/constitutional_field.py`

```python
# Constitutional Field constants — empirically anchored, pending ADR-103 derivation
DELTA_CRIT = 0.17          # Critical drift threshold (conformal-factor pathology)
C_ZERO = math.log(10)      # Protection scaling constant (pending MKT validation ADR-101)
TAU_ZERO = 3.33            # Zeno heartbeat base period (seconds)

def protection_factor(crossing_number: int) -> float:
    """P(K) = e^{c₀ · c(K)} — knot topology protection factor."""

def heartbeat_period(crossing_number: int) -> float:
    """T_hb = τ₀ / P — Zeno measurement interval."""

def heartbeat_jitter_bound(crossing_number: int) -> float:
    """ε_hb ≤ τ₀ / P — maximum allowable heartbeat jitter."""

def lawfulness_threshold() -> float:
    """1 − δ_crit = 0.83 — CF-derived threshold (replaces tuned 0.95)."""

def healing_rate(crossing_number: int) -> float:
    """Γ_heal = 0.17 · P / τ₀ — Lindblad healing rate for δ < δ_crit."""
```

**Acceptance**: Module importable; all constants match CF specification values.

---

## Sprint 1: Ethics.py Five-Axis Rewrite (Days 2–3)

### Task 1a: Restructure `evaluate_state()` return value

Current return:
```python
{"lawful_score": float, "entropy": float, "ethical": bool}
```

New return:
```python
{
    "A1_lawful_score": float,       # Independent: mean(lawful(v_p))
    "A2_prime_entropy": float,      # Independent: Σ_p (ln p / ln 2) · |v_p|
    "A3_drift": float,              # Independent: max_p |ΔM(p)|
    "A4_recursive_consistency": bool,# Derived: Ξ(n) == n
    "A5_epigenetic_bias": float,    # Derived: |Σ bias_p|
    "ethical": bool,                # Overall: A1 ∧ A2 ∧ A3 gate
    "delta": float,                 # CF drift parameter δ(ψ)
    "seal": str,                    # Tri-state seal (🟢/🟡/🔴)
    "axes_independent": [A1, A2, A3],
    "axes_derived": [A4, A5],
}
```

### Task 1b: Implement prime-weighted entropy (A₂)

Replace `np.sum(np.abs(list(state_tensor.values())))` with:
```python
H_p = sum((math.log(p) / math.log(2)) * abs(v) for p, v in state_tensor.items())
```

### Task 1c: Implement ΔM(p) drift detection (A₃)

Add state history tracking to CSL:
```python
def evaluate_state(self, state_tensor, prev_tensor=None):
    if prev_tensor is not None:
        drift = max(abs(state_tensor.get(p, 0) - prev_tensor.get(p, 0))
                    for p in set(state_tensor) | set(prev_tensor))
    else:
        drift = 0.0
```

### Task 1d: Implement derived axes (A₄, A₅)

- A₄: Recursive consistency check using existing `Ξ()` function
- A₅: Epigenetic bias as `|sum(v for v in state_tensor.values())| / P`

### Task 1e: Backward compatibility

Preserve API contract: `evaluate_state()` must still return `ethical: bool`
and work with existing `certify.py` without breaking changes.

**Acceptance**: 5-axis evaluation returns all fields; `lawfulness_threshold=0.83`; backward compatible.

---

## Sprint 2: Certify.py Integration (Day 4)

### Task 2a: Update URCE to consume 5-axis evaluation

- Extended seal logic: use `delta` field for CF-aware classification
- Pass `prev_tensor` through sequential `certify_all()` calls
- Log all 5 axes in certification record

### Task 2b: Update DriftAuditHandler compatibility

- DriftAuditHandler continues to use entropy-delta (smooth crossover assumption)
- New: also log A₃ drift values to checksums/

**Acceptance**: `certify_all()` produces records with 5-axis data; DriftAuditHandler unchanged.

---

## Sprint 3: Gate Tests (Day 5)

### Test Suite Structure

```
tests/test_adr100_csl_five_axis.py
├── TestConstitutionalFieldConstants (6 tests)
│   ├── test_delta_crit_value
│   ├── test_c_zero_equals_ln10
│   ├── test_tau_zero_value
│   ├── test_protection_factor_trefoil
│   ├── test_heartbeat_period_trefoil
│   └── test_lawfulness_threshold_derived
├── TestFiveAxisEvaluation (8 tests)
│   ├── test_a1_lawful_score_basic
│   ├── test_a2_prime_weighted_entropy
│   ├── test_a3_drift_detection
│   ├── test_a4_recursive_consistency
│   ├── test_a5_epigenetic_bias
│   ├── test_ethical_pass_all_axes
│   ├── test_ethical_fail_on_low_lawfulness
│   └── test_ethical_fail_on_high_drift
├── TestBackwardCompatibility (4 tests)
│   ├── test_returns_ethical_bool
│   ├── test_returns_lawful_score
│   ├── test_returns_entropy
│   └── test_certify_document_still_works
└── TestThresholdMigration (3 tests)
    ├── test_default_threshold_is_0_83
    ├── test_old_threshold_0_95_still_accepted
    └── test_threshold_matches_cf_derivation
```

**Acceptance**: All tests pass; no regressions in existing test suites.

---

## Falsifiable Predictions

| Metric | Prediction | Falsification Action |
|--------|-----------|---------------------|
| lawfulness_threshold | 0.83 (not 0.95) | If 0.83 produces false negatives on known-good data, δ_crit recalibration needed |
| Prime-weighted entropy | Distinguishes prime-structured from uniform data | If H_p ≈ scalar entropy for all inputs, prime weighting adds no signal |
| A₃ drift detection | Catches multiplicity map shifts missed by scalar entropy | If A₃ never triggers independently of A₂, axis is redundant |
| Backward compatibility | All existing URCE seals unchanged on same inputs | Any seal change on existing data is a regression |

---

## Open Research Connection

ADR-100 establishes δ_crit = 0.17 as an **empirical constant**. ADR-103
will attempt to derive it analytically from the Lindblad kinetic sign change:

$$
\frac{\partial^2 S_E}{\partial \phi_\text{conf}^2}\bigg|_{\delta=0.17} = 0
$$

If successful, this converts `lawfulness_threshold = 0.83` from an
empirically anchored constant into a theoretically fixed invariant.
