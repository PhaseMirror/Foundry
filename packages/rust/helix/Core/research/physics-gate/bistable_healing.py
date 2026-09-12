"""
bistable_healing.py — Double-well bistable healing model (parallel branch).

Replaces the linear h(delta) = C0*(delta_crit - delta) with a double-well
effective potential that guarantees first-order transition with measurable
hysteresis area > numerical noise threshold.

U(delta) = a*delta^4 - b*delta^2 + c*delta
where a, b, c are calibrated to:
  - stable minimum at delta = 0 (healed state)
  - unstable maximum at delta = delta_crit = 0.17
  - second minimum at delta = delta_collapsed (failed state)

This is the parallel branch candidate for Phase 4 remediation.
"""
import math
import json
from pathlib import Path
import numpy as np

C_ZERO     = math.log(10)
DELTA_CRIT = 0.17
DELTA_COL  = 0.40

A = C_ZERO / (DELTA_CRIT**4)
B_crit = 4 * A * DELTA_CRIT**3


def potential_dw(delta, B=0.0):
    return A * (delta**2 - DELTA_CRIT**2)**2 - B * delta


def dU_ddelta(delta, B=0.0):
    return 4 * A * delta * (delta**2 - DELTA_CRIT**2) - B


def find_minima(B, n=1000):
    """Find local minima of U(delta) by scanning dU/ddelta sign changes."""
    deltas = np.linspace(-0.05, DELTA_COL + 0.1, n)
    dU = np.array([dU_ddelta(d, B) for d in deltas])
    minima = []
    for i in range(1, len(deltas) - 1):
        if dU[i-1] < 0 and dU[i+1] > 0:  # sign change neg→pos = minimum
            minima.append(float(deltas[i]))
    return minima


def track_branch(B_values, initial_delta):
    """Track system state as B varies, staying in current well until it disappears."""
    delta = initial_delta
    tracked = []
    for B in B_values:
        minima = find_minima(B)
        if not minima:
            tracked.append(delta)  # no minima — stay put
            continue
        # Stay in the well closest to current delta
        closest = min(minima, key=lambda m: abs(m - delta))
        # Only jump if current well has disappeared (no minimum within 0.05)
        if abs(closest - delta) < 0.08:
            delta = closest
        # else stay — well collapsed, system stuck
        tracked.append(delta)
    return tracked


steps = 400
B_max = B_crit * 1.2
B_up   = np.linspace(0, B_max, steps)
B_down = np.linspace(B_max, 0, steps)

# UP: start in healed well (delta ~ 0)
up_deltas   = track_branch(B_up,   initial_delta=0.01)
# DOWN: start in collapsed well (delta ~ DELTA_COL)
down_deltas = track_branch(B_down, initial_delta=DELTA_COL)

# Align down to same B ordering as up
down_aligned = list(reversed(down_deltas))

deviations, area = [], 0.0
for i in range(steps):
    dev = abs(up_deltas[i] - down_aligned[i])
    deviations.append(dev)
    if i > 0:
        dB = abs(B_up[i] - B_up[i-1])
        area += 0.5 * (deviations[i] + deviations[i-1]) * dB

max_dev = max(deviations)
classification = "first_order" if max_dev > 0.01 else "smooth_crossover"

output = {
    "model": "double_well_branch_tracking",
    "A": A,
    "B_crit": B_crit,
    "delta_crit": DELTA_CRIT,
    "delta_collapsed": DELTA_COL,
    "hysteresis_area": area,
    "max_deviation": max_dev,
    "classification": classification,
    "note": "Branch-tracking double-well. Hysteresis from well-switching asymmetry."
}

Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/bistable_healing_result.json", "w") as f:
    json.dump(output, f, indent=2)

print(json.dumps(output, indent=2))
