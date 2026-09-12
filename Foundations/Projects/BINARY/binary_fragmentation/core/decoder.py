"""
core/decoder.py
===============
Decoders for the Binary Fragmentation Simulator.
Reconstructs multidimensional State from binary byte streams.
"""

from __future__ import annotations
import json
import struct
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge


class BaseDecoder(ABC):
    """Abstract base class for state decoders."""

    @abstractmethod
    def decode(self, data: bytes, template_state: Optional[State] = None) -> State:
        """Reconstructs a State from a binary buffer."""
        pass


class BinaryScalarDecoder(BaseDecoder):
    """
    Decodes a flat scalar binary buffer.
    Because scalar encoding strips edges and metadata, the reconstructed state
    contains only the extracted node values.
    """

    def decode(self, data: bytes, template_state: Optional[State] = None) -> State:
        state = State()
        if len(data) < 4:
            return state
            
        offset = 0
        (num_nodes,) = struct.unpack_from(">I", data, offset)
        offset += 4
        
        # If template_state is provided, reuse node IDs; otherwise generate n0, n1, ...
        node_ids = (
            sorted(template_state.nodes.keys())
            if template_state and len(template_state.nodes) == num_nodes
            else [f"n_{i}" for i in range(num_nodes)]
        )
        
        for i in range(num_nodes):
            if offset >= len(data):
                break
            nid = node_ids[i] if i < len(node_ids) else f"n_{i}"
            
            # Try unpacking float64
            if offset + 8 <= len(data):
                (val,) = struct.unpack_from(">d", data, offset)
                offset += 8
                state.add_node(Node(id=nid, value=val))
            else:
                break
                
        return state


class BinaryRecordDecoder(BaseDecoder):
    """Decodes binary key-value records into nodes."""

    def decode(self, data: bytes, template_state: Optional[State] = None) -> State:
        state = State()
        if len(data) < 8 or data[:4] != b"BREC":
            return state
            
        offset = 4
        (num_nodes,) = struct.unpack_from(">I", data, offset)
        offset += 4
        
        for _ in range(num_nodes):
            if offset + 2 > len(data):
                break
            (id_len,) = struct.unpack_from(">H", data, offset)
            offset += 2
            
            if offset + id_len > len(data):
                break
            nid = data[offset : offset + id_len].decode("utf-8", errors="replace")
            offset += id_len
            
            if offset >= len(data):
                break
            tag = data[offset : offset + 1]
            offset += 1
            
            if tag == b"\x01":
                if offset + 8 > len(data):
                    break
                (val,) = struct.unpack_from(">d", data, offset)
                offset += 8
                state.add_node(Node(id=nid, value=val))
            elif tag == b"\x02":
                if offset + 4 > len(data):
                    break
                (v_len,) = struct.unpack_from(">I", data, offset)
                offset += 4
                if offset + v_len > len(data):
                    break
                val_str = data[offset : offset + v_len].decode("utf-8", errors="replace")
                offset += v_len
                state.add_node(Node(id=nid, value=val_str))
                
        return state


class BinaryRelationalDecoder(BaseDecoder):
    """Decodes full binary relational streams."""

    def decode(self, data: bytes, template_state: Optional[State] = None) -> State:
        if len(data) < 8 or data[:4] != b"BREL":
            # Fallback to pure JSON if magic missing
            try:
                raw_json = data.decode("utf-8")
                return State.from_dict(json.loads(raw_json))
            except Exception:
                return State()
                
        offset = 4
        (payload_len,) = struct.unpack_from(">I", data, offset)
        offset += 4
        
        raw_bytes = data[offset : offset + payload_len]
        try:
            raw_json = raw_bytes.decode("utf-8")
            return State.from_dict(json.loads(raw_json))
        except Exception:
            return State()


class PrimeIndexedDecoder(BaseDecoder):
    """Decodes prime-indexed binary representations."""

    def decode(self, data: bytes, template_state: Optional[State] = None) -> State:
        if len(data) < 20 or data[:4] != b"BPRM":
            return State()
            
        offset = 16  # Magic (4) + counts (12)
        (payload_len,) = struct.unpack_from(">I", data, offset)
        offset += 4
        
        raw_bytes = data[offset : offset + payload_len]
        try:
            raw_json = raw_bytes.decode("utf-8")
            return State.from_dict(json.loads(raw_json))
        except Exception:
            return State()


class JSONBinaryDecoder(BaseDecoder):
    """Decodes UTF-8 JSON binary byte stream."""

    def decode(self, data: bytes, template_state: Optional[State] = None) -> State:
        try:
            raw_json = data.decode("utf-8")
            return State.from_dict(json.loads(raw_json))
        except Exception:
            return State()
