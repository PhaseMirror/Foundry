# ADR-102: Phase Transition Classification + Discontinuity Detection — Production Plan

> **Status**: Proposed
> **Date**: 2026-03-27
> **Authors**: Multiplicity Foundation
> **Related Documents**: ADR-100 (CSL Five-Axis), ADR-101 (MKT Bridge), CSL-ADR-ROADMAP-2
> **Implements**: Phase transition classification, Zeno heartbeat, RT thread assessment
> **Depends on**: ADR-100 (CF constants), ADR-101 (knot protection)

---

## Executive Summary

Determine whether the Constitutional Field's collapse boundary at δ = 0.17 is a
first-order geometric phase transition or a smooth crossover. This resolves
Tension 4 from CSL-ADR-ROADMAP-2 and has direct architectural consequences for
the DriftAuditHandler and tri-state seal model.

**Duration**: 1 sprint (~5 days)
**Lines**: ~250 (new modules + tests)
**Risk**: High — result determines whether 🟡 state is physically forbidden

---

## Problem Statement

### Current State

1. DriftAuditHandler uses linear |E(t) − E(t−1)| < ε_burn guard (assumes smooth crossover)
2. Tri-state seal (🟢/🟡/🔴) in certify.py assumes a gradient exists
3. No hysteresis measurement capability
4. No Zeno heartbeat enforcement
5. Watchdog.py is a Python FileSystemEventHandler (GIL-bound, best-effort)

### After ADR-102

1. Phase transition classified: first-order or smooth crossover
2. DriftAuditHandler upgraded if first-order (discontinuity detector)
3. Zeno heartbeat module with T_hb = τ₀ / P enforcement
4. RT thread feasibility documented for trefoil constraint (ε_hb ≤ 3.33 μs)

---

## Sprint 0: Hysteresis Measurement (Days 1–2)

### Task 0a: Create `multiplicity/phase_transition.py`

```python
def sweep_delta(state_tensor, delta_range, direction="up"):
    """Sweep δ from low→high (up) or high→low (down)."""

def detect_hysteresis(up_sweep, down_sweep, tolerance=0.01):
    """Compare up/down sweeps; hysteresis = first-order."""

def classify_transition(hysteresis_result):
    """Return 'first_order' or 'smooth_crossover'."""
```

### Task 0b: Measurement protocol

1. Sweep δ from 0 → 0.25 in 100 steps, recording healing curve
2. Sweep δ from 0.25 → 0 in 100 steps, recording healing curve
3. Compare: if paths differ significantly → first-order (hysteresis loop)
4. If paths overlap → smooth crossover

**Acceptance**: Classification result documented with numerical evidence.

---

## Sprint 1: Architectural Decision (Day 3)

### If first-order:
- Replace DriftAuditHandler linear guard with discontinuity detector
- Remove 🟡 seal — system is binary (🟢 protected / 🔴 collapsed)
- Spike detection algorithm replaces epsilon_burn comparison

### If smooth crossover:
- Retain DriftAuditHandler and tri-state seal (validates current design)
- Document that 🟡 state is physically meaningful
- No changes to certify.py seal logic

**Acceptance**: Architectural decision documented; code changes applied if needed.

---

## Sprint 2: Zeno Heartbeat (Day 4)

### Task 2a: Create `multiplicity/zeno_heartbeat.py`

```python
@dataclass(frozen=True)
class HeartbeatConfig:
    tau_zero: float = 3.33     # Base period (seconds)
    crossing_number: int = 3    # Trefoil default
    P: float = ...             # Computed from protection_factor()
    T_hb: float = ...          # τ₀ / P
    epsilon_hb: float = ...    # Max jitter = τ₀ / P

def enforce_heartbeat(config, callback, measured_jitter):
    """Assert measured_jitter ≤ config.epsilon_hb."""
```

### Task 2b: RT thread feasibility assessment

For trefoil (c(K)=3): ε_hb ≤ 3.33 μs.
- Python FileSystemEventHandler: ~1–50 ms latency → INFEASIBLE
- POSIX SCHED_FIFO RT thread: ~1–10 μs latency → FEASIBLE
- Document: CPython GIL prevents sub-millisecond guarantees
- Recommendation: RT thread promotion for production deployment

**Acceptance**: Heartbeat module implemented; RT infeasibility documented.

---

## Sprint 3: Gate Tests (Day 5)

```
tests/test_adr102_phase_transition.py
├── TestHysteresis (5 tests)
├── TestTransitionClassification (3 tests)
├── TestZenoHeartbeat (4 tests)
├── TestRTConstraint (3 tests)
└── TestSealModelConsistency (3 tests)
```

**Acceptance**: 18+ tests passing.

---

## Falsification Gate

| Metric | Smooth Crossover | First-Order | Action |
|--------|-----------------|-------------|--------|
| Hysteresis area | < tolerance | > tolerance | Classify |
| 🟡 state | Retained | Removed | Update certify.py |
| DriftAuditHandler | Retained | Replaced | Update watchdog.py |
| ε_hb feasibility | N/A | ≤ 3.33 μs | RT thread required |
