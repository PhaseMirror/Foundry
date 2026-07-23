#!/usr/bin/env bash
set -euo pipefail

# honesty_audit.sh: Verifies the UAC-ALP boundary by ensuring 'sorry' blocks
# only exist for explicitly manifested ALP functions.

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MANIFEST="${ROOT_DIR}/alp_sorry_manifest.json"
LEAN_DIR="${ROOT_DIR}/lean"

echo "=== Honesty Audit: UAC-ALP Boundary ==="

if [[ ! -f "$MANIFEST" ]]; then
  echo "❌ Error: alp_sorry_manifest.json not found!"
  exit 1
fi

echo "Extracting permitted sorrys from manifest..."
# Simple parser to extract just the values
permitted_sorrys=$(grep -o '"ALP\.[^"]*"' "$MANIFEST" | tr -d '"')

echo "Scanning lean/ (excluding .lake/) for sorry instances..."
# We search for 'sorry' and then backtrack to find the surrounding theorem name
found_sorrys=0
unauthorized=0

# A simple approach is to find files containing sorry, then list the theorems.
# Lean files are formatted nicely, so we can grep for 'theorem' or 'def' before 'sorry'.
# For robustness, we will use a python script inline to parse it.

python3 - <<EOF
import os
import glob
import sys
import json

manifest_path = "$MANIFEST"
with open(manifest_path, 'r') as f:
    data = json.load(f)
    permitted = set(data.get("permitted_sorrys", []))

lean_dir = "$LEAN_DIR"
lean_files = glob.glob(os.path.join(lean_dir, "**/*.lean"), recursive=True)
# Exclude .lake/ (vendored std library)
lean_files = [f for f in lean_files if ".lake" not in f]

unauthorized_count = 0

for file_path in lean_files:
    with open(file_path, 'r') as f:
        content = f.read()
    
    if "sorry" not in content:
        continue
        
    lines = content.split('\n')
    current_theorem = None
    current_namespace = None
    
    for i, line in enumerate(lines):
        line = line.strip()
        if line.startswith("namespace "):
            current_namespace = line.split()[1]
        elif line.startswith("end "):
            current_namespace = None
        elif line.startswith("theorem ") or line.startswith("def "):
            parts = line.split()
            if len(parts) > 1:
                current_theorem = parts[1]
                if current_namespace:
                    current_theorem = f"{current_namespace}.{current_theorem}"
        elif "sorry" in line:
            if not line.startswith("--"): # skip comments
                if current_theorem:
                    if current_theorem not in permitted:
                        print(f"❌ Unauthorized 'sorry' found in {file_path} at theorem {current_theorem}")
                        unauthorized_count += 1
                else:
                    print(f"❌ Unauthorized 'sorry' found in {file_path} (could not determine theorem context)")
                    unauthorized_count += 1

if unauthorized_count > 0:
    print(f"❌ Audit Failed: Found {unauthorized_count} unmanifested sorry blocks crossing the boundary.")
    sys.exit(1)
else:
    print("✅ Audit Passed: All 'sorry' blocks are perfectly bounded within the manifest.")
    sys.exit(0)
EOF
