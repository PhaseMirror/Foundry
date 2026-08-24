"""
Phase 4 gate: phase transition classification (ADR-102).
Self-contained — no multiplicity package import needed.
Run from anywhere: python Z:\run_phase4.py
"""
import math
import json
from pathlib import Path

# CF constants (from constitutional_field.py)
DELTA_CRIT = 0.17
C_ZERO = math.log(10)


def healing_rate(delta):
    if delta >= DELTA_CRIT:
        return 0.0
    return C_ZERO * (DELTA_CRIT - delta)


def sweep_delta(delta_start, delta_end, steps=100, direction="up"):
    deltas, healing_values = [], []
    for i in range(steps + 1):
        frac = i / steps
        d = delta_start + frac * (delta_end - delta_start)
        deltas.append(d)
        healing_values.append(healing_rate(d))
    return {"direction": direction, "deltas": deltas, "healing_values": healing_values}


def detect_hysteresis(up, down, tolerance=0.01):
    down_vals = list(reversed(down["healing_values"]))
    n = min(len(up["deltas"]), len(down_vals))
    deviations, area = [], 0.0
    for i in range(n):
        dev = abs(up["healing_values"][i] - down_vals[i])
        deviations.append(dev)
        if i > 0:
            dx = abs(up["deltas"][i] - up["deltas"][i - 1])
            area += 0.5 * (deviations[i] + deviations[i - 1]) * dx
    max_dev = max(deviations) if deviations else 0.0
    classification = "first_order" if max_dev > tolerance else "smooth_crossover"
    return {"hysteresis_area": area, "max_deviation": max_dev, "classification": classification}


up   = sweep_delta(0.0, DELTA_CRIT + 0.08, steps=100, direction="up")
down = sweep_delta(DELTA_CRIT + 0.08, 0.0, steps=100, direction="down")
result = detect_hysteresis(up, down)

output = {
    "hysteresis_area":  result["hysteresis_area"],
    "max_deviation":    result["max_deviation"],
    "classification":   result["classification"],
    "TRANSITION_ORDER": "pending",
    "unrenormalized_state": True,
    "note": "Phase 4 run in unrenormalized state per Phase Mirror oracle — Lindblad renormalization pending (ADR-103)"
}

Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/transition_order_result.json", "w") as f:
    json.dump(output, f, indent=2)

print(json.dumps(output, indent=2))
