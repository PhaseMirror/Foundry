"""
fragmentation/compression.py
============================
Compression / Recompression operators.
"""

from __future__ import annotations
import zlib
from typing import Tuple
from binary_fragmentation.core.state import State
from binary_fragmentation.core.operators import BinaryOperator
from binary_fragmentation.core.provenance import ProvenanceRecord


class ZlibCompressDecompressOperator(BinaryOperator):
    """
    Simulates binary transport through zlib deflate/inflate compression cycles.
    """

    def __init__(self, level: int = 6):
        self.level = level
        super().__init__(name="ZlibCompressDecompressOperator", parameters={"level": level})

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        raw_bytes = state.to_canonical_json().encode("utf-8")
        compressed = zlib.compress(raw_bytes, self.level)
        decompressed = zlib.decompress(compressed)
        
        # State reconstruction from decompressed JSON
        import json
        reconstructed = State.from_dict(json.loads(decompressed.decode("utf-8")))
        reconstructed.generation = state.generation + 1
        reconstructed.parent_id = state.state_id

        rec = ProvenanceRecord(
            state_id=reconstructed.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"raw_bytes": len(raw_bytes), "compressed_bytes": len(compressed)},
            info_added={},
            checksum_before=state.compute_checksum(),
            checksum_after=reconstructed.compute_checksum(),
            reversible=True,
            reversibility_notes="Lossless zlib compression cycle",
        )
        reconstructed.provenance_records.append(rec.to_dict())
        return reconstructed, rec
