"""
experiments/etl_metadata_stripping.py
=====================================
The "Metadata Stripping / ETL Projection" Experiment.

Simulates the standard enterprise data engineering pipeline:
Relational/Graph Database -> Flat Tabular/CSV Export -> Numeric Aggregation -> Downstream Service.

Demonstrates that the breakdown is an ARCHITECTURAL decision (assuming scalars are sufficient)
rather than an inherent defect in binary physics.
"""

from __future__ import annotations
from typing import Any, Dict, List
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.metrics.vector import MetricCalculator


class ETLMetadataStrippingExperiment:
    """Simulates enterprise CSV/tabular extraction from rich graph states."""

    def run(self, initial_state: State) -> Dict[str, Any]:
        # Step 1: Extract flat tabular rows (ignoring edges, hyperedges, and context)
        tabular_rows: List[Dict[str, Any]] = []
        for nid, node in sorted(initial_state.nodes.items()):
            row = {
                "entity_id": nid,
                "numeric_value": float(node.value) if isinstance(node.value, (int, float)) else 0.0,
            }
            tabular_rows.append(row)

        # Step 2: Simulate downstream aggregation / transformation on flat rows
        # E.g. sort by value, compute totals
        sorted_rows = sorted(tabular_rows, key=lambda r: r["numeric_value"])

        # Step 3: Reconstruct State from tabular export
        reconstructed_state = State()
        for r in sorted_rows:
            reconstructed_state.add_node(Node(id=r["entity_id"], value=r["numeric_value"]))

        # Step 4: Evaluate 8D Fragmentation Vector
        vector = MetricCalculator.evaluate(initial_state, reconstructed_state)

        return {
            "experiment": "ETL Metadata Stripping & Tabular Projection",
            "source_nodes": len(initial_state.nodes),
            "source_edges": len(initial_state.edges),
            "source_hyperedges": len(initial_state.hyperedges),
            "source_context_keys": len(initial_state.context),
            "tabular_rows_exported": len(tabular_rows),
            "metrics": {
                "value_loss_Fv": vector.F_v,
                "relational_loss_Fr": vector.F_r,
                "structural_loss_Fs": vector.F_s,
                "context_loss_Fc": vector.F_c,
                "provenance_loss_Fp": vector.F_p,
                "overall_L2_loss": vector.l2_norm,
                "vector": vector.to_dict(),
            },
            "findings": (
                f"Value integrity is {vector.value_preservation_pct:.1f}%, but relational integrity is "
                f"{vector.relational_preservation_pct:.1f}% and context loss is {vector.F_c * 100:.1f}%. "
                "Confirms the architectural thesis: tabular scalar projections strip semantic causality."
            ),
        }
