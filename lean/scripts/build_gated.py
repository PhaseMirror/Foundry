#!/usr/bin/env python3
"""build_gated.py – Entrypoint for the gated Einstein implementation.

Features:
* Parses YAML policies from `templates/`.
* Calls the Sedona Spine (Rust engine + WASM SDK) to compute preservation alerts.
* Runs SAPGC validation, EFT scaling sanity, and Spin‑Foam RG flow verification.
* Builds a signed artifact bundle.
* Implements `--check-hook` for the Git pre‑receive validation.
"""

import argparse
import subprocess
import sys
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # repository root (PhaseMirror)
TEMPLATES = ROOT / "templates"

def _run_engine(entry_point: str) -> dict:
    """Invoke the Rust engine via Cargo.
    `entry_point` selects which module to run (e.g. 'sapgc', 'eft', 'spinfoam').
    Returns the parsed JSON output.
    """
    cmd = ["cargo", "run", "--manifest-path", str(ROOT / "lean" / "Cargo.toml"), "--quiet", "--", entry_point]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        print(f"[ERROR] Engine step '{entry_point}' failed:\n{result.stderr}")
        sys.exit(result.returncode)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print(f"[ERROR] Invalid JSON from engine step '{entry_point}'.")
        sys.exit(1)

def _load_yaml(name: str) -> dict:
    import yaml
    path = TEMPLATES / name
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def check_hook():
    """Run all validation steps and abort on any violation.
    The Sedona Spine contractivity check is the authoritative source of truth.
    """
    # 1. SAPGC validation
    sapgc = _run_engine("sapgc")
    if sapgc.get("status") != "ok":
        print("[PRESERVATION ALERT] SAPGC validation failed – rejecting push.")
        sys.exit(1)

    # 2. EFT scaling sanity
    eft = _run_engine("eft")
    if eft.get("status") != "ok":
        print("[PRESERVATION ALERT] EFT scaling sanity failed – rejecting push.")
        sys.exit(1)

    # 3. Spin‑Foam RG flow verification
    spin = _run_engine("spinfoam")
    if spin.get("status") != "ok":
        print("[PRESERVATION ALERT] Spin‑Foam RG flow validation failed – rejecting push.")
        sys.exit(1)

    print("All gated validations passed. Hook check succeeded.")
    sys.exit(0)

def build_bundle(sign: bool):
    out_dir = ROOT / "lean" / "gated" / "Einstein" / "dist"
    out_dir.mkdir(parents=True, exist_ok=True)
    bundle = out_dir / "einstein_bundle.zip"
    subprocess.run(["zip", "-r", str(bundle), "lean/gated/Einstein"], check=True)
    if sign:
        # Simple GPG signing – replace with your production signing method.
        subprocess.run(["gpg", "--output", f"{bundle}.sig", "--detach-sig", str(bundle)], check=True)
        print(f"Signed bundle created at {bundle}.sig")
    print(f"Bundle created at {bundle}")

def main():
    parser = argparse.ArgumentParser(description="Einstein gated build helper")
    parser.add_argument("--check-hook", action="store_true", help="Run pre‑receive hook validation")
    parser.add_argument("--build", action="store_true", help="Build the artifact bundle")
    parser.add_argument("--sign", action="store_true", help="Sign the bundle after building")
    args = parser.parse_args()

    if args.check_hook:
        check_hook()
    elif args.build:
        build_bundle(sign=args.sign)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
