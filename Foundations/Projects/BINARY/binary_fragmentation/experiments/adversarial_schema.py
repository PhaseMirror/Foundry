"""
experiments/adversarial_schema.py
=================================
Challenging the Fixed-Point Attractor: Adversarial and Structural Schema Failures.

Investigates:
1. Schema Projection (selective edge type filtering / permission views)
2. Edge Weight Quantization (discretizing continuous coupling strengths)
3. Node-Only Serialization (document store / entity-only serialization)
4. Field & Provenance Pruning (audit metadata stripping)
"""

from __future__ import annotations
import copy
from typing import Any, Dict, List, Set, Tuple

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


class SchemaProjectionOperator(BinaryOperator):
    """
    Simulates role-based access control (RBAC), permission views, or microservice
    API projections that selectively filter and discard specific edge relation types.
    """

    def __init__(self, allowed_relation_types: Set[str]):
        self.allowed_relation_types = allowed_relation_types
        super().__init__(
            name="SchemaProjectionOperator",
            parameters={"allowed_relation_types": list(allowed_relation_types)},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        # Filter edges by allowed types
        retained_edges = [
            e for e in new_state.edges if e.relation_type in self.allowed_relation_types
        ]
        dropped_edges = len(new_state.edges) - len(retained_edges)
        new_state.edges = retained_edges

        # Filter hyperedges
        retained_hypers = [
            h for h in new_state.hyperedges if h.relation_type in self.allowed_relation_types
        ]
        new_state.hyperedges = retained_hypers

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"dropped_edges_count": dropped_edges},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=(dropped_edges == 0),
            reversibility_notes=f"Filtered {dropped_edges} edges not in allowed schema projection.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class EdgeWeightQuantizationOperator(BinaryOperator):
    """
    Quantizes continuous relational edge weights into low-precision discrete bins
    (e.g., 2-bit [0, 0.33, 0.66, 1.0] or 1-bit boolean [0, 1]).
    Simulates systems that lose relationship strength / capacity nuance.
    """

    def __init__(self, levels: int = 4):
        self.levels = levels
        super().__init__(
            name="EdgeWeightQuantizationOperator",
            parameters={"levels": levels},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        step = 1.0 / max(self.levels - 1, 1)
        max_deviation = 0.0

        for edge in new_state.edges:
            orig_w = edge.weight
            quant_w = round(orig_w / step) * step
            dev = abs(quant_w - orig_w)
            if dev > max_deviation:
                max_deviation = dev
            edge.weight = quant_w

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"max_weight_distortion": max_deviation},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=(max_deviation == 0.0),
            reversibility_notes=f"Edge weights quantized to {self.levels} discrete levels.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class NodeOnlySerializationOperator(BinaryOperator):
    """
    Simulates document stores / NoSQL key-value stores where nodes and their
    immediate properties are serialized, but global graph topology is omitted.
    """

    def __init__(self) -> None:
        super().__init__(name="NodeOnlySerializationOperator")

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = State(
            state_id=state.state_id,
            parent_id=state.parent_id,
            generation=state.generation + 1,
            nodes={k: Node.from_dict(v.to_dict()) for k, v in state.nodes.items()},
            edges=[],  # Edges stripped by document store design
            hyperedges=[],
            context=copy.deepcopy(state.context),
            metadata=copy.deepcopy(state.metadata),
        )

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            info_removed={"edges_stripped": len(state.edges), "hypers_stripped": len(state.hyperedges)},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes="Node-only document serialization dropped edge graph.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class FieldPruningOperator(BinaryOperator):
    """
    Simulates payload minification and telemetry stripping by deleting
    provenance histories and contextual metadata before transmission.
    """

    def __init__(self, strip_provenance: bool = True, strip_context: bool = True):
        self.strip_provenance = strip_provenance
        self.strip_context = strip_context
        super().__init__(
            name="FieldPruningOperator",
            parameters={"strip_provenance": strip_provenance, "strip_context": strip_context},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = None if self.strip_provenance else state.state_id

        if self.strip_provenance:
            new_state.provenance_records = []
        if self.strip_context:
            new_state.context = {}

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=None,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"provenance_stripped": self.strip_provenance, "context_stripped": self.strip_context},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes="Field pruning stripped causal history and context.",
        )
        if not self.strip_provenance:
            new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class AdversarialSchemaExperiment:
    """Executes all adversarial and structural schema degradation experiments."""

    def run(self, initial_state: State) -> Dict[str, Any]:
        # 1. Schema Projection (Keep only 1 of 4 edge types)
        sample_edge_types = list(set(e.relation_type for e in initial_state.edges))
        retained_type = sample_edge_types[0] if sample_edge_types else "links"
        proj_op = SchemaProjectionOperator(allowed_relation_types={retained_type})
        st_proj, _ = proj_op.apply(initial_state)
        vec_proj = MetricCalculator.evaluate(initial_state, st_proj)

        # 2. Edge Weight Quantization (2-bit discretization)
        quant_op = EdgeWeightQuantizationOperator(levels=3)
        st_quant, _ = quant_op.apply(initial_state)
        vec_quant = MetricCalculator.evaluate(initial_state, st_quant)

        # 3. Node-Only Serialization (Document Store)
        node_op = NodeOnlySerializationOperator()
        st_node, _ = node_op.apply(initial_state)
        vec_node = MetricCalculator.evaluate(initial_state, st_node)

        # 4. Field & Provenance Pruning
        prune_op = FieldPruningOperator(strip_provenance=True, strip_context=True)
        st_prune, _ = prune_op.apply(initial_state)
        vec_prune = MetricCalculator.evaluate(initial_state, st_prune)

        return {
            "experiment": "Challenging the Fixed-Point Attractor (Adversarial Schema)",
            "schema_projection": {
                "allowed_type": retained_type,
                "edges_retained": len(st_proj.edges),
                "edges_lost": len(initial_state.edges) - len(st_proj.edges),
                "relational_loss_Fr": vec_proj.F_r,
                "vector": vec_proj.to_dict(),
            },
            "edge_weight_quantization": {
                "levels": 3,
                "relational_loss_Fr": vec_quant.F_r,
                "vector": vec_quant.to_dict(),
            },
            "node_only_serialization": {
                "description": "Document-store entity extraction (all edges dropped)",
                "value_loss_Fv": vec_node.F_v,
                "relational_loss_Fr": vec_node.F_r,
                "vector": vec_node.to_dict(),
            },
            "field_pruning": {
                "provenance_loss_Fp": vec_prune.F_p,
                "context_loss_Fc": vec_prune.F_c,
                "vector": vec_prune.to_dict(),
            },
        }
