#!/usr/bin/env bash
#
# run-folder-loop.sh — Automate the PhaseMirror Folder-Loop (ADR-0001) on a project.
#
# Builds (if needed) the `phasemirror-folder-loop` binary and runs it over a
# configurable input folder, writing loop_report.{json,md} to a configurable
# output folder. Defaults to scanning the entire repository (respecting the
# same skip rules as the engine: .git, target, node_modules, .lake).
#
# Usage:
#   scripts/run-folder-loop.sh [--input DIR] [--output DIR] [--iterations N] [--rebuild] [--quiet]
#
# Exit codes mirror the binary:
#   0  success (no entry errors)
#   1  loop/write failure or at least one entry errored
#   2  misconfiguration (missing/unreadable input, unwritable output)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CRATE_DIR="$REPO_ROOT/phase-mirror-cli/phasemirror-folder-loop"
BIN="$CRATE_DIR/target/release/phasemirror-folder-loop"

INPUT="$REPO_ROOT"
OUTPUT="$REPO_ROOT/reports/folder-loop"
ITERATIONS=1
REBUILD=0
QUIET=0

usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)      INPUT="$2"; shift 2 ;;
    --output)     OUTPUT="$2"; shift 2 ;;
    --iterations) ITERATIONS="$2"; shift 2 ;;
    --rebuild)    REBUILD=1; shift ;;
    --quiet)      QUIET=1; shift ;;
    -h|--help)    usage ;;
    *) echo >&2 "Unknown argument: $1"; usage ;;
  esac
done

# 1. Prerequisites
command -v cargo >/dev/null 2>&1 || { echo >&2 "cargo not found. Install Rust first."; exit 2; }

# 2. Build the binary (release) unless it exists and --rebuild was not given
if [[ "$REBUILD" -eq 1 || ! -x "$BIN" ]]; then
  echo "==> Building phasemirror-folder-loop (release)..."
  (cd "$CRATE_DIR" && cargo build --release)
fi

# 3. Ensure output folder exists
mkdir -p "$OUTPUT"

# 4. Run the loop
echo "==> Running folder-loop over: $INPUT"
echo "==> Report output: $OUTPUT"
set +e
"$BIN" --input "$INPUT" --output "$OUTPUT" --iterations "$ITERATIONS"
RC=$?
set -e

if [[ "$QUIET" -eq 0 ]]; then
  echo "==> Artifacts:"
  ls -1 "$OUTPUT"/loop_report.* 2>/dev/null || true
fi

exit "$RC"
