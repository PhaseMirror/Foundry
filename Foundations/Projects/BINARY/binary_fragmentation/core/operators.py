"""
core/operators.py
=================
Operational Transformation Primitives for the Binary Fragmentation Simulator.
Each operator transforms an input State S_n into S_{n+1}, generating a comprehensive
ProvenanceRecord of the transition.
"""

from __future__ import annotations
import copy
import hashlib
import math
import random
import struct
import time
import uuid
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional, Tuple

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.provenance import ProvenanceRecord
from binary_fragmentation.core.encoder import BaseEncoder, BinaryScalarEncoder, BinaryRelationalEncoder
from binary_fragmentation.core.decoder import BaseDecoder, BinaryScalarDecoder, BinaryRelationalDecoder


class BinaryOperator(ABC):
    """Abstract base class for all state transformation operators."""

    def __init__(self, name: str, parameters: Optional[Dict[str, Any]] = None):
        self.name = name
        self.parameters = parameters or {}

    @abstractmethod
    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        """Applies the operator to a state and returns (new_state, provenance_record)."""
        pass

    def __call__(self, state: State) -> Tuple[State, ProvenanceRecord]:
        return self.apply(state)


class IdentityOperator(BinaryOperator):
    """Lossless identity pass-through."""

    def __init__(self) -> None:
        super().__init__(name="IdentityOperator")

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.parent_id = state.state_id
        new_state.state_id = str(uuid.uuid4())
        new_state.generation = state.generation + 1
        new_state.timestamp = time.time()

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={},
            info_added={},
            checksum_before=state.compute_checksum(),
            checksum_after=new_state.compute_checksum(),
            reversible=True,
            reversibility_notes="Identity mapping is trivially reversible.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class SerializeDeserializeOperator(BinaryOperator):
    """
    Simulates the round-trip pipeline:
    S_n -> Binary Encoding -> Binary Decoding -> S_{n+1}
    using specified encoder and decoder pairs.
    """

    def __init__(
        self,
        encoder: Optional[BaseEncoder] = None,
        decoder: Optional[BaseDecoder] = None,
        name: str = "SerializeDeserializeOperator",
    ):
        self.encoder = encoder or BinaryScalarEncoder()
        self.decoder = decoder or BinaryScalarDecoder()
        super().__init__(
            name=name,
            parameters={
                "encoder": self.encoder.__class__.__name__,
                "decoder": self.decoder.__class__.__name__,
            },
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        chk_before = state.compute_checksum()
        encoded_bytes = self.encoder.encode(state)
        decoded_state = self.decoder.decode(encoded_bytes, template_state=state)

        # Inherit generation and lineage
        decoded_state.parent_id = state.state_id
        decoded_state.state_id = str(uuid.uuid4())
        decoded_state.generation = state.generation + 1
        decoded_state.timestamp = time.time()
        decoded_state.provenance_records = copy.deepcopy(state.provenance_records)

        # Determine information removed
        edges_removed = len(state.edges) - len(decoded_state.edges)
        hypers_removed = len(state.hyperedges) - len(decoded_state.hyperedges)
        context_removed = len(state.context) - len(decoded_state.context)

        chk_after = decoded_state.compute_checksum()
        is_rev = (chk_before == chk_after)

        rec = ProvenanceRecord(
            state_id=decoded_state.state_id,
            parent_state_id=state.state_id,
            operator=f"{self.name}[{self.encoder.__class__.__name__}->{self.decoder.__class__.__name__}]",
            parameters=self.parameters,
            info_removed={
                "bytes_encoded": len(encoded_bytes),
                "edges_removed": edges_removed,
                "hyperedges_removed": hypers_removed,
                "context_removed": context_removed,
            },
            info_added={},
            checksum_before=chk_before,
            checksum_after=chk_after,
            reversible=is_rev,
            reversibility_notes="Exact match" if is_rev else "Information dropped during serialization/deserialization.",
        )
        decoded_state.provenance_records.append(rec.to_dict())
        return decoded_state, rec


class QuantizationOperator(BinaryOperator):
    """
    Quantizes all numeric node values to discrete steps or bit-widths:
    val' = round(val / step) * step
    """

    def __init__(self, bits: int = 8, step: Optional[float] = None):
        self.bits = bits
        self.step = step or (1.0 / (2**bits))
        super().__init__(name="QuantizationOperator", parameters={"bits": bits, "step": self.step})

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.parent_id = state.state_id
        new_state.state_id = str(uuid.uuid4())
        new_state.generation = state.generation + 1
        new_state.timestamp = time.time()

        max_delta = 0.0
        for nid, node in new_state.nodes.items():
            if isinstance(node.value, (int, float)):
                orig_val = float(node.value)
                quantized = round(orig_val / self.step) * self.step
                delta = abs(quantized - orig_val)
                if delta > max_delta:
                    max_delta = delta
                node.value = quantized

        chk_before = state.compute_checksum()
        chk_after = new_state.compute_checksum()
        is_rev = (max_delta == 0.0)

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"max_quantization_delta": max_delta},
            info_added={},
            checksum_before=chk_before,
            checksum_after=chk_after,
            reversible=is_rev,
            reversibility_notes="Zero distortion" if is_rev else f"Quantization distortion max_delta={max_delta:.6f}",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class TruncationOperator(BinaryOperator):
    """
    Truncates floating point precision to specified decimal places or significant bits.
    """

    def __init__(self, decimals: int = 2):
        self.decimals = decimals
        super().__init__(name="TruncationOperator", parameters={"decimals": decimals})

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.parent_id = state.state_id
        new_state.state_id = str(uuid.uuid4())
        new_state.generation = state.generation + 1
        new_state.timestamp = time.time()

        for nid, node in new_state.nodes.items():
            if isinstance(node.value, float):
                node.value = round(node.value, self.decimals)

        chk_before = state.compute_checksum()
        chk_after = new_state.compute_checksum()

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"decimals_retained": self.decimals},
            info_added={},
            checksum_before=chk_before,
            checksum_after=chk_after,
            reversible=(chk_before == chk_after),
            reversibility_notes="Lossy precision truncation",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class HashingOperator(BinaryOperator):
    """
    Replaces node/edge attributes and values with one-way SHA-256 digests.
    Simulates cryptographic hashing and irreversible commitment layers.
    """

    def __init__(self, hash_values: bool = True, hash_ids: bool = False):
        self.hash_values = hash_values
        self.hash_ids = hash_ids
        super().__init__(name="HashingOperator", parameters={"hash_values": hash_values, "hash_ids": hash_ids})

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        new_state = state.clone()
        new_state.parent_id = state.state_id
        new_state.state_id = str(uuid.uuid4())
        new_state.generation = state.generation + 1
        new_state.timestamp = time.time()

        for nid, node in new_state.nodes.items():
            if self.hash_values:
                raw = str(node.value).encode("utf-8")
                node.value = hashlib.sha256(raw).hexdigest()[:16]

        chk_before = state.compute_checksum()
        chk_after = new_state.compute_checksum()

        rec = ProvenanceRecord(
            state_id=new_state.state_id,
            parent_state_id=state.state_id,
            operator=self.name,
            parameters=self.parameters,
            info_removed={"one_way_hashed": True},
            info_added={},
            checksum_before=chk_before,
            checksum_after=chk_after,
            reversible=False,
            reversibility_notes="Cryptographic hash is strictly one-way.",
        )
        new_state.provenance_records.append(rec.to_dict())
        return new_state, rec


class CascadeOperator(BinaryOperator):
    """Composes a sequence of operators into a single unified step."""

    def __init__(self, operators: List[BinaryOperator], name: str = "CascadeOperator"):
        self.operators = operators
        super().__init__(
            name=name,
            parameters={"operators": [op.name for op in operators]},
        )

    def apply(self, state: State) -> Tuple[State, ProvenanceRecord]:
        current_state = state
        last_rec: Optional[ProvenanceRecord] = None
        for op in self.operators:
            current_state, last_rec = op.apply(current_state)
        return current_state, last_rec  # type: ignore
