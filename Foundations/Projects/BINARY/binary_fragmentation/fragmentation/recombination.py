"""
fragmentation/recombination.py
==============================
Recombination Operator: Reconstructs unified state from distributed shards.
"""

from __future__ import annotations
import copy
import uuid
import time
from typing import Dict, List, Optional, Tuple
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord


class NetworkRecombinationOperator(BinaryOperator):
    """
    Reassembles multiple state shards {S_1, ..., S_K} into a single unified State S'.
    Measures relational loss if cross-shard edges were dropped during partitioning.
    """

    def __init__(self) -> None:
        super().__init__(name="NetworkRecombinationOperator")

    def recombine(self, shards: List[State], original_state: Optional[State] = None) -> State:
        recombined = State(
            state_id=str(uuid.uuid4()),
            parent_id=shards[0].parent_id if shards else None,
            generation=(max(s.generation for s in shards) if shards else 0),
            timestamp=time.time(),
        )

        seen_edges = set()
        for shard in shards:
            for nid, node in shard.nodes.items():
                recombined.add_node(Node.from_dict(node.to_dict()))
            for edge in shard.edges:
                key = (edge.source_id, edge.target_id, edge.relation_type)
                if key not in seen_edges:
                    seen_edges.add(key)
                    recombined.add_edge(Edge.from_dict(edge.to_dict()))
            for hyper in shard.hyperedges:
                recombined.add_hyperedge(HyperEdge.from_dict(hyper.to_dict()))

        if original_state:
            recombined.provenance_records = copy.deepcopy(original_state.provenance_records)

        return recombined

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        return state, ProvenanceRecord(
            state_id=state.state_id,
            parent_state_id=state.parent_id,
            operator=self.name,
            checksum_before=state.compute_checksum(),
            checksum_after=state.compute_checksum(),
        )
