"""
metrics/identity.py
===================
Identity Loss Metric (F_i):
Measures entity resolution collapse, surrogate key drift, and identifier corruption.
"""

from __future__ import annotations
from binary_fragmentation.core.state import State


def compute_identity_loss(s0: State, sn: State) -> float:
    """
    Computes identity loss F_i in [0.0, 1.0].
    Evaluates what fraction of original entity IDs are retained.
    """
    if not s0.nodes:
        return 0.0 if not sn.nodes else 1.0

    ids0 = set(s0.nodes.keys())
    idsn = set(sn.nodes.keys())

    retained_ids = ids0.intersection(idsn)
    lost_ids = len(ids0) - len(retained_ids)
    phantom_ids = len(idsn) - len(retained_ids)

    loss_ratio = (lost_ids + 0.5 * phantom_ids) / max(len(ids0), 1)
    return max(0.0, min(1.0, loss_ratio))
