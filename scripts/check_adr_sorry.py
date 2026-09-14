#!/usr/bin/env python3
"""ADR: Sorry Check Script (precise).

Scans ADR/ directory for `sorry` tactic usage in Lean 4 source files.
Fails if any are found outside the allowed quarantine file
(ADR/Core/Axioms.lean).

Enforces ADR-0010 (Axiom-Clean Kernel Boundary): zero untracked
proof debt in the ADR/ directory.

Usage:  python3 scripts/check_adr_sorry.py
CI:     Add to workflow via `python3 scripts/check_adr_sorry.py`
"""

import os
import re
import sys

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADR_DIR = os.path.join(PROJECT_DIR, "ADR")

# Pattern matches Lean 4 `sorry` as a tactic, not in comments or strings.
# Covers: `by sorry`, `:= sorry`, `[sorry]`, `using sorry`, `<sorry>`, `!sorry`
SORRY_TACTIC_RE = re.compile(
    r'(?:^|[\s,;({[<])(sorry\b)(?!\w)',
    re.MULTILINE,
)

# Patterns that are definitely NOT tactic usage (comments, strings, docstrings)
COMMENT_RE = re.compile(r'^\s*--|^\s*/')
STRING_SORRY_RE = re.compile(r'"[^"]*sorry[^"]*"', re.DOTALL)
QUOTE_SORRY_RE = re.compile(r"'[^']*sorry[^']*'")

ALLOWED_EXCEPTION = os.path.join(ADR_DIR, "Core", "Axioms.lean")


def scan_file(filepath: str) -> list[tuple[int, str]]:
    hits = []
    with open(filepath, "r") as f:
        lines = f.readlines()

    for i, line in enumerate(lines, 1):
        if COMMENT_RE.search(line):
            continue
        if STRING_SORRY_RE.search(line) or QUOTE_SORRY_RE.search(line):
            continue
        if SORRY_TACTIC_RE.search(line):
            hits.append((i, line.rstrip()))
    return hits


def main() -> int:
    print("=== ADR Sorry Check (precise) ===")
    print(f"Scanning: {ADR_DIR}")
    print(f"Allowed exception: {ALLOWED_EXCEPTION}")
    print()

    all_hits = []
    for root, _dirs, files in os.walk(ADR_DIR):
        for fname in sorted(files):
            if not fname.endswith(".lean"):
                continue
            filepath = os.path.join(root, fname)
            if os.path.normpath(filepath) == os.path.normpath(ALLOWED_EXCEPTION):
                continue
            hits = scan_file(filepath)
            for lineno, line in hits:
                all_hits.append((filepath, lineno, line))
                print(f"SORRY TACTIC: {filepath}:{lineno}")
                print(f"  {line}")

    print()
    if all_hits:
        print(f"FAILED: Found {len(all_hits)} sorry tactic(s) in ADR/ (outside Core/Axioms.lean)")
        print("ADR-0010 violation: zero untracked proof debt required on main branch.")
        return 1
    else:
        print("PASSED: No sorry tactics found in ADR/ directory")
        return 0


if __name__ == "__main__":
    sys.exit(main())