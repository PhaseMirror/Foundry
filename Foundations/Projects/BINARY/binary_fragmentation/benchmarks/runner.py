"""
binary_fragmentation/benchmarks/runner.py
=========================================
Unified Benchmark Suite Runner.

Orchestrates all computational performance benchmarks across representations,
transformation pipelines, scaling sweeps, recursive stress cascades, and
trade-off analyses.
"""

from __future__ import annotations
import time
from typing import Any, Dict, List, Optional

from binary_fragmentation.core.state import State
from binary_fragmentation.core.encoder import (
    BinaryScalarEncoder,
    BinaryRecordEncoder,
    BinaryRelationalEncoder,
    JSONBinaryEncoder,
    PrimeIndexedEncoder,
)
from binary_fragmentation.core.decoder import (
    BinaryScalarDecoder,
    BinaryRecordDecoder,
    BinaryRelationalDecoder,
    JSONBinaryDecoder,
    PrimeIndexedDecoder,
)
from binary_fragmentation.core.operators import (
    IdentityOperator,
    QuantizationOperator,
    TruncationOperator,
    HashingOperator,
    SerializeDeserializeOperator,
    CascadeOperator,
)
from binary_fragmentation.experiments.relational_stress import (
    EdgePermutationOperator,
    RelationalStressExperiment,
)
from binary_fragmentation.metrics.vector import MetricCalculator
from binary_fragmentation.benchmarks.timing import TimingHarness, TimingResult
from binary_fragmentation.benchmarks.memory import MemoryProfiler, MemoryResult
from binary_fragmentation.benchmarks.scaling import (
    generate_benchmark_graph,
    get_preset_state,
    ScalingBenchmarkRunner,
    ScalingSweepResult,
)


from binary_fragmentation.benchmarks.pipelines import (
    PipelineBenchmarks,
    CompressionBenchmarkResult,
    ShardingBenchmarkResult,
    EnterpriseThroughputResult,
)


class BenchmarkSuite:
    """
    Main orchestrator for the performance and scalability benchmarking suite.
    """

    REPRESENTATIONS = [
        ("1. Flat Binary Scalar", BinaryScalarEncoder(), BinaryScalarDecoder()),
        ("2. Binary Key-Value Record", BinaryRecordEncoder(), BinaryRecordDecoder()),
        ("3. Relational Graph Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
        ("4. Hypergraph JSON Binary", JSONBinaryEncoder(), JSONBinaryDecoder()),
        ("5. Prime-Indexed Gödel", PrimeIndexedEncoder(), PrimeIndexedDecoder()),
    ]

    @classmethod
    def run_representation_comparison(
        cls,
        preset: str = "medium",
        repetitions: int = 10,
        warmup: int = 2,
    ) -> Dict[str, Any]:
        """Runs fixed-state benchmark comparing the 5 representations."""
        st = get_preset_state(preset)
        results = []

        for name, enc, dec in cls.REPRESENTATIONS:
            t_enc = TimingHarness.benchmark_encoding(enc, st, repetitions=repetitions, warmup=warmup)
            enc_bytes = enc.encode(st)
            t_dec = TimingHarness.benchmark_decoding(dec, enc_bytes, template_state=st, repetitions=repetitions, warmup=warmup)
            t_rt = TimingHarness.benchmark_roundtrip(enc, dec, st, repetitions=repetitions, warmup=warmup)

            _, mem_enc = MemoryProfiler.profile_encoding(enc, st)
            _, mem_dec = MemoryProfiler.profile_decoding(dec, enc_bytes, template_state=st)
            peak_kb = max(mem_enc.peak_kb, mem_dec.peak_kb)

            results.append({
                "name": name,
                "encode_time_ms": t_enc.median_time_sec * 1000.0,
                "decode_time_ms": t_dec.median_time_sec * 1000.0,
                "roundtrip_time_ms": t_rt.median_time_sec * 1000.0,
                "encode_ops_sec": t_enc.throughput_ops_per_sec,
                "decode_ops_sec": t_dec.throughput_ops_per_sec,
                "roundtrip_ops_sec": t_rt.throughput_ops_per_sec,
                "peak_memory_kb": peak_kb,
                "serialized_bytes": len(enc_bytes),
            })

        return {
            "preset": preset,
            "state_profile": {
                "nodes": len(st.nodes),
                "edges": len(st.edges),
                "hyperedges": len(st.hyperedges),
            },
            "results": results,
        }

    @classmethod
    def run_pipeline_benchmarks(
        cls,
        preset: str = "medium",
        repetitions: int = 10,
        warmup: int = 2,
    ) -> List[Dict[str, Any]]:
        """Benchmarks latencies across distinct transformation pipelines."""
        st = get_preset_state(preset)

        pipelines = [
            ("1. Lossless Identity Pass", IdentityOperator()),
            ("2. Attribute Quantization (8-bit)", QuantizationOperator(bits=8)),
            ("3. Precision Truncation (2 dec)", TruncationOperator(decimals=2)),
            ("4. Isomorphic Edge Permutation", EdgePermutationOperator(seed=42)),
            ("5. Cryptographic One-Way Hashing", HashingOperator()),
            (
                "6. Flat Binary Round-Trip",
                SerializeDeserializeOperator(
                    encoder=BinaryScalarEncoder(),
                    decoder=BinaryScalarDecoder(),
                    name="FlatRoundTrip",
                ),
            ),
            (
                "7. Relational Binary Round-Trip",
                SerializeDeserializeOperator(
                    encoder=BinaryRelationalEncoder(),
                    decoder=BinaryRelationalDecoder(),
                    name="RelationalRoundTrip",
                ),
            ),
            (
                "8. Quantization + Relational Serialization Cascade",
                CascadeOperator(
                    operators=[
                        QuantizationOperator(bits=8),
                        SerializeDeserializeOperator(
                            encoder=BinaryRelationalEncoder(),
                            decoder=BinaryRelationalDecoder(),
                        ),
                    ],
                    name="QuantizeSerializeCascade",
                ),
            ),
            (
                "9. Deep Relational Stress Cycle (4 Ops)",
                CascadeOperator(
                    operators=[
                        EdgePermutationOperator(seed=42),
                        QuantizationOperator(bits=8),
                        TruncationOperator(decimals=3),
                        SerializeDeserializeOperator(
                            encoder=BinaryRelationalEncoder(),
                            decoder=BinaryRelationalDecoder(),
                        ),
                    ],
                    name="StressCycle4Ops",
                ),
            ),
        ]

        results = []
        for name, op in pipelines:
            t_res = TimingHarness.benchmark_pipeline(op, st, name=name, repetitions=repetitions, warmup=warmup)
            results.append(t_res.to_dict())

        return results

    @classmethod
    def run_scaling_sweep(
        cls,
        node_counts: Optional[List[int]] = None,
        repetitions: int = 5,
        warmup: int = 1,
    ) -> Dict[str, Any]:
        """Runs scalable state sweep across representations."""
        counts = node_counts or [10, 50, 100, 500, 1000]
        res = ScalingBenchmarkRunner.run_scaling_sweep(
            node_counts=counts,
            repetitions=repetitions,
            warmup=warmup,
        )
        return res.to_dict()

    @classmethod
    def run_recursive_stress_latency(
        cls,
        cycles: int = 25,
        preset: str = "small",
        repetitions: int = 3,
    ) -> Dict[str, Any]:
        """Evaluates execution latency across recursive transformation cycles."""
        st = get_preset_state(preset)
        exp = RelationalStressExperiment(cycles=cycles)

        t_res = TimingHarness.time_callable(
            fn=lambda: exp.run(st),
            name=f"RecursiveStress_x{cycles}",
            repetitions=repetitions,
            warmup=1,
        )

        res_data = exp.run(st)
        total_time_ms = t_res.median_time_sec * 1000.0
        per_cycle_ms = total_time_ms / cycles if cycles > 0 else 0.0

        return {
            "cycles": cycles,
            "preset": preset,
            "total_time_ms": total_time_ms,
            "per_cycle_latency_ms": per_cycle_ms,
            "cycles_per_sec": (cycles / t_res.median_time_sec) if t_res.median_time_sec > 0 else 0.0,
            "final_F_r": res_data.get("final_vector", {}).get("F_r", 0.0),
            "timing_details": t_res.to_dict(),
        }

    @classmethod
    def run_tradeoff_analysis(
        cls,
        preset: str = "medium",
        repetitions: int = 10,
    ) -> List[Dict[str, Any]]:
        """Evaluates the Trade-off Matrix between Information Loss (F_r) and Computational Cost."""
        st = get_preset_state(preset)
        tradeoff_rows = []

        baseline_time_ms = 1.0

        for idx, (name, enc, dec) in enumerate(cls.REPRESENTATIONS):
            # Timing
            t_rt = TimingHarness.benchmark_roundtrip(enc, dec, st, repetitions=repetitions, warmup=2)
            rt_ms = t_rt.median_time_sec * 1000.0

            if idx == 0:
                baseline_time_ms = max(rt_ms, 1e-6)

            slowdown = rt_ms / baseline_time_ms

            # Memory
            raw_bytes = enc.encode(st)
            _, mem = MemoryProfiler.profile_roundtrip(enc, dec, st)

            # Metric evaluation
            decoded = dec.decode(raw_bytes, template_state=st)
            vec = MetricCalculator.evaluate(st, decoded)

            verdict = (
                "Critical Loss (Severed Topology)"
                if vec.F_r > 0.5
                else "Lossless Relational Fidelity"
            )

            tradeoff_rows.append({
                "name": name,
                "relational_loss_Fr": vec.F_r,
                "value_loss_Fv": vec.F_v,
                "structural_loss_Fs": vec.F_s,
                "overall_loss_L2": vec.l2_norm,
                "roundtrip_time_ms": rt_ms,
                "slowdown_factor": slowdown,
                "peak_memory_kb": mem.peak_kb,
                "serialized_bytes": len(raw_bytes),
                "verdict": verdict,
            })

        return tradeoff_rows

    @classmethod
    def run_all(
        cls,
        quick: bool = False,
        preset: str = "medium",
        node_counts: Optional[List[int]] = None,
        repetitions: int = 5,
    ) -> Dict[str, Any]:
        """Runs the complete suite of performance benchmarks."""
        reps = 3 if quick else repetitions
        counts = node_counts or ([10, 50, 100, 250] if quick else [10, 50, 100, 500, 1000])

        suite_data: Dict[str, Any] = {
            "timestamp": time.time(),
            "configuration": {
                "quick": quick,
                "preset": preset,
                "node_counts": counts,
                "repetitions": reps,
            },
        }

        print("  [1/8] Benchmarking 5-Way Representation Performance...")
        suite_data["representation_comparison"] = cls.run_representation_comparison(preset=preset, repetitions=reps)

        print("  [2/8] Benchmarking Pipeline Transformation Latencies...")
        suite_data["pipeline_latencies"] = cls.run_pipeline_benchmarks(preset=preset, repetitions=reps)

        print(f"  [3/8] Executing State Size Scaling Sweeps ({counts})...")
        suite_data["scaling_sweep"] = cls.run_scaling_sweep(node_counts=counts, repetitions=reps)

        print("  [4/8] Evaluating Compression Efficiency (Zlib Entropy Reduction)...")
        suite_data["compression_benchmark"] = [
            r.to_dict() for r in PipelineBenchmarks.benchmark_compression(preset=preset, repetitions=reps)
        ]

        print("  [5/8] Benchmarking Distributed Sharding (Naive vs Boundary-Witness)...")
        suite_data["sharding_benchmark"] = [
            r.to_dict() for r in PipelineBenchmarks.benchmark_sharding_overhead(preset=preset, num_shards=4, repetitions=reps)
        ]

        print("  [6/8] Sweeping Attribute Density (1 to 50 Attributes/Node)...")
        suite_data["attribute_density_sweep"] = PipelineBenchmarks.benchmark_attribute_density(
            num_nodes=50,
            attribute_counts=[1, 5, 10, 20] if quick else [1, 5, 10, 20, 50],
            repetitions=reps,
        )

        print("  [7/8] Evaluating Deep Multi-Cycle Recursion (Up to 500 Generations)...")
        cycle_list = [10, 50, 100] if quick else [10, 50, 100, 250, 500]
        suite_data["deep_recursion_sweep"] = PipelineBenchmarks.benchmark_deep_recursion_sweep(
            cycle_counts=cycle_list,
            preset="small",
        )

        print("  [8/8] Evaluating Real-World Enterprise Record Batch Throughput...")
        n_records = 100 if quick else 500
        suite_data["enterprise_throughput"] = {
            k: v.to_dict()
            for k, v in PipelineBenchmarks.benchmark_enterprise_throughput(
                num_records=n_records,
                nodes_per_record=6,
                edges_per_record=8,
            ).items()
        }

        print("  [+] Synthesizing Cost of Relational Fidelity Trade-off Matrix...")
        suite_data["tradeoff_analysis"] = cls.run_tradeoff_analysis(preset=preset, repetitions=reps)

        return suite_data

