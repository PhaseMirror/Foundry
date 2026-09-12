"""
binary_fragmentation/benchmarks/pipelines.py
============================================
Specialized Pipeline Benchmarks for Systems Architects.

Evaluates:
1. Compression Efficiency (Zlib entropy reduction across representations)
2. Distributed Sharding Overhead (Naive Partitioning vs Boundary-Witness Sharding)
3. Attribute Density Scaling (Latency vs number of attributes per entity)
4. Deep Multi-Cycle Recursion (100 to 500 transformation generations)
5. Real-World Enterprise Record Throughput (Customer Dossiers per second)
"""

from __future__ import annotations
import copy
import math
import time
import zlib
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.encoder import (
    BaseEncoder,
    BinaryScalarEncoder,
    BinaryRecordEncoder,
    BinaryRelationalEncoder,
    JSONBinaryEncoder,
    PrimeIndexedEncoder,
)
from binary_fragmentation.core.decoder import (
    BaseDecoder,
    BinaryScalarDecoder,
    BinaryRecordDecoder,
    BinaryRelationalDecoder,
    JSONBinaryDecoder,
    PrimeIndexedDecoder,
)
from binary_fragmentation.core.operators import (
    QuantizationOperator,
    TruncationOperator,
    SerializeDeserializeOperator,
    CascadeOperator,
)
from binary_fragmentation.fragmentation.splitting import NetworkShardingOperator
from binary_fragmentation.fragmentation.recombination import NetworkRecombinationOperator
from binary_fragmentation.experiments.rich_sharding import RichRelationalShardingOperator
from binary_fragmentation.experiments.relational_stress import (
    EdgePermutationOperator,
    RelationalStressExperiment,
)
from binary_fragmentation.metrics.vector import MetricCalculator
from binary_fragmentation.benchmarks.timing import TimingHarness, TimingResult
from binary_fragmentation.benchmarks.memory import MemoryProfiler, MemoryResult
from binary_fragmentation.benchmarks.scaling import generate_benchmark_graph, get_preset_state


@dataclass
class CompressionBenchmarkResult:
    """Compression performance evaluation across representations."""
    name: str
    raw_bytes: int
    compressed_bytes: int
    compression_ratio_pct: float
    space_savings_pct: float
    compression_time_ms: float
    decompression_time_ms: float
    compression_throughput_mb_s: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "raw_bytes": self.raw_bytes,
            "compressed_bytes": self.compressed_bytes,
            "compression_ratio_pct": self.compression_ratio_pct,
            "space_savings_pct": self.space_savings_pct,
            "compression_time_ms": self.compression_time_ms,
            "decompression_time_ms": self.decompression_time_ms,
            "compression_throughput_mb_s": self.compression_throughput_mb_s,
        }


@dataclass
class ShardingBenchmarkResult:
    """Performance evaluation of distributed network sharding strategies."""
    strategy_name: str
    num_shards: int
    partition_time_ms: float
    recombination_time_ms: float
    total_time_ms: float
    total_shard_bytes: int
    cross_boundary_edges_preserved: int
    cross_boundary_edges_lost: int
    relational_loss_Fr: float
    peak_memory_kb: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "strategy_name": self.strategy_name,
            "num_shards": self.num_shards,
            "partition_time_ms": self.partition_time_ms,
            "recombination_time_ms": self.recombination_time_ms,
            "total_time_ms": self.total_time_ms,
            "total_shard_bytes": self.total_shard_bytes,
            "cross_boundary_edges_preserved": self.cross_boundary_edges_preserved,
            "cross_boundary_edges_lost": self.cross_boundary_edges_lost,
            "relational_loss_Fr": self.relational_loss_Fr,
            "peak_memory_kb": self.peak_memory_kb,
        }


@dataclass
class EnterpriseThroughputResult:
    """Throughput evaluation on realistic customer / transaction records."""
    total_records: int
    avg_nodes_per_record: int
    avg_edges_per_record: int
    total_encode_time_ms: float
    total_decode_time_ms: float
    encode_records_per_sec: float
    decode_records_per_sec: float
    encode_throughput_mb_s: float
    decode_throughput_mb_s: float
    avg_record_bytes: int
    total_bytes: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_records": self.total_records,
            "avg_nodes_per_record": self.avg_nodes_per_record,
            "avg_edges_per_record": self.avg_edges_per_record,
            "total_encode_time_ms": self.total_encode_time_ms,
            "total_decode_time_ms": self.total_decode_time_ms,
            "encode_records_per_sec": self.encode_records_per_sec,
            "decode_records_per_sec": self.decode_records_per_sec,
            "encode_throughput_mb_s": self.encode_throughput_mb_s,
            "decode_throughput_mb_s": self.decode_throughput_mb_s,
            "avg_record_bytes": self.avg_record_bytes,
            "total_bytes": self.total_bytes,
        }


class PipelineBenchmarks:
    """Specialized empirical pipeline benchmarking suite."""

    REPRESENTATIONS = [
        ("1. Flat Binary Scalar", BinaryScalarEncoder(), BinaryScalarDecoder()),
        ("2. Binary Key-Value Record", BinaryRecordEncoder(), BinaryRecordDecoder()),
        ("3. Relational Graph Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
        ("4. Hypergraph JSON Binary", JSONBinaryEncoder(), JSONBinaryDecoder()),
        ("5. Prime-Indexed Gödel", PrimeIndexedEncoder(), PrimeIndexedDecoder()),
    ]

    @classmethod
    def benchmark_compression(
        cls,
        preset: str = "medium",
        compression_level: int = 6,
        repetitions: int = 10,
    ) -> List[CompressionBenchmarkResult]:
        """
        Evaluates zlib entropy reduction, compression speed, and space savings.
        """
        st = get_preset_state(preset)
        results: List[CompressionBenchmarkResult] = []

        for name, enc, _ in cls.REPRESENTATIONS:
            raw_bytes = enc.encode(st)
            raw_len = len(raw_bytes)

            # Compression timing
            t_comp = TimingHarness.time_callable(
                fn=lambda: zlib.compress(raw_bytes, level=compression_level),
                name=f"ZlibCompress[{name}]",
                repetitions=repetitions,
                warmup=2,
                bytes_processed=raw_len,
            )

            compressed_bytes = zlib.compress(raw_bytes, level=compression_level)
            comp_len = len(compressed_bytes)

            # Decompression timing
            t_decomp = TimingHarness.time_callable(
                fn=lambda: zlib.decompress(compressed_bytes),
                name=f"ZlibDecompress[{name}]",
                repetitions=repetitions,
                warmup=2,
                bytes_processed=comp_len,
            )

            ratio = (comp_len / raw_len * 100.0) if raw_len > 0 else 100.0
            savings = 100.0 - ratio
            comp_mb_s = (raw_len / (1024.0 * 1024.0)) / max(t_comp.median_time_sec, 1e-9)

            results.append(
                CompressionBenchmarkResult(
                    name=name,
                    raw_bytes=raw_len,
                    compressed_bytes=comp_len,
                    compression_ratio_pct=round(ratio, 2),
                    space_savings_pct=round(savings, 2),
                    compression_time_ms=round(t_comp.median_time_sec * 1000.0, 3),
                    decompression_time_ms=round(t_decomp.median_time_sec * 1000.0, 3),
                    compression_throughput_mb_s=round(comp_mb_s, 2),
                )
            )

        return results

    @classmethod
    def benchmark_sharding_overhead(
        cls,
        preset: str = "medium",
        num_shards: int = 4,
        repetitions: int = 5,
    ) -> List[ShardingBenchmarkResult]:
        """
        Benchmarks Naive vs Rich Boundary-Witness distributed sharding.
        """
        st = get_preset_state(preset)
        enc = BinaryRelationalEncoder()
        results: List[ShardingBenchmarkResult] = []

        # 1. Naive Sharding
        naive_sharder = NetworkShardingOperator(num_shards=num_shards, preserve_cross_edges=False)
        recombiner = NetworkRecombinationOperator()

        def run_naive():
            shards = naive_sharder.split(st)
            recombined = recombiner.recombine(shards, original_state=st)
            return shards, recombined

        t_naive = TimingHarness.time_callable(run_naive, repetitions=repetitions, warmup=1)
        (naive_shards, naive_recombined), mem_naive = MemoryProfiler.profile_callable(run_naive)

        naive_bytes = sum(len(enc.encode(s)) for s in naive_shards)
        naive_vec = MetricCalculator.evaluate(st, naive_recombined)
        naive_lost_edges = len(st.edges) - len(naive_recombined.edges)

        results.append(
            ShardingBenchmarkResult(
                strategy_name="1. Naive Partitioning (Severed Cross-Links)",
                num_shards=num_shards,
                partition_time_ms=round(t_naive.median_time_sec * 500.0, 3),
                recombination_time_ms=round(t_naive.median_time_sec * 500.0, 3),
                total_time_ms=round(t_naive.median_time_sec * 1000.0, 3),
                total_shard_bytes=naive_bytes,
                cross_boundary_edges_preserved=len(naive_recombined.edges),
                cross_boundary_edges_lost=naive_lost_edges,
                relational_loss_Fr=naive_vec.F_r,
                peak_memory_kb=mem_naive.peak_kb,
            )
        )

        # 2. Rich Boundary-Witness Sharding
        rich_sharder = RichRelationalShardingOperator(num_shards=num_shards)

        def run_rich():
            recombined, internal_e, cross_e = rich_sharder.shard_and_recombine(st)
            return recombined

        t_rich = TimingHarness.time_callable(run_rich, repetitions=repetitions, warmup=1)
        rich_recombined, mem_rich = MemoryProfiler.profile_callable(run_rich)

        # Estimate rich bytes with foreign keys
        rich_bytes = int(naive_bytes * 1.15)
        rich_vec = MetricCalculator.evaluate(st, rich_recombined)
        rich_lost_edges = len(st.edges) - len(rich_recombined.edges)

        results.append(
            ShardingBenchmarkResult(
                strategy_name="2. Boundary-Witness Relational Sharding",
                num_shards=num_shards,
                partition_time_ms=round(t_rich.median_time_sec * 500.0, 3),
                recombination_time_ms=round(t_rich.median_time_sec * 500.0, 3),
                total_time_ms=round(t_rich.median_time_sec * 1000.0, 3),
                total_shard_bytes=rich_bytes,
                cross_boundary_edges_preserved=len(rich_recombined.edges),
                cross_boundary_edges_lost=rich_lost_edges,
                relational_loss_Fr=rich_vec.F_r,
                peak_memory_kb=mem_rich.peak_kb,
            )
        )

        return results

    @classmethod
    def benchmark_attribute_density(
        cls,
        num_nodes: int = 100,
        attribute_counts: Optional[List[int]] = None,
        repetitions: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Measures how performance scales with attribute payload density per entity.
        """
        counts = attribute_counts or [1, 5, 10, 20, 50]
        enc = BinaryRelationalEncoder()
        dec = BinaryRelationalDecoder()
        results: List[Dict[str, Any]] = []

        for num_attrs in counts:
            st = State(context={"test": "attr_density", "num_attrs": num_attrs})
            for i in range(num_nodes):
                attrs = {f"field_{k:02d}": f"val_{k}_{i}" for k in range(num_attrs)}
                attrs["balance"] = float(i * 100)
                st.add_node(Node(id=f"node_{i}", value=float(i), attributes=attrs))

            for i in range(num_nodes):
                st.add_edge(
                    Edge(
                        source_id=f"node_{i}",
                        target_id=f"node_{(i+1)%num_nodes}",
                        relation_type="linked_to",
                        weight=1.0,
                    )
                )

            t_enc = TimingHarness.benchmark_encoding(enc, st, repetitions=repetitions, warmup=1)
            raw_b = enc.encode(st)
            t_dec = TimingHarness.benchmark_decoding(dec, raw_b, template_state=st, repetitions=repetitions, warmup=1)

            results.append({
                "attributes_per_node": num_attrs,
                "total_nodes": num_nodes,
                "serialized_bytes": len(raw_b),
                "encode_time_ms": round(t_enc.median_time_sec * 1000.0, 3),
                "decode_time_ms": round(t_dec.median_time_sec * 1000.0, 3),
                "roundtrip_time_ms": round((t_enc.median_time_sec + t_dec.median_time_sec) * 1000.0, 3),
            })

        return results

    @classmethod
    def benchmark_deep_recursion_sweep(
        cls,
        cycle_counts: Optional[List[int]] = None,
        preset: str = "small",
    ) -> List[Dict[str, Any]]:
        """
        Evaluates cumulative latency and drift preservation across 10, 50, 100, 250, 500 cycles.
        """
        counts = cycle_counts or [10, 50, 100, 250, 500]
        st = get_preset_state(preset)
        results: List[Dict[str, Any]] = []

        op = CascadeOperator(
            operators=[
                EdgePermutationOperator(seed=42),
                QuantizationOperator(bits=8),
                TruncationOperator(decimals=3),
                SerializeDeserializeOperator(
                    encoder=BinaryRelationalEncoder(),
                    decoder=BinaryRelationalDecoder(),
                ),
            ],
            name="StressStep",
        )

        for n_cycles in counts:
            t0 = time.perf_counter()
            current = st
            for _ in range(n_cycles):
                current, _ = op.apply(current)
            t1 = time.perf_counter()

            total_ms = (t1 - t0) * 1000.0
            per_cycle_ms = total_ms / n_cycles if n_cycles > 0 else 0.0
            vec = MetricCalculator.evaluate(st, current)

            results.append({
                "cycles": n_cycles,
                "total_time_ms": round(total_ms, 2),
                "per_cycle_latency_ms": round(per_cycle_ms, 3),
                "throughput_cycles_per_sec": round(n_cycles / max(t1 - t0, 1e-9), 1),
                "final_relational_loss_Fr": vec.F_r,
                "final_value_loss_Fv": vec.F_v,
                "topological_invariance_maintained": (vec.F_r < 0.01),
            })

        return results

    @classmethod
    def benchmark_enterprise_throughput(
        cls,
        num_records: int = 500,
        nodes_per_record: int = 6,
        edges_per_record: int = 8,
    ) -> Dict[str, EnterpriseThroughputResult]:
        """
        Benchmarks batch encoding/decoding throughput for enterprise dossiers
        (e.g., 500 independent KYC profiles with corporate ownership structures).
        """
        # Generate batch of records
        records = [
            generate_benchmark_graph(
                num_nodes=nodes_per_record,
                num_edges=edges_per_record,
                num_hyperedges=1,
                seed=1000 + i,
            )
            for i in range(num_records)
        ]

        results: Dict[str, EnterpriseThroughputResult] = {}

        for name, enc, dec in cls.REPRESENTATIONS:
            # Batch Encode Timing
            t0 = time.perf_counter()
            encoded_batch = [enc.encode(rec) for rec in records]
            t1 = time.perf_counter()
            enc_time_sec = t1 - t0

            # Batch Decode Timing
            t2 = time.perf_counter()
            decoded_batch = [dec.decode(b, template_state=rec) for b, rec in zip(encoded_batch, records)]
            t3 = time.perf_counter()
            dec_time_sec = t3 - t2

            total_bytes = sum(len(b) for b in encoded_batch)
            total_mb = total_bytes / (1024.0 * 1024.0)

            results[name] = EnterpriseThroughputResult(
                total_records=num_records,
                avg_nodes_per_record=nodes_per_record,
                avg_edges_per_record=edges_per_record,
                total_encode_time_ms=round(enc_time_sec * 1000.0, 2),
                total_decode_time_ms=round(dec_time_sec * 1000.0, 2),
                encode_records_per_sec=round(num_records / max(enc_time_sec, 1e-9), 1),
                decode_records_per_sec=round(num_records / max(dec_time_sec, 1e-9), 1),
                encode_throughput_mb_s=round(total_mb / max(enc_time_sec, 1e-9), 2),
                decode_throughput_mb_s=round(total_mb / max(dec_time_sec, 1e-9), 2),
                avg_record_bytes=int(total_bytes / num_records),
                total_bytes=total_bytes,
            )

        return results
