#!/usr/bin/env python3
import os
import re
import json
import sys

# Configuration
src_dir = "lean/F1Square"
report_file = "honesty_report.json"

# State
mathlib_violations = []
sorry_instances = []
crux_violations = []
governance_failures = []

# Regex patterns
rx_decl_start = re.compile(r'^\s*(def|theorem|lemma|instance|example|structure|class)\s+([^:\s]+)')
rx_gov_marker = re.compile(r'ContractivityReceipt|AnalyticContractivityReceipt')

print("============================================================")
print("  F1SQUARE EPISTEMIC HONESTY AUDIT (v0.9.1)                 ")
print("============================================================")

if not os.path.exists(src_dir):
    print(f"Error: Directory {src_dir} not found. Run from the workspace root.")
    sys.exit(1)

for root, dirs, files in os.walk(src_dir):
    for f in files:
        if not f.endswith('.lean'): continue
        path = os.path.join(root, f)
        
        with open(path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
            
        current_decl = "<global>"
        is_gov_context = False
        
        for i, line in enumerate(lines):
            line_no = i + 1
            
            # 1. Zero-Mathlib Check
            if "import Mathlib" in line:
                mathlib_violations.append({"file": path, "line": line_no})
                
            # 2. Crux Guard Check
            if re.search(r'liPositivityStatus.*\b(some true|true)\b', line):
                crux_violations.append({"file": path, "line": line_no})
                
            # Track Declaration Context
            m = rx_decl_start.match(line)
            if m:
                current_decl = m.group(2)
                # Look ahead a few lines to capture the type signature
                type_sig = line
                for j in range(1, 4):
                    if i + j < len(lines):
                        type_sig += lines[i+j]
                        if ":=" in lines[i+j]: break # Stop at definition body
                
                # Check if it's a ContractivityReceipt or enforce* function
                is_gov_context = bool(rx_gov_marker.search(type_sig)) or current_decl.lower().startswith("enforce")
                
            # 3. Sorry Scanner
            if "sorry" in line:
                instance = {
                    "file": path,
                    "line": line_no,
                    "declaration": current_decl,
                    "is_governance": is_gov_context
                }
                sorry_instances.append(instance)
                if is_gov_context:
                    governance_failures.append(instance)

# Generate JSON Report
report_data = {
    "mathlib_violations": mathlib_violations,
    "crux_violations": crux_violations,
    "governance_failures": governance_failures,
    "sorry_stubs": [s for s in sorry_instances if not s["is_governance"]]
}

with open(report_file, 'w') as f:
    json.dump(report_data, f, indent=2)

fail = False

print("[1/3] Enforcing Zero-Mathlib mandate... ", end="")
if mathlib_violations:
    print("FAIL")
    for v in mathlib_violations: print(f"  -> {v['file']}:{v['line']}")
    fail = True
else:
    print("PASS")

print("[2/3] Auditing Crux boundary integrity (Li Positivity)... ", end="")
if crux_violations:
    print("FAIL")
    for v in crux_violations: print(f"  -> {v['file']}:{v['line']}")
    fail = True
else:
    print("PASS")

print("[3/3] Scanning 'sorry' stubs and Governance claims...")
stubs = len(sorry_instances) - len(governance_failures)
print(f"  -> Found {stubs} general 'sorry' stubs (Warning only).")

if governance_failures:
    print(f"  -> FAIL: Found {len(governance_failures)} 'sorry' inside Governance/Contractivity blocks!")
    for v in governance_failures:
        print(f"     {v['file']}:{v['line']} (in {v['declaration']})")
    fail = True
else:
    print("  -> PASS: No unverified governance claims.")

print("============================================================")
if fail:
    print("  AUDIT FAILED: Epistemic constraints violated. See report.")
    print(f"  Detailed JSON report saved to {report_file}")
    sys.exit(1)
else:
    print("  AUDIT COMPLETE: All epistemic constraints satisfied.")
    print(f"  Detailed JSON report saved to {report_file}")
    sys.exit(0)
