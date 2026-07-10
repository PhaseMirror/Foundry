# PERTURBATION_FAMILIES.md

This document defines the canonical perturbation families, their bounds, and associated ε_X (drift tolerance) values for Lane A engineering.

## 1. Core Definitions

### ε_X (Drift Tolerance)
The maximum allowable divergence from the baseline coherence state before a substrate is considered unstable or "fragile."

| Substrate | ε_X Value | Rationale |
|---|---|---|
| `metallurgical_fatigue` | 0.08 | Empirical fatigue threshold for cyclic loads. |
| `ai_recursion_stability` | 0.12 | Divergence limit for contradiction density. |

---

## 2. Perturbation Families

### `amplitude_ramp`
- **Mechanism:** Linear or exponential increase in stress magnitude $S_0$.
- **Target:** Stress-impedance bridge saturation.
- **Expected Bounds:** $S_0 \in [0.1, 10.0] \times \text{nominal}$.

### `frequency_shift`
- **Mechanism:** Perturbation of cyclic frequency $\omega$.
- **Target:** Resonance and recovery deficit identification.
- **Expected Bounds:** $\omega \in [0.5, 2.0] \times \text{nominal}$.

### `drag_spike`
- **Mechanism:** Impulse injection of kinematic drag $D_k$.
- **Target:** Recovery latency and hysteresis measurement.
- **Expected Bounds:** Magnitude $\in [1.0, 5.0]$.

### `dual_symbolic_numeric`
- **Mechanism:** Simultaneous stress on numerical state and symbolic metadata.
- **Target:** Multiplicity boundary integrity.

---

## 3. Fragility Classification Labels

- `robust`: Drift stays within ε_X; recovery is rapid.
- `impedance-spike-precursor`: Drift accelerating toward saturation.
- `fragile-under-coupling`: Stability lost only when $\kappa > 0$.
- `time-delayed-failure`: Drift accumulates and triggers threshold post-perturbation.
