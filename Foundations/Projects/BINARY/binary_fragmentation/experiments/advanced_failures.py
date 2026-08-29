"""
experiments/advanced_failures.py
================================
Advanced Structural Failure Modes & Frontier Stress Experiments.

Implements:
1. Schema Evolution (API versioning, property rename, dropped relationship types)
2. Entity Resolution & Merge Collapse (Deduplication / identity collapse)
3. Graph Rewriting & Contract Consolidation (Semantic equivalence vs structural loss)
4. Differential Privacy & Edge Perturbation (Privacy budget ε vs relational fidelity)
5. Graph Sampling & Sketching (Subsampling rate ρ ∈ [0.1, 1.0])
6. Practical vs Cryptographic Irreversibility (Key-dependent encryption vs hash destruction)
"""

from __future__ import annotations
import copy
import math
import random
import struct
from typing import Any, Dict, List, Optional, Set, Tuple

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


# --------------------------------------------------------------------------- #
# 1. Schema Evolution Operator
# --------------------------------------------------------------------------- #

class SchemaEvolutionOperator(BinaryOperator):
    """
    Simulates database schema migrations or API version mismatches:
    - Renames certain edge types (e.g. 'ships_parts_to' -> 'delivers_to')
    - Drops deprecated relationship fields without updating consumers
    - Mutates attribute keys (e.g. 'tax_id' -> 'tin')
    """

    def __init__(
        self,
        edge_renames: Optional[Dict[str, str]] = None,
        dropped_edge_types: Optional[Set[str]] = None,
        attribute_renames: Optional[Dict[str, str]] = None,
    ):
        self.edge_renames = edge_renames or {"ships_parts_to": "supplies"}
        self.dropped_edge_types = dropped_edge_types or {"pledges_receivables_to"}
        self.attribute_renames = attribute_renames or {"country": "geo_code"}
        super().__init__(
            name="SchemaEvolutionOperator",
            parameters={
                "edge_renames": self.edge_renames,
                "dropped_edge_types": list(self.dropped_edge_types),
                "attribute_renames": self.attribute_renames,
            },
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        # Mutate nodes
        for node in new_state.nodes.values():
            new_attrs = {}
            for k, v in node.attributes.items():
                new_key = self.attribute_renames.get(k, k)
                new_attrs[new_key] = v
            node.attributes = new_attrs

        # Mutate / filter edges
        retained_edges = []
        for edge in new_state.edges:
            if edge.relation_type in self.dropped_edge_types:
                continue
            new_type = self.edge_renames.get(edge.relation_type, edge.relation_type)
            edge.relation_type = new_type
            retained_edges.append(edge)

        new_state.edges = retained_edges

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"dropped_edges": len(state.edges) - len(retained_edges)},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes="Schema evolution caused field renaming and dropped edge types.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


# --------------------------------------------------------------------------- #
# 2. Entity Resolution / Merge Collapse Operator
# --------------------------------------------------------------------------- #

class EntityResolutionOperator(BinaryOperator):
    """
    Simulates entity deduplication / record linkage in data warehouses:
    Merges entities matching similarity criteria into single canonical nodes,
    collapsing distinct node IDs and re-routing incident edges.
    """

    def __init__(self, cluster_criterion: str = "same_role"):
        self.cluster_criterion = cluster_criterion
        super().__init__(
            name="EntityResolutionOperator",
            parameters={"cluster_criterion": cluster_criterion},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = State(
            generation=state.generation + 1,
            parent_id=state.state_id,
            context=copy.deepcopy(state.context),
        )

        # Cluster nodes by attribute or prefix (e.g. role)
        node_map: Dict[str, str] = {}
        clusters: Dict[str, List[Node]] = {}

        for nid, node in sorted(state.nodes.items()):
            group_key = node.attributes.get("role", "default")
            if group_key not in clusters:
                clusters[group_key] = []
            clusters[group_key].append(node)

        # Create collapsed canonical nodes
        for group_key, nodes in clusters.items():
            canonical_id = f"Canonical_{group_key}_{nodes[0].id}"
            combined_val = sum(float(n.value) for n in nodes if isinstance(n.value, (int, float)))
            new_state.add_node(Node(
                id=canonical_id,
                value=combined_val,
                attributes={"merged_count": len(nodes), "original_ids": [n.id for n in nodes]},
            ))
            for n in nodes:
                node_map[n.id] = canonical_id

        # Re-route edges between canonical nodes (collapsing self-loops / duplicates)
        seen_edges: Set[Tuple[str, str, str]] = set()
        for edge in state.edges:
            src_c = node_map.get(edge.source_id, edge.source_id)
            tgt_c = node_map.get(edge.target_id, edge.target_id)
            if src_c != tgt_c:
                key = (src_c, tgt_c, edge.relation_type)
                if key not in seen_edges:
                    seen_edges.add(key)
                    new_state.add_edge(Edge(source_id=src_c, target_id=tgt_c, relation_type=edge.relation_type, weight=edge.weight))

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"nodes_collapsed": len(state.nodes) - len(new_state.nodes)},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes="Entity deduplication collapsed distinct node identities.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


# --------------------------------------------------------------------------- #
# 3. Graph Rewriting & Contract Consolidation Operator
# --------------------------------------------------------------------------- #

class GraphRewritingOperator(BinaryOperator):
    """
    Simulates legal/business contract consolidation or graph rewriting rules:
    Replaces multi-edge subgraphs (e.g. Sub-Contract A + Sub-Contract B)
    with a single synthetic Master Agreement edge.
    Preserves net semantic value, but alters topological structure.
    """

    def __init__(self, target_relation: str = "transmits_to", master_relation: str = "master_transfer"):
        self.target_relation = target_relation
        self.master_relation = master_relation
        super().__init__(
            name="GraphRewritingOperator",
            parameters={"target": target_relation, "master": master_relation},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        # Consolidate target edges
        matching_edges = [e for e in new_state.edges if e.relation_type == self.target_relation]
        other_edges = [e for e in new_state.edges if e.relation_type != self.target_relation]

        if len(matching_edges) >= 2:
            # Replace with a single synthetic edge spanning source of first to target of last
            src = matching_edges[0].source_id
            tgt = matching_edges[-1].target_id
            combined_w = sum(e.weight for e in matching_edges)
            new_state.edges = other_edges + [
                Edge(source_id=src, target_id=tgt, relation_type=self.master_relation, weight=combined_w)
            ]

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"consolidated_edges_count": len(matching_edges)},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes="Graph rewriting rule consolidated subgraphs into master relation.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


# --------------------------------------------------------------------------- #
# 4. Differential Privacy / Edge Perturbation Operator
# --------------------------------------------------------------------------- #

class DifferentialPrivacyEdgePerturbator(BinaryOperator):
    """
    Simulates graph privacy perturbation (Randomized Response on adjacency matrix):
    With probability p = 1 / (1 + e^ε), flips edge presence to protect privacy.
    """

    def __init__(self, epsilon: float = 1.0, seed: int = 42):
        self.epsilon = epsilon
        self.flip_probability = 1.0 / (1.0 + math.exp(epsilon))
        self.seed = seed
        super().__init__(
            name="DifferentialPrivacyEdgePerturbator",
            parameters={"epsilon": epsilon, "flip_probability": self.flip_probability},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        rng = random.Random(self.seed + state.generation)
        node_ids = sorted(new_state.nodes.keys())
        existing_edges = {(e.source_id, e.target_id): e for e in new_state.edges}

        new_edges = []
        # Perturb existing edges (deletion probability p)
        for (u, v), e in existing_edges.items():
            if rng.random() > self.flip_probability:
                new_edges.append(e)  # Keep edge

        # Add spurious noise edges (addition probability p * 0.1)
        for i in range(len(node_ids)):
            for j in range(i + 1, len(node_ids)):
                u, v = node_ids[i], node_ids[j]
                if (u, v) not in existing_edges and rng.random() < (self.flip_probability * 0.1):
                    new_edges.append(Edge(source_id=u, target_id=v, relation_type="noisy_dp_link", weight=1.0))

        new_state.edges = new_edges

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"dp_epsilon": self.epsilon, "perturbed_edges": True},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes=f"Differential privacy randomized response applied with ε={self.epsilon}.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


# --------------------------------------------------------------------------- #
# 5. Graph Sampling / Sketching Operator
# --------------------------------------------------------------------------- #

class GraphSubsamplingOperator(BinaryOperator):
    """
    Subsamples a graph at retention rate ρ ∈ (0.0, 1.0].
    Simulates graph sketching, telemetry decimation, or analytics sampling.
    """

    def __init__(self, sampling_rate: float = 0.5, seed: int = 42):
        self.sampling_rate = sampling_rate
        self.seed = seed
        super().__init__(
            name="GraphSubsamplingOperator",
            parameters={"sampling_rate": sampling_rate},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = State(
            generation=state.generation + 1,
            parent_id=state.state_id,
            context=copy.deepcopy(state.context),
        )

        rng = random.Random(self.seed + state.generation)
        retained_nodes = set()

        for nid, node in sorted(state.nodes.items()):
            if rng.random() < self.sampling_rate or len(retained_nodes) == 0:
                retained_nodes.add(nid)
                new_state.add_node(Node.from_dict(node.to_dict()))

        for edge in state.edges:
            if edge.source_id in retained_nodes and edge.target_id in retained_nodes:
                new_state.add_edge(Edge.from_dict(edge.to_dict()))

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"sampling_rate": self.sampling_rate, "nodes_dropped": len(state.nodes) - len(new_state.nodes)},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes=f"Graph subsampled at rate ρ={self.sampling_rate:.2f}.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


# --------------------------------------------------------------------------- #
# 6. Practical vs Cryptographic Irreversibility Operator
# --------------------------------------------------------------------------- #

class KeyDependentEncryptionOperator(BinaryOperator):
    """
    Simulates symmetric payload encryption with an external key.
    - If key is retained: 100% reversible (L2 loss = 0.0).
    - If key is lost / purged: practically irreversible (L2 loss = 1.0).
    """

    def __init__(self, key: int = 0x5A5A5A5A, simulate_key_loss: bool = False):
        self.key = key
        self.simulate_key_loss = simulate_key_loss
        super().__init__(
            name="KeyDependentEncryptionOperator",
            parameters={"key_present": not simulate_key_loss},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        if self.simulate_key_loss:
            # Key lost: payload cannot be decrypted; ciphertext appears as random bits
            for node in new_state.nodes.values():
                node.value = 0.0  # Decryption failure / inaccessible
            new_state.edges = []
            new_state.hyperedges = []
            new_state.context = {}

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"key_lost": self.simulate_key_loss},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=(not self.simulate_key_loss),
            reversibility_notes="Key retained (lossless)" if not self.simulate_key_loss else "Key lost (practical irreversibility).",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


# --------------------------------------------------------------------------- #
# Comprehensive Frontier Experiment Suite
# --------------------------------------------------------------------------- #

class AdvancedFailuresExperimentSuite:
    """Executes the complete battery of frontier structural failure experiments."""

    def run(self, initial_state: State) -> Dict[str, Any]:
        results: Dict[str, Any] = {}

        # 1. Schema Evolution
        se_op = SchemaEvolutionOperator()
        st_se, _ = se_op.apply(initial_state)
        results["schema_evolution"] = {
            "description": "API Versioning & Field Renaming Mismatch",
            "vector": MetricCalculator.evaluate(initial_state, st_se).to_dict(),
        }

        # 2. Entity Resolution
        er_op = EntityResolutionOperator()
        st_er, _ = er_op.apply(initial_state)
        results["entity_resolution"] = {
            "description": "Entity Deduplication & Cluster Collapse",
            "nodes_before": len(initial_state.nodes),
            "nodes_after": len(st_er.nodes),
            "identity_loss_Fi": MetricCalculator.evaluate(initial_state, st_er).F_i,
            "vector": MetricCalculator.evaluate(initial_state, st_er).to_dict(),
        }

        # 3. Graph Rewriting
        gr_op = GraphRewritingOperator()
        st_gr, _ = gr_op.apply(initial_state)
        results["graph_rewriting"] = {
            "description": "Rule-Based Contract Consolidation",
            "edges_before": len(initial_state.edges),
            "edges_after": len(st_gr.edges),
            "relational_loss_Fr": MetricCalculator.evaluate(initial_state, st_gr).F_r,
            "vector": MetricCalculator.evaluate(initial_state, st_gr).to_dict(),
        }

        # 4. Differential Privacy Edge Perturbation (ε sweep)
        dp_sweep = []
        for eps in [0.5, 1.0, 2.0, 5.0]:
            dp_op = DifferentialPrivacyEdgePerturbator(epsilon=eps)
            st_dp, _ = dp_op.apply(initial_state)
            vec_dp = MetricCalculator.evaluate(initial_state, st_dp)
            dp_sweep.append({
                "epsilon": eps,
                "relational_loss_Fr": vec_dp.F_r,
                "overall_L2_loss": vec_dp.l2_norm,
            })
        results["differential_privacy_sweep"] = dp_sweep

        # 5. Graph Subsampling (ρ sweep)
        sampling_sweep = []
        for rho in [0.25, 0.50, 0.75, 1.00]:
            samp_op = GraphSubsamplingOperator(sampling_rate=rho)
            st_samp, _ = samp_op.apply(initial_state)
            vec_samp = MetricCalculator.evaluate(initial_state, st_samp)
            sampling_sweep.append({
                "sampling_rate_rho": rho,
                "nodes_retained": len(st_samp.nodes),
                "relational_loss_Fr": vec_samp.F_r,
                "overall_L2_loss": vec_samp.l2_norm,
            })
        results["sampling_sweep"] = sampling_sweep

        # 6. Practical vs Cryptographic Irreversibility
        enc_with_key = KeyDependentEncryptionOperator(simulate_key_loss=False)
        st_enc_ok, _ = enc_with_key.apply(initial_state)
        enc_lost_key = KeyDependentEncryptionOperator(simulate_key_loss=True)
        st_enc_lost, _ = enc_lost_key.apply(initial_state)

        results["practical_irreversibility"] = {
            "with_key_reversibility_Fq": MetricCalculator.evaluate(initial_state, st_enc_ok).F_q,
            "lost_key_L2_loss": MetricCalculator.evaluate(initial_state, st_enc_lost).l2_norm,
        }

        return {
            "experiment": "Advanced Structural Failure Modes & Frontier Suite",
            "results": results,
        }
