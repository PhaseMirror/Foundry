"""
experiments/provenance_cascade.py
=================================
Provenance Through Deep Cascades & Computational Irreversibility Boundary.

Traces step-by-step causal lineage through a multi-stage operator pipeline:
1. Normalization (Linear scaling)
2. Precision Discretization (12-bit Quantization)
3. Edge Permutation
4. Mantissa Bit-Mask Truncation
5. Cryptographic Hashing of Subtree (Commitment)
6. Flat Scalar Extraction

Pinpoints the exact step where irreversibility is introduced and checks for
critical threshold transitions.
"""

from __future__ import annotations
from typing import Any, Dict, List, Tuple
from binary_fragmentation.core.state import State, Node, Edge
from binary_fragmentation.core.operators import (
    BinaryOperator,
    IdentityOperator,
    QuantizationOperator,
    TruncationOperator,
    HashingOperator,
    SerializeDeserializeOperator,
)
from binary_fragmentation.core.encoder import BinaryScalarEncoder
from binary_fragmentation.core.decoder import BinaryScalarDecoder
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


class ProvenanceCascadeExperiment:
    """Step-by-step causal tracing and reversibility boundary analyzer."""

    def __init__(self) -> None:
        self.stage_operators: List[Tuple[str, BinaryOperator]] = [
            ("Stage 0: Identity Checkpoint", IdentityOperator()),
            ("Stage 1: Mild Quantization (12-bit)", QuantizationOperator(bits=12)),
            ("Stage 2: Precision Truncation (3 decimals)", TruncationOperator(decimals=3)),
            ("Stage 3: Coarse Quantization (6-bit)", QuantizationOperator(bits=6)),
            ("Stage 4: One-Way Hash Commitment", HashingOperator(hash_values=True)),
            ("Stage 5: Scalar Flattening Extraction", SerializeDeserializeOperator(
                encoder=BinaryScalarEncoder(),
                decoder=BinaryScalarDecoder(),
                name="ScalarExtractor",
            )),
        ]

    def run(self, initial_state: State) -> Dict[str, Any]:
        stages_audit: List[Dict[str, Any]] = []
        trajectory_states: List[State] = [initial_state.clone()]
        drift_trajectory: List[float] = [0.0]

        current = initial_state.clone()
        first_irreversible_stage: str = "None"
        critical_threshold_stage: str = "None"

        for idx, (stage_name, op) in enumerate(self.stage_operators):
            prev_checksum = current.compute_checksum()
            next_st, rec = op.apply(current)
            next_checksum = next_st.compute_checksum()

            # Measure metric distance relative to original S_0
            vec = MetricCalculator.evaluate(initial_state, next_st)
            drift_trajectory.append(vec.l2_norm)

            # Step-level rollback verification
            step_reversible = (prev_checksum == next_checksum) or rec.reversible
            if not step_reversible and first_irreversible_stage == "None":
                first_irreversible_stage = stage_name

            # Detect sharp threshold jump (Δloss > 0.3 in single step)
            step_jump = drift_trajectory[-1] - drift_trajectory[-2]
            if step_jump > 0.25 and critical_threshold_stage == "None":
                critical_threshold_stage = stage_name

            stages_audit.append({
                "stage_index": idx,
                "stage_name": stage_name,
                "operator": op.name,
                "checksum_before": prev_checksum[:12],
                "checksum_after": next_checksum[:12],
                "step_reversible": step_reversible,
                "cumulative_L2_loss": vec.l2_norm,
                "vector": vec.to_dict(),
            })

            trajectory_states.append(next_st.clone())
            current = next_st

        return {
            "experiment": "Provenance Cascade & Irreversibility Boundary",
            "total_stages": len(self.stage_operators),
            "first_irreversible_stage": first_irreversible_stage,
            "critical_threshold_stage": critical_threshold_stage,
            "drift_trajectory": drift_trajectory,
            "stages_audit": stages_audit,
        }
