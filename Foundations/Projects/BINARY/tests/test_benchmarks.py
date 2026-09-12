"""
tests/test_benchmarks.py
========================
Comprehensive Unit Test Suite for the BFS Performance Benchmark Harness.
"""

import os
import sys
import unittest

# Ensure package root is in sys.path
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_DIR not in sys.path:
    sys.path.insert(0, PROJECT_DIR)

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.encoder import BinaryScalarEncoder, BinaryRelationalEncoder
from binary_fragmentation.core.decoder import BinaryScalarDecoder, BinaryRelationalDecoder
from binary_fragmentation.core.operators import IdentityOperator, QuantizationOperator
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
from binary_fragmentation.benchmarks.report import BenchmarkReportGenerator, render_ascii_scaling_chart
from binary_fragmentation.benchmarks.runner import BenchmarkSuite


class TestTimingHarness(unittest.TestCase):
    """Verifies precision timing, GC management, and statistical metrics."""

    def setUp(self):
        self.state = get_preset_state("small")
        self.enc = BinaryScalarEncoder()
        self.dec = BinaryScalarDecoder()

    def test_time_callable_basic(self):
        call_count = 0

        def dummy_action():
            nonlocal call_count
            call_count += 1

        res = TimingHarness.time_callable(dummy_action, name="test_dummy", repetitions=5, warmup=2)
        self.assertEqual(res.name, "test_dummy")
        self.assertEqual(res.iterations, 5)
        self.assertEqual(call_count, 7)  # 2 warmup + 5 measurement
        self.assertGreater(res.throughput_ops_per_sec, 0.0)
        self.assertGreaterEqual(res.max_time_sec, res.min_time_sec)
        self.assertGreaterEqual(res.p99_time_sec, res.p95_time_sec)

        d = res.to_dict()
        self.assertIn("mean_time_ms", d)
        self.assertIn("median_time_ms", d)

    def test_benchmark_encoding_and_decoding(self):
        t_enc = TimingHarness.benchmark_encoding(self.enc, self.state, repetitions=3, warmup=1)
        self.assertGreater(t_enc.bytes_processed, 0)
        self.assertGreater(t_enc.throughput_bytes_per_sec, 0.0)

        raw = self.enc.encode(self.state)
        t_dec = TimingHarness.benchmark_decoding(self.dec, raw, template_state=self.state, repetitions=3, warmup=1)
        self.assertGreater(t_dec.iterations, 0)

    def test_benchmark_roundtrip(self):
        t_rt = TimingHarness.benchmark_roundtrip(self.enc, self.dec, self.state, repetitions=3, warmup=1)
        self.assertGreater(t_rt.iterations, 0)
        self.assertGreater(t_rt.throughput_ops_per_sec, 0.0)

    def test_benchmark_pipeline(self):
        op = QuantizationOperator(bits=8)
        t_pipe = TimingHarness.benchmark_pipeline(op, self.state, repetitions=3, warmup=1)
        self.assertGreater(t_pipe.iterations, 0)

    def test_benchmark_recursive_stress(self):
        op = IdentityOperator()
        t_stress = TimingHarness.benchmark_recursive_stress(op, self.state, cycles=5, repetitions=2, warmup=1)
        self.assertGreater(t_stress.total_time_sec, 0.0)


class TestMemoryProfiler(unittest.TestCase):
    """Verifies tracemalloc memory profiling and allocation tracking."""

    def setUp(self):
        self.state = get_preset_state("small")
        self.enc = BinaryRelationalEncoder()
        self.dec = BinaryRelationalDecoder()

    def test_profile_encoding_and_decoding(self):
        data, mem_enc = MemoryProfiler.profile_encoding(self.enc, self.state)
        self.assertIsInstance(data, bytes)
        self.assertGreater(mem_enc.peak_bytes, 0)
        self.assertGreater(mem_enc.peak_kb, 0.0)
        self.assertEqual(mem_enc.serialized_bytes, len(data))

        decoded_state, mem_dec = MemoryProfiler.profile_decoding(self.dec, data, template_state=self.state)
        self.assertEqual(len(decoded_state.nodes), len(self.state.nodes))
        self.assertGreater(mem_dec.peak_bytes, 0)

        d = mem_enc.to_dict()
        self.assertIn("peak_kb", d)
        self.assertIn("serialized_bytes", d)

    def test_profile_roundtrip(self):
        st_out, mem_rt = MemoryProfiler.profile_roundtrip(self.enc, self.dec, self.state)
        self.assertEqual(len(st_out.edges), len(self.state.edges))
        self.assertGreater(mem_rt.peak_bytes, 0)

    def test_profile_pipeline(self):
        op = IdentityOperator()
        st_out, mem_pipe = MemoryProfiler.profile_pipeline(op, self.state)
        self.assertEqual(len(st_out.nodes), len(self.state.nodes))
        self.assertGreater(mem_pipe.peak_bytes, 0)


class TestScalingModule(unittest.TestCase):
    """Verifies synthetic state scaling generators and asymptotic power-law fitting."""

    def test_generate_benchmark_graph(self):
        st = generate_benchmark_graph(num_nodes=20, num_edges=30, num_hyperedges=3, seed=123)
        self.assertEqual(len(st.nodes), 20)
        self.assertEqual(len(st.edges), 30)
        self.assertEqual(len(st.hyperedges), 3)
        self.assertIn("domain", st.context)

        # Check node attribute integrity
        node_0 = list(st.nodes.values())[0]
        self.assertIn("role", node_0.attributes)
        self.assertIn("risk_score", node_0.attributes)

    def test_presets(self):
        for preset in ["small", "medium", "large"]:
            st = get_preset_state(preset)
            self.assertGreater(len(st.nodes), 0)
            self.assertGreater(len(st.edges), 0)

    def test_power_law_fit(self):
        x = [10.0, 50.0, 100.0, 500.0]
        # Linear y = 2.0 * x^1.0
        y = [2.0 * xi for xi in x]
        alpha, k, r2 = ScalingBenchmarkRunner._fit_power_law(x, y)
        self.assertAlmostEqual(alpha, 1.0, places=1)
        self.assertGreaterEqual(r2, 0.99)

        # Quadratic y = 0.5 * x^2.0
        y_quad = [0.5 * (xi ** 2) for xi in x]
        alpha_q, _, r2_q = ScalingBenchmarkRunner._fit_power_law(x, y_quad)
        self.assertAlmostEqual(alpha_q, 2.0, places=1)
        self.assertGreaterEqual(r2_q, 0.99)

    def test_run_scaling_sweep_mini(self):
        sweep_res = ScalingBenchmarkRunner.run_scaling_sweep(
            node_counts=[5, 10],
            edge_multiplier=1.5,
            hyperedge_multiplier=0.1,
            repetitions=2,
            warmup=1,
        )
        self.assertIsInstance(sweep_res, ScalingSweepResult)
        self.assertEqual(len(sweep_res.points), 2)
        self.assertIn("1. Flat Binary Scalar", sweep_res.asymptotic_growth_exponents)


class TestPipelineBenchmarks(unittest.TestCase):
    """Verifies specialized pipeline benchmarks."""

    def test_compression_benchmark(self):
        comp_res = PipelineBenchmarks.benchmark_compression(preset="small", repetitions=2)
        self.assertEqual(len(comp_res), 5)
        # Relational binary should have space savings > 50%
        rel_row = next(r for r in comp_res if "Relational Graph" in r.name)
        self.assertGreater(rel_row.space_savings_pct, 40.0)
        self.assertGreater(rel_row.compression_throughput_mb_s, 0.0)

    def test_sharding_benchmark(self):
        shard_res = PipelineBenchmarks.benchmark_sharding_overhead(preset="small", num_shards=2, repetitions=2)
        self.assertEqual(len(shard_res), 2)
        naive = shard_res[0]
        rich = shard_res[1]
        self.assertGreaterEqual(naive.relational_loss_Fr, 0.0)
        self.assertAlmostEqual(rich.relational_loss_Fr, 0.0, places=2)

    def test_attribute_density_benchmark(self):
        attr_res = PipelineBenchmarks.benchmark_attribute_density(
            num_nodes=10,
            attribute_counts=[1, 5],
            repetitions=2,
        )
        self.assertEqual(len(attr_res), 2)
        self.assertGreater(attr_res[1]["serialized_bytes"], attr_res[0]["serialized_bytes"])

    def test_deep_recursion_sweep(self):
        rec_res = PipelineBenchmarks.benchmark_deep_recursion_sweep(cycle_counts=[5, 10], preset="small")
        self.assertEqual(len(rec_res), 2)
        self.assertTrue(rec_res[0]["topological_invariance_maintained"])
        self.assertTrue(rec_res[1]["topological_invariance_maintained"])

    def test_enterprise_throughput(self):
        ent_res = PipelineBenchmarks.benchmark_enterprise_throughput(
            num_records=10,
            nodes_per_record=4,
            edges_per_record=5,
        )
        self.assertEqual(len(ent_res), 5)
        for name, row in ent_res.items():
            self.assertGreater(row.encode_records_per_sec, 0.0)
            self.assertGreater(row.decode_records_per_sec, 0.0)


class TestReportGenerator(unittest.TestCase):
    """Verifies ASCII chart rendering and Markdown report generation."""

    def test_render_ascii_scaling_chart(self):
        series_map = {
            "1. Flat Binary Scalar": [0.1, 0.5, 1.0],
            "3. Relational Graph Binary": [1.0, 5.0, 10.0],
        }
        labels = ["N=10", "N=50", "N=100"]
        chart = render_ascii_scaling_chart(series_map, labels)
        self.assertIn("N=10", chart)
        self.assertIn("Legend", chart)

    def test_generate_markdown_report_comprehensive(self):
        suite_data = BenchmarkSuite.run_all(quick=True)
        report_md = BenchmarkReportGenerator.generate_markdown_report(suite_data)
        self.assertIn("# Binary Fragmentation Simulator", report_md)
        self.assertIn("1. Executive Summary", report_md)
        self.assertIn("2. Representation Performance Comparison", report_md)
        self.assertIn("3. Asymptotic Scaling Analysis", report_md)
        self.assertIn("4. Compression Efficiency", report_md)
        self.assertIn("5. Distributed Network Sharding", report_md)
        self.assertIn("6. Attribute Density Scaling", report_md)
        self.assertIn("7. Pipeline Transformation Latencies", report_md)
        self.assertIn("8. Deep Multi-Cycle Recursion", report_md)
        self.assertIn("9. Real-World Enterprise Batch Throughput", report_md)
        self.assertIn("10. Trade-off Analysis: The Cost of Relational Fidelity Matrix", report_md)


class TestBenchmarkSuiteOrchestration(unittest.TestCase):
    """Verifies end-to-end orchestration of all benchmark components."""

    def test_representation_comparison(self):
        res = BenchmarkSuite.run_representation_comparison(preset="small", repetitions=2, warmup=1)
        self.assertEqual(len(res["results"]), 5)
        for r in res["results"]:
            self.assertGreater(r["encode_ops_sec"], 0.0)
            self.assertGreater(r["peak_memory_kb"], 0.0)

    def test_pipeline_benchmarks(self):
        res = BenchmarkSuite.run_pipeline_benchmarks(preset="small", repetitions=2, warmup=1)
        self.assertGreaterEqual(len(res), 8)

    def test_tradeoff_analysis(self):
        rows = BenchmarkSuite.run_tradeoff_analysis(preset="small", repetitions=2)
        self.assertEqual(len(rows), 5)
        # Flat scalar must have F_r == 1.0
        self.assertAlmostEqual(rows[0]["relational_loss_Fr"], 1.0, places=2)
        # Relational binary must have F_r == 0.0
        self.assertAlmostEqual(rows[2]["relational_loss_Fr"], 0.0, places=2)


if __name__ == "__main__":
    unittest.main()
