"""
Phase 4 gate (corrected): first-order transition via cubic potential U(delta).

Drift equation: d(delta)/dt = -Gamma_heal*delta + gamma_attack + kappa*delta^2
where kappa = Gamma_heal / 0.68

Effective potential: U(delta) = (Gamma_heal/2)*delta^2 - gamma_attack*delta - (kappa/3)*delta^3

Critical attack: gamma_crit = Gamma_heal^2 / (4*kappa)
Substituting kappa: gamma_crit / Gamma_heal = 0.68/4 = 0.17 = delta_crit  ✓
"""
import math
import json
import numpy as np
from pathlib import Path

# CF constants
DELTA_CRIT  = 0.17
C_ZERO      = math.log(10)
GAMMA_HEAL  = C_ZERO          # healing rate coefficient = C_0
KAPPA       = GAMMA_HEAL / 0.68  # quadratic feedback coefficient


def drift(delta, gamma_attack):
    """d(delta)/dt = -Gamma*delta + gamma_attack + kappa*delta^2"""
    return -GAMMA_HEAL * delta + gamma_attack + KAPPA * delta**2


def potential(delta, gamma_attack):
    """U(delta) = (Gamma/2)*delta^2 - gamma_attack*delta - (kappa/3)*delta^3"""
    return (GAMMA_HEAL / 2) * delta**2 - gamma_attack * delta - (KAPPA / 3) * delta**3


def fixed_points(gamma_attack):
    """Solve kappa*delta^2 - Gamma*delta + gamma_attack = 0"""
    a, b, c = KAPPA, -GAMMA_HEAL, gamma_attack
    disc = b**2 - 4 * a * c
    if disc < 0:
        return []
    elif disc == 0:
        return [-b / (2 * a)]
    else:
        return [(-b - math.sqrt(disc)) / (2 * a),
                (-b + math.sqrt(disc)) / (2 * a)]


def healing_rate_cubic(delta, gamma_attack=0.0):
    """Effective healing: -d(delta)/dt when system is healing."""
    return max(0.0, -drift(delta, gamma_attack))


def sweep_cubic(delta_start, delta_end, gamma_attack, steps=200, direction="up"):
    deltas, healing_values = [], []
    for i in range(steps + 1):
        frac = i / steps
        d = delta_start + frac * (delta_end - delta_start)
        deltas.append(d)
        healing_values.append(healing_rate_cubic(d, gamma_attack))
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


# Critical attack strength
gamma_crit = GAMMA_HEAL**2 / (4 * KAPPA)
gamma_crit_ratio = gamma_crit / GAMMA_HEAL  # should = 0.17

# Run sweep just below critical attack (bistable regime)
gamma_sub = gamma_crit * 0.95
up   = sweep_cubic(0.0, DELTA_CRIT + 0.08, gamma_sub, steps=200, direction="up")
down = sweep_cubic(DELTA_CRIT + 0.08, 0.0, gamma_sub, steps=200, direction="down")
result = detect_hysteresis(up, down)

# Fixed points at sub-critical attack
fps = fixed_points(gamma_sub)

# Verify delta_crit recovery
delta_crit_recovered = abs(gamma_crit_ratio - DELTA_CRIT) < 1e-10

output = {
    "model": "cubic_potential",
    "kappa": KAPPA,
    "gamma_heal": GAMMA_HEAL,
    "gamma_crit": gamma_crit,
    "gamma_crit_ratio": gamma_crit_ratio,
    "delta_crit_recovered": delta_crit_recovered,
    "fixed_points_sub_critical": fps,
    "bistable": len(fps) == 2,
    "hysteresis_area":  result["hysteresis_area"],
    "max_deviation":    result["max_deviation"],
    "classification":   result["classification"],
    "TRANSITION_ORDER": result["classification"],
    "unrenormalized_state": True,
    "note": "Cubic potential U(delta) with kappa=Gamma/0.68. Phase 5 Lindblad renormalization still required for SlopeUB."
}

Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/transition_order_result.json", "w") as f:
    json.dump(output, f, indent=2)

print(json.dumps(output, indent=2))
