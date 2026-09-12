"""
datasets/corporate_ownership_graph.py
=====================================
Real-World Benchmark Dataset: Multi-Jurisdictional Corporate Ownership & AML Graph.

Models an offshore beneficial ownership, trade finance, and correspondent banking network:
- Ultimate Beneficial Owner (Sanctioned entity)
- Multi-tier offshore holding companies (Cyprus, BVI, Switzerland)
- Nominee directors and shell accounts
- Correspondent US dollar clearing banks
- Triadic letters of credit facilities
"""

from __future__ import annotations
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge


def load_corporate_ownership_graph() -> State:
    """Constructs the canonical offshore ownership and trade financing graph."""
    st = State(
        context={
            "jurisdiction_set": ["CY", "VG", "CH", "US", "NL"],
            "regulatory_regime": "FATF-Recommendation-24-25",
            "compliance_flag": "PEP-UBO-Watchlist",
        }
    )

    # 1. Entities (Nodes)
    nodes = [
        ("UBO_Target_77", 125000000.0, {"role": "beneficial_owner", "pep": True, "risk": "High"}),
        ("HoldCo_Cyprus_Ltd", 85000000.0, {"role": "holding_company", "jurisdiction": "CY"}),
        ("Trading_BVI_Corp", 45000000.0, {"role": "trading_shell", "jurisdiction": "VG"}),
        ("Nominee_Services_Trust", 100000.0, {"role": "nominee_fiduciary", "jurisdiction": "CY"}),
        ("Swiss_Commodity_SA", 60000000.0, {"role": "operating_trader", "jurisdiction": "CH"}),
        ("US_Clearing_Bank", 500000000.0, {"role": "correspondent_bank", "jurisdiction": "US"}),
        ("Rotterdam_Logistics_BV", 20000000.0, {"role": "freight_carrier", "jurisdiction": "NL"}),
    ]

    for nid, val, attrs in nodes:
        st.add_node(Node(id=nid, value=val, attributes=attrs))

    # 2. Directed Ownership & Financing Relations (Edges)
    edges = [
        ("UBO_Target_77", "HoldCo_Cyprus_Ltd", "beneficially_owns_100pct", 85000000.0),
        ("HoldCo_Cyprus_Ltd", "Trading_BVI_Corp", "wholly_owns_subsidiary", 45000000.0),
        ("Nominee_Services_Trust", "Trading_BVI_Corp", "provides_nominee_director", 1.0),
        ("Trading_BVI_Corp", "Swiss_Commodity_SA", "extends_subordinated_loan", 25000000.0),
        ("Swiss_Commodity_SA", "Rotterdam_Logistics_BV", "charters_cargo_fleet", 15000000.0),
        ("Swiss_Commodity_SA", "US_Clearing_Bank", "clears_dollar_wire", 40000000.0),
        ("Trading_BVI_Corp", "US_Clearing_Bank", "maintains_treasury_account", 10000000.0),
    ]

    for src, tgt, rel, w in edges:
        st.add_edge(Edge(source_id=src, target_id=tgt, relation_type=rel, weight=w))

    # 3. Hyperedge: Triadic Letter of Credit Facility
    st.add_hyperedge(HyperEdge(
        node_ids=["Trading_BVI_Corp", "Swiss_Commodity_SA", "US_Clearing_Bank"],
        relation_type="triadic_lc_facility",
        attributes={"facility_limit": 50000000.0, "collateral_pledge": "inventory"},
    ))

    return st
