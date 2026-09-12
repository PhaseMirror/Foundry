"""
binary_fragmentation/benchmarks/scaling.py
==========================================
State Scaling Generators and Asymptotic Complexity Sweep Harness.

Generates scalable synthetic property graph states across small (10 nodes),
medium (100 nodes), large (1,000 nodes), and very large (10,000+ nodes) scales.
Executes automated sweeps across representations and fits empirical asymptotic
growth models (T(N) = k * N^alpha).
"""

from __future__ import annotations
import math
import random
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
from binary_fragmentation.benchmarks.timing import TimingHarness, TimingResult
from binary_fragmentation.benchmarks.memory import MemoryProfiler, MemoryResult


def generate_benchmark_graph(
    num_nodes: int,
    num_edges: int,
    num_hyperedges: int = 0,
    avg_attributes_per_node: int = 3,
    seed: int = 42,
) -> State:
    """
    Generates a deterministic synthetic property graph with typed relations,
    hyperedges, and regulatory context frames.
    """
    rng = random.Random(seed)
    st = State(
        context={
            "domain": "Enterprise Regulatory Multiplicity",
            "audit_tier": "Tier-1 Sovereign",
            "scale_profile": f"nodes_{num_nodes}_edges_{num_edges}",
            "seed": seed,
        }
    )

    roles = ["holding_co", "operating_sub", "fiduciary_trust", "wire_clearing", "escrow_agent"]
    jurisdictions = ["CH", "LU", "KY", "BVI", "GB", "US", "DE", "SG"]
    rel_types = ["beneficial_owner_of", "fiduciary_for", "syndicated_credit_to", "subcontracts_to", "settles_via"]

    # 1. Add Nodes
    for i in range(num_nodes):
        nid = f"entity_{i:06d}"
        val = round(rng.uniform(1000.0, 1000000.0), 2)
        attrs = {
            "role": roles[i % len(roles)],
            "jurisdiction": jurisdictions[i % len(jurisdictions)],
            "risk_score": round(rng.uniform(0.01, 0.99), 4),
            "tier": (i % 5) + 1,
        }
        st.add_node(
            Node(
                id=nid,
                value=val,
                attributes=attrs,
                created_at=1700000000.0 + i * 60.0,
                provenance_tag=f"prov_genesis_{i:06d}",
            )
        )

    node_ids = list(st.nodes.keys())
    if num_nodes < 2:
        return st

    # 2. Add Edges (structured network with preferential attachment / cycle motifs)
    edge_set = set()
    for e_idx in range(num_edges):
        # Prefer connecting to earlier nodes or neighboring indices
        if rng.random() < 0.6:
            src_idx = e_idx % num_nodes
            tgt_idx = (src_idx + rng.randint(1, min(5, num_nodes - 1))) % num_nodes
        else:
            src_idx = rng.randint(0, num_nodes - 1)
            tgt_idx = rng.randint(0, num_nodes - 1)

        if src_idx == tgt_idx:
            tgt_idx = (src_idx + 1) % num_nodes

        src_id = node_ids[src_idx]
        tgt_id = node_ids[tgt_idx]
        key = (src_id, tgt_id)

        if key in edge_set:
            # Shift slightly to avoid duplicate edges
            tgt_idx = (tgt_idx + 1) % num_nodes
            tgt_id = node_ids[tgt_idx]
            key = (src_id, tgt_id)

        edge_set.add(key)
        rel = rel_types[e_idx % len(rel_types)]
        w = round(rng.uniform(10000.0, 500000.0), 2)
        st.add_edge(
            Edge(
                source_id=src_id,
                target_id=tgt_id,
                relation_type=rel,
                weight=w,
                attributes={"contract_id": f"CTR-{e_idx:06d}", "active": True},
                provenance_tag=f"prov_edge_{e_idx:06d}",
            )
        )

    # 3. Add Hyperedges
    for h_idx in range(num_hyperedges):
        h_size = rng.randint(3, min(6, num_nodes))
        start_node = (h_idx * 3) % num_nodes
        h_nodes = [node_ids[(start_node + k) % num_nodes] for k in range(h_size)]
        st.add_hyperedge(
            HyperEdge(
                node_ids=h_nodes,
                relation_type="triadic_escrow_syndicate",
                attributes={
                    "facility_id": f"FAC-{h_idx:04d}",
                    "notional_limit": 50000000.0,
                    "quorum": 0.67,
                },
                provenance_tag=f"prov_hyper_{h_idx:04d}",
            )
        )

    return st


def get_preset_state(preset_name: str = "medium") -> State:
    """Returns a standardized benchmark state preset."""
    presets = {
        "small": (10, 15, 2),
        "medium": (100, 200, 10),
        "large": (1000, 2000, 50),
        "very_large": (10000, 20000, 100),
    }
    nodes, edges, hypers = presets.get(preset_name.lower(), presets["medium"])
    return generate_benchmark_graph(num_nodes=nodes, num_edges=edges, num_hyperedges=hypers)


@dataclass
class RepresentationBenchmarkMetrics:
    """Benchmark performance metrics for a single representation at a single scale."""
    name: str
    encode_time_ms: float
    decode_time_ms: float
    roundtrip_time_ms: float
    encode_throughput_ops_sec: float
    decode_throughput_ops_sec: float
    throughput_mb_sec: float
    peak_memory_kb: float
    serialized_bytes: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "encode_time_ms": self.encode_time_ms,
            "decode_time_ms": self.decode_time_ms,
            "roundtrip_time_ms": self.roundtrip_time_ms,
            "encode_throughput_ops_sec": self.encode_throughput_ops_sec,
            "decode_throughput_ops_sec": self.decode_throughput_ops_sec,
            "throughput_mb_sec": self.throughput_mb_sec,
            "peak_memory_kb": self.peak_memory_kb,
            "serialized_bytes": self.serialized_bytes,
        }


@dataclass
class ScalingSweepPoint:
    """Measurement point in a scale sweep."""
    nodes: int
    edges: int
    hyperedges: int
    metrics_by_representation: Dict[str, RepresentationBenchmarkMetrics] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "nodes": self.nodes,
            "edges": self.edges,
            "hyperedges": self.hyperedges,
            "representations": {k: v.to_dict() for k, v in self.metrics_by_representation.items()},
        }


@dataclass
class ScalingSweepResult:
    """Complete results of an empirical scale sweep across representations."""
    points: List[ScalingSweepPoint]
    representations: List[str]
    asymptotic_growth_exponents: Dict[str, Dict[str, float]] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "points": [p.to_dict() for p in self.points],
            "representations": self.representations,
            "asymptotic_growth_exponents": self.asymptotic_growth_exponents,
        }


class ScalingBenchmarkRunner:
    """
    Executes automated scaling sweeps and computes asymptotic growth models.
    """

    STANDARD_REPRESENTATIONS = [
        ("1. Flat Binary Scalar", BinaryScalarEncoder(), BinaryScalarDecoder()),
        ("2. Binary Key-Value Record", BinaryRecordEncoder(), BinaryRecordDecoder()),
        ("3. Relational Graph Binary", BinaryRelationalEncoder(), BinaryRelationalDecoder()),
        ("4. Hypergraph JSON Binary", JSONBinaryEncoder(), JSONBinaryDecoder()),
        ("5. Prime-Indexed Gödel", PrimeIndexedEncoder(), PrimeIndexedDecoder()),
    ]

    @staticmethod
    def _fit_power_law(x_vals: List[float], y_vals: List[float]) -> Tuple[float, float, float]:
        """
        Fits y = k * x^alpha via log-log linear regression.
        Returns (alpha, k, R_squared).
        """
        valid_pairs = [(x, y) for x, y in zip(x_vals, y_vals) if x > 0 and y > 0]
        if len(valid_pairs) < 2:
            return 1.0, 1.0, 1.0

        lx = [math.log(x) for x, _ in valid_pairs]
        ly = [math.log(y) for _, y in valid_pairs]
        n = len(lx)
        mean_x = sum(lx) / n
        mean_y = sum(ly) / n

        ss_xx = sum((x - mean_x) ** 2 for x in lx)
        ss_xy = sum((x - mean_x) * (y - mean_y) for x, y in zip(lx, ly))
        ss_yy = sum((y - mean_y) ** 2 for y in ly)

        if ss_xx == 0:
            return 1.0, math.exp(mean_y), 1.0

        alpha = ss_xy / ss_xx
        beta = mean_y - alpha * mean_x
        k = math.exp(beta)
        r2 = (ss_xy ** 2) / (ss_xx * ss_yy) if ss_yy > 0 else 1.0

        return round(alpha, 3), round(k, 6), round(r2, 4)

    @classmethod
    def run_scaling_sweep(
        cls,
        node_counts: Optional[List[int]] = None,
        edge_multiplier: float = 2.0,
        hyperedge_multiplier: float = 0.05,
        repetitions: int = 5,
        warmup: int = 1,
    ) -> ScalingSweepResult:
        """
        Runs scaling benchmark sweep across representations and evaluates empirical growth.
        """
        counts = node_counts or [10, 50, 100, 500, 1000]
        rep_names = [name for name, _, _ in cls.STANDARD_REPRESENTATIONS]
        points: List[ScalingSweepPoint] = []

        for n_nodes in counts:
            n_edges = int(n_nodes * edge_multiplier)
            n_hypers = max(1, int(n_nodes * hyperedge_multiplier))

            st = generate_benchmark_graph(
                num_nodes=n_nodes,
                num_edges=n_edges,
                num_hyperedges=n_hypers,
                seed=42,
            )

            point = ScalingSweepPoint(nodes=n_nodes, edges=n_edges, hyperedges=n_hypers)

            for name, enc, dec in cls.STANDARD_REPRESENTATIONS:
                # 1. Timing
                t_enc = TimingHarness.benchmark_encoding(enc, st, repetitions=repetitions, warmup=warmup)
                encoded_bytes = enc.encode(st)
                t_dec = TimingHarness.benchmark_decoding(dec, encoded_bytes, template_state=st, repetitions=repetitions, warmup=warmup)
                t_rt = TimingHarness.benchmark_roundtrip(enc, dec, st, repetitions=repetitions, warmup=warmup)

                # 2. Memory
                _, mem_enc = MemoryProfiler.profile_encoding(enc, st)
                _, mem_dec = MemoryProfiler.profile_decoding(dec, encoded_bytes, template_state=st)
                peak_kb = max(mem_enc.peak_kb, mem_dec.peak_kb)

                # Throughput MB/sec
                mb_processed = (len(encoded_bytes) / (1024.0 * 1024.0))
                throughput_mb_s = (mb_processed / t_rt.median_time_sec) if t_rt.median_time_sec > 0 else 0.0

                rep_metrics = RepresentationBenchmarkMetrics(
                    name=name,
                    encode_time_ms=t_enc.median_time_sec * 1000.0,
                    decode_time_ms=t_dec.median_time_sec * 1000.0,
                    roundtrip_time_ms=t_rt.median_time_sec * 1000.0,
                    encode_throughput_ops_sec=t_enc.throughput_ops_per_sec,
                    decode_throughput_ops_sec=t_dec.throughput_ops_per_sec,
                    throughput_mb_sec=throughput_mb_s,
                    peak_memory_kb=peak_kb,
                    serialized_bytes=len(encoded_bytes),
                )
                point.metrics_by_representation[name] = rep_metrics

            points.append(point)

        # Compute empirical asymptotic exponents for each representation
        growth_models: Dict[str, Dict[str, float]] = {}
        nodes_list = [float(p.nodes) for p in points]

        for name in rep_names:
            rt_times = [p.metrics_by_representation[name].roundtrip_time_ms for p in points]
            mem_kbs = [p.metrics_by_representation[name].peak_memory_kb for p in points]
            bytes_list = [float(p.metrics_by_representation[name].serialized_bytes) for p in points]

            alpha_time, _, r2_time = cls._fit_power_law(nodes_list, rt_times)
            alpha_mem, _, r2_mem = cls._fit_power_law(nodes_list, mem_kbs)
            alpha_bytes, _, r2_bytes = cls._fit_power_law(nodes_list, bytes_list)

            growth_models[name] = {
                "time_scaling_exponent_alpha": alpha_time,
                "time_r2": r2_time,
                "memory_scaling_exponent_alpha": alpha_mem,
                "memory_r2": r2_mem,
                "bytes_scaling_exponent_alpha": alpha_bytes,
                "bytes_r2": r2_bytes,
            }

        return ScalingSweepResult(
            points=points,
            representations=rep_names,
            asymptotic_growth_exponents=growth_models,
        )
