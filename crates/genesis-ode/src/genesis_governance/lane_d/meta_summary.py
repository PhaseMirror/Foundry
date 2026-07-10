import json
import os
import sys
import numpy as np
from typing import Optional, List
from genesis_governance.lane_d.history import MetaHistoryStore
from genesis_governance.lane_d.schema import MetaShrapnelFragment

def get_summary(window_size: int = 50, reference_id: str = "MET_BASELINE_V050"):
    store = MetaHistoryStore()
    history = store.get_history()

    if not history:
        print("No meta-history available.")
        return

    # Slice window
    window = history[-window_size:]

    # Load Reference
    ref_path = os.path.join("meta-reference", f"{reference_id}.json")
    if os.path.exists(ref_path):
        with open(ref_path, "r") as f:
            ref_data = json.load(f)
            ref_frag = MetaShrapnelFragment(**ref_data["meta_fragments"][0])
    else:
        ref_frag = None

    # Snapshot (latest)
    latest = window[-1]

    # Summary stats
    cd_scores = [f.cd_overall for f in window]
    avg_cd = np.mean(cd_scores)
    median_cd = np.median(cd_scores)

    # Fragility distribution
    frag_classes = [f.meta_fragility_class for f in window]
    from collections import Counter
    frag_counts = Counter(frag_classes)

    # SLOs & Policy Compliance
    slos = {
        "Mean_CD": avg_cd >= 0.65,
        "Stability": len([f for f in window if f.cd_overall >= 0.60]) / len(window) >= 0.8,
        "Collapse_Rate": len([f for f in window if f.meta_fragility_class == "META_GOVERNANCE_COLLAPSE"]) / len(window) <= 0.1
    }

    # Regression Check
    regression = False
    if ref_frag:
        # Check if latest CD is significantly lower than baseline
        if latest.cd_overall < ref_frag.cd_overall * 0.9:
            regression = True

    print("\n=== Meta-Telemetry Snapshot (Latest) ===")
    print(f"Run ID: {latest.source_run_id} | ADR: {latest.context.adr_version}")
    print(f"Fragility: {latest.meta_fragility_class}")
    print(f"Bottleneck: {latest.bottleneck}")
    print(f"Overall CD: {latest.cd_overall:.3f}")
    print(f"Policy Compliant: {'YES' if latest.is_policy_compliant else 'NO'}")
    if not latest.is_policy_compliant:
        print(f"Violation Reason: {latest.violation_reason}")

    if regression:
        print("!!! REGRESSION DETECTED: Meta-coherence below baseline threshold !!!")
    print(f"\n=== Window Summary (Last {len(window)} runs) ===")
    print(f"Mean CD: {avg_cd:.3f} | Median CD: {median_cd:.3f}")
    print("\nSLO Compliance:")
    for k, v in slos.items():
        print(f"  {k:15}: {'PASS' if v else 'FAIL'}")

    print("\nFragility Histogram:")
    for cls, count in frag_counts.items():
        print(f"  {cls:35}: {count}")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Genesis Governance Meta-Summary")
    parser.add_argument("--window", type=int, default=50, help="Analysis window size")
    parser.add_argument("--ref", type=str, default="MET_BASELINE_V050", help="Reference cohort ID")
    args = parser.parse_args()

    get_summary(window_size=args.window, reference_id=args.ref)

if __name__ == "__main__":
    main()

