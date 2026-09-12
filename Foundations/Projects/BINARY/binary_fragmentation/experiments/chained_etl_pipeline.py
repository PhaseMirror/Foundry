"""
experiments/chained_etl_pipeline.py
===================================
Multi-Hop Chained Enterprise ETL Pipeline Simulation.

Simulates the compound degradation across 5 realistic enterprise hops:
Hop 0: Canonical Graph State (Source OLTP)
Hop 1: SQL View Projection (Partial field select)
Hop 2: Flat CSV Dump (Edge list stripped)
Hop 3: External Key Join (Foreign metadata merged, lineage lost)
Hop 4: GroupBy Rollup Aggregation (Entities collapsed)
Hop 5: Columnar Parquet Store & Reload (Data Mart ingestion)
"""

from __future__ import annotations
import copy
from typing import Any, Dict, List, Tuple

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


def create_enterprise_supply_chain_state() -> State:
    """Constructs a multi-tier supply chain and credit financing graph."""
    st = State(context={"compliance": "SOX-404", "currency": "USD", "risk_model": "Sedona-Tier1"})

    # Nodes
    st.add_node(Node(id="Supplier_Alpha", value=150000.0, attributes={"country": "DE", "tier": 1}))
    st.add_node(Node(id="Manufacturer_Beta", value=500000.0, attributes={"country": "US", "tier": 2}))
    st.add_node(Node(id="Distributor_Gamma", value=750000.0, attributes={"country": "US", "tier": 3}))
    st.add_node(Node(id="Bank_Omega", value=1000000.0, attributes={"country": "UK", "role": "Factoring Bank"}))

    # Edges
    st.add_edge(Edge(source_id="Supplier_Alpha", target_id="Manufacturer_Beta", relation_type="ships_parts_to", weight=150000.0))
    st.add_edge(Edge(source_id="Manufacturer_Beta", target_id="Distributor_Gamma", relation_type="delivers_units_to", weight=500000.0))
    st.add_edge(Edge(source_id="Bank_Omega", target_id="Supplier_Alpha", relation_type="extends_credit_to", weight=100000.0))
    st.add_edge(Edge(source_id="Distributor_Gamma", target_id="Bank_Omega", relation_type="pledges_receivables_to", weight=500000.0))

    # Hyperedge: Multi-party triadic factoring agreement
    st.add_hyperedge(HyperEdge(
        node_ids=["Supplier_Alpha", "Distributor_Gamma", "Bank_Omega"],
        relation_type="triadic_factoring_facility",
        attributes={"facility_limit": 750000.0},
    ))

    return st


class ChainedEnterpriseETLExperiment:
    """Traces information degradation across a 5-hop enterprise data pipeline."""

    def run(self) -> Dict[str, Any]:
        s0 = create_enterprise_supply_chain_state()
        hops_audit: List[Dict[str, Any]] = []
        vectors: List[FragmentationVector] = []

        # --- Hop 0: Source State ---
        vec0 = MetricCalculator.evaluate(s0, s0)
        hops_audit.append({
            "hop": 0,
            "name": "Source OLTP Graph",
            "nodes": len(s0.nodes),
            "edges": len(s0.edges),
            "hyperedges": len(s0.hyperedges),
            "vector": vec0.to_dict(),
        })

        # --- Hop 1: SQL View Projection (Drops hyperedges, keeps edges) ---
        s1 = s0.clone()
        s1.generation = 1
        s1.hyperedges = []  # Relational DB views rarely model hypergraphs
        vec1 = MetricCalculator.evaluate(s0, s1)
        hops_audit.append({
            "hop": 1,
            "name": "SQL View Projection",
            "nodes": len(s1.nodes),
            "edges": len(s1.edges),
            "hyperedges": len(s1.hyperedges),
            "vector": vec1.to_dict(),
        })

        # --- Hop 2: Flat CSV Export (Edge list stripped, context stripped) ---
        s2 = State(
            generation=2,
            nodes={k: Node.from_dict(v.to_dict()) for k, v in s1.nodes.items()},
            edges=[],
            hyperedges=[],
            context={},
        )
        vec2 = MetricCalculator.evaluate(s0, s2)
        hops_audit.append({
            "hop": 2,
            "name": "Flat CSV Dump",
            "nodes": len(s2.nodes),
            "edges": len(s2.edges),
            "hyperedges": 0,
            "vector": vec2.to_dict(),
        })

        # --- Hop 3: External Join (Attributes altered, lineage severed) ---
        s3 = s2.clone()
        s3.generation = 3
        for nid, n in s3.nodes.items():
            n.attributes["external_credit_score"] = 720
            n.provenance_tag = "joined_dw"
        vec3 = MetricCalculator.evaluate(s0, s3)
        hops_audit.append({
            "hop": 3,
            "name": "External Join & Merge",
            "nodes": len(s3.nodes),
            "edges": 0,
            "hyperedges": 0,
            "vector": vec3.to_dict(),
        })

        # --- Hop 4: GroupBy Aggregation (Supplier + Manufacturer collapsed by country) ---
        s4 = State(generation=4)
        # US group
        s4.add_node(Node(id="US_Entities", value=1250000.0, attributes={"country": "US"}))
        s4.add_node(Node(id="DE_Entities", value=150000.0, attributes={"country": "DE"}))
        s4.add_node(Node(id="UK_Entities", value=1000000.0, attributes={"country": "UK"}))
        vec4 = MetricCalculator.evaluate(s0, s4)
        hops_audit.append({
            "hop": 4,
            "name": "GroupBy Country Aggregation",
            "nodes": len(s4.nodes),
            "edges": 0,
            "hyperedges": 0,
            "vector": vec4.to_dict(),
        })

        # --- Hop 5: Data Mart Reload ---
        s5 = s4.clone()
        s5.generation = 5
        vec5 = MetricCalculator.evaluate(s0, s5)
        hops_audit.append({
            "hop": 5,
            "name": "Data Mart Ingestion",
            "nodes": len(s5.nodes),
            "edges": 0,
            "hyperedges": 0,
            "vector": vec5.to_dict(),
        })

        return {
            "experiment": "Chained Multi-Hop Enterprise ETL Pipeline",
            "total_hops": 5,
            "final_vector": vec5.to_dict(),
            "hops_audit": hops_audit,
        }
