"""
metrics/context.py
==================
Contextual Loss Metric (F_c):
Measures loss of domain metadata, environment context, and semantic frames.
"""

from __future__ import annotations
from typing import Any, Dict
from binary_fragmentation.core.state import State


def compute_context_loss(s0: State, sn: State) -> float:
    """
    Computes context loss F_c in [0.0, 1.0].
    Evaluates key-value overlap in the state context and metadata dictionary.
    """
    c0 = s0.context
    cn = sn.context

    if not c0:
        return 0.0 if not cn else 0.2

    matched_keys = 0
    value_mismatches = 0

    for k, v in c0.items():
        if k in cn:
            matched_keys += 1
            if cn[k] != v:
                value_mismatches += 1

    missing_keys = len(c0) - matched_keys
    total_loss = (missing_keys + 0.5 * value_mismatches) / len(c0)
    return max(0.0, min(1.0, total_loss))
