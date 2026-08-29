"""
metrics/provenance.py
=====================
Provenance Loss Metric (F_p):
Measures decay in lineage traceability, causal depth, and audit record continuity.
"""

from __future__ import annotations
from binary_fragmentation.core.state import State


def compute_provenance_loss(s0: State, sn: State) -> float:
    """
    Computes provenance loss F_p in [0.0, 1.0].
    Evaluates unbroken parentage chain and record retention.
    """
    # If S_n has generation > 0, check if provenance records match generation
    expected_records = sn.generation
    if expected_records == 0:
        return 0.0

    actual_records = len(sn.provenance_records)
    if actual_records >= expected_records:
        # Check if parent_id is unbroken
        return 0.0 if sn.parent_id else 0.2
    elif actual_records == 0:
        # Complete provenance wipe
        return 1.0
    else:
        # Partial provenance loss
        return max(0.0, min(1.0, 1.0 - (actual_records / expected_records)))
