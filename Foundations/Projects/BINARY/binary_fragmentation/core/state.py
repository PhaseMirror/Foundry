"""
core/state.py
=============
Multidimensional State Representation for the Binary Fragmentation Simulator.
Treats information as multidimensional:
I = (I_value, I_structure, I_relation, I_provenance, I_identity, I_temporal, I_context)
"""

from __future__ import annotations
import copy
import hashlib
import json
import time
import uuid
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set, Tuple


@dataclass
class Node:
    """Individual entity / node in a multidimensional state."""
    id: str
    value: Any
    attributes: Dict[str, Any] = field(default_factory=dict)
    created_at: float = 0.0
    provenance_tag: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "value": self.value,
            "attributes": copy.deepcopy(self.attributes),
            "created_at": self.created_at,
            "provenance_tag": self.provenance_tag,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> Node:
        return cls(
            id=str(data["id"]),
            value=data.get("value"),
            attributes=data.get("attributes", {}),
            created_at=float(data.get("created_at", 0.0)),
            provenance_tag=str(data.get("provenance_tag", "")),
        )


@dataclass
class Edge:
    """Directed relational link between two nodes."""
    source_id: str
    target_id: str
    relation_type: str
    weight: float = 1.0
    attributes: Dict[str, Any] = field(default_factory=dict)
    provenance_tag: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "source_id": self.source_id,
            "target_id": self.target_id,
            "relation_type": self.relation_type,
            "weight": self.weight,
            "attributes": copy.deepcopy(self.attributes),
            "provenance_tag": self.provenance_tag,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> Edge:
        return cls(
            source_id=str(data["source_id"]),
            target_id=str(data["target_id"]),
            relation_type=str(data["relation_type"]),
            weight=float(data.get("weight", 1.0)),
            attributes=data.get("attributes", {}),
            provenance_tag=str(data.get("provenance_tag", "")),
        )


@dataclass
class HyperEdge:
    """N-ary relational structure spanning multiple nodes simultaneously."""
    node_ids: List[str]
    relation_type: str
    attributes: Dict[str, Any] = field(default_factory=dict)
    provenance_tag: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "node_ids": list(self.node_ids),
            "relation_type": self.relation_type,
            "attributes": copy.deepcopy(self.attributes),
            "provenance_tag": self.provenance_tag,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> HyperEdge:
        return cls(
            node_ids=[str(x) for x in data.get("node_ids", [])],
            relation_type=str(data.get("relation_type", "")),
            attributes=data.get("attributes", {}),
            provenance_tag=str(data.get("provenance_tag", "")),
        )


class State:
    """
    Coherent state container encompassing scalar, structural, relational,
    temporal, contextual, and provenance dimensions.
    """

    def __init__(
        self,
        state_id: Optional[str] = None,
        parent_id: Optional[str] = None,
        generation: int = 0,
        nodes: Optional[Dict[str, Node]] = None,
        edges: Optional[List[Edge]] = None,
        hyperedges: Optional[List[HyperEdge]] = None,
        context: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        timestamp: float = 0.0,
    ):
        self.state_id = state_id or str(uuid.uuid4())
        self.parent_id = parent_id
        self.generation = generation
        self.nodes: Dict[str, Node] = nodes or {}
        self.edges: List[Edge] = edges or []
        self.hyperedges: List[HyperEdge] = hyperedges or []
        self.context: Dict[str, Any] = context or {}
        self.metadata: Dict[str, Any] = metadata or {}
        self.timestamp = timestamp
        self.provenance_records: List[Dict[str, Any]] = []

    def add_node(self, node: Node) -> None:
        self.nodes[node.id] = node

    def add_edge(self, edge: Edge) -> None:
        self.edges.append(edge)

    def add_hyperedge(self, hyperedge: HyperEdge) -> None:
        self.hyperedges.append(hyperedge)

    def get_adjacency(self) -> Dict[str, List[Tuple[str, str, float]]]:
        """Returns adjacency map: source -> list of (target, relation_type, weight)."""
        adj: Dict[str, List[Tuple[str, str, float]]] = {nid: [] for nid in self.nodes}
        for edge in self.edges:
            if edge.source_id in adj:
                adj[edge.source_id].append((edge.target_id, edge.relation_type, edge.weight))
        return adj

    def compute_content_checksum(self) -> str:
        """Computes a deterministic SHA-256 digest of semantic and relational content."""
        canonical_repr = self.to_canonical_json()
        return hashlib.sha256(canonical_repr.encode("utf-8")).hexdigest()

    def compute_checksum(self) -> str:
        """Alias for compute_content_checksum."""
        return self.compute_content_checksum()

    def to_canonical_json(self) -> str:
        """Serializes semantic and topological content to deterministic sorted JSON."""
        payload = {
            "nodes": {
                k: {
                    "id": self.nodes[k].id,
                    "value": self.nodes[k].value,
                    "attributes": self.nodes[k].attributes,
                }
                for k in sorted(self.nodes.keys())
            },
            "edges": [
                {
                    "source_id": e.source_id,
                    "target_id": e.target_id,
                    "relation_type": e.relation_type,
                    "weight": e.weight,
                    "attributes": e.attributes,
                }
                for e in sorted(
                    self.edges,
                    key=lambda x: (x.source_id, x.target_id, x.relation_type),
                )
            ],
            "hyperedges": [
                {
                    "node_ids": sorted(h.node_ids),
                    "relation_type": h.relation_type,
                    "attributes": h.attributes,
                }
                for h in sorted(
                    self.hyperedges,
                    key=lambda x: (",".join(sorted(x.node_ids)), x.relation_type),
                )
            ],
            "context": self.context,
            "metadata": self.metadata,
        }
        return json.dumps(payload, sort_keys=True)

    def clone(self) -> State:
        """Creates a deep copy of the state."""
        cloned = State(
            state_id=self.state_id,
            parent_id=self.parent_id,
            generation=self.generation,
            nodes={k: Node.from_dict(v.to_dict()) for k, v in self.nodes.items()},
            edges=[Edge.from_dict(e.to_dict()) for e in self.edges],
            hyperedges=[HyperEdge.from_dict(h.to_dict()) for h in self.hyperedges],
            context=copy.deepcopy(self.context),
            metadata=copy.deepcopy(self.metadata),
            timestamp=self.timestamp,
        )
        cloned.provenance_records = copy.deepcopy(self.provenance_records)
        return cloned

    def to_dict(self) -> Dict[str, Any]:
        return {
            "state_id": self.state_id,
            "parent_id": self.parent_id,
            "generation": self.generation,
            "timestamp": self.timestamp,
            "nodes": {k: v.to_dict() for k, v in self.nodes.items()},
            "edges": [e.to_dict() for e in self.edges],
            "hyperedges": [h.to_dict() for h in self.hyperedges],
            "context": copy.deepcopy(self.context),
            "metadata": copy.deepcopy(self.metadata),
            "provenance_records": copy.deepcopy(self.provenance_records),
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> State:
        st = cls(
            state_id=str(data.get("state_id", uuid.uuid4())),
            parent_id=data.get("parent_id"),
            generation=int(data.get("generation", 0)),
            nodes={k: Node.from_dict(v) for k, v in data.get("nodes", {}).items()},
            edges=[Edge.from_dict(e) for e in data.get("edges", [])],
            hyperedges=[HyperEdge.from_dict(h) for h in data.get("hyperedges", [])],
            context=data.get("context", {}),
            metadata=data.get("metadata", {}),
            timestamp=float(data.get("timestamp", 0.0)),
        )
        st.provenance_records = data.get("provenance_records", [])
        return st
