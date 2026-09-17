#!/usr/bin/env python3
"""ADR Test Runner — runs the formal verification gate for a single ADR
and propagates the results automatically into `docs/adr/results/`.

Every run is captured verbatim (stdout + stderr + exit code) and persisted as:

    docs/adr/results/<adr-id>-<slug>/
      latest/
        logs/                raw per-step log files
        summary.json         machine-readable per-step PASS/FAIL
        REPORT.md            human-readable report
      run-YYYYMMDD-HHMMSS/   immutable timestamped snapshot (copy of the run)

The gate is the same one `make adr-verify` runs (`adr-index`, `adr-sorry-check`,
`lake build ADR`, `lake test`), extended per-ADR (see `ADR_CONFIG`) with the
operator-class engine Rust tests and the Kani bounded-model-checking harnesses
listed in the ADR itself. ADRs without a config entry run the Lean-only gate.

Usage:
    python3 scripts/run_adr_tests.py "<path/to/ADR-XXXX-slug.md>"
    python3 scripts/run_adr_tests.py "<path/to/ADR-XXXX-slug.md>" --skip-kani
    python3 scripts/run_adr_tests.py "<path/to/ADR-XXXX-slug.md>" --results-dir docs/adr/results

Exit code is 0 iff every step PASSED; any failure is reported and propagated to CI.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

# --- constants ---------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_RESULTS_DIR = REPO_ROOT / "docs" / "adr" / "results"
PIRTM_ENGINE_DIR = REPO_ROOT / "packages" / "rust" / "pirtm-engine"

# Kani bounded-model-checking harnesses named verbatim in ADR-0108 §"Kani
# Bounded-Model-Checking Harness" and §"Rust/Kani Integration Harness".
KANI_HARNESSES = [
    "adversarial_gain_is_vetoed_despite_valid_semantics",
    "invalid_semantics_are_rejected",
    "bcs_serialization_is_injective",
    "canonical_wire_format_is_injective",
    "canonical_wire_format_roundtrips",
    "contractivity_gate_is_fail_closed",
]

# Per-ADR gate extensions. An ADR absent from this table runs the Lean-only
# gate (adr-index → adr-sorry-check → lake build ADR → lake test), which is the
# correct gate for e.g. ADR-0110 (OSCAL and PrismPM): its whole formal model —
# the Legalese Scopist law, zero-drift, consequence entailment, and registry
# invariants — is discharged inside the `adrTest` Lean driver.
ADR_CONFIG = {
    "ADR-0108": {
        "cargo_dir": PIRTM_ENGINE_DIR,
        "cargo_test": True,
        "cargo_description": "pirtm-engine Rust tests (ensemble manifest, Phase D, interop, property)",
        "kani": KANI_HARNESSES,
    },
    "ADR-0110": {
        "cargo_test": False,
        "kani": [],
    },
}

ADR_ID_RE = re.compile(r"ADR-\d{3,4}")

# -----------------------------------------------------------------------------
# result model
# -----------------------------------------------------------------------------


@dataclass
class StepResult:
    name: str
    description: str
    status: str  # "PASS" | "FAIL"
    exit_code: int | None
    duration_ms: int
    summary_line: str = ""
    log_path: str = ""

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "description": self.description,
            "status": self.status,
            "exit_code": self.exit_code,
            "duration_ms": self.duration_ms,
            "summary_line": self.summary_line,
            "log_path": self.log_path,
        }


@dataclass
class RunRecord:
    adr_file: Path
    adr_id: str
    slug: str
    started_at: str
    duration_ms: int = 0
    steps: list[StepResult] = field(default_factory=list)
    overall: str = ""

    def to_dict(self) -> dict:
        return {
            "adr_file": str(self.adr_file),
            "adr_id": self.adr_id,
            "slug": self.slug,
            "started_at": self.started_at,
            "duration_ms": self.duration_ms,
            "overall": self.overall,
            "steps": [s.to_dict() for s in self.steps],
        }


# -----------------------------------------------------------------------------
# helpers
# -----------------------------------------------------------------------------


def run_step(
    record: RunRecord,
    adr_slug: str,
    name: str,
    description: str,
    cmd: list[str],
    *,
    workdir: Path,
    logs_dir: Path,
    env: dict | None = None,
) -> StepResult:
    """Run one gate step, capture full output, return the structured result."""
    log_path = logs_dir / f"{name}.log"
    started = time.monotonic()
    proc = subprocess.run(
        cmd,
        cwd=workdir,
        capture_output=True,
        text=True,
        env={**os.environ, **(env or {})},
    )
    duration_ms = int((time.monotonic() - started) * 1000)
    with log_path.open("w") as fh:
        fh.write(f"$ {' '.join(cmd)}\n")
        fh.write(f"# workdir: {workdir}\n")
        fh.write(f"# exit: {proc.returncode}\n")
        fh.write("# ---- stdout ----\n")
        fh.write(proc.stdout)
        fh.write("\n# ---- stderr ----\n")
        fh.write(proc.stderr)

    summary_line = (proc.stdout.strip().splitlines() or proc.stderr.strip().splitlines() or [""])[-1]
    status = "PASS" if proc.returncode == 0 else "FAIL"
    step = StepResult(
        name=name,
        description=description,
        status=status,
        exit_code=proc.returncode,
        duration_ms=duration_ms,
        summary_line=summary_line[:200],
        log_path=f"latest/logs/{name}.log",
    )
    record.steps.append(step)
    print(f"[{status}] {name}: {description} (exit={proc.returncode}, {duration_ms}ms)")
    if status == "FAIL":
        snippet = (proc.stderr or proc.stdout).strip().splitlines()[-8:]
        for line in snippet:
            print(f"        {line}")
    return step


def slugify(path: Path) -> str:
    """ADR-0108-PrismPM and Langlands Prism.md -> ADR-0108-PrismPM-and-Langlands-Prism"""
    stem = re.sub(r"\s+", "-", path.stem.strip())
    return re.sub(r"[^A-Za-z0-9_.-]", "-", stem)


def extract_adr_id(path: Path) -> str:
    m = ADR_ID_RE.search(path.stem)
    return m.group(0) if m else path.stem


def render_report(record: RunRecord, results_dir: Path) -> str:
    try:
        results_rel = str(results_dir.resolve().relative_to(REPO_ROOT))
    except ValueError:
        results_rel = str(results_dir)
    lines: list[str] = []
    lines.append(f"# ADR Test Results — {record.adr_id}")
    lines.append("")
    try:
        adr_rel = str(record.adr_file.resolve().relative_to(REPO_ROOT))
    except ValueError:
        adr_rel = str(record.adr_file)
    lines.append(f"- **ADR file:** `{adr_rel}`")
    lines.append(f"- **Started:** {record.started_at}")
    lines.append(f"- **Duration:** {record.duration_ms} ms")
    lines.append(f"- **Overall:** `{record.overall}`")
    lines.append("")
    lines.append("## Gate")
    lines.append("")
    lines.append("| Step | Description | Status | Exit | Duration |")
    lines.append("| :--- | :--- | :--- | :---: | ---: |")
    for step in record.steps:
        lines.append(
            f"| `{step.name}` | {step.description} | `{step.status}` | "
            f"{step.exit_code} | {step.duration_ms} ms |"
        )
    lines.append("")
    lines.append("## Artifacts")
    lines.append("")
    lines.append(f"Results directory: `{results_rel}`")
    lines.append("")
    for step in record.steps:
        lines.append(f"* [`{step.name}` log]({step.log_path})")
    lines.append("")
    lines.append(f"* [`summary.json`](summary.json)")
    lines.append("")
    if record.overall == "PASS":
        lines.append("**All checks passed.** ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・ ・")
    else:
        lines.append("**One or more checks failed — see logs.**")
    lines.append("")
    return "\n".join(lines)


# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("adr_file", type=Path, help="Path to the ADR markdown file under test")
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_DIR,
                        help="Root results folder (default: docs/adr/results)")
    parser.add_argument("--skip-kani", action="store_true",
                        help="Skip the Kani bounded-model-checking harnesses")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    adr_file: Path = args.adr_file.resolve()
    if not adr_file.exists():
        print(f"error: ADR file not found: {adr_file}", file=sys.stderr)
        return 2

    adr_id = extract_adr_id(adr_file)
    adr_slug = slugify(adr_file)
    started = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    per_adr_dir = args.results_dir.resolve() / f"{adr_slug}"
    run_dir = per_adr_dir / f"run-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}"
    logs_dir = run_dir / "logs"
    latest_dir = per_adr_dir / "latest"
    logs_dir.mkdir(parents=True, exist_ok=False)

    record = RunRecord(
        adr_file=adr_file,
        adr_id=adr_id,
        slug=adr_slug,
        started_at=started,
    )

    config = ADR_CONFIG.get(adr_id)

    # --- gate steps ----------------------------------------------------------
    run_step(
        record, adr_slug, "adr-index",
        "Regenerate docs/adr/README.md from registry.json",
        [sys.executable, "scripts/generate_adr_index.py"],
        workdir=REPO_ROOT, logs_dir=logs_dir,
    )
    run_step(
        record, adr_slug, "adr-sorry-check",
        "ADR-0010: zero untracked sorry tactics in ADR/",
        [sys.executable, "scripts/check_adr_sorry.py"],
        workdir=REPO_ROOT, logs_dir=logs_dir,
    )
    run_step(
        record, adr_slug, "lean-build",
        "lake build ADR (Lean 4 formal library)",
        ["lake", "build", "ADR"],
        workdir=REPO_ROOT, logs_dir=logs_dir,
    )
    run_step(
        record, adr_slug, "lean-test",
        f"lake test (adrTest driver, formal model of {adr_id})",
        ["lake", "test"],
        workdir=REPO_ROOT, logs_dir=logs_dir,
    )
    if config and config.get("cargo_test"):
        run_step(
            record, adr_slug, "cargo-test",
            config["cargo_description"],
            ["cargo", "test"],
            workdir=config["cargo_dir"], logs_dir=logs_dir,
        )
        if not args.skip_kani:
            for harness in config.get("kani", []):
                run_step(
                    record, adr_slug, f"kani:{harness}",
                    f"Kani bounded model checking — {harness}",
                    ["cargo", "kani", "--tests", "--harness", harness],
                    workdir=config["cargo_dir"], logs_dir=logs_dir,
                )
    else:
        print(f"(no cargo/Kani gate for {adr_id or 'unregistered ADR-id'} — Lean-only gate)")

    # --- record ---------------------------------------------------------------
    record.duration_ms = sum(s.duration_ms for s in record.steps)
    record.overall = "PASS" if all(s.status == "PASS" for s in record.steps) else "FAIL"

    with (run_dir / "summary.json").open("w") as fh:
        json.dump(record.to_dict(), fh, indent=2)
        fh.write("\n")

    with (run_dir / "REPORT.md").open("w") as fh:
        fh.write(render_report(record, per_adr_dir))

    # propagate to latest (mirror of the newest run)
    if latest_dir.exists():
        shutil.rmtree(latest_dir)
    shutil.copytree(run_dir, latest_dir)

    print()
    print(f"Results written to:")
    print(f"  {run_dir}")
    print(f"  {latest_dir}")
    print(f"Overall: {record.overall}")
    for step in record.steps:
        print(f"  [{step.status}] {step.name}")
    return 0 if record.overall == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))