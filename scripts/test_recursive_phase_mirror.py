#!/usr/bin/env python3
"""
test_recursive_phase_mirror.py — self-contained test harness for ADR-232.

Builds a fixture repository under a temp dir and asserts the time-aware triage
verdicts required by ADR-232 §8:

  [1] sorry-free declaration  => GOLDEN            (regardless of mtime)
  [2] missing + impl newer    => DOC_STALE         (update the doc)
  [3] missing + doc newer     => CODE_STALE        (update the math/code)
  [4] template docs excluded
  [5] frozen docs excluded
  [6] sorry'd declaration     => CODE_STALE        (math behind the claim)
  [7] dry-run writes nothing
  [8] idempotent plan numbering
  [9] resolved plan ADR demoted to Status: Resolved

Run: python3 scripts/test_recursive_phase_mirror.py
"""

from __future__ import annotations

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ENGINE = os.path.join(HERE, "recursive_phase_mirror.py")

RESULTS = {"pass": 0, "fail": 0}


def check(name: str, cond: bool, detail: str = "") -> None:
    if cond:
        RESULTS["pass"] += 1
        print(f"  PASS  {name}")
    else:
        RESULTS["fail"] += 1
        print(f"  FAIL  {name} {detail}")


def write(path: str, content: str, mtime: float) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(content)
    os.utime(path, (mtime, mtime))


def build_fixture(root: str) -> None:
    base = time.time() - 10000  # 'now' minus 10k seconds

    # --- docs (stated intent) ---
    # Claim a theorem that DOES exist as a sorry-free declaration.
    write(os.path.join(root, "Governance", "adr", "accepted", "ADR-001-test.md"),
          "# ADR-001\n\n`golden_theorem` is formally verified in Lean 4.\n",
          base - 200)
    # Claim a theorem that is MISSING; document is OLDER than newest impl.
    write(os.path.join(root, "paper", "stale-doc.md"),
          "# Stale paper\n\n`missing_theorem_old` is proven.\n",
          base - 5000)
    # Claim a theorem that is MISSING; document is NEWER than newest impl.
    write(os.path.join(root, "docs", "new-commitment.md"),
          "# New commitment\n\n`missing_theorem_new` is proven.\n",
          base - 10)
    # Claim a theorem whose declaration still discharges via `sorry`.
    write(os.path.join(root, "Governance", "adr", "accepted", "ADR-002-test.md"),
          "# ADR-002\n\n`sorry_theorem` is verified.\n",
          base - 300)
    # Template doc: illustrative fence, must NOT become a claim.
    write(os.path.join(root, "Governance", "adr", "templates", "template.md"),
          "# Template\n\n```lean\ntheorem illustrative_fence : True := by trivial\n```\n",
          base)
    # Frozen doc: completed ADR, must NOT generate a claim.
    write(os.path.join(root, "Governance", "adr", "completed", "ADR-999.md"),
          "# Completed\n\n`frozen_theorem` is proven.\n",
          base - 100)

    # --- implementation (developed reality) ---
    write(os.path.join(root, "lean", "Core", "Golden.lean"),
          "import Mathlib\n\ntheorem golden_theorem : True := by\n  trivial\n",
          base - 100)  # NEWER than the doc claiming it
    write(os.path.join(root, "lean", "Core", "Sorry.lean"),
          "theorem sorry_theorem : True := by\n  sorry\n",
          base - 50)  # NEWER than the doc, but sorry => CODE_STALE
    # Rust corpus: newest impl file, newer than the "old" paper doc.
    write(os.path.join(root, "rust", "core", "src", "lib.rs"),
          "pub fn newest_impl_fn() -> u32 { 1 }\n",
          base - 20)


def run_engine(root: str, *extra: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, ENGINE, "--root", root, *extra],
        capture_output=True, text=True, cwd=root)


def read_plan_state(root: str) -> dict:
    with open(os.path.join(root, "state", "recursive_phase_mirror.json"), encoding="utf-8") as fh:
        return json.load(fh)


def main() -> None:
    tmp = tempfile.mkdtemp(prefix="rpm-test-")
    try:
        build_fixture(tmp)
        print(f"fixture: {tmp}")

        # [7] dry-run writes nothing
        proc = run_engine(tmp, "--dry-run")
        check("[7] dry-run exit 0", proc.returncode == 0, proc.stderr)
        check("[7] dry-run writes no state",
              not os.path.exists(os.path.join(tmp, "state", "recursive_phase_mirror.json")))
        check("[7] dry-run writes no index",
              not os.path.exists(os.path.join(tmp, "Governance", "adr", "proposed",
                                              "ADR-Plan-Recursive-Phase-Mirror-Loop.md")))

        # full run
        proc = run_engine(tmp)
        check("engine exit 0", proc.returncode == 0, proc.stderr)
        state = read_plan_state(tmp)

        verdicts = {t["claim"]["name"]: t["verdict"] for t in state["tensions"]}
        print(f"  verdicts: {verdicts}")

        # [1] sorry-free resolution => GOLDEN (doc is OLDER than impl)
        check("[1] golden_theorem => GOLDEN",
              verdicts.get("golden_theorem") == "GOLDEN",
              str(verdicts.get("golden_theorem")))
        # [2] missing + impl newer => DOC_STALE
        check("[2] missing_theorem_old => DOC_STALE",
              verdicts.get("missing_theorem_old") == "DOC_STALE",
              str(verdicts.get("missing_theorem_old")))
        # [3] missing + doc newer => CODE_STALE
        check("[3] missing_theorem_new => CODE_STALE",
              verdicts.get("missing_theorem_new") == "CODE_STALE",
              str(verdicts.get("missing_theorem_new")))
        # [6] sorry'd declaration => CODE_STALE even though impl is newer
        check("[6] sorry_theorem => CODE_STALE",
              verdicts.get("sorry_theorem") == "CODE_STALE",
              str(verdicts.get("sorry_theorem")))

        # [4] template doc excluded: illustrative_fence must not be a claim
        check("[4] template fence not harvested",
              "illustrative_fence" not in verdicts, str(list(verdicts)))
        # [5] frozen doc excluded: frozen_theorem must not be a claim
        check("[5] frozen doc not harvested",
              "frozen_theorem" not in verdicts, str(list(verdicts)))

        # [8] idempotent plan numbering: re-run produces no extra plans
        plans1 = {f for f in os.listdir(os.path.join(tmp, "Governance", "adr", "proposed"))
                  if f.startswith("ADR-RML-")}
        run_engine(tmp)
        plans2 = {f for f in os.listdir(os.path.join(tmp, "Governance", "adr", "proposed"))
                  if f.startswith("ADR-RML-")}
        check("[8] idempotent plan numbering", plans1 == plans2,
              f"{plans1} vs {plans2}")

        # [9] resolving a document's claims demotes its plan ADR to Resolved
        plan_doc = os.path.join(tmp, "Governance", "adr", "accepted", "ADR-002-test.md")
        # Fix the sorry: make the declaration sorry-free and NEWER so the claim
        # becomes GOLDEN, which removes the document from the cluster set.
        write(os.path.join(tmp, "lean", "Core", "Sorry.lean"),
              "theorem sorry_theorem : True := by\n  trivial\n",
              time.time())
        write(plan_doc, "# ADR-002\n\n`sorry_theorem` is verified.\n", time.time())
        run_engine(tmp)
        resolved_files = []
        for f in os.listdir(os.path.join(tmp, "Governance", "adr", "proposed")):
            if f.startswith("ADR-RML-") and f.endswith(".md"):
                text = open(os.path.join(tmp, "Governance", "adr", "proposed", f),
                            encoding="utf-8").read()
                if "## Status\nResolved" in text:
                    resolved_files.append(f)
        check("[9] resolved plan ADR demoted to Status: Resolved",
              len(resolved_files) == 1, str(resolved_files))

        # index exists and lists mismatches
        idx = os.path.join(tmp, "Governance", "adr", "proposed",
                           "ADR-Plan-Recursive-Phase-Mirror-Loop.md")
        check("master index written", os.path.isfile(idx))
        with open(idx, encoding="utf-8") as fh:
            idx_text = fh.read()
        check("index lists DOC_STALE", "DOC_STALE" in idx_text)
        check("index lists CODE_STALE", "CODE_STALE" in idx_text)

    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print(f"\n{RESULTS['pass']} passed, {RESULTS['fail']} failed")
    return 0 if RESULTS["fail"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
