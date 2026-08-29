"""
experiments/comparative.py
==========================
Mode E — Comparative Representation Control Experiment.
Executes the identical computational transformations across 5 representations:
1. Binary Scalar Encoding
2. Binary Record Encoding (Binary + Tagged Fields)
3. Relational Graph Encoding
4. Hypergraph Encoding
5. Prime-Indexed Representation

Falsification Principle:
If all 5 representations experience identical relational degradation under the same
operations, binary is not the special cause. If binary loses relational structure
while richer representations preserve it, the ADR hypothesis is empirically validated.
"""

from __future__ import annotations
from typing import Any, Dict, List
from binary_fragmentation.core.state import State
from binary_fragmentation.core.encoder import (
    BinaryScalarEncoder,
    BinaryRecordEncoder,
    BinaryRelationalEncoder,
    PrimeIndexedEncoder,
)
from binary_fragmentation.core.decoder import (
    BinaryScalarDecoder,
    BinaryRecordDecoder,
    BinaryRelationalDecoder,
    PrimeIndexedDecoder,
)
from binary_fragmentation.core.operators import SerializeDeserializeOperator
from binary_fragmentation.metrics.vector import MetricCalculator


class ComparativeRepresentationExperiment:
    """Mode E: 5-Way Comparative Representation Benchmark."""

    def __init__(self) -> None:
        self.representations = [
            ("1. Flat Binary Scalar", BinaryScalarEncoder(), BinaryScalarDecoder()),
            ("2. Binary Key-Value Record", BinaryRecordEncoder(), BinaryRecordDecoder()),
            ("3. Relational Graph Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
            ("4. Hypergraph JSON Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
            ("5. Prime-Indexed Gödel", PrimeIndexedEncoder(), PrimeIndexedDecoder()),
        ]

    def run(self, initial_state: State) -> Dict[str, Any]:
        results: List[Dict[str, Any]] = []

        for name, enc, dec in self.representations:
            op = SerializeDeserializeOperator(encoder=enc, decoder=dec, name=name)
            transformed, rec = op.apply(initial_state)
            vector = MetricCalculator.evaluate(initial_state, transformed)

            results.append({
                "representation": name,
                "encoded_byte_size": rec.info_removed.get("bytes_encoded", 0),
                "value_loss_Fv": vector.F_v,
                "relational_loss_Fr": vector.F_r,
                "structural_loss_Fs": vector.F_s,
                "overall_loss_L2": vector.l2_norm,
                "vector": vector.to_dict(),
            })

        return {
            "mode": "Mode E (Comparative Representation Benchmark)",
            "comparison": results,
        }
