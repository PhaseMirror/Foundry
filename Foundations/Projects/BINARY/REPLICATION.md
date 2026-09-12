# Replication & Open-Source Artifact Guide

**Binary Fragmentation Simulator (BFS) v1.5.0**  
*Empirical Calculus of Information Fragmentation in Computational Pipelines*

---

## 1. Quick Start & Replication

The BFS framework is self-contained and requires **zero external third-party dependencies** (Python 3.10+ standard library only).

### Run the Interactive Demo:
```bash
python3 demo_case_study.py
```

### Run the Complete 15-Suite Simulation Battery:
```bash
python3 run_simulations.py --out reports/dossier.md --json-out reports/dossier.json
```

### Run the Full Unit Test Suite:
```bash
python3 -m unittest discover -s tests -v
```
*Expected Output:* **30 / 30 tests passing (0 failures, 0 errors, < 100 ms).**

---

## 2. Directory Layout & Key Artifacts

```text
Projects/BINARY/
├── Binary-Compute-Simulator.md   # Architectural Decision Record (ADR-001)
├── README.md                      # Project Overview & Architecture Guide
├── REPLICATION.md                 # Replication & Open Science Guide
├── run_simulations.py             # Top-Level CLI Simulation Runner
├── demo_case_study.py             # Interactive Terminal Walkthrough Script
├── paper/
│   └── Relational-Information-Fragmentation-Paper.md # Academic Manuscript
├── docs/
│   └── Practitioner-Guide-Avoiding-The-Blind-Spot.md # Data Engineering Guidelines
├── reports/
│   ├── dossier.md                 # Generated Markdown Empirical Dossier
│   └── dossier.json               # Generated JSON Telemetry Data
├── binary_fragmentation/          # Core Python Package
│   ├── core/                      # State, Node, Edge, HyperEdge, Encoders, Decoders
│   ├── datasets/                  # Corporate AML Graph & Procurement Graphs
│   ├── fragmentation/             # Sharding, Recombination, Quantization, Truncation
│   ├── metrics/                   # 9D Metric Evaluators (F_v, F_s, F_r, F_p, F_i, F_t, F_c, F_q, F_sem)
│   ├── experiments/               # 15 Empirical Experiment Suites
│   └── reports/                   # Markdown & ASCII Visualizer
└── tests/                         # 30 Unit Tests (100% Passing)
```

---

## 3. Extending the Framework

To define a new custom dataset or transformation operator:
1. Subclass `BinaryOperator` in `binary_fragmentation/core/operators.py` and implement `apply(state: State) -> Tuple[State, ProvenanceRecord]`.
2. Evaluate state divergence using `MetricCalculator.evaluate(s_original, s_transformed)`.
3. Register the experiment in `binary_fragmentation/experiments/`.
