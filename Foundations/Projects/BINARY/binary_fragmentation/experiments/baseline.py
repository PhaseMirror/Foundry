"""
experiments/baseline.py
=======================
Mode A — Perfect Binary Representation Experiment.
Evaluates whether representation alone in a lossless binary pipeline
produces information loss.
"""

from __future__ import annotations
from typing import Any, Dict
from binary_fragmentation.core.state import State, Node, Edge
from binary_fragmentation.core.encoder import BinaryRelationalEncoder
from binary_fragmentation.core.decoder import BinaryRelationalDecoder
from binary_fragmentation.core.operators import SerializeDeserializeOperator
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


class BaselineExperiment:
    """Mode A: Lossless Binary Serialization & Reconstruction."""

    def __init__(self) -> None:
        self.encoder = BinaryRelationalEncoder()
        self.decoder = BinaryRelationalDecoder()
        self.operator = SerializeDeserializeOperator(
            encoder=self.encoder,
            decoder=self.decoder,
            name="LosslessRelationalBinaryOperator",
        )

    def run(self, initial_state: State) -> Dict[str, Any]:
        transformed_state, rec = self.operator.apply(initial_state)
        vector = MetricCalculator.evaluate(initial_state, transformed_state)

        return {
            "mode": "Mode A (Perfect Binary Representation)",
            "initial_checksum": initial_state.compute_checksum(),
            "final_checksum": transformed_state.compute_checksum(),
            "lossless_exact_match": (
                initial_state.compute_checksum() == transformed_state.compute_checksum()
            ),
            "vector": vector.to_dict(),
            "provenance_record": rec.to_dict(),
        }
