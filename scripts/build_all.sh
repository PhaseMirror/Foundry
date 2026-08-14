#!/usr/bin/env bash

# build_all.sh – compile every Lean project under ./lean/projects
#
# Usage:
#   ./build_all.sh            # builds all projects in release mode
#   ./build_all.sh --debug    # builds in debug mode (no --release flag)
#   ./build_all.sh --skip-lint # skips lint/format checks
#
# The script iterates each sub‑directory that contains a `lakefile.lean`
# and runs `lake build` (or `lake build --release`).  The compiled
# artifacts (.olean, .c, etc.) are left in the same project directory –
# this is the default behavior of `lake`.

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
PROJECTS_DIR="$ROOT_DIR/lean/projects"

BUILD_MODE="--release"
SKIP_LINT=false

while (( "$#" )); do
  case "$1" in
    --debug)    BUILD_MODE=""; shift;;
    --skip-lint) SKIP_LINT=true; shift;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

if ! command -v lake >/dev/null 2>&1; then
  echo "Error: 'lake' (Lean build tool) is not installed or not in PATH."
  exit 1
fi

echo "Building Lean projects in $PROJECTS_DIR"

for dir in "$PROJECTS_DIR"/*/; do
  if [[ -f "$dir/lakefile.lean" ]]; then
    echo "\n=== Building $(basename "$dir") ==="
    pushd "$dir" > /dev/null
    if [ "$SKIP_LINT" = false ]; then
      echo "Running lake fmt..."
      lake fmt
      echo "Running lake lint..."
      lake lint
    fi
    echo "Running lake build $BUILD_MODE..."
    lake build $BUILD_MODE
    popd > /dev/null
  else
    echo "Skipping $(basename "$dir") – no lakefile.lean"
  fi
done

echo "\nAll projects processed."
