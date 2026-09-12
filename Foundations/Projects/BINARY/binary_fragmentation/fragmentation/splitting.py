"""
fragmentation/splitting.py
==========================
Network State Partitioning / Sharding Operator.
Splits a coherent state across K independent nodes/shards.
"""

from __future__ import annotations
import copy
import uuid
import time
from typing import Dict, List, Tuple
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord


class NetworkShardingOperator(BinaryOperator):
    """
    Splits a state S into K independent shard states {S_1, S_2, ..., S_K}.
    Simulates distributed microservice / sharded database architectures.
    Edges crossing partition boundaries may be isolated or severed.
    """

    def __init__(self, num_shards: int = 4, preserve_cross_edges: bool = False):
        self.num_shards = num_shards
        self.preserve_cross_edges = preserve_cross_edges
        super().__init__(
            name="NetworkShardingOperator",
            parameters={"num_shards": num_shards, "preserve_cross_edges": preserve_cross_edges},
        )

    def split(self, state: State) -> List[State]:
        """Partitions the state into K separate State shards."""
        shards: List[State] = [
            State(
                state_id=f"{state.state_id}_shard_{i}",
                parent_id=state.state_id,
                generation=state.generation + 1,
            )
            for i in range(self.num_shards)
        ]

        # Partition nodes round-robin or hash-based
        node_to_shard: Dict[str, int] = {}
        for idx, (nid, node) in enumerate(sorted(state.nodes.items())):
            shard_idx = idx % self.num_shards
            node_to_shard[nid] = shard_idx
            shards[shard_idx].add_node(Node.from_dict(node.to_dict()))

        # Assign edges
        for edge in state.edges:
            src_shard = node_to_shard.get(edge.source_id)
            tgt_shard = node_to_shard.get(edge.target_id)
            if src_shard is not None and tgt_shard is not None:
                if src_shard == tgt_shard:
                    shards[src_shard].add_edge(Edge.from_dict(edge.to_dict()))
                elif self.preserve_cross_edges:
                    # In strict mode, store in both or first
                    shards[src_shard].add_edge(Edge.from_dict(edge.to_dict()))

        return shards

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        """For pipeline compatibility, shards and recombines."""
        from binary_fragmentation.fragmentation.recombination import NetworkRecombinationOperator
        shards = self.split(state)
        recombiner = NetworkRecombinationOperator()
        recombined = recombiner.recombine(shards, original_state=state)

        rec = ProvenanceRecord(
            state_id=recombined.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"shards_count": self.num_shards},
            info_added={},
            checksum_before=state.compute_checksum(),
            checksum_after=recombined.compute_checksum(),
            reversible=(state.compute_checksum() == recombined.compute_checksum()),
            reversibility_notes="Distributed network sharding cycle",
        )
        recombined.provenance_records.append(rec.to_dict())
        return recombined, rec
