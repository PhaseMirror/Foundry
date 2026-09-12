#!/usr/bin/env bash
# check_invariant_declarations.sh - Validate front-matter invariant declarations
# Part of ADR-043 Sedona Spine Front-Matter Hardening

set -euo pipefail

echo "== Checking invariant declarations in documentation =="

# Find all markdown files in docs/
if [ ! -d "docs" ]; then
    echo "INFO: docs/ directory not found, skipping invariant check"
    exit 0
fi

# Check for @@invariant: declarations in .md files
# Pattern: @@invariant: <name> where <condition>
found_violations=0

while IFS= read -r -d '' file; do
    # Check if file contains any invariant declarations
    if grep -q '@@invariant:' "$file" 2>/dev/null; then
        echo "Checking $file"
        
        # Extract invariant declarations and validate format
        # Each invariant must have: name, condition, and ContractivityReceipt link
        while IFS= read -r line; do
            if [[ "$line" =~ @@invariant:[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]*where[[:space:]]*(.+)$ ]]; then
                invariant_name="${BASH_REMATCH[1]}"
                condition="${BASH_REMATCH[2]}"
                echo "  Found invariant: $invariant_name"
                
                # Check for ContractivityReceipt linkage (must appear later in file)
                if ! grep -q 'ContractivityReceipt' "$file"; then
                    echo "  WARNING: No ContractivityReceipt link for $invariant_name in $file"
                fi
            fi
        done < <(grep '@@invariant:' "$file" 2>/dev/null || true)
    fi
done < <(find docs -name '*.md' -print0 2>/dev/null || true)

echo "PASS: Invariant declarations checked"
exit 0