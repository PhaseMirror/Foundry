import argparse
import json
import os
import sys
import numpy as np
from datetime import datetime
from collections import Counter
from typing import Optional

# Add src to sys.path
sys.path.append(os.path.abspath("src"))

from genesis_governance.lane_d.schema import ConstitutionalIncidentReport, HumanAudit
from genesis_governance.lane_d.history import MetaHistoryStore

def list_cirs(limit: int, status_filter: Optional[str] = None):
    reports_dir = "output/reports"
    if not os.path.exists(reports_dir):
        print("No reports found.")
        return
        
    reports = []
    for f in os.listdir(reports_dir):
        if f.endswith(".json"):
            with open(os.path.join(reports_dir, f), "r") as file:
                try:
                    reports.append(ConstitutionalIncidentReport(**json.load(file)))
                except Exception:
                    continue
    
    # Sort by time
    reports.sort(key=lambda r: r.timestamp, reverse=True)
    
    if status_filter:
        reports = [r for r in reports if r.human_audit and r.human_audit.status == status_filter]
        
    print(f"{'Report ID':<40} | {'Status':<10} | {'Time'}")
    for r in reports[:limit]:
        status = r.human_audit.status if r.human_audit else "OPEN"
        print(f"{r.report_id:<40} | {status:<10} | {r.timestamp}")

def report_cirs(window: int = 50):
    store = MetaHistoryStore()
    history = store.get_history()
    
    if not history:
        print("No meta-history available.")
        return

    window_data = history[-window:]
    
    avg_cd = np.mean([f.cd_overall for f in window_data])
    frag_counts = Counter([f.meta_fragility_class for f in window_data])
    
    print(f"
=== Genesis Governance Report (Last {len(window_data)} runs) ===")
    print(f"Mean Meta-Coherence: {avg_cd:.3f}")
    
    print("
Fragility Histogram:")
    for cls, count in frag_counts.items():
        print(f"  {cls:35}: {count}")

def show_cir(report_id: str, format: str = "text"):
    reports_dir = "output/reports"
    report_file = None
    for f in os.listdir(reports_dir):
        if report_id in f:
            report_file = os.path.join(reports_dir, f)
            break
            
    if not report_file:
        print(f"Report {report_id} not found.")
        return

    with open(report_file, "r") as f:
        data = json.load(f)
    
    if format == "json":
        print(json.dumps(data, indent=2))
        return
        
    # Text rendering
    report = ConstitutionalIncidentReport(**data)
    print(f"
=== Constitutional Incident Report: {report.report_id} ===")
    print(f"Source Run: {report.source_run_id} | Artifact Hash: {report.artifact_hash[:8]}...")
    print(f"Time: {report.timestamp}")
    print(f"Fragility: {report.meta_fragility_class} | Global CD: {report.cd_global:.3f}")
    
    print("
--- Rule Trace ---")
    for action in report.actions:
        if action.trace:
            print(f"[{action.trace.rule_source}] {action.trace.rule_id}")
            print(f"  Condition: {action.trace.condition_predicate}")
            print(f"  Justification: {action.trace.justification}")
            
    print("
--- Commanded Actions ---")
    for action in report.actions:
        print(f"Lane {action.lane_id} -> {action.commanded_profile} ({action.target_fragility_class})")

    if report.human_audit:
        print("
--- Human Audit ---")
        print(f"Status: {report.human_audit.status} by {report.human_audit.reviewer_id}")
        print(f"Comment: {report.human_audit.comment}")

def annotate_cir(report_id: str, reviewer_id: str, status: str, comment: str):
    reports_dir = "output/reports"
    report_file = None
    for f in os.listdir(reports_dir):
        if report_id in f:
            report_file = os.path.join(reports_dir, f)
            break
            
    if not report_file:
        print(f"Report {report_id} not found.")
        return
        
    with open(report_file, "r") as f:
        data = json.load(f)
    
    report = ConstitutionalIncidentReport(**data)
    
    # Add audit entry
    report.human_audit = HumanAudit(
        reviewer_id=reviewer_id,
        status=status,
        comment=comment
    )
    
    # Save (maintaining immutability of original data fields)
    with open(report_file, "w") as f:
        f.write(report.model_dump_json(indent=2))
    print(f"Report {report.report_id} annotated successfully.")

def main():
    parser = argparse.ArgumentParser(description="Genesis Governance Console (genesis-gov)")
    subparsers = parser.add_subparsers(dest="command")
    
    # List
    list_parser = subparsers.add_parser("list")
    list_parser.add_argument("--limit", type=int, default=20)
    list_parser.add_argument("--status", choices=["OPEN", "APPROVED", "REJECTED", "ESCALATED"])
    
    # Report
    rep_parser = subparsers.add_parser("report")
    rep_parser.add_argument("--window", type=int, default=50)

    # Show
    show_parser = subparsers.add_parser("show")
    show_parser.add_argument("report_id")
    show_parser.add_argument("--format", choices=["text", "json"], default="text")
    
    # Annotate
    ann_parser = subparsers.add_parser("annotate")
    ann_parser.add_argument("report_id")
    ann_parser.add_argument("--reviewer", required=True)
    ann_parser.add_argument("--status", choices=["OPEN", "APPROVED", "REJECTED", "ESCALATED"], required=True)
    ann_parser.add_argument("--comment", required=True)
    
    args = parser.parse_args()
    
    if args.command == "list":
        list_cirs(args.limit, args.status)
    elif args.command == "report":
        report_cirs(args.window)
    elif args.command == "show":
        show_cir(args.report_id, args.format)
    elif args.command == "annotate":
        annotate_cir(args.report_id, args.reviewer, args.status, args.comment)

if __name__ == "__main__":
    main()
