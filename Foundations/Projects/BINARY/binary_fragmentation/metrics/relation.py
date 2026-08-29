"""
metrics/relation.py
===================
Relational Loss Metric (F_r):
Measures loss of semantic relationships, directed edges, relationship types,
weights, and hypergraph relations.

Crucial ADR Invariant:
A state with 100% value integrity (F_v = 0.0) can experience 100% relational
fragmentation (F_r = 1.0) if relationships between entities are severed.
"""

from __future__ import annotations
from typing import Dict, Set, Tuple
from binary_fragmentation.core.state import State


def compute_relation_loss(s0: State, sn: State) -> float:
    """
    Computes relational loss F_r in [0.0, 1.0].
    0.0 = all edges, types, and hyper-relations perfectly preserved
    1.0 = total relational disruption
    """
    if len(s0.edges) == 0 and len(s0.hyperedges) == 0:
        # If no relations originally, 0 loss if none now, else penalty
        return 0.0 if (len(sn.edges) == 0 and len(sn.hyperedges) == 0) else 0.5

    # Binary edge match
    edges0_map: Dict[Tuple[str, str, str], float] = {
        (e.source_id, e.target_id, e.relation_type): e.weight for e in s0.edges
    }
    edgesn_map: Dict[Tuple[str, str, str], float] = {
        (e.source_id, e.target_id, e.relation_type): e.weight for e in sn.edges
    }

    matched_edges = 0
    weight_deviations = 0.0

    for key, w0 in edges0_map.items():
        if key in edgesn_map:
            matched_edges += 1
            wn = edgesn_map[key]
            weight_deviations += min(1.0, abs(w0 - wn) / max(abs(w0), 1.0))
        else:
            # Edge completely missing
            weight_deviations += 1.0

    edge_loss = (
        (len(s0.edges) - matched_edges + weight_deviations) / (2.0 * max(len(s0.edges), 1))
        if s0.edges
        else 0.0
    )

    # Hyperedge relational match
    hypers0_set: Set[Tuple[Tuple[str, ...], str]] = {
        (tuple(sorted(h.node_ids)), h.relation_type) for h in s0.hyperedges
    }
    hypersn_set: Set[Tuple[Tuple[str, ...], str]] = {
        (tuple(sorted(h.node_ids)), h.relation_type) for h in sn.hyperedges
    }

    if s0.hyperedges:
        matched_hypers = len(hypers0_set.intersection(hypersn_set))
        hyper_loss = (len(hypers0_set) - matched_hypers) / len(hypers0_set)
    else:
        hyper_loss = 0.0 if not sn.hyperedges else 1.0

    total_relations0 = len(s0.edges) + len(s0.hyperedges)
    if total_relations0 == 0:
        return 0.0

    w_edge = len(s0.edges) / total_relations0
    w_hyper = len(s0.hyperedges) / total_relations0

    total_r = w_edge * edge_loss + w_hyper * hyper_loss
    return max(0.0, min(1.0, total_r))
