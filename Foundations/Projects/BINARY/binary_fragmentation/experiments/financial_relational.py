"""
experiments/financial_relational.py
===================================
Section 8 Crucial Experiment: Financial Relational Fragmentation.

State:
Person A
    │
    ├── owns → Asset X ($100,000)
    │
    ├── owes → Institution B ($25,000)
    │
    └── contracted → Agreement C (Term: 36 mo)

Pipeline:
1. Generate relational financial graph
2. Apply binary flattening (serialization, splitting, sorting, aggregation)
3. Measure:
   - Value integrity (I_value = 100% / F_v = 0.0)
   - Relational integrity (I_relation < 100% / F_r >> 0.0)
"""

from __future__ import annotations
from typing import Any, Dict
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.encoder import BinaryScalarEncoder, BinaryRelationalEncoder
from binary_fragmentation.core.decoder import BinaryScalarDecoder, BinaryRelationalDecoder
from binary_fragmentation.core.operators import SerializeDeserializeOperator
from binary_fragmentation.metrics.vector import MetricCalculator


def create_financial_state() -> State:
    """Constructs the canonical Section 8 financial relationship state."""
    state = State(
        context={
            "jurisdiction": "Delaware",
            "regulatory_framework": "UCC-Article-9",
            "audit_standard": "GAAP",
        }
    )

    # Nodes
    state.add_node(Node(id="Person_A", value={"name": "Alice Corp", "tax_id": "99-1234567"}))
    state.add_node(Node(id="Asset_X", value=100000.0, attributes={"type": "Commercial Real Estate"}))
    state.add_node(Node(id="Institution_B", value=25000.0, attributes={"type": "Senior Creditor Bank"}))
    state.add_node(Node(id="Agreement_C", value=36, attributes={"type": "Collateral Pledge Agreement"}))

    # Directed Relational Edges
    state.add_edge(Edge(source_id="Person_A", target_id="Asset_X", relation_type="owns", weight=1.0))
    state.add_edge(Edge(source_id="Person_A", target_id="Institution_B", relation_type="owes", weight=25000.0))
    state.add_edge(Edge(source_id="Person_A", target_id="Agreement_C", relation_type="contracted", weight=1.0))

    # Hyperedge: Multi-party securitization binding Person A, Asset X, and Institution B
    state.add_hyperedge(HyperEdge(
        node_ids=["Person_A", "Asset_X", "Institution_B"],
        relation_type="perfected_security_interest",
        attributes={"priority": "first_lien"}
    ))

    return state


class FinancialRelationalExperiment:
    """Executes the Section 8 Crucial Experiment."""

    def run(self) -> Dict[str, Any]:
        s0 = create_financial_state()

        # Pipeline 1: Binary Scalar Flattening (Traditional Flat Ledger)
        scalar_op = SerializeDeserializeOperator(
            encoder=BinaryScalarEncoder(),
            decoder=BinaryScalarDecoder(),
            name="FlatBinaryLedgerOperator",
        )
        s_flat, _ = scalar_op.apply(s0)
        vec_flat = MetricCalculator.evaluate(s0, s_flat)

        # Pipeline 2: Relational Preservation (Rich Multidimensional Ledger)
        rel_op = SerializeDeserializeOperator(
            encoder=BinaryRelationalEncoder(),
            decoder=BinaryRelationalDecoder(),
            name="RelationalMultiplicityLedgerOperator",
        )
        s_rel, _ = rel_op.apply(s0)
        vec_rel = MetricCalculator.evaluate(s0, s_rel)

        # Verification of Crucial Theorem: Value Preserved vs Relational Dissolution
        # When flattened, numerical node values survive, but the graph relations dissolve.
        return {
            "experiment": "Section 8 Financial Relational Experiment",
            "initial_state_summary": {
                "nodes": len(s0.nodes),
                "edges": len(s0.edges),
                "hyperedges": len(s0.hyperedges),
                "relations": [(e.source_id, e.relation_type, e.target_id) for e in s0.edges],
            },
            "flat_binary_result": {
                "description": "Flat binary storage: values extracted, relations severed.",
                "value_loss_Fv": vec_flat.F_v,
                "relational_loss_Fr": vec_flat.F_r,
                "structural_loss_Fs": vec_flat.F_s,
                "preserves_values": (vec_flat.F_v < 0.2),
                "loses_relations": (vec_flat.F_r > 0.8),
                "vector": vec_flat.to_dict(),
            },
            "relational_result": {
                "description": "Relational binary storage: full topology and metadata preserved.",
                "value_loss_Fv": vec_rel.F_v,
                "relational_loss_Fr": vec_rel.F_r,
                "structural_loss_Fs": vec_rel.F_s,
                "vector": vec_rel.to_dict(),
            },
            "crucial_hypothesis_confirmed": (
                (vec_flat.F_v < 0.3) and (vec_flat.F_r > 0.7) and (vec_rel.F_r < 0.05)
            ),
        }
