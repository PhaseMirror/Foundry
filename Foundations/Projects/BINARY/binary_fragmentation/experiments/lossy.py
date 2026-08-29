"""
experiments/lossy.py
====================
Mode B — Lossy Binary Transformation Experiment.
Applies quantization, precision truncation, and scalar flattening.
"""

from __future__ import annotations
from typing import Any, Dict, List
from binary_fragmentation.core.state import State
from binary_fragmentation.core.operators import (
    BinaryOperator,
    QuantizationOperator,
    TruncationOperator,
    SerializeDeserializeOperator,
    CascadeOperator,
)
from binary_fragmentation.core.encoder import BinaryScalarEncoder
from binary_fragmentation.core.decoder import BinaryScalarDecoder
from binary_fragmentation.metrics.vector import MetricCalculator


class LossyBinaryExperiment:
    """Mode B: Controlled Lossy Binary Transformations."""

    def __init__(self, quant_bits: int = 4, truncation_decimals: int = 2):
        self.quant_op = QuantizationOperator(bits=quant_bits)
        self.trunc_op = TruncationOperator(decimals=truncation_decimals)
        self.scalar_op = SerializeDeserializeOperator(
            encoder=BinaryScalarEncoder(),
            decoder=BinaryScalarDecoder(),
            name="ScalarFlatteningOperator",
        )
        self.cascade = CascadeOperator(
            operators=[self.quant_op, self.trunc_op, self.scalar_op],
            name="LossyCascadePipeline",
        )

    def run(self, initial_state: State) -> Dict[str, Any]:
        transformed_state, rec = self.cascade.apply(initial_state)
        vector = MetricCalculator.evaluate(initial_state, transformed_state)

        return {
            "mode": "Mode B (Lossy Binary Transformation)",
            "initial_nodes": len(initial_state.nodes),
            "final_nodes": len(transformed_state.nodes),
            "initial_edges": len(initial_state.edges),
            "final_edges": len(transformed_state.edges),
            "vector": vector.to_dict(),
            "provenance_records": transformed_state.provenance_records,
        }
