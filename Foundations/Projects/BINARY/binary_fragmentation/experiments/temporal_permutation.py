"""
experiments/temporal_permutation.py
===================================
Adversarial Temporal Permutation & Event Sequence De-ordering.

Investigates:
When a temporal event log or causal workflow is sorted or clustered by
non-temporal attributes (e.g., entity name, value magnitude, hash), does the
system suffer chronological inversion (F_t) and causal confusion?
"""

from __future__ import annotations
import random
from typing import Any, Dict, List, Tuple

from binary_fragmentation.core.state import State, Node, Edge
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


def create_causal_event_state() -> State:
    """Generates a strictly ordered sequence of causal lifecycle events."""
    st = State(context={"workflow": "Settlement & Clearing Pipeline"})
    
    # 6 sequential events with strictly increasing timestamps
    events = [
        ("evt_1_order_placed", 100.0, 10.0),
        ("evt_2_kyc_verified", 250.0, 20.0),
        ("evt_3_funds_locked", 1000.0, 30.0),
        ("evt_4_match_cleared", 1000.0, 40.0),
        ("evt_5_asset_transferred", 1000.0, 50.0),
        ("evt_6_settlement_sealed", 1000.0, 60.0),
    ]

    for eid, val, t in events:
        st.add_node(Node(id=eid, value=val, created_at=t))

    for i in range(len(events) - 1):
        st.add_edge(Edge(
            source_id=events[i][0],
            target_id=events[i + 1][0],
            relation_type="precedes",
            weight=1.0,
        ))

    return st


class NonTemporalSortOperator(BinaryOperator):
    """
    Simulates database or log aggregator sorting events by value magnitude or hash,
    destroying the native creation timestamp sequence.
    """

    def __init__(self, sort_by: str = "value_descending"):
        self.sort_by = sort_by
        super().__init__(name="NonTemporalSortOperator", parameters={"sort_by": sort_by})

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        # Sort nodes by value descending
        sorted_nodes = sorted(
            new_state.nodes.values(),
            key=lambda n: (float(n.value) if isinstance(n.value, (int, float)) else 0.0),
            reverse=True,
        )

        # Re-assign timestamps to reflect the new arbitrary index ordering
        for idx, node in enumerate(sorted_nodes):
            node.created_at = float(idx * 10.0)

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"original_timestamps": True},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=False,
            reversibility_notes="Sorted by non-temporal attribute; chronological timeline inverted.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class TemporalPermutationExperiment:
    """Evaluates temporal order loss under non-temporal sorting."""

    def run(self) -> Dict[str, Any]:
        s0 = create_causal_event_state()
        sort_op = NonTemporalSortOperator(sort_by="value_descending")
        s_perm, _ = sort_op.apply(s0)

        vec = MetricCalculator.evaluate(s0, s_perm)

        return {
            "experiment": "Adversarial Temporal Permutation (Kendall Tau Inversion)",
            "initial_events": len(s0.nodes),
            "temporal_loss_Ft": vec.F_t,
            "value_loss_Fv": vec.F_v,
            "relational_loss_Fr": vec.F_r,
            "overall_loss_L2": vec.l2_norm,
            "vector": vec.to_dict(),
            "interpretation": (
                f"Chronological inversion loss is F_t = {vec.F_t:.4f} ({vec.F_t * 100:.1f}% inverted pairs). "
                "Values and edges remained intact, but causal workflow precedence was scrambled."
            ),
        }
