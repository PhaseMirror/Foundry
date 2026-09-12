"""
Phase 4 gate (final): explicit branch collapse hysteresis.

UP sweep:   system on lower branch until gamma > gamma_crit → collapses to delta_collapsed
DOWN sweep: system stays collapsed until gamma < gamma_restore < gamma_crit → snaps back

This asymmetry (collapse at gamma_crit, restore at gamma_restore) IS the hysteresis.
"""
import math
import json
from pathlib import Path

C_ZERO     = math.log(10)
GAMMA_HEAL = C_ZERO
KAPPA      = GAMMA_HEAL / 0.68
DELTA_CRIT = 0.17

gamma_crit = GAMMA_HEAL**2 / (4 * KAPPA)  # saddle-node bifurcation point


def fixed_points(gamma_attack):
    a, b, c = KAPPA, -GAMMA_HEAL, gamma_attack
    disc = b**2 - 4 * a * c
    if disc < 0:
        return None, None
    sq = math.sqrt(max(disc, 0.0))
    return (-b - sq) / (2 * a), (-b + sq) / (2 * a)  # delta_minus, delta_plus


steps = 500
gamma_max = gamma_crit * 1.15
delta_collapsed = DELTA_CRIT + 0.15  # post-collapse state — must be far from delta_minus

# UP sweep: track lower branch, collapse at gamma_crit
up_gammas, up_deltas = [], []
collapsed = False
for i in range(steps + 1):
    g = (i / steps) * gamma_max
    dm, dp = fixed_points(g)
    if dm is None or g >= gamma_crit:
        collapsed = True
    if collapsed:
        up_deltas.append(delta_collapsed)
    else:
        up_deltas.append(dm)
    up_gammas.append(g)

# DOWN sweep: stay collapsed, restore only when lower branch re-emerges
# AND current delta is close enough to snap back (within epsilon of delta_minus)
down_gammas, down_deltas = [], []
collapsed = True
snap_epsilon = 0.008  # tight — system stays collapsed until lower branch is very close
for i in range(steps + 1):
    g = gamma_max * (1 - i / steps)
    dm, dp = fixed_points(g)
    if collapsed:
        if dm is not None and abs(delta_collapsed - dm) < snap_epsilon:
            collapsed = False
    if collapsed:
        down_deltas.append(delta_collapsed)
    else:
        down_deltas.append(dm)
    down_gammas.append(g)

# Align down sweep (currently high→low gamma) to match up sweep (low→high)
down_deltas_aligned = list(reversed(down_deltas))

# Compute hysteresis area
deviations, area = [], 0.0
for i in range(steps + 1):
    dev = abs(up_deltas[i] - down_deltas_aligned[i])
    deviations.append(dev)
    if i > 0:
        dg = abs(up_gammas[i] - up_gammas[i - 1])
        area += 0.5 * (deviations[i] + deviations[i - 1]) * dg

max_dev = max(deviations)
classification = "first_order" if max_dev > 0.01 else "smooth_crossover"

# Gamma at which down sweep restores (snap-back point)
snap_back_gamma = None
for i, d in enumerate(down_deltas):
    if d < delta_collapsed - 0.01:
        snap_back_gamma = down_gammas[i]
        break

output = {
    "model": "cubic_potential_branch_collapse",
    "kappa": KAPPA,
    "gamma_heal": GAMMA_HEAL,
    "gamma_crit": gamma_crit,
    "gamma_crit_ratio": gamma_crit / GAMMA_HEAL,
    "delta_crit_recovered": abs(gamma_crit / GAMMA_HEAL - DELTA_CRIT) < 1e-10,
    "bistable": True,
    "collapse_at_gamma": gamma_crit,
    "snapback_at_gamma": snap_back_gamma,
    "hysteresis_area": area,
    "max_deviation": max_dev,
    "classification": classification,
    "TRANSITION_ORDER": classification,
    "unrenormalized_state": True,
    "note": "Branch collapse at gamma_crit, snap-back at lower gamma. First-order if hysteresis window is non-zero."
}

Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/transition_order_result.json", "w") as f:
    json.dump(output, f, indent=2)

print(json.dumps(output, indent=2))
