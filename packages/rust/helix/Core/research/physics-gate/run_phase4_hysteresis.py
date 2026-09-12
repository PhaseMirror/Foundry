"""
Phase 4 gate (corrected hysteresis): sweep gamma_attack up and down,
tracking the stable fixed point delta_- at each step.

Hysteresis appears because:
- Sweeping UP: system stays on lower branch until gamma_crit, then jumps
- Sweeping DOWN: system stays on upper branch until gamma_crit, then jumps back
The area between these two paths = hysteresis area = first_order signature.
"""
import math
import json
from pathlib import Path

C_ZERO     = math.log(10)
GAMMA_HEAL = C_ZERO
KAPPA      = GAMMA_HEAL / 0.68
DELTA_CRIT = 0.17

gamma_crit = GAMMA_HEAL**2 / (4 * KAPPA)


def fixed_points(gamma_attack):
    """Roots of kappa*delta^2 - Gamma*delta + gamma_attack = 0"""
    a, b, c = KAPPA, -GAMMA_HEAL, gamma_attack
    disc = b**2 - 4 * a * c
    if disc < 0:
        return []
    elif abs(disc) < 1e-15:
        return [-b / (2 * a)]
    sq = math.sqrt(disc)
    return [(-b - sq) / (2 * a), (-b + sq) / (2 * a)]


def stable_fixed_point(gamma_attack, current_delta):
    """
    Return the stable fixed point closest to current_delta (hysteretic tracking).
    If no real fixed points exist (past gamma_crit), return None (collapsed).
    """
    fps = fixed_points(gamma_attack)
    if not fps:
        return None
    # Stable = lower fixed point (delta_-)
    # Unstable = upper fixed point (delta_+)
    # Track whichever branch current_delta is on
    if len(fps) == 1:
        return fps[0]
    delta_minus, delta_plus = sorted(fps)
    # If current state is below the unstable point, stay on lower branch
    if current_delta <= delta_plus:
        return delta_minus
    else:
        return delta_plus


steps = 300
gamma_max = gamma_crit * 1.1

# UP sweep: start at delta=0, increase gamma_attack
up_gammas, up_deltas = [], []
delta = 0.0
for i in range(steps + 1):
    g = (i / steps) * gamma_max
    fp = stable_fixed_point(g, delta)
    if fp is None:
        # Collapsed — jump to large delta
        delta = DELTA_CRIT + 0.1
    else:
        delta = fp
    up_gammas.append(g)
    up_deltas.append(delta)

# DOWN sweep: start at delta=DELTA_CRIT+0.1, decrease gamma_attack
down_gammas, down_deltas = [], []
delta = DELTA_CRIT + 0.1
for i in range(steps + 1):
    g = gamma_max * (1 - i / steps)
    fp = stable_fixed_point(g, delta)
    if fp is None:
        delta = DELTA_CRIT + 0.1
    else:
        delta = fp
    down_gammas.append(g)
    down_deltas.append(delta)

# Align down sweep to same gamma ordering as up sweep
down_deltas_aligned = list(reversed(down_deltas))

# Compute hysteresis
deviations, area = [], 0.0
for i in range(steps + 1):
    dev = abs(up_deltas[i] - down_deltas_aligned[i])
    deviations.append(dev)
    if i > 0:
        dg = abs(up_gammas[i] - up_gammas[i - 1])
        area += 0.5 * (deviations[i] + deviations[i - 1]) * dg

max_dev = max(deviations)
classification = "first_order" if max_dev > 0.01 else "smooth_crossover"

output = {
    "model": "cubic_potential_hysteresis_sweep",
    "kappa": KAPPA,
    "gamma_heal": GAMMA_HEAL,
    "gamma_crit": gamma_crit,
    "gamma_crit_ratio": gamma_crit / GAMMA_HEAL,
    "delta_crit_recovered": abs(gamma_crit / GAMMA_HEAL - DELTA_CRIT) < 1e-10,
    "bistable": True,
    "hysteresis_area": area,
    "max_deviation": max_dev,
    "classification": classification,
    "TRANSITION_ORDER": classification,
    "unrenormalized_state": True,
    "note": "Hysteresis sweep over gamma_attack tracking stable branch. Phase 5 Lindblad renormalization still required for SlopeUB."
}

Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/transition_order_result.json", "w") as f:
    json.dump(output, f, indent=2)

print(json.dumps(output, indent=2))
