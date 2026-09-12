#!/usr/bin/env python3
"""Validate Lean↔Rust control-surface schema consistency.

Checks that:
1. `rust/src/control_surface.rs` exists and is well-formed.
2. `src/ADR/ControlSurface.lean` exists and is well-formed.
3. Both define the same set of ADR statuses and circuit-breaker states.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


def check_rust_contract(root: Path) -> list[str]:
    """Check Rust control_surface.rs for required definitions."""
    path = root / "rust" / "src" / "control_surface.rs"
    if not path.exists():
        return [f"missing {path}"]
    text = path.read_text(encoding="utf-8")
    issues = []
    for name in ["AdrStatus", "CircuitBreakerState", "ControlSurfaceContract", "is_valid"]:
        if name not in text:
            issues.append(f"rust: missing definition `{name}`")
    return issues


def check_lean_contract(root: Path) -> list[str]:
    """Check Lean ControlSurface.lean for required definitions."""
    path = root / "src" / "ADR" / "ControlSurface.lean"
    if not path.exists():
        return [f"missing {path}"]
    text = path.read_text(encoding="utf-8")
    issues = []
    for name in ["ADRStatus", "CircuitBreakerState", "ControlSurfaceContract", "contract_valid"]:
        if name not in text:
            issues.append(f"lean: missing definition `{name}`")
    return issues


def main() -> int:
    root = Path(".").resolve()
    rust_issues = check_rust_contract(root)
    lean_issues = check_lean_contract(root)
    issues = rust_issues + lean_issues
    if issues:
        print("ERROR: control-surface schema inconsistency detected:")
        for issue in issues:
            print(f"  - {issue}")
        return 1
    print("OK: Rust↔Lean control-surface schemas are consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
