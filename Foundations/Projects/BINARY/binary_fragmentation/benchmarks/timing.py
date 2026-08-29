"""
binary_fragmentation/benchmarks/timing.py
=========================================
High-Resolution Timing Harness and Statistical Evaluation Suite.

Provides nanosecond-precision execution timing for state encoders, decoders,
round-trip pipelines, and transformation cascades. Implements controlled
garbage collection management and computes robust statistical metrics
(mean, median, standard deviation, percentiles, throughput).
"""

from __future__ import annotations
import gc
import math
import statistics
import time
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Tuple

from binary_fragmentation.core.state import State
from binary_fragmentation.core.encoder import BaseEncoder
from binary_fragmentation.core.decoder import BaseDecoder
from binary_fragmentation.core.operators import BinaryOperator


@dataclass
class TimingResult:
    """Statistical summary of execution timing for an operation."""
    name: str
    iterations: int
    raw_durations_sec: List[float] = field(default_factory=list)
    total_time_sec: float = 0.0
    mean_time_sec: float = 0.0
    median_time_sec: float = 0.0
    std_dev_sec: float = 0.0
    min_time_sec: float = 0.0
    max_time_sec: float = 0.0
    p95_time_sec: float = 0.0
    p99_time_sec: float = 0.0
    throughput_ops_per_sec: float = 0.0
    throughput_bytes_per_sec: float = 0.0
    bytes_processed: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "iterations": self.iterations,
            "total_time_sec": self.total_time_sec,
            "mean_time_sec": self.mean_time_sec,
            "mean_time_ms": self.mean_time_sec * 1000.0,
            "median_time_sec": self.median_time_sec,
            "median_time_ms": self.median_time_sec * 1000.0,
            "std_dev_sec": self.std_dev_sec,
            "std_dev_ms": self.std_dev_sec * 1000.0,
            "min_time_sec": self.min_time_sec,
            "min_time_ms": self.min_time_sec * 1000.0,
            "max_time_sec": self.max_time_sec,
            "max_time_ms": self.max_time_sec * 1000.0,
            "p95_time_sec": self.p95_time_sec,
            "p95_time_ms": self.p95_time_sec * 1000.0,
            "p99_time_sec": self.p99_time_sec,
            "p99_time_ms": self.p99_time_sec * 1000.0,
            "throughput_ops_per_sec": self.throughput_ops_per_sec,
            "throughput_bytes_per_sec": self.throughput_bytes_per_sec,
            "bytes_processed": self.bytes_processed,
        }


class TimingHarness:
    """
    High-precision timing harness with GC control and statistical estimation.
    """

    @staticmethod
    def _compute_percentile(sorted_data: List[float], percentile: float) -> float:
        if not sorted_data:
            return 0.0
        k = (len(sorted_data) - 1) * (percentile / 100.0)
        f = math.floor(k)
        c = math.ceil(k)
        if f == c:
            return sorted_data[int(k)]
        d0 = sorted_data[int(f)] * (c - k)
        d1 = sorted_data[int(c)] * (k - f)
        return d0 + d1

    @classmethod
    def time_callable(
        cls,
        fn: Callable[[], Any],
        name: str = "operation",
        repetitions: int = 10,
        warmup: int = 2,
        bytes_processed: int = 0,
    ) -> TimingResult:
        """
        Executes a callable across warmup and measurement iterations with GC management.
        """
        # Warmup iterations
        for _ in range(max(1, warmup)):
            fn()

        durations: List[float] = []
        
        # Execute timed runs
        for _ in range(max(1, repetitions)):
            gc.collect()
            gc_was_enabled = gc.isenabled()
            gc.disable()
            try:
                t0 = time.perf_counter()
                fn()
                t1 = time.perf_counter()
                durations.append(t1 - t0)
            finally:
                if gc_was_enabled:
                    gc.enable()

        total_t = sum(durations)
        sorted_d = sorted(durations)
        n = len(durations)
        mean_t = statistics.mean(durations) if n > 0 else 0.0
        median_t = statistics.median(durations) if n > 0 else 0.0
        std_dev = statistics.stdev(durations) if n > 1 else 0.0
        min_t = min(durations) if n > 0 else 0.0
        max_t = max(durations) if n > 0 else 0.0
        p95_t = cls._compute_percentile(sorted_d, 95.0)
        p99_t = cls._compute_percentile(sorted_d, 99.0)

        throughput_ops = (1.0 / median_t) if median_t > 0 else 0.0
        throughput_bytes = (bytes_processed / median_t) if median_t > 0 else 0.0

        return TimingResult(
            name=name,
            iterations=n,
            raw_durations_sec=durations,
            total_time_sec=total_t,
            mean_time_sec=mean_t,
            median_time_sec=median_t,
            std_dev_sec=std_dev,
            min_time_sec=min_t,
            max_time_sec=max_t,
            p95_time_sec=p95_t,
            p99_time_sec=p99_t,
            throughput_ops_per_sec=throughput_ops,
            throughput_bytes_per_sec=throughput_bytes,
            bytes_processed=bytes_processed,
        )

    @classmethod
    def benchmark_encoding(
        cls,
        encoder: BaseEncoder,
        state: State,
        name: str = "",
        repetitions: int = 10,
        warmup: int = 2,
    ) -> TimingResult:
        """Benchmarks the serialization speed of an encoder."""
        tag = name or encoder.__class__.__name__
        sample_bytes = encoder.encode(state)
        byte_len = len(sample_bytes)

        return cls.time_callable(
            fn=lambda: encoder.encode(state),
            name=f"Encode[{tag}]",
            repetitions=repetitions,
            warmup=warmup,
            bytes_processed=byte_len,
        )

    @classmethod
    def benchmark_decoding(
        cls,
        decoder: BaseDecoder,
        encoded_data: bytes,
        template_state: Optional[State] = None,
        name: str = "",
        repetitions: int = 10,
        warmup: int = 2,
    ) -> TimingResult:
        """Benchmarks the deserialization speed of a decoder."""
        tag = name or decoder.__class__.__name__
        byte_len = len(encoded_data)

        return cls.time_callable(
            fn=lambda: decoder.decode(encoded_data, template_state=template_state),
            name=f"Decode[{tag}]",
            repetitions=repetitions,
            warmup=warmup,
            bytes_processed=byte_len,
        )

    @classmethod
    def benchmark_roundtrip(
        cls,
        encoder: BaseEncoder,
        decoder: BaseDecoder,
        state: State,
        name: str = "",
        repetitions: int = 10,
        warmup: int = 2,
    ) -> TimingResult:
        """Benchmarks full round-trip encode -> decode cycle."""
        tag = name or f"{encoder.__class__.__name__}->{decoder.__class__.__name__}"
        sample_bytes = encoder.encode(state)
        byte_len = len(sample_bytes)

        def roundtrip() -> State:
            b = encoder.encode(state)
            return decoder.decode(b, template_state=state)

        return cls.time_callable(
            fn=roundtrip,
            name=f"RoundTrip[{tag}]",
            repetitions=repetitions,
            warmup=warmup,
            bytes_processed=byte_len,
        )

    @classmethod
    def benchmark_pipeline(
        cls,
        operator: BinaryOperator,
        state: State,
        name: str = "",
        repetitions: int = 10,
        warmup: int = 2,
    ) -> TimingResult:
        """Benchmarks a single operator or cascade transformation step."""
        tag = name or operator.name
        return cls.time_callable(
            fn=lambda: operator.apply(state),
            name=f"Pipeline[{tag}]",
            repetitions=repetitions,
            warmup=warmup,
            bytes_processed=0,
        )

    @classmethod
    def benchmark_recursive_stress(
        cls,
        operator: BinaryOperator,
        initial_state: State,
        cycles: int = 25,
        name: str = "",
        repetitions: int = 5,
        warmup: int = 1,
    ) -> TimingResult:
        """Benchmarks recursive transformation latency across N successive cycles."""
        tag = name or f"{operator.name}_x{cycles}"

        def recursive_run() -> State:
            cur = initial_state
            for _ in range(cycles):
                cur, _ = operator.apply(cur)
            return cur

        return cls.time_callable(
            fn=recursive_run,
            name=f"RecursiveStress[{tag}]",
            repetitions=repetitions,
            warmup=warmup,
            bytes_processed=0,
        )
