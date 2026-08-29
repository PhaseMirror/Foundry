# Binary Fragmentation Simulator (BFS)

**Production Reference Implementation of ADR-001**  
*Testing Information Degradation, Relational Disruption, and Computational Irreversibility Under Binary Computation*

---

## 1. Overview

The **Binary Fragmentation Simulator (BFS)** is an empirical scientific framework designed to test the hypothesis that **repeated binary encoding and transformation can preserve local numerical correctness while progressively degrading higher-order relational and contextual information**.

Rather than treating information as a single scalar or bit-error rate, BFS measures information loss across a **9-dimensional Fragmentation Vector**:

$$
\mathbf{F} = (F_v, F_s, F_r, F_p, F_i, F_t, F_c, F_q, F_{sem}) \in [0, 1]^9
$$

Where $0.0 = \text{fully preserved}$ and $1.0 = \text{fully lost}$.

| Metric Dimension | Meaning | Formal Indicator |
|---|---|---|
| **$F_v$** | **Value Loss** | Numerical distortion, attribute truncation, NRMSE |
| **$F_s$** | **Structural Loss** | Graph topology, node degree sequence divergence |
| **$F_r$** | **Relational Loss** | Directed edges, relation types, hypergraph link loss |
| **$F_p$** | **Provenance Loss** | Checksum continuity, causal ancestry degradation |
| **$F_i$** | **Identity Loss** | Entity resolution collapse, identifier drift |
| **$F_t$** | **Temporal Loss** | Chronological ordering inversions (Kendall $\tau$) |
| **$F_c$** | **Contextual Loss** | Metadata, regulatory constraints, domain frame loss |
| **$F_q$** | **Reversibility Loss** | Computational irreversibility ($S_n \not\to S_{n-1}$ rollback failure) |
| **$F_{sem}$** | **Semantic Loss** | Business/financial invariant conservation (net balance, reachability) |

---

## 2. Complete Taxonomy of 10 Structural Failure Modes

```
    Operation / Transformation               Value (F_v)   Relation (F_r)   Temporal (F_t)   Context (F_c)   Provenance (F_p)
   ─────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Lossless Relational Stress (25 cyc)       0.0000        0.0000           0.0000           0.0000          0.0000
    Edge Weight Quantization (2-bit)          0.0000        0.0200           0.0000           0.0000          0.0000
    Schema Evolution (Field Renames)          0.0000        0.0000           0.0000           0.0000          0.0000
    Graph Rewriting (Rule Consolidation)      0.0000        0.4000           0.0000           0.0000          0.0000
    Schema Projection (RBAC / Sub-graph)      0.0000        0.8000           0.0000           0.0000          0.0000
    Node-Only Document Store                  0.0000        1.0000           0.0000           0.0000          0.0000
    Adversarial Non-Temporal Sorting          0.0000        0.0000           0.6000           0.0000          0.0000
    Differential Privacy Edge Noise (ε=0.5)   0.0000        0.6000           0.0000           0.0000          0.0000
    Entity Deduplication (Merge Collapse)     0.0000        0.0000           0.0000           0.0000          0.0000 (F_i=1.0)
    Multi-Hop Chained ETL (Hop 5)             1.0000        1.0000           0.0000           1.0000          1.0000
```

---

## 3. Directory Structure

```
Projects/BINARY/
├── Binary-Compute-Simulator.md   # Architectural Decision Record (ADR-001)
├── README.md                      # Project Overview & Architecture Guide
├── REPLICATION.md                 # Open-Science Replication & Verification Guide
├── CITATION.cff                   # Machine-Readable Academic Citation Metadata
├── LICENSE                        # MIT Open Source License
├── demo_case_study.py             # Interactive Terminal Walkthrough Script
├── run_simulations.py             # Top-Level CLI Simulation Runner
├── run_benchmarks.py              # Performance & Scalability Benchmark Runner
├── paper/
│   ├── Relational-Information-Fragmentation-Paper.md # Academic Manuscript
│   ├── Cover-Letter-JDIQ.md       # Journal Submission Cover Letter
│   └── Reviewer-Simulation-Rebuttal.md # Simulated Review & Author Rebuttals
├── docs/
│   ├── Regulatory-Brief-Executive-Summary.md # Executive Brief for Regulators/CROs
│   ├── Blog-Post-The-Architectural-Blind-Spot.md # Practitioner Article
│   └── Practitioner-Guide-Avoiding-The-Blind-Spot.md # Data Engineering Guidelines
├── reports/
│   ├── dossier.md                 # Generated Markdown Empirical Dossier
│   ├── dossier.json               # Generated JSON Telemetry Data
│   ├── benchmark_dossier.md       # Generated Computational Performance Dossier
│   └── benchmark_dossier.json     # Generated Performance JSON Telemetry
├── binary_fragmentation/          # Core Python Package (Zero external dependencies)
│   ├── core/                      # State, Node, Edge, HyperEdge, Encoders, Decoders
│   ├── benchmarks/                # Timing Harness, Memory Profiler, Scaling Sweeps, Reporting
│   ├── datasets/                  # 1. Corporate AML Graph & 2. Public Procurement Graph
│   ├── fragmentation/             # Sharding, Recombination, Quantization, Truncation
│   ├── metrics/                   # 9D Metric Evaluators (F_v, F_s, F_r, F_p, F_i, F_t, F_c, F_q, F_sem)
│   ├── experiments/               # 15 Empirical Experiment Suites
│   └── reports/                   # Markdown & ASCII Visualizer
└── tests/                         # Full Unit Test Suite (47 tests, 100% passing)
```

---

## 4. Running Simulations, Benchmarks & Tests

### Run the Interactive Demo:
```bash
python3 demo_case_study.py
```

### Run All 15 Experiment Suites:
```bash
python3 run_simulations.py --out reports/dossier.md --json-out reports/dossier.json
```

### Run the Computational Performance & Scalability Benchmark Suite:
```bash
python3 run_benchmarks.py --reps 5 --nodes 10,50,100,500,1000 --out reports/benchmark_dossier.md --json-out reports/benchmark_dossier.json
```
*Or execute via `run_simulations.py`:*
```bash
python3 run_simulations.py --benchmark --benchmark-preset medium
```

### Run Unit Tests:
```bash
python3 -m unittest discover -s tests -v
```
*Result:* **47 / 47 tests passing in ~5 seconds.**

