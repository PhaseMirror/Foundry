"""
fragmentation/truncation.py
===========================
Truncation and bit-masking operators.
"""

from __future__ import annotations
import struct
from typing import Tuple
from binary_fragmentation.core.state import State
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord


class BitMaskTruncator(BinaryOperator):
    """
    Simulates floating-point mantissa bit zeroing (e.g. bfloat16 / fp8 truncation).
    Zeroes the lowest N bits of the 64-bit IEEE 754 float representation.
    """

    def __init__(self, bits_to_zero: int = 16):
        self.bits_to_zero = bits_to_zero
        self.mask = (~((1 << bits_to_zero) - 1)) & 0xFFFFFFFFFFFFFFFF
        super().__init__(name="BitMaskTruncator", parameters={"bits_to_zero": bits_to_zero})

    def _truncate_float(self, val: float) -> float:
        packed = struct.pack(">d", val)
        (as_int,) = struct.unpack(">Q", packed)
        truncated_int = as_int & self.mask
        (res,) = struct.unpack(">d", struct.pack(">Q", truncated_int))
        return res

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        for nid, node in new_state.nodes.items():
            if isinstance(node.value, float):
                node.value = self._truncate_float(node.value)

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
