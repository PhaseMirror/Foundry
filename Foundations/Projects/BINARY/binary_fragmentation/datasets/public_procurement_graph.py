"""
datasets/public_procurement_graph.py
====================================
Second Real-World Benchmark Dataset: Public Procurement & Collusive Subcontracting.

Models a municipal infrastructure procurement and vendor collusion network:
- Municipal Transit Authority (Procurement Issuer)
- Prime Contractor (Bid winner)
- 3 Shell Subcontractors (Pass-through entities)
- Conflict-of-Interest Official (City Procurement Board Member)
- Financial Factoring Facility (Collusive funding circle)
"""

from __future__ import annotations
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge


def load_public_procurement_graph() -> State:
    """Constructs the municipal procurement and subcontractor collusion network."""
    st = State(
        context={
            "jurisdiction": "Municipal-Infrastructure-Division",
            "regulatory_framework": "Public-Procurement-Directive-2014-24-EU",
            "tender_id": "TENDER-2026-METRO-09",
        }
    )

    # 1. Nodes (Entities)
    entities = [
        ("Transit_Authority_Public", 150000000.0, {"role": "procuring_agency", "type": "public_sector"}),
        ("Board_Member_Official_X", 180000.0, {"role": "procurement_official", "pep": True}),
        ("Prime_Contractor_Consortium", 150000000.0, {"role": "prime_contractor", "type": "general_builder"}),
        ("Subcontractor_Alpha_Shell", 45000000.0, {"role": "pass_through_sub", "type": "shell_company"}),
        ("Subcontractor_Beta_Consulting", 30000000.0, {"role": "advisory_sub", "type": "consultancy"}),
        ("Offshore_Consulting_Panama", 25000000.0, {"role": "kickback_vehicle", "type": "offshore_entity"}),
        ("Commercial_Escrow_Bank", 150000000.0, {"role": "escrow_depository", "type": "financial_institution"}),
    ]

    for nid, val, attrs in entities:
        st.add_node(Node(id=nid, value=val, attributes=attrs))

    # 2. Edges (Tender awards, subcontracts, kickbacks, familial ties)
    edges = [
        ("Transit_Authority_Public", "Prime_Contractor_Consortium", "awards_master_tender", 150000000.0),
        ("Prime_Contractor_Consortium", "Subcontractor_Alpha_Shell", "subcontracts_tunneling", 45000000.0),
        ("Prime_Contractor_Consortium", "Subcontractor_Beta_Consulting", "subcontracts_engineering", 30000000.0),
        ("Subcontractor_Alpha_Shell", "Offshore_Consulting_Panama", "transfers_consulting_fee", 25000000.0),
        ("Offshore_Consulting_Panama", "Board_Member_Official_X", "undisclosed_beneficial_trust", 5000000.0),
        ("Board_Member_Official_X", "Transit_Authority_Public", "chairs_evaluation_committee", 1.0),
        ("Prime_Contractor_Consortium", "Commercial_Escrow_Bank", "deposits_performance_bond", 15000000.0),
    ]

    for src, tgt, rel, w in edges:
        st.add_edge(Edge(source_id=src, target_id=tgt, relation_type=rel, weight=w))

    # 3. Hyperedge: Triadic Procurement Oversight Agreement
    st.add_hyperedge(HyperEdge(
        node_ids=["Transit_Authority_Public", "Prime_Contractor_Consortium", "Commercial_Escrow_Bank"],
        relation_type="triadic_escrow_oversight",
        attributes={"escrow_terms": "milestone_completion_signoff"},
    ))

    return st
