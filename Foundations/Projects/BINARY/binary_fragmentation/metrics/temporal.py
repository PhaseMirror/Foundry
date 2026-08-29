"""
metrics/temporal.py
===================
Temporal Loss Metric (F_t):
Measures chronological ordering inversion and event timestamp degradation.
"""

from __future__ import annotations
from typing import List, Tuple
from binary_fragmentation.core.state import State


def compute_temporal_loss(s0: State, sn: State) -> float:
    """
    Computes temporal loss F_t in [0.0, 1.0].
    Evaluates Kendall tau inversion count of node timestamps.
    """
    common_nodes = [nid for nid in s0.nodes if nid in sn.nodes]
    if len(common_nodes) < 2:
        return 0.0

    # Sort common nodes by original created_at
    sorted_orig = sorted(common_nodes, key=lambda nid: s0.nodes[nid].created_at)
    
    # Check inversions in S_n
    inversions = 0
    total_pairs = 0
    for i in range(len(sorted_orig)):
        for j in range(i + 1, len(sorted_orig)):
            total_pairs += 1
            nid_a = sorted_orig[i]
            nid_b = sorted_orig[j]
            t_a = sn.nodes[nid_a].created_at
            t_b = sn.nodes[nid_b].created_at
            if t_a > t_b:
                inversions += 1

    return float(inversions) / max(total_pairs, 1)
