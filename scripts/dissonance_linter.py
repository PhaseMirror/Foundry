#!/usr/bin/env python3
"""
dissonance_linter.py - The Π₄ Governance Linter

Enforces the dissonance operator's prose-to-code discipline.
Any markdown file asserting a claim must link to an executable
benchmark, script, or notebook (benchmarks/, notebooks/, src/).

"Prose without code is null in the conscious lattice."
"""
import sys
import re
from pathlib import Path

# The epistemic triggers that flag a formal claim
CLAIM_TRIGGERS = [
    r"we assert",
    r"the lattice shows",
    r"the bound is",
    r"proven to",
    r"guarantees",
    r"formally verified"
]
CLAIM_PATTERN = re.compile(r"(?i)(" + "|".join(CLAIM_TRIGGERS) + r")")

# The code anchors that satisfy the claim (must be linked nearby)
ANCHOR_PATTERN = re.compile(r"(benchmarks/|notebooks/|src/)[^\s)]+\.(py|ipynb|json|lean|rs|yaml)")

def lint_file(filepath: Path) -> int:
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"::error file={filepath}::Could not read file: {e}")
        return 1

    # Split into paragraphs to check local context of claims
    paragraphs = content.split('\n\n')
    violations = 0

    for i, p in enumerate(paragraphs):
        match = CLAIM_PATTERN.search(p)
        if match:
            # Claim found, search for an anchor in the same paragraph
            if not ANCHOR_PATTERN.search(p):
                claim_text = match.group(0)
                print(f"::error file={filepath}::Unverified claim detected: '{claim_text}'. "
                      f"Prose without code is null in the conscious lattice. "
                      f"You must link to a path in src/, benchmarks/, or notebooks/.")
                violations += 1

    return violations

def main():
    if len(sys.argv) < 2:
        print("No files provided.")
        sys.exit(0)

    files_to_check = sys.argv[1:]
    total_violations = 0

    print(f"Applying Π₄ Dissonance Linter to {len(files_to_check)} files...")
    
    for f in files_to_check:
        path = Path(f)
        if path.exists():
            violations = lint_file(path)
            total_violations += violations
        else:
            print(f"Warning: File {f} does not exist.")

    if total_violations > 0:
        print(f"\n[FAILED] Π₄ Operator detected {total_violations} dissonance violations.")
        print("Every claim must be anchored to an executable artifact.")
        sys.exit(1)
    else:
        print("\n[SUCCESS] All claims are successfully anchored. The lattice is coherent.")
        sys.exit(0)

if __name__ == "__main__":
    main()
