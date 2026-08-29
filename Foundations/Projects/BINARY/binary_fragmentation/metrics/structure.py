"""
metrics/structure.py
====================
Structural Loss Metric (F_s):
Measures topological graph divergence, degree sequence divergence,
and hyperedge structural drift.
"""

from __future__ import annotations
import math
from typing import Dict, List
from binary_fragmentation.core.state import State


def compute_structure_loss(s0: State, sn: State) -> float:
    """
    Computes structural loss F_s in [0.0, 1.0].
    Evaluates degree profile divergence and hyperedge topology.
    """
    if len(s0.nodes) == 0 and len(sn.nodes) == 0:
        return 0.0

    # Node count distortion
    n0 = len(s0.nodes)
    nn = len(sn.nodes)
    node_loss = abs(n0 - nn) / max(n0, 1)

    # Degree sequence comparison
    deg0: Dict[str, int] = {nid: 0 for nid in s0.nodes}
    for e in s0.edges:
        if e.source_id in deg0:
            deg0[e.source_id] += 1
        if e.target_id in deg0:
            deg0[e.target_id] += 1

    degn: Dict[str, int] = {nid: 0 for nid in sn.nodes}
    for e in sn.edges:
        if e.source_id in degn:
            degn[e.source_id] += 1
        if e.target_id in degn:
            degn[e.target_id] += 1

    deg_diff = 0
    max_deg_possible = 0
    for nid, d in deg0.items():
        dn = degn.get(nid, 0)
        deg_diff += abs(d - dn)
        max_deg_possible += max(d, 1)

    deg_loss = deg_diff / max(max_deg_possible, 1)

    # Hyperedge structural comparison
    h0 = len(s0.hyperedges)
    hn = len(sn.hyperedges)
    hyper_loss = abs(h0 - hn) / max(h0, 1) if h0 > 0 else (1.0 if hn > 0 else 0.0)

    # Combined structural loss
    total_s = 0.3 * node_loss + 0.5 * deg_loss + 0.2 * hyper_loss
    return max(0.0, min(1.0, total_s))
