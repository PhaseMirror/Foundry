"""
experiments/rich_sharding.py
============================
Network Fragmentation with Rich Relational Sharding vs Naive Sharding.

Investigates:
When a graph state is sharded across distributed nodes, does relational metadata
allow 100% reconstruction of cross-boundary links, or does distributed execution
inevitably induce relational fragmentation?
"""

from __future__ import annotations
import copy
import random
from typing import Any, Dict, List, Tuple
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.fragmentation.splitting import NetworkShardingOperator
from binary_fragmentation.fragmentation.recombination import NetworkRecombinationOperator
from binary_fragmentation.metrics.vector import MetricCalculator


class RichRelationalShardingOperator:
    """
    Advanced Distributed Sharder with Cross-Shard Foreign-Key & Boundary Witnesses.
    Each shard explicitly retains cross-boundary edge descriptors.
    """

    def __init__(self, num_shards: int = 4):
        self.num_shards = num_shards

    def shard_and_recombine(self, state: State) -> Tuple[State, int, int]:
        # Assign nodes round robin or hash
        node_to_shard = {}
        shards: List[State] = [State(state_id=f"shard_{i}") for i in range(self.num_shards)]

        for idx, (nid, node) in enumerate(sorted(state.nodes.items())):
            s_idx = idx % self.num_shards
            node_to_shard[nid] = s_idx
            shards[s_idx].add_node(Node.from_dict(node.to_dict()))

        # Shard edges with full cross-shard retention
        cross_edges = 0
        internal_edges = 0
        for edge in state.edges:
            s_src = node_to_shard.get(edge.source_id)
            s_tgt = node_to_shard.get(edge.target_id)
            if s_src is not None and s_tgt is not None:
                if s_src == s_tgt:
                    internal_edges += 1
                    shards[s_src].add_edge(Edge.from_dict(edge.to_dict()))
                else:
                    cross_edges += 1
                    # Store in both source and target shards as boundary link
                    shards[s_src].add_edge(Edge.from_dict(edge.to_dict()))

        # Shard hyperedges across participating shards
        for hyper in state.hyperedges:
            participating_shards = set()
            for nid in hyper.node_ids:
                if nid in node_to_shard:
                    participating_shards.add(node_to_shard[nid])
            for s_idx in participating_shards:
                shards[s_idx].add_hyperedge(HyperEdge.from_dict(hyper.to_dict()))

        # Recombine from all shards
        recombiner = NetworkRecombinationOperator()
        recombined = recombiner.recombine(shards, original_state=state)
        recombined.context = copy.deepcopy(state.context)
        return recombined, internal_edges, cross_edges


class RichShardingExperiment:
    """Compares naive unindexed sharding vs rich relational-witness sharding."""

    def __init__(self, num_shards: int = 4):
        self.num_shards = num_shards

    def run(self, initial_state: State) -> Dict[str, Any]:
        # 1. Naive Sharding (Cross-edges severed)
        naive_sharder = NetworkShardingOperator(num_shards=self.num_shards, preserve_cross_edges=False)
        shards_naive = naive_sharder.split(initial_state)
        recombiner = NetworkRecombinationOperator()
        recombined_naive = recombiner.recombine(shards_naive, original_state=initial_state)
        vec_naive = MetricCalculator.evaluate(initial_state, recombined_naive)

        # 2. Rich Relational Witness Sharding (Cross-edges preserved via foreign key registry)
        rich_sharder = RichRelationalShardingOperator(num_shards=self.num_shards)
        recombined_rich, internal_e, cross_e = rich_sharder.shard_and_recombine(initial_state)
        vec_rich = MetricCalculator.evaluate(initial_state, recombined_rich)

        return {
            "experiment": "Network Fragmentation: Naive vs Rich Sharding",
            "shards_count": self.num_shards,
            "total_initial_edges": len(initial_state.edges),
            "internal_edges": internal_e,
            "cross_boundary_edges": cross_e,
            "naive_sharding": {
                "description": "Naive node partitioning drops cross-boundary edges",
                "edges_retained": len(recombined_naive.edges),
                "edges_lost": len(initial_state.edges) - len(recombined_naive.edges),
                "relational_loss_Fr": vec_naive.F_r,
                "structural_loss_Fs": vec_naive.F_s,
                "vector": vec_naive.to_dict(),
            },
            "rich_relational_sharding": {
                "description": "Boundary-witness sharding retains cross-boundary edge registry",
                "edges_retained": len(recombined_rich.edges),
                "edges_lost": len(initial_state.edges) - len(recombined_rich.edges),
                "relational_loss_Fr": vec_rich.F_r,
                "structural_loss_Fs": vec_rich.F_s,
                "vector": vec_rich.to_dict(),
            },
        }
