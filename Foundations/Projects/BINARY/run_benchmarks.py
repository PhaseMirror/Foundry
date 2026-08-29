#!/usr/bin/env python3
"""
run_benchmarks.py
=================
Top-level executable runner for the BFS Computational Performance Benchmark Suite.
Measures execution timing, memory footprints, scaling dynamics, and trade-off metrics.
"""

from __future__ import annotations
import argparse
import json
import os
import sys

# Add directory to sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from binary_fragmentation.benchmarks.runner import BenchmarkSuite
from binary_fragmentation.benchmarks.report import BenchmarkReportGenerator


def main() -> int:
    parser = argparse.ArgumentParser(
        description="BFS Computational Performance & Scalability Benchmark Suite"
    )
    parser.add_argument(
        "--preset",
        type=str,
        default="medium",
        choices=["small", "medium", "large", "very_large"],
        help="State size preset for representation comparison and pipeline latency",
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Run accelerated benchmark with reduced iterations and scale points",
    )
    parser.add_argument(
        "--nodes",
        type=str,
        default="",
        help="Comma-separated list of node counts for scale sweep (e.g., 10,50,100,500,1000)",
    )
    parser.add_argument(
        "--reps",
        type=int,
        default=5,
        help="Number of repetitions per measurement",
    )
    parser.add_argument(
        "--out",
        type=str,
        default="",
        help="Output markdown report file path",
    )
    parser.add_argument(
        "--json-out",
        type=str,
        default="",
        help="Output JSON benchmark telemetry file path",
    )

    args = parser.parse_args()

    print("=" * 80)
    print("  BINARY FRAGMENTATION SIMULATOR (BFS) — PERFORMANCE & SCALABILITY BENCHMARK")
    print("  Computational Cost & Asymptotic Growth Analysis of Relational Encodings")
    print("=" * 80)

    node_counts = None
    if args.nodes:
        node_counts = [int(x.strip()) for x in args.nodes.split(",") if x.strip().isdigit()]

    suite_data = BenchmarkSuite.run_all(
        quick=args.quick,
        preset=args.preset,
        node_counts=node_counts,
        repetitions=args.reps,
    )

    md_report = BenchmarkReportGenerator.generate_markdown_report(suite_data)
    print("\n" + md_report)

    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(md_report)
        print(f"\n[✓] Performance benchmark report exported to {args.out}")

    if args.json_out:
        os.makedirs(os.path.dirname(os.path.abspath(args.json_out)), exist_ok=True)
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(suite_data, f, indent=2)
        print(f"[✓] Benchmark JSON telemetry exported to {args.json_out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
