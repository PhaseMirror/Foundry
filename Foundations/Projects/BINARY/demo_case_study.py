#!/usr/bin/env python3
"""
demo_case_study.py
==================
Interactive Demonstration of the Binary Fragmentation Simulator (BFS).

Demonstrates:
1. The Crucial Financial Experiment (Section 8)
2. Real-World Case Study 1: Offshore Corporate Ownership & AML Sanctions Screening
3. Real-World Case Study 2: Municipal Public Procurement & Kickback Collusion
4. The 9-Dimensional Fragmentation Vector & Semantic Equivalence
"""

import sys
import json
from binary_fragmentation.core.state import State, Node, Edge
from binary_fragmentation.experiments.financial_relational import FinancialRelationalExperiment
from binary_fragmentation.experiments.real_world_case_study import RealWorldCorporateCaseStudy
from binary_fragmentation.experiments.procurement_case_study import ProcurementCaseStudy
from binary_fragmentation.reports.ascii_plots import render_ascii_bar


def print_banner(title: str):
    print("\n" + "=" * 78)
    print(f"  {title}")
    print("=" * 78)


def demo_financial_crucial():
    print_banner("1. THE CRUCIAL FINANCIAL EXPERIMENT (ADR-001 Section 8)")
    print("Evaluating state: Person A owns Asset X ($100k), owes Inst B ($25k), contracted Agree C.")
    
    exp = FinancialRelationalExperiment()
    res = exp.run()
    
    flat = res["flat_binary_result"]
    rel = res["relational_result"]
    
    print("\n[RESULT TABLE]")
    print(f"  {'Metric':<25} | {'Flat Binary Ledger':<18} | {'Relational Binary Ledger':<24}")
    print("  " + "-" * 72)
    print(f"  {'Value Loss (F_v)':<25} | {flat['value_loss_Fv']:<18.4f} | {rel['value_loss_Fv']:<24.4f}")
    print(f"  {'Relational Loss (F_r)':<25} | {flat['relational_loss_Fr']:<18.4f} | {rel['relational_loss_Fr']:<24.4f}")
    print(f"  {'Structural Loss (F_s)':<25} | {flat['structural_loss_Fs']:<18.4f} | {rel['structural_loss_Fs']:<24.4f}")
    print(f"  {'Total Loss (L_2)':<25} | {flat['vector']['l2_norm']:<18.4f} | {rel['vector']['l2_norm']:<24.4f}")
    
    print("\n[FINDING]: Flat binary preserves local values ($F_v = 0.25$) but 100% destroys relations ($F_r = 1.00$).")
    print("           Relational binary preserves 100% of both ($F_v = 0.00, F_r = 0.00$).")


def demo_aml_case_study():
    print_banner("2. REAL-WORLD CASE STUDY 1: OFFSHORE CORPORATE OWNERSHIP & AML SCREENING")
    print("Network: Sanctioned Oligarch UBO -> Cyprus HoldCo -> BVI Trading Shell -> Swiss Trader <-> US Bank")
    
    exp = RealWorldCorporateCaseStudy()
    res = exp.run()
    
    print("\n[REGIME COMPARISON]")
    for r_name, r_data in res["regimes"].items():
        ubo_str = "✓ DETECTED" if r_data["ubo_traceability_intact"] else "✗ SEVERED (BREACH)"
        f_r = r_data.get("relational_loss_Fr", 0.0)
        l2 = r_data.get("total_L2_loss", 0.0)
        print(f"\n▶ {r_name.upper()}:")
        print(f"    Description: {r_data['description']}")
        print(f"    UBO Traceability: {ubo_str}")
        print(f"    Relational Loss:  F_r = {f_r:.4f}")
        print(f"    Total L_2 Loss:   L_2 = {l2:.4f}")
        if "aml_impact" in r_data:
            print(f"    FATF AML Impact:  {r_data['aml_impact']}")


def demo_procurement_case_study():
    print_banner("3. REAL-WORLD CASE STUDY 2: PUBLIC PROCUREMENT & SUBCONTRACTOR COLLUSION")
    print("Network: Transit Authority -> Prime Contractor -> Shell Sub -> Panama Vehicle -> Board Member Official")
    
    exp = ProcurementCaseStudy()
    res = exp.run()
    
    print("\n[REGIME COMPARISON]")
    for r_name, r_data in res["regimes"].items():
        audit_str = "✓ DETECTABLE" if r_data["conflict_of_interest_detectable"] else "✗ CONCEALED (BLIND SPOT)"
        f_r = r_data.get("relational_loss_Fr", 0.0)
        l2 = r_data.get("total_L2_loss", 0.0)
        print(f"\n▶ {r_name.upper()}:")
        print(f"    Description: {r_data['description']}")
        print(f"    Kickback Loop:   {audit_str}")
        print(f"    Relational Loss: F_r = {f_r:.4f}")
        print(f"    Total L_2 Loss:  L_2 = {l2:.4f}")
        if "audit_failure" in r_data:
            print(f"    Audit Impact:    {r_data['audit_failure']}")


def main():
    print("=" * 78)
    print("  BINARY FRAGMENTATION SIMULATOR — INTERACTIVE RESEARCH DEMONSTRATION")
    print("  Measuring Structural Information Loss Across Discrete Computational Pipelines")
    print("=" * 78)
    
    demo_financial_crucial()
    demo_aml_case_study()
    demo_procurement_case_study()
    
    print_banner("DEMONSTRATION COMPLETE")
    print("To run the full 15-suite test battery, execute:")
    print("  python3 run_simulations.py --out reports/dossier.md --json-out reports/dossier.json\n")


if __name__ == "__main__":
    main()
