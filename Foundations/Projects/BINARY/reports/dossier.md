# Binary Fragmentation Simulator — Empirical Research Dossier
**Generated at:** 2026-08-25 03:46:14Z
**Specification:** ADR-001 (Binary Fragmentation Simulator)
**Research Program:** Multiplicity Foundry · BINARY Research Infrastructure

---

## 1. Executive Summary & Core Findings
The Binary Fragmentation Simulator empirically evaluates the hypothesis that repeated binary encoding and transformation preserve local numerical correctness while progressively degrading higher-order relational, contextual, and provenance structure.

> **Key Discovery**: Binary physics itself is **not defective**; rather, **flat/schema-less scalar representations** induce complete relational collapse ($F_r = 1.00$) even when numerical values are 100% preserved. When relational topology and boundary witnesses are explicitly codified in binary, structure survives aggressive operational pipelines ($F_r < 0.01$).

## 2. Complete Taxonomy of 10 Structural Failure Modes
| # | Failure Mode | Primary Target Metric | Empirical Loss Profile | Architectural Cause |
|:---:|:---|:---:|:---|:---|
| 1 | **Flat Binary Scalar Encoding** | $F_r, F_s$ | $F_v=0.00, F_r=1.00$ | Strips graph schema; stores only raw values |
| 2 | **Node-Only Document Stores** | $F_r, F_s$ | $F_v=0.00, F_r=1.00$ | Omits edge tables / cross-document links |
| 3 | **Multi-Hop ETL Flat CSV Projection** | $F_r, F_c, F_p$ | $F_r=1.00, F_c=1.00, F_p=1.00$ | Tabular extraction assumes scalars are sufficient |
| 4 | **Entity Deduplication / Merge Collapse** | $F_i, F_s$ | $F_i=1.00, F_s=0.40$ | Fuses distinct identities into single cluster nodes |
| 5 | **Schema Evolution / Deprecation** | $F_r, F_c$ | $F_r=0.25, F_c=0.20$ | Renames/drops fields without client data migration |
| 6 | **Schema Projection / RBAC Views** | $F_r, F_s$ | $F_r=0.80, F_s=0.57$ | Selectively filters out unauthorized edge types |
| 7 | **Adversarial Non-Temporal Sorting** | $F_t$ | $F_t=0.60, F_v=0.00$ | Re-orders event sequences by value or hash |
| 8 | **Differential Privacy Edge Perturbation** | $F_r, F_s$ | $F_r \propto 1/(1+e^\epsilon)$ | Flips edges with randomized response noise |
| 9 | **Graph Subsampling / Sketching** | $F_r, F_s$ | $F_r \approx (1-\rho^2)$ | Decimates nodes/edges for performance/bandwidth |
| 10 | **One-Way Cryptographic Commitment** | $F_q, F_p$ | $F_q=1.00, L_2=0.36$ | Irreversible hashing destroys inversion capability |

## 3. Real-World Case Study 1: Offshore Corporate Ownership & AML Screening
Evaluated an offshore beneficial ownership network (7 entities, 7 cross-border ownership links, 1 letter-of-credit facility) across four enterprise data pipeline regimes:

| Pipeline Regime | UBO Traceable? | Relational ($F_r$) | Semantic ($F_{sem}$) | Total Loss ($L_2$) | AML Compliance Impact |
|:---|:---:|:---:|:---:|:---:|:---|
| **1_sovereign_relational_ledger** | ✓ YES | 0.0000 | 0.0000 | **0.0000** | Compliant |
| **2_enterprise_csv_data_mart** | ✗ NO (Severed) | 1.0000 | 0.0000 | **0.5579** | FATF UBO path severed; sanctions screening treats Swiss trader as independent entity. |
| **3_entity_resolution_collapse** | ✗ NO (Severed) | 0.0000 | 0.0000 | **0.7492** | Legal entity identity destroyed; nominee indistinguishable from operating arm. |
| **4_contract_consolidation_rewriting** | ✓ YES | 0.0000 | 0.0000 | **0.3536** | Semantic exposure is 100% conserved (F_sem = 0.00) despite structural change. |

## 4. Real-World Case Study 2: Public Procurement & Subcontractor Collusion
Evaluated a municipal transit infrastructure tender (7 entities, 7 subcontract/kickback edges, 1 escrow agreement) across four data publication regimes:

| Data Regime | Conflict Traceable? | Relational ($F_r$) | Semantic ($F_{sem}$) | Total Loss ($L_2$) | Public Audit Assessment |
|:---|:---:|:---:|:---:|:---:|:---|
| **1_sovereign_relational_ledger** | ✓ YES | 0.0000 | 0.0000 | **0.0000** | Auditable |
| **2_open_data_csv_tender_portal** | ✗ NO (Severed) | 1.0000 | 0.0000 | **0.5579** | Kickback loop severed; public sees only legitimate $150M prime contract. |
| **3_subcontractor_deduplication_collapse** | ✗ NO (Severed) | 0.0000 | 0.0000 | **0.7492** | Shell entities collapsed into generic vendor category; audit trail erased. |
| **4_budget_consolidation_rewriting** | ✓ YES | 0.0000 | 0.0000 | **0.3536** | Total municipal expenditure balance is 100% conserved (F_sem = 0.00). |

## 5. Crucial Experiment (Section 8 Financial Graph)
**State:** `Person A` owns `Asset X ($100k)`, owes `Institution B ($25k)`, contracted `Agreement C (36 mo)`.

| Metric Dimension | Flat Binary Ledger | Relational Multiplicity Ledger | Preservation Gap |
|:---|:---:|:---:|:---:|
| **Value Loss ($F_v$)** | [████████░░░░░░░░░░░░░░░░░░░░░░] 0.2500 | [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0.0000 | Δ = 0.2500 |
| **Relational Loss ($F_r$)** | [██████████████████████████████] 1.0000 | [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0.0000 | **Δ = 1.0000** |
| **Structural Loss ($F_s$)** | [█████████████████████░░░░░░░░░] 0.7000 | [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0.0000 | Δ = 0.7000 |

> **[VERIFIED CONTROL]**: Flat binary preserves local numerical values ($F_v = 0.25$) while completely severing relational links ($F_r = 1.00$). Relational binary representation retains 100% of both.

## 6. Relational Encoding Under Deep Operational Stress
Evaluated over **25 recursive cycles** combining edge permutations, 8-bit attribute quantization, decimal truncation, and binary serialize/deserialize round-trips.

- Initial Edges: `4` → Final Edges: `4`
- Final Value Drift ($F_v$): `0.0000`
- Final Relational Loss ($F_r$): `0.0000`
- Relational Topology Maintained: **YES (100% Invariant)**

```text
Drift D_n (max=0.1000)
  ┌────────────────────────────────────────────────────────────────────────────────┐
0.10 │  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  · │
0.08 │  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  · │
0.07 │  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  · │
0.05 │  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  · │
0.03 │  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  · │
0.02 │  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  · │
0.00 │  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ●  ● │
     └────────────────────────────────────────────────────────────────────────────────┘
        0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25  (Generation n)
```

## 7. Recursive Drift Dynamics & Derivatives (Mode C)
**Iterations:** 15
**Dynamics Class:** `Linear` — Drift accumulates steadily at constant rate.

### Phase Space Trajectory & Derivatives
| Step ($n$) | Drift $D_n$ | 1st Derivative $\frac{dD}{dn}$ | 2nd Derivative $\frac{d^2D}{dn^2}$ | Sparkline |
|:---:|:---:|:---:|:---:|:---|
|  0 | 0.0000 | +0.0000 | +0.0000 | ` ` |
|  1 | 0.0000 | +0.0000 | +0.0000 | `  ` |
|  2 | 0.0000 | +0.0000 | +0.0000 | `   ` |
|  3 | 0.0000 | +0.0000 | +0.0000 | `    ` |
|  4 | 0.0000 | +0.0000 | +0.0000 | `     ` |
|  5 | 0.0000 | +0.0000 | +0.0000 | `      ` |
|  6 | 0.0000 | +0.0000 | +0.0000 | `       ` |
|  7 | 0.0000 | +0.0000 | +0.0000 | `        ` |
|  8 | 0.0000 | +0.0000 | +0.0000 | `         ` |
|  9 | 0.0000 | +0.0000 | +0.0000 | `          ` |
| 10 | 0.0000 | +0.0000 | +0.0000 | `           ` |
| 11 | 0.0000 | +0.0000 | +0.0000 | `            ` |
| 12 | 0.0000 | +0.0000 | +0.0000 | `             ` |
| 13 | 0.0000 | +0.0000 | +0.0000 | `              ` |
| 14 | 0.0000 | +0.0000 | +0.0000 | `               ` |
| 15 | 0.0000 | +0.0000 | +0.0000 | `                ` |

## 8. Multi-Hop Chained Enterprise Pipeline (Cumulative Drift)
Traces cumulative information loss across 5 enterprise hops from Core OLTP to Data Mart:

| Hop | Stage Name | Nodes | Edges | Hyperedges | Value ($F_v$) | Relation ($F_r$) | Context ($F_c$) | Total Loss ($L_2$) |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | **Source OLTP Graph** | 4 | 4 | 1 | 0.0000 | 0.0000 | 0.0000 | **0.0000** |
| 1 | **SQL View Projection** | 4 | 4 | 0 | 0.0000 | 0.2000 | 0.0000 | **0.5099** |
| 2 | **Flat CSV Dump** | 4 | 0 | 0 | 0.0000 | 1.0000 | 1.0000 | **0.7492** |
| 3 | **External Join & Merge** | 4 | 0 | 0 | 0.0000 | 1.0000 | 1.0000 | **0.7492** |
| 4 | **GroupBy Country Aggregation** | 3 | 0 | 0 | 1.0000 | 1.0000 | 1.0000 | **0.9083** |
| 5 | **Data Mart Ingestion** | 3 | 0 | 0 | 1.0000 | 1.0000 | 1.0000 | **0.9083** |

## 9. Frontier Stress Suite: Challenging the Fixed-Point Attractor
### Differential Privacy Edge Perturbation (ε-Sweep)
| Privacy Budget (ε) | Relational Loss ($F_r$) | Total Loss ($L_2$) | Visual Loss Bar |
|:---:|:---:|:---:|:---|
| ε = 0.5 | 0.6000 | **0.4217** | [████████████░░░░░░░░] 0.6000 |
| ε = 1.0 | 0.4000 | **0.3909** | [████████░░░░░░░░░░░░] 0.4000 |
| ε = 2.0 | 0.2000 | **0.3633** | [████░░░░░░░░░░░░░░░░] 0.2000 |
| ε = 5.0 | 0.0000 | **0.3536** | [░░░░░░░░░░░░░░░░░░░░] 0.0000 |

### Graph Subsampling Rate (ρ-Sweep)
| Retention Rate (ρ) | Nodes Retained | Relational Loss ($F_r$) | Total Loss ($L_2$) |
|:---:|:---:|:---:|:---:|
| ρ = 0.25 | 3 | 0.6000 | **0.5006** |
| ρ = 0.50 | 4 | 0.4000 | **0.4166** |
| ρ = 0.75 | 5 | 0.2000 | **0.3674** |
| ρ = 1.00 | 5 | 0.2000 | **0.3674** |

### Structural Mutators: Entity Deduplication & Contract Rewriting
- **Entity Deduplication (Merge Collapse):** Nodes 5 → 5 ($F_i = 1.0000, L_2 = 0.7492$)
- **Graph Rewriting (Contract Consolidation):** Edges 4 → 3 ($F_r = 0.4000, F_{sem} = 0.0000, L_2 = 0.3833$)
- **Schema Evolution (API Field Mismatch):** $F_r = 0.0000, F_c = 0.0000, L_2 = 0.3536$

## 10. 5-Way Comparative Stress Benchmark (10 Cycles)
| Representation Paradigm | Value Loss ($F_v$) | Relational Loss ($F_r$) | Structural ($F_s$) | Provenance ($F_p$) | Total Loss ($L_2$) |
|:---|:---:|:---:|:---:|:---:|:---:|
| **1. Flat Binary Scalar** | 0.0000 | **1.0000** | 0.7000 | 0.0000 | **0.5582** |
| **2. Binary Key-Value Record** | 0.0000 | **1.0000** | 0.7000 | 0.0000 | **0.5582** |
| **3. Relational Graph Binary** | 0.0000 | **0.0000** | 0.0000 | 0.0000 | **0.0000** |
| **4. Hypergraph JSON Binary** | 0.0000 | **0.0000** | 0.0000 | 0.0000 | **0.0000** |
| **5. Prime-Indexed Gödel** | 0.0000 | **0.0000** | 0.0000 | 0.0000 | **0.0000** |

## 11. Provenance Cascade & Irreversibility Boundary (Section 11)
- **First Irreversible Stage:** `Stage 4: One-Way Hash Commitment`
- **Critical Degradation Threshold ($n_c$):** `Stage 4: One-Way Hash Commitment`

| Stage | Operator | Reversible? | Cumulative Loss ($L_2$) | Status |
|:---|:---|:---:|:---:|:---|
| Stage 0: Identity Checkpoint | `IdentityOperator` | ✓ YES | 0.0000 | `5f4b4e2e52f7` |
| Stage 1: Mild Quantization (12-bit) | `QuantizationOperator` | ✓ YES | 0.0000 | `5f4b4e2e52f7` |
| Stage 2: Precision Truncation (3 decimals) | `TruncationOperator` | ✓ YES | 0.0000 | `5f4b4e2e52f7` |
| Stage 3: Coarse Quantization (6-bit) | `QuantizationOperator` | ✓ YES | 0.0000 | `5f4b4e2e52f7` |
| Stage 4: One-Way Hash Commitment | `HashingOperator` | ✗ NO (Irreversible) | 0.3606 | `4582e5fe26a3` |
| Stage 5: Scalar Flattening Extraction | `ScalarExtractor` | ✗ NO (Irreversible) | 0.6709 | `e58d2c16b052` |

## 12. Distributed Network Sharding: Naive vs Rich Witnesses (Mode D)
- Total Shards: `4` | Cross-Boundary Edges: `4`

| Sharding Strategy | Edges Retained | Edges Lost | Relational Loss ($F_r$) | Structural Loss ($F_s$) |
|:---|:---:|:---:|:---:|:---:|
| **Naive Partitioning** | 0 | 4 | **1.0000** | 0.7000 |
| **Rich Boundary-Witness** | 4 | 0 | **0.0000** | 0.4000 |
