"""
metrics/reversibility.py
========================
Reversibility Loss Metric (F_q):
Measures computational irreversibility and rollback failure.
0.0 = fully reversible (exact rollback possible)
1.0 = strictly irreversible transition
"""

from __future__ import annotations
from binary_fragmentation.core.state import State


def compute_reversibility_loss(s0: State, sn: State) -> float:
    """
    Computes reversibility loss F_q in [0.0, 1.0].
    Evaluates provenance record irreversibility flags and checksum divergences.
    """
    if not sn.provenance_records:
        # If generation > 0 with no provenance, marked irreversible
        return 0.0 if sn.generation == 0 else 1.0

    irreversible_steps = 0
    for r in sn.provenance_records:
        if not r.get("reversible", True):
            irreversible_steps += 1

    ratio = irreversible_steps / max(len(sn.provenance_records), 1)
    return max(0.0, min(1.0, ratio))
