#!/usr/bin/env python3
"""
honesty_audit.py — verifies that no Lean file under F1/AnalyticBridge contains
a ``sorry`` placeholder.  Zero sorries is the production gate for this module.
"""
import pathlib
import sys

ROOT = pathlib.Path("/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/F1/AnalyticBridge")

def main() -> int:
    bad = []
    for path in ROOT.rglob("*.lean"):
        text = path.read_text()
        if "sorry" in text:
            bad.append(str(path))
    if bad:
        print("FAIL: sorry found in:")
        for p in bad:
            print(f"  {p}")
        return 1
    print("PASS: zero sorries in F1/AnalyticBridge")
    return 0

if __name__ == "__main__":
    sys.exit(main())
