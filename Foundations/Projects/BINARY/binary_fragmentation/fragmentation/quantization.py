"""
fragmentation/quantization.py
=============================
Quantization operators for bit-level and numeric discretization.
"""

from __future__ import annotations
import math
from typing import Any, Dict, Optional, Tuple
from binary_fragmentation.core.state import State
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord


class NonUniformQuantizer(BinaryOperator):
    r"""
    Non-uniform logarithmic / $\mu$-law quantization simulating companding converters:
    y = sgn(x) * ln(1 + \mu |x|) / ln(1 + \mu)
    """

    def __init__(self, mu: float = 255.0, levels: int = 256):
        self.mu = mu
        self.levels = levels
        super().__init__(name="NonUniformQuantizer", parameters={"mu": mu, "levels": levels})

    def _compand(self, x: float) -> float:
        if abs(x) < 1e-12:
            return 0.0
        sgn = 1.0 if x >= 0 else -1.0
        norm_x = min(1.0, abs(x))
        compressed = sgn * math.log(1.0 + self.mu * norm_x) / math.log(1.0 + self.mu)
        # Discretize
        q_step = 2.0 / self.levels
        quantized = round(compressed / q_step) * q_step
        # Expand back
        exp_abs = (math.pow(1.0 + self.mu, abs(quantized)) - 1.0) / self.mu
        return (1.0 if quantized >= 0 else -1.0) * exp_abs

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        for nid, node in new_state.nodes.items():
            if isinstance(node.value, (int, float)):
                node.value = self._compand(float(node.value))

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=(state.compute_checksum() == new_state.compute_checksum()),
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec
