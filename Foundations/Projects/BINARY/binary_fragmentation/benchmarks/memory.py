"""
binary_fragmentation/benchmarks/memory.py
=========================================
Memory Profiling and Allocation Measurement Harness.

Uses Python's standard `tracemalloc` facility to measure peak memory footprint,
transient allocations, and serialized payload size across encoding, decoding,
and pipeline transformations without external C dependencies.
"""

from __future__ import annotations
import gc
import tracemalloc
from dataclasses import dataclass
from typing import Any, Callable, Dict, Optional, Tuple

from binary_fragmentation.core.state import State
from binary_fragmentation.core.encoder import BaseEncoder
from binary_fragmentation.core.decoder import BaseDecoder
from binary_fragmentation.core.operators import BinaryOperator


@dataclass
class MemoryResult:
    """Statistical summary of memory allocation during execution."""
    name: str
    peak_bytes: int
    current_bytes: int
    serialized_bytes: int = 0

    @property
    def peak_kb(self) -> float:
        return self.peak_bytes / 1024.0

    @property
    def peak_mb(self) -> float:
        return self.peak_bytes / (1024.0 * 1024.0)

    @property
    def serialized_kb(self) -> float:
        return self.serialized_bytes / 1024.0

    @property
    def serialized_mb(self) -> float:
        return self.serialized_bytes / (1024.0 * 1024.0)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "peak_bytes": self.peak_bytes,
            "peak_kb": self.peak_kb,
            "peak_mb": self.peak_mb,
            "current_bytes": self.current_bytes,
            "serialized_bytes": self.serialized_bytes,
            "serialized_kb": self.serialized_kb,
            "serialized_mb": self.serialized_mb,
        }


class MemoryProfiler:
    """
    Precision memory measurement harness leveraging tracemalloc.
    """

    @classmethod
    def profile_callable(
        cls,
        fn: Callable[[], Any],
        name: str = "operation",
        serialized_bytes: int = 0,
    ) -> Tuple[Any, MemoryResult]:
        """
        Executes a callable under active tracemalloc tracing and records peak allocation.
        """
        gc.collect()
        tracemalloc_was_active = tracemalloc.is_tracing()
        if not tracemalloc_was_active:
            tracemalloc.start()
        tracemalloc.reset_peak()

        result = None
        try:
            result = fn()
            current, peak = tracemalloc.get_traced_memory()
        finally:
            if not tracemalloc_was_active:
                tracemalloc.stop()

        mem_res = MemoryResult(
            name=name,
            peak_bytes=peak,
            current_bytes=current,
            serialized_bytes=serialized_bytes,
        )
        return result, mem_res

    @classmethod
    def profile_encoding(
        cls,
        encoder: BaseEncoder,
        state: State,
        name: str = "",
    ) -> Tuple[bytes, MemoryResult]:
        """Profiles memory usage during state serialization."""
        tag = name or encoder.__class__.__name__

        def encode_action() -> bytes:
            return encoder.encode(state)

        data, mem = cls.profile_callable(encode_action, name=f"MemEncode[{tag}]")
        mem.serialized_bytes = len(data) if isinstance(data, (bytes, bytearray)) else 0
        return data, mem

    @classmethod
    def profile_decoding(
        cls,
        decoder: BaseDecoder,
        encoded_data: bytes,
        template_state: Optional[State] = None,
        name: str = "",
    ) -> Tuple[State, MemoryResult]:
        """Profiles memory usage during state deserialization."""
        tag = name or decoder.__class__.__name__

        def decode_action() -> State:
            return decoder.decode(encoded_data, template_state=template_state)

        state_out, mem = cls.profile_callable(
            decode_action,
            name=f"MemDecode[{tag}]",
            serialized_bytes=len(encoded_data),
        )
        return state_out, mem

    @classmethod
    def profile_roundtrip(
        cls,
        encoder: BaseEncoder,
        decoder: BaseDecoder,
        state: State,
        name: str = "",
    ) -> Tuple[State, MemoryResult]:
        """Profiles peak memory across a full serialize -> deserialize cycle."""
        tag = name or f"{encoder.__class__.__name__}->{decoder.__class__.__name__}"
        raw_bytes = encoder.encode(state)

        def roundtrip_action() -> State:
            b = encoder.encode(state)
            return decoder.decode(b, template_state=state)

        state_out, mem = cls.profile_callable(
            roundtrip_action,
            name=f"MemRoundTrip[{tag}]",
            serialized_bytes=len(raw_bytes),
        )
        return state_out, mem

    @classmethod
    def profile_pipeline(
        cls,
        operator: BinaryOperator,
        state: State,
        name: str = "",
    ) -> Tuple[State, MemoryResult]:
        """Profiles memory usage during an operational transformation step."""
        tag = name or operator.name

        def pipeline_action() -> State:
            res_state, _ = operator.apply(state)
            return res_state

        state_out, mem = cls.profile_callable(pipeline_action, name=f"MemPipeline[{tag}]")
        return state_out, mem
