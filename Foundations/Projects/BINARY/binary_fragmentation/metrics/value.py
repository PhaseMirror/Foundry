"""
metrics/value.py
================
Value Loss Metric (F_v):
Measures numerical and attribute distortion between original and transformed states.
0.0 = perfect value match
1.0 = total value corruption or absence
"""

from __future__ import annotations
import math
from typing import Any
from binary_fragmentation.core.state import State


def compute_value_loss(s0: State, sn: State) -> float:
    """
    Computes value loss F_v in [0.0, 1.0].
    Evaluates relative difference for numeric nodes and string distance for categorical nodes.
    """
    if not s0.nodes:
        return 0.0 if not sn.nodes else 1.0

    total_loss = 0.0
    nodes_evaluated = 0

    for nid, node0 in s0.nodes.items():
        nodes_evaluated += 1
        if nid not in sn.nodes:
            # Missing node: maximum value loss
            total_loss += 1.0
            continue

        noden = sn.nodes[nid]
        v0 = node0.value
        vn = noden.value

        if isinstance(v0, (int, float)) and isinstance(vn, (int, float)):
            v0_f = float(v0)
            vn_f = float(vn)
            diff = abs(v0_f - vn_f)
            denom = max(abs(v0_f), 1.0)
            # Normalized relative distortion capped at 1.0
            norm_loss = min(1.0, diff / denom)
            total_loss += norm_loss
        elif isinstance(v0, (list, tuple)) and isinstance(vn, (list, tuple)):
            if len(v0) == 0:
                total_loss += 0.0 if len(vn) == 0 else 1.0
            else:
                sub_losses = []
                for i in range(min(len(v0), len(vn))):
                    if isinstance(v0[i], (int, float)) and isinstance(vn[i], (int, float)):
                        d = abs(float(v0[i]) - float(vn[i]))
                        sub_losses.append(min(1.0, d / max(abs(float(v0[i])), 1.0)))
                    else:
                        sub_losses.append(0.0 if v0[i] == vn[i] else 1.0)
                # Penalty for length mismatch
                len_penalty = abs(len(v0) - len(vn)) / max(len(v0), 1)
                item_loss = (sum(sub_losses) / max(len(sub_losses), 1))
                total_loss += min(1.0, 0.7 * item_loss + 0.3 * len_penalty)
        else:
            # String / categorical exact comparison
            total_loss += 0.0 if str(v0) == str(vn) else 1.0

    return max(0.0, min(1.0, total_loss / max(nodes_evaluated, 1)))
