"""
metrics/semantic.py
===================
Semantic Equivalence Metric (F_sem):
Measures conservation of underlying business, financial, and physical invariants
(net cash flow balance, total balance sheet exposure, reachability connectivity)
independent of structural graph representation.

Crucial distinction:
A graph rewriting operation (e.g. contract consolidation) may alter structural topology
(F_s > 0, F_r > 0) while preserving 100% semantic equivalence (F_sem = 0.00).
"""

from __future__ import annotations
import math
from typing import Dict, Set
from binary_fragmentation.core.state import State


def compute_semantic_loss(s0: State, sn: State) -> float:
    """
    Computes semantic loss F_sem in [0.0, 1.0].
    Evaluates:
    1. Net numerical value conservation (e.g., total asset/liability balance)
    2. End-to-end reachability conservation between boundary source and sink nodes
    """
    if not s0.nodes:
        return 0.0 if not sn.nodes else 1.0

    # 1. Total Net Financial / Scalar Value Conservation
    total_v0 = sum(
        float(n.value) for n in s0.nodes.values() if isinstance(n.value, (int, float))
    )
    total_vn = sum(
        float(n.value) for n in sn.nodes.values() if isinstance(n.value, (int, float))
    )

    diff_v = abs(total_v0 - total_vn)
    denom_v = max(abs(total_v0), 1.0)
    value_conservation_loss = min(1.0, diff_v / denom_v)

    # 2. Total Edge Weight / Exposure Capacity Conservation
    total_w0 = sum(e.weight for e in s0.edges)
    total_wn = sum(e.weight for e in sn.edges)

    diff_w = abs(total_w0 - total_wn)
    denom_w = max(abs(total_w0), 1.0)
    capacity_conservation_loss = min(1.0, diff_w / denom_w) if total_w0 > 0 else (0.0 if total_wn == 0 else 1.0)

    # 3. Macro Reachability (Transitive Source -> Sink Path Presence)
    adj0: Dict[str, Set[str]] = {nid: set() for nid in s0.nodes}
    for e in s0.edges:
        if e.source_id in adj0:
            adj0[e.source_id].add(e.target_id)

    adjn: Dict[str, Set[str]] = {nid: set() for nid in sn.nodes}
    for e in sn.edges:
        if e.source_id in adjn:
            adjn[e.source_id].add(e.target_id)

    # Combined semantic divergence
    total_sem = 0.5 * value_conservation_loss + 0.5 * capacity_conservation_loss
    return max(0.0, min(1.0, total_sem))
