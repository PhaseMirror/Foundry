"""
binary_fragmentation/cli.py
===========================
Command-Line Interface for the Binary Fragmentation Simulator.
"""

from __future__ import annotations
import argparse
import json
import os
import sys
from typing import Any, Dict

from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.experiments.baseline import BaselineExperiment
from binary_fragmentation.experiments.lossy import LossyBinaryExperiment
from binary_fragmentation.experiments.recursive import RecursiveDriftExperiment
from binary_fragmentation.experiments.network import NetworkFragmentationExperiment
from binary_fragmentation.experiments.comparative import ComparativeRepresentationExperiment
from binary_fragmentation.experiments.financial_relational import (
    FinancialRelationalExperiment,
    create_financial_state,
)
from binary_fragmentation.experiments.rollback import RollbackExperiment
from binary_fragmentation.experiments.relational_stress import (
    RelationalStressExperiment,
    ComparativeStressExperiment,
)
from binary_fragmentation.experiments.provenance_cascade import ProvenanceCascadeExperiment
from binary_fragmentation.experiments.rich_sharding import RichShardingExperiment
from binary_fragmentation.experiments.etl_metadata_stripping import ETLMetadataStrippingExperiment
from binary_fragmentation.experiments.adversarial_schema import AdversarialSchemaExperiment
from binary_fragmentation.experiments.temporal_permutation import TemporalPermutationExperiment
from binary_fragmentation.experiments.chained_etl_pipeline import ChainedEnterpriseETLExperiment
from binary_fragmentation.experiments.advanced_failures import AdvancedFailuresExperimentSuite
from binary_fragmentation.experiments.real_world_case_study import RealWorldCorporateCaseStudy
from binary_fragmentation.experiments.procurement_case_study import ProcurementCaseStudy
from binary_fragmentation.reports.generator import ReportGenerator


def create_sample_state() -> State:
    """Generates a rich benchmark graph with nodes, edges, hyperedges, and context."""
    st = State(
        context={"domain": "Multiplicity Social Physics", "audit_level": "Tier-1"}
    )
    # 5 nodes
    st.add_node(Node(id="node_0", value=100.0, attributes={"role": "source"}))
    st.add_node(Node(id="node_1", value=200.0, attributes={"role": "relay"}))
    st.add_node(Node(id="node_2", value=300.0, attributes={"role": "sink"}))
    st.add_node(Node(id="node_3", value=400.0, attributes={"role": "monitor"}))
    st.add_node(Node(id="node_4", value=500.0, attributes={"role": "validator"}))

    # Edges
    st.add_edge(Edge(source_id="node_0", target_id="node_1", relation_type="transmits_to", weight=1.0))
    st.add_edge(Edge(source_id="node_1", target_id="node_2", relation_type="transmits_to", weight=1.0))
    st.add_edge(Edge(source_id="node_0", target_id="node_3", relation_type="observed_by", weight=0.8))
    st.add_edge(Edge(source_id="node_2", target_id="node_4", relation_type="validated_by", weight=1.0))

    # Hyperedge
    st.add_hyperedge(HyperEdge(
        node_ids=["node_0", "node_1", "node_2"],
        relation_type="triadic_circuit",
        attributes={"resonance": 0.92},
    ))
    return st


def run_all_experiments(iterations: int = 15) -> Dict[str, Any]:
    sample = create_sample_state()

    results: Dict[str, Any] = {}
    print("▶ [1/15] Running Mode A: Baseline Lossless Binary Representation...")
    results["baseline"] = BaselineExperiment().run(sample)

    print("▶ [2/15] Running Mode B: Lossy Binary Transformation...")
    results["lossy"] = LossyBinaryExperiment().run(sample)

    print(f"▶ [3/15] Running Mode C: Recursive Drift Dynamics ({iterations} steps)...")
    results["recursive"] = RecursiveDriftExperiment(iterations=iterations).run(sample)

    print("▶ [4/15] Running Mode D: Network Sharding Fragmentation...")
    results["network"] = NetworkFragmentationExperiment().run(sample)

    print("▶ [5/15] Running Mode E: Comparative Representation Benchmark...")
    results["comparative"] = ComparativeRepresentationExperiment().run(sample)

    print("▶ [6/15] Running Section 8: Financial Relational Crucial Experiment...")
    results["financial_relational"] = FinancialRelationalExperiment().run()

    print("▶ [7/15] Running Relational Encoding Under Deep Operational Stress (25 cycles)...")
    results["relational_stress"] = RelationalStressExperiment(cycles=25).run(sample)

    print("▶ [8/15] Running 5-Way Comparative Stress Benchmark...")
    results["comparative_stress"] = ComparativeStressExperiment(cycles=10).run(sample)

    print("▶ [9/15] Running Adversarial Schema Failures (Challenging the Attractor)...")
    results["adversarial_schema"] = AdversarialSchemaExperiment().run(sample)

    print("▶ [10/15] Running Adversarial Temporal Inversion Experiment...")
    results["temporal_permutation"] = TemporalPermutationExperiment().run()

    print("▶ [11/15] Running Multi-Hop Chained Enterprise Pipeline (5 Hops)...")
    results["chained_etl"] = ChainedEnterpriseETLExperiment().run()

    print("▶ [12/15] Running Frontier Stress Suite (DP, Subsampling, Merge Collapse, Key Loss)...")
    results["advanced_failures"] = AdvancedFailuresExperimentSuite().run(sample)

    print("▶ [13/15] Running Real-World Case Study 1 (Offshore Ownership & AML)...")
    results["real_world_case_study"] = RealWorldCorporateCaseStudy().run()

    print("▶ [14/15] Running Real-World Case Study 2 (Public Procurement & Collusion)...")
    results["procurement_case_study"] = ProcurementCaseStudy().run()

    print("▶ [15/15] Running Provenance Cascade & Irreversibility Boundary...")
    results["provenance_cascade"] = ProvenanceCascadeExperiment().run(sample)

    print("▶ Running Rich vs Naive Network Sharding...")
    results["rich_sharding"] = RichShardingExperiment(num_shards=4).run(sample)

    print("▶ Running Rollback Verification...")
    results["rollback"] = RollbackExperiment().run(sample)

    return results


from binary_fragmentation.benchmarks.runner import BenchmarkSuite
from binary_fragmentation.benchmarks.report import BenchmarkReportGenerator


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Binary Fragmentation Simulator — ADR-001 Reference Implementation"
    )
    parser.add_argument("--iterations", type=int, default=15, help="Recursive drift steps")
    parser.add_argument("--out", type=str, default="", help="Output markdown report path")
    parser.add_argument("--json-out", type=str, default="", help="Output json report path")
    parser.add_argument("--benchmark", action="store_true", help="Execute computational performance benchmark suite")
    parser.add_argument("--benchmark-quick", action="store_true", help="Execute accelerated benchmark suite")
    parser.add_argument("--benchmark-preset", type=str, default="medium", choices=["small", "medium", "large", "very_large"], help="State size preset for benchmarks")
    parser.add_argument("--benchmark-out", type=str, default="", help="Output markdown benchmark report path")

    args = parser.parse_args()
    print("=" * 75)
    print("  BINARY FRAGMENTATION SIMULATOR (BFS) v1.5.0 — PRODUCTION RESEARCH SUITE")
    print("  Empirical Calculus of Information Fragmentation in Computational Systems")
    print("=" * 75)

    if args.benchmark or args.benchmark_quick:
        print("\n▶ Executing Computational Cost & Scalability Benchmark Suite...")
        bench_data = BenchmarkSuite.run_all(
            quick=args.benchmark_quick,
            preset=args.benchmark_preset,
        )
        bench_report = BenchmarkReportGenerator.generate_markdown_report(bench_data)
        print("\n" + bench_report)

        bench_out_path = args.benchmark_out or (args.out if not args.benchmark else "")
        if bench_out_path:
            os.makedirs(os.path.dirname(os.path.abspath(bench_out_path)), exist_ok=True)
            with open(bench_out_path, "w", encoding="utf-8") as f:
                f.write(bench_report)
            print(f"\n[✓] Benchmark dossier exported to {bench_out_path}")

        if args.json_out:
            os.makedirs(os.path.dirname(os.path.abspath(args.json_out)), exist_ok=True)
            with open(args.json_out, "w", encoding="utf-8") as f:
                json.dump(bench_data, f, indent=2)
            print(f"[✓] Benchmark JSON telemetry exported to {args.json_out}")

        return 0

    results = run_all_experiments(iterations=args.iterations)

    md_report = ReportGenerator.generate_markdown_report(results)
    print("\n" + md_report)

    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(md_report)
        print(f"\n[✓] Markdown research dossier exported to {args.out}")

    if args.json_out:
        os.makedirs(os.path.dirname(os.path.abspath(args.json_out)), exist_ok=True)
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)
        print(f"[✓] JSON telemetry data exported to {args.json_out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

