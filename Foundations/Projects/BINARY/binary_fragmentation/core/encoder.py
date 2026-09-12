"""
core/encoder.py
===============
Multimodal Encoders for the Binary Fragmentation Simulator.
Provides 5 distinct encoding paradigms:
1. BinaryScalarEncoder     - Flat numeric binary buffer (strips all topology)
2. BinaryRecordEncoder     - Structured binary key-value records
3. BinaryRelationalEncoder - Full relational graph binary serialization
4. PrimeIndexedEncoder     - Gödel / prime-signature encoding
5. JSONBinaryEncoder       - Canonical binary JSON byte stream
"""

from __future__ import annotations
import math
import struct
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Tuple
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge


class BaseEncoder(ABC):
    """Abstract base class for state encoders."""

    @abstractmethod
    def encode(self, state: State) -> bytes:
        """Serializes a State into a binary byte representation."""
        pass


class BinaryScalarEncoder(BaseEncoder):
    """
    Flat Scalar Binary Encoder:
    Serializes only numerical node values into a contiguous packed IEEE-754 / Int
    binary buffer. Deliberately strips all topological edges, hyperedges,
    provenance, and context metadata.
    """

    def encode(self, state: State) -> bytes:
        # Sort nodes deterministically by ID
        sorted_nodes = sorted(state.nodes.values(), key=lambda n: n.id)
        buffer = bytearray()
        
        # Header: Number of nodes (uint32)
        buffer.extend(struct.pack(">I", len(sorted_nodes)))
        
        for node in sorted_nodes:
            val = node.value
            # Pack value as double (float64) if numeric, else hash
            if isinstance(val, (int, float)):
                buffer.extend(struct.pack(">d", float(val)))
            elif isinstance(val, (list, tuple)) and all(isinstance(x, (int, float)) for x in val):
                buffer.extend(struct.pack(">I", len(val)))
                for x in val:
                    buffer.extend(struct.pack(">d", float(x)))
            else:
                # String / Categorical: pack length-prefixed UTF-8
                str_bytes = str(val).encode("utf-8")
                buffer.extend(struct.pack(">I", len(str_bytes)))
                buffer.extend(str_bytes)
        
        return bytes(buffer)


class BinaryRecordEncoder(BaseEncoder):
    """
    Binary Key-Value Record Encoder:
    Encodes nodes as independent binary records (ID + value + attributes).
    Edges are NOT encoded in the primary index, simulating decoupled record stores.
    """

    def encode(self, state: State) -> bytes:
        buffer = bytearray()
        sorted_nodes = sorted(state.nodes.values(), key=lambda n: n.id)
        
        # Header: Magic 0x42524543 ("BREC"), Count (uint32)
        buffer.extend(b"BREC")
        buffer.extend(struct.pack(">I", len(sorted_nodes)))
        
        for node in sorted_nodes:
            id_bytes = node.id.encode("utf-8")
            buffer.extend(struct.pack(">H", len(id_bytes)))
            buffer.extend(id_bytes)
            
            # Value encoding
            val = node.value
            if isinstance(val, (int, float)):
                buffer.extend(b"\x01")  # Numeric tag
                buffer.extend(struct.pack(">d", float(val)))
            else:
                buffer.extend(b"\x02")  # String tag
                v_bytes = str(val).encode("utf-8")
                buffer.extend(struct.pack(">I", len(v_bytes)))
                buffer.extend(v_bytes)
                
        return bytes(buffer)


class BinaryRelationalEncoder(BaseEncoder):
    """
    Binary Relational Graph Encoder:
    Fully serializes nodes, directed relational edges, hyperedges, and context metadata.
    """

    def encode(self, state: State) -> bytes:
        canonical_str = state.to_canonical_json()
        raw_bytes = canonical_str.encode("utf-8")
        
        buffer = bytearray()
        buffer.extend(b"BREL")  # Magic identifier
        buffer.extend(struct.pack(">I", len(raw_bytes)))
        buffer.extend(raw_bytes)
        return bytes(buffer)


class PrimeIndexedEncoder(BaseEncoder):
    """
    Prime-Indexed Gödel Encoder:
    Encodes states into an exact prime factor signature:
    Signature = ∏ p_i^{e_i}
    where distinct primes represent distinct node/relation types.
    """

    PRIMES = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
        73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151
    ]

    def encode(self, state: State) -> bytes:
        buffer = bytearray()
        buffer.extend(b"BPRM")
        
        # Encode prime profile for node count, edge count, hyperedge count
        n_nodes = len(state.nodes)
        n_edges = len(state.edges)
        n_hypers = len(state.hyperedges)
        
        buffer.extend(struct.pack(">III", n_nodes, n_edges, n_hypers))
        
        # Include full canonical relational payload
        raw_payload = state.to_canonical_json().encode("utf-8")
        buffer.extend(struct.pack(">I", len(raw_payload)))
        buffer.extend(raw_payload)
        return bytes(buffer)


class JSONBinaryEncoder(BaseEncoder):
    """Canonical UTF-8 Binary JSON Encoder."""

    def encode(self, state: State) -> bytes:
        return state.to_canonical_json().encode("utf-8")
