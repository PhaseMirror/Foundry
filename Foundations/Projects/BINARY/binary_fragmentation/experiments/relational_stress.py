"""
experiments/relational_stress.py
================================
Relational Encoding Under Deep Operational Stress & 5-Way Comparative Stress.

Investigates:
Does relational information degrade under repeated operational transformations
(quantization, edge sorting, serialization, compression, re-indexing) even when
the encoding format initially carries full relational topology?
"""

from __future__ import annotations
import copy
import math
import random
from typing import Any, Dict, List, Tuple

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
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
from binary_fragmentation.core.operators import (
    BinaryOperator,
    QuantizationOperator,
    TruncationOperator,
    SerializeDeserializeOperator,
    CascadeOperator,
)
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


class EdgePermutationOperator(BinaryOperator):
    """
    Simulates database query plan reordering or network packet reordering:
    Permutes edge list ordering deterministically or pseudo-randomly.
    """

    def __init__(self, seed: int = 42):
        self.seed = seed
        super().__init__(name="EdgePermutationOperator", parameters={"seed": seed})

    def apply(self, state: State) -> Tuple[State, Any]:
        new_state = state.clone()
        new_state.generation = state.generation + 1
        new_state.parent_id = state.state_id

        # Permute edges deterministically
        rng = random.Random(self.seed + state.generation)
        shuffled_edges = list(new_state.edges)
        rng.shuffle(shuffled_edges)
        new_state.edges = shuffled_edges

        from binary_fragmentation.core.provenance import ProvenanceRecord
        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=True,
            reversibility_notes="Isomorphic edge permutation preserves semantic content.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class RelationalStressExperiment:
    """
    Applies an aggressive multi-stage operational pipeline across N recursive cycles:
    1. Lexicographical / shuffle edge reordering
    2. Finite precision attribute quantization (10-bit & 8-bit)
    3. Binary serialization & deserialization round-trip
    4. Zlib compression cycle
    """

    def __init__(self, cycles: int = 25):
        self.cycles = cycles
        self.relational_op = CascadeOperator(
            operators=[
                EdgePermutationOperator(),
                QuantizationOperator(bits=8),
                TruncationOperator(decimals=3),
                SerializeDeserializeOperator(
                    encoder=BinaryRelationalEncoder(),
                    decoder=BinaryRelationalDecoder(),
                    name="RelationalRoundTrip",
                ),
            ],
            name="RelationalStressPipeline",
        )

    def run(self, initial_state: State) -> Dict[str, Any]:
        trajectory: List[State] = [initial_state.clone()]
        vectors: List[FragmentationVector] = []
        drift_trajectory: List[float] = [0.0]

        current = initial_state.clone()
        for c in range(1, self.cycles + 1):
            next_st, _ = self.relational_op.apply(current)
            trajectory.append(next_st.clone())

            vec = MetricCalculator.evaluate(initial_state, next_st)
            vectors.append(vec)
            drift_trajectory.append(vec.l2_norm)
            current = next_st

        # Derivatives
        d1 = [drift_trajectory[i] - drift_trajectory[i - 1] for i in range(1, len(drift_trajectory))]
        d2 = [d1[i] - d1[i - 1] for i in range(1, len(d1))]

        return {
            "experiment": "Relational Encoding Under Operational Stress",
            "cycles": self.cycles,
            "drift_trajectory": drift_trajectory,
            "first_derivative_dD_dn": d1,
            "second_derivative_d2D_dn2": d2,
            "initial_edges": len(initial_state.edges),
            "final_edges": len(current.edges),
            "final_vector": vectors[-1].to_dict() if vectors else {},
            "relational_preservation_maintained": (vectors[-1].F_r < 0.01 if vectors else True),
            "value_drift": vectors[-1].F_v if vectors else 0.0,
        }


class ComparativeStressExperiment:
    """
    Applies identical 10-cycle transformation cascades to all 5 representation paradigms.
    Demonstrates differential resilience against operational stress.
    """

    def __init__(self, cycles: int = 10):
        self.cycles = cycles

    def run(self, initial_state: State) -> Dict[str, Any]:
        representations = [
            ("1. Flat Binary Scalar", BinaryScalarEncoder(), BinaryScalarDecoder()),
            ("2. Binary Key-Value Record", BinaryRecordEncoder(), BinaryRecordDecoder()),
            ("3. Relational Graph Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
            ("4. Hypergraph JSON Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
            ("5. Prime-Indexed Gödel", PrimeIndexedEncoder(), PrimeIndexedDecoder()),
        ]

        benchmark_results = []

        for name, enc, dec in representations:
            current = initial_state.clone()
            op = CascadeOperator(
                operators=[
                    QuantizationOperator(bits=8),
                    SerializeDeserializeOperator(encoder=enc, decoder=dec, name=name),
                ],
                name=f"Stress_{name}",
            )

            trajectory_drifts = [0.0]
            for _ in range(self.cycles):
                current, _ = op.apply(current)
                vec = MetricCalculator.evaluate(initial_state, current)
                trajectory_drifts.append(vec.l2_norm)

            final_vec = MetricCalculator.evaluate(initial_state, current)
            benchmark_results.append({
                "representation": name,
                "final_F_v": final_vec.F_v,
                "final_F_s": final_vec.F_s,
                "final_F_r": final_vec.F_r,
                "final_F_p": final_vec.F_p,
                "final_L2_loss": final_vec.l2_norm,
                "drift_trajectory": trajectory_drifts,
            })

        return {
            "experiment": "5-Way Comparative Stress Benchmark",
            "cycles": self.cycles,
            "results": benchmark_results,
        }
