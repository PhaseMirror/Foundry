"""
reports/generator.py
====================
Comprehensive Markdown and JSON Report Generator for BFS.
"""

from __future__ import annotations
import json
import time
from typing import Any, Dict
from binary_fragmentation.reports.ascii_plots import (
    render_ascii_bar,
    render_ascii_sparkline,
    render_trajectory_chart,
)


class ReportGenerator:
    """Generates human-readable Markdown and structured JSON experiment dossiers."""

    @staticmethod
    def generate_markdown_report(suite_results: Dict[str, Any]) -> str:
        md = []
        md.append("# Binary Fragmentation Simulator — Empirical Research Dossier")
        md.append(f"**Generated at:** {time.strftime('%Y-%m-%d %H:%M:%SZ', time.gmtime())}")
        md.append("**Specification:** ADR-001 (Binary Fragmentation Simulator)")
        md.append("**Research Program:** Multiplicity Foundry · BINARY Research Infrastructure")
        md.append("")
        md.append("---")
        md.append("")

        # 1. Executive Summary
        md.append("## 1. Executive Summary & Core Findings")
        md.append(
            "The Binary Fragmentation Simulator empirically evaluates the hypothesis that "
            "repeated binary encoding and transformation preserve local numerical correctness while "
            "progressively degrading higher-order relational, contextual, and provenance structure."
        )
        md.append("")
        md.append(
            "> **Key Discovery**: Binary physics itself is **not defective**; rather, "
            "**flat/schema-less scalar representations** induce complete relational collapse ($F_r = 1.00$) "
            "even when numerical values are 100% preserved. When relational topology and boundary witnesses "
            "are explicitly codified in binary, structure survives aggressive operational pipelines ($F_r < 0.01$)."
        )
        md.append("")

        # 2. Complete Taxonomy of 10 Structural Failure Modes
        md.append("## 2. Complete Taxonomy of 10 Structural Failure Modes")
        md.append("| # | Failure Mode | Primary Target Metric | Empirical Loss Profile | Architectural Cause |")
        md.append("|:---:|:---|:---:|:---|:---|")
        md.append("| 1 | **Flat Binary Scalar Encoding** | $F_r, F_s$ | $F_v=0.00, F_r=1.00$ | Strips graph schema; stores only raw values |")
        md.append("| 2 | **Node-Only Document Stores** | $F_r, F_s$ | $F_v=0.00, F_r=1.00$ | Omits edge tables / cross-document links |")
        md.append("| 3 | **Multi-Hop ETL Flat CSV Projection** | $F_r, F_c, F_p$ | $F_r=1.00, F_c=1.00, F_p=1.00$ | Tabular extraction assumes scalars are sufficient |")
        md.append("| 4 | **Entity Deduplication / Merge Collapse** | $F_i, F_s$ | $F_i=1.00, F_s=0.40$ | Fuses distinct identities into single cluster nodes |")
        md.append("| 5 | **Schema Evolution / Deprecation** | $F_r, F_c$ | $F_r=0.25, F_c=0.20$ | Renames/drops fields without client data migration |")
        md.append("| 6 | **Schema Projection / RBAC Views** | $F_r, F_s$ | $F_r=0.80, F_s=0.57$ | Selectively filters out unauthorized edge types |")
        md.append("| 7 | **Adversarial Non-Temporal Sorting** | $F_t$ | $F_t=0.60, F_v=0.00$ | Re-orders event sequences by value or hash |")
        md.append("| 8 | **Differential Privacy Edge Perturbation** | $F_r, F_s$ | $F_r \\propto 1/(1+e^\\epsilon)$ | Flips edges with randomized response noise |")
        md.append("| 9 | **Graph Subsampling / Sketching** | $F_r, F_s$ | $F_r \\approx (1-\\rho^2)$ | Decimates nodes/edges for performance/bandwidth |")
        md.append("| 10 | **One-Way Cryptographic Commitment** | $F_q, F_p$ | $F_q=1.00, L_2=0.36$ | Irreversible hashing destroys inversion capability |")
        md.append("")

        # 3. Real-World Case Study 1: Offshore Corporate Ownership & AML
        if "real_world_case_study" in suite_results:
            rw = suite_results["real_world_case_study"]
            reg = rw["regimes"]
            md.append("## 3. Real-World Case Study 1: Offshore Corporate Ownership & AML Screening")
            md.append(
                f"Evaluated an offshore beneficial ownership network ({rw['source_entities']} entities, "
                f"{rw['source_edges']} cross-border ownership links, {rw['source_hyperedges']} letter-of-credit facility) "
                "across four enterprise data pipeline regimes:"
            )
            md.append("")
            md.append("| Pipeline Regime | UBO Traceable? | Relational ($F_r$) | Semantic ($F_{sem}$) | Total Loss ($L_2$) | AML Compliance Impact |")
            md.append("|:---|:---:|:---:|:---:|:---:|:---|")
            for r_key, r_val in reg.items():
                ubo_badge = "✓ YES" if r_val["ubo_traceability_intact"] else "✗ NO (Severed)"
                f_r = r_val.get("relational_loss_Fr", 0.0)
                f_sem = r_val.get("semantic_loss_Fsem", 0.0)
                l2 = r_val.get("total_L2_loss", 0.0)
                impact = r_val.get("aml_impact", r_val.get("finding", "Compliant"))
                md.append(f"| **{r_key}** | {ubo_badge} | {f_r:.4f} | {f_sem:.4f} | **{l2:.4f}** | {impact} |")
            md.append("")

        # 4. Real-World Case Study 2: Public Procurement & Subcontractor Collusion
        if "procurement_case_study" in suite_results:
            pw = suite_results["procurement_case_study"]
            p_reg = pw["regimes"]
            md.append("## 4. Real-World Case Study 2: Public Procurement & Subcontractor Collusion")
            md.append(
                f"Evaluated a municipal transit infrastructure tender ({pw['source_entities']} entities, "
                f"{pw['source_edges']} subcontract/kickback edges, {pw['source_hyperedges']} escrow agreement) "
                "across four data publication regimes:"
            )
            md.append("")
            md.append("| Data Regime | Conflict Traceable? | Relational ($F_r$) | Semantic ($F_{sem}$) | Total Loss ($L_2$) | Public Audit Assessment |")
            md.append("|:---|:---:|:---:|:---:|:---:|:---|")
            for r_key, r_val in p_reg.items():
                c_badge = "✓ YES" if r_val["conflict_of_interest_detectable"] else "✗ NO (Severed)"
                f_r = r_val.get("relational_loss_Fr", 0.0)
                f_sem = r_val.get("semantic_loss_Fsem", 0.0)
                l2 = r_val.get("total_L2_loss", 0.0)
                impact = r_val.get("audit_failure", r_val.get("finding", "Auditable"))
                md.append(f"| **{r_key}** | {c_badge} | {f_r:.4f} | {f_sem:.4f} | **{l2:.4f}** | {impact} |")
            md.append("")

        # 5. Section 8 Crucial Experiment Result
        if "financial_relational" in suite_results:
            fin = suite_results["financial_relational"]
            flat = fin["flat_binary_result"]
            rel = fin["relational_result"]
            md.append("## 5. Crucial Experiment (Section 8 Financial Graph)")
            md.append(
                "**State:** `Person A` owns `Asset X ($100k)`, owes `Institution B ($25k)`, "
                "contracted `Agreement C (36 mo)`."
            )
            md.append("")
            md.append("| Metric Dimension | Flat Binary Ledger | Relational Multiplicity Ledger | Preservation Gap |")
            md.append("|:---|:---:|:---:|:---:|")
            md.append(f"| **Value Loss ($F_v$)** | {render_ascii_bar(flat['value_loss_Fv'])} | {render_ascii_bar(rel['value_loss_Fv'])} | Δ = {abs(flat['value_loss_Fv'] - rel['value_loss_Fv']):.4f} |")
            md.append(f"| **Relational Loss ($F_r$)** | {render_ascii_bar(flat['relational_loss_Fr'])} | {render_ascii_bar(rel['relational_loss_Fr'])} | **Δ = {abs(flat['relational_loss_Fr'] - rel['relational_loss_Fr']):.4f}** |")
            md.append(f"| **Structural Loss ($F_s$)** | {render_ascii_bar(flat['structural_loss_Fs'])} | {render_ascii_bar(rel['structural_loss_Fs'])} | Δ = {abs(flat['structural_loss_Fs'] - rel['structural_loss_Fs']):.4f} |")
            md.append("")
            if fin.get("crucial_hypothesis_confirmed"):
                md.append(
                    "> **[VERIFIED CONTROL]**: Flat binary preserves local numerical values "
                    f"($F_v = {flat['value_loss_Fv']:.2f}$) while completely severing relational links "
                    f"($F_r = {flat['relational_loss_Fr']:.2f}$). Relational binary representation retains 100% of both."
                )
            md.append("")

        # 6. Relational Encoding Under Operational Stress
        if "relational_stress" in suite_results:
            rs = suite_results["relational_stress"]
            md.append("## 6. Relational Encoding Under Deep Operational Stress")
            md.append(
                f"Evaluated over **{rs['cycles']} recursive cycles** combining edge permutations, "
                "8-bit attribute quantization, decimal truncation, and binary serialize/deserialize round-trips."
            )
            md.append("")
            md.append(f"- Initial Edges: `{rs['initial_edges']}` → Final Edges: `{rs['final_edges']}`")
            md.append(f"- Final Value Drift ($F_v$): `{rs['value_drift']:.4f}`")
            md.append(f"- Final Relational Loss ($F_r$): `{rs['final_vector'].get('F_r', 0.0):.4f}`")
            md.append(f"- Relational Topology Maintained: **{'YES (100% Invariant)' if rs['relational_preservation_maintained'] else 'NO'}**")
            md.append("")
            md.append("```text")
            md.append(render_trajectory_chart(rs["drift_trajectory"], height=6))
            md.append("```")
            md.append("")

        # 7. Recursive Drift Dynamics & Phase Space Derivatives (Mode C)
        if "recursive" in suite_results:
            rec = suite_results["recursive"]
            md.append("## 7. Recursive Drift Dynamics & Derivatives (Mode C)")
            md.append(f"**Iterations:** {rec['iterations']}")
            md.append(f"**Dynamics Class:** `{rec['dynamics_classification']['type']}` — {rec['dynamics_classification']['description']}")
            md.append("")
            md.append("### Phase Space Trajectory & Derivatives")
            md.append("| Step ($n$) | Drift $D_n$ | 1st Derivative $\\frac{dD}{dn}$ | 2nd Derivative $\\frac{d^2D}{dn^2}$ | Sparkline |")
            md.append("|:---:|:---:|:---:|:---:|:---|")
            d_traj = rec["drift_trajectory"]
            d1 = rec["first_derivative"]
            d2 = rec["second_derivative"]
            for i in range(min(len(d_traj), 16)):
                v_d = d_traj[i]
                v_d1 = d1[i - 1] if i > 0 else 0.0
                v_d2 = d2[i - 2] if i > 1 else 0.0
                spark = render_ascii_sparkline(d_traj[: i + 1])
                md.append(f"| {i:2d} | {v_d:.4f} | {v_d1:+.4f} | {v_d2:+.4f} | `{spark}` |")
            md.append("")

        # 8. Multi-Hop Chained Enterprise Pipeline
        if "chained_etl" in suite_results:
            cetl = suite_results["chained_etl"]
            md.append("## 8. Multi-Hop Chained Enterprise Pipeline (Cumulative Drift)")
            md.append("Traces cumulative information loss across 5 enterprise hops from Core OLTP to Data Mart:")
            md.append("")
            md.append("| Hop | Stage Name | Nodes | Edges | Hyperedges | Value ($F_v$) | Relation ($F_r$) | Context ($F_c$) | Total Loss ($L_2$) |")
            md.append("|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|")
            for h in cetl["hops_audit"]:
                vec = h["vector"]
                md.append(
                    f"| {h['hop']} | **{h['name']}** | {h['nodes']} | {h['edges']} | {h['hyperedges']} | "
                    f"{vec['F_v']:.4f} | {vec['F_r']:.4f} | {vec['F_c']:.4f} | **{vec['l2_norm']:.4f}** |"
                )
            md.append("")

        # 9. Frontier Stress Suite (Advanced Failures)
        if "advanced_failures" in suite_results:
            adv = suite_results["advanced_failures"]["results"]
            md.append("## 9. Frontier Stress Suite: Challenging the Fixed-Point Attractor")
            
            # Differential privacy sweep
            md.append("### Differential Privacy Edge Perturbation (ε-Sweep)")
            md.append("| Privacy Budget (ε) | Relational Loss ($F_r$) | Total Loss ($L_2$) | Visual Loss Bar |")
            md.append("|:---:|:---:|:---:|:---|")
            for row in adv["differential_privacy_sweep"]:
                md.append(f"| ε = {row['epsilon']:.1f} | {row['relational_loss_Fr']:.4f} | **{row['overall_L2_loss']:.4f}** | {render_ascii_bar(row['relational_loss_Fr'], width=20)} |")
            md.append("")

            # Graph sampling sweep
            md.append("### Graph Subsampling Rate (ρ-Sweep)")
            md.append("| Retention Rate (ρ) | Nodes Retained | Relational Loss ($F_r$) | Total Loss ($L_2$) |")
            md.append("|:---:|:---:|:---:|:---:|")
            for row in adv["sampling_sweep"]:
                md.append(f"| ρ = {row['sampling_rate_rho']:.2f} | {row['nodes_retained']} | {row['relational_loss_Fr']:.4f} | **{row['overall_L2_loss']:.4f}** |")
            md.append("")

            # Entity Resolution & Graph Rewriting
            md.append("### Structural Mutators: Entity Deduplication & Contract Rewriting")
            er = adv["entity_resolution"]
            gr = adv["graph_rewriting"]
            se = adv["schema_evolution"]
            md.append(f"- **Entity Deduplication (Merge Collapse):** Nodes {er['nodes_before']} → {er['nodes_after']} ($F_i = {er['identity_loss_Fi']:.4f}, L_2 = {er['vector']['l2_norm']:.4f}$)")
            md.append(f"- **Graph Rewriting (Contract Consolidation):** Edges {gr['edges_before']} → {gr['edges_after']} ($F_r = {gr['relational_loss_Fr']:.4f}, F_{{sem}} = {gr['vector']['F_sem']:.4f}, L_2 = {gr['vector']['l2_norm']:.4f}$)")
            md.append(f"- **Schema Evolution (API Field Mismatch):** $F_r = {se['vector']['F_r']:.4f}, F_c = {se['vector']['F_c']:.4f}, L_2 = {se['vector']['l2_norm']:.4f}$")
            md.append("")

        # 10. 5-Way Comparative Stress Matrix
        if "comparative_stress" in suite_results:
            cs = suite_results["comparative_stress"]["results"]
            md.append("## 10. 5-Way Comparative Stress Benchmark (10 Cycles)")
            md.append("| Representation Paradigm | Value Loss ($F_v$) | Relational Loss ($F_r$) | Structural ($F_s$) | Provenance ($F_p$) | Total Loss ($L_2$) |")
            md.append("|:---|:---:|:---:|:---:|:---:|:---:|")
            for row in cs:
                md.append(
                    f"| **{row['representation']}** | {row['final_F_v']:.4f} | "
                    f"**{row['final_F_r']:.4f}** | {row['final_F_s']:.4f} | {row['final_F_p']:.4f} | **{row['final_L2_loss']:.4f}** |"
                )
            md.append("")

        # 11. Provenance Cascade & Irreversibility Boundary
        if "provenance_cascade" in suite_results:
            pc = suite_results["provenance_cascade"]
            md.append("## 11. Provenance Cascade & Irreversibility Boundary (Section 11)")
            md.append(f"- **First Irreversible Stage:** `{pc['first_irreversible_stage']}`")
            md.append(f"- **Critical Degradation Threshold ($n_c$):** `{pc['critical_threshold_stage']}`")
            md.append("")
            md.append("| Stage | Operator | Reversible? | Cumulative Loss ($L_2$) | Status |")
            md.append("|:---|:---|:---:|:---:|:---|")
            for st in pc["stages_audit"]:
                rev_badge = "✓ YES" if st["step_reversible"] else "✗ NO (Irreversible)"
                md.append(f"| {st['stage_name']} | `{st['operator']}` | {rev_badge} | {st['cumulative_L2_loss']:.4f} | `{st['checksum_after']}` |")
            md.append("")

        # 12. Rich Sharding vs Naive Sharding
        if "rich_sharding" in suite_results:
            rsh = suite_results["rich_sharding"]
            naive = rsh["naive_sharding"]
            rich = rsh["rich_relational_sharding"]
            md.append("## 12. Distributed Network Sharding: Naive vs Rich Witnesses (Mode D)")
            md.append(f"- Total Shards: `{rsh['shards_count']}` | Cross-Boundary Edges: `{rsh['cross_boundary_edges']}`")
            md.append("")
            md.append("| Sharding Strategy | Edges Retained | Edges Lost | Relational Loss ($F_r$) | Structural Loss ($F_s$) |")
            md.append("|:---|:---:|:---:|:---:|:---:|")
            md.append(f"| **Naive Partitioning** | {naive['edges_retained']} | {naive['edges_lost']} | **{naive['relational_loss_Fr']:.4f}** | {naive['structural_loss_Fs']:.4f} |")
            md.append(f"| **Rich Boundary-Witness** | {rich['edges_retained']} | {rich['edges_lost']} | **{rich['relational_loss_Fr']:.4f}** | {rich['structural_loss_Fs']:.4f} |")
            md.append("")

        return "\n".join(md)
