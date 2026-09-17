#!/usr/bin/env bash
# check_lake_toolchain.sh — fail-closed preflight.
#
# Verifies that the `lake` binary resolved from PATH reports the same Lean
# version as the toolchain pinned in the cwd's `lean-toolchain`. Protects
# against PATH shadowing by standalone binaries (e.g. a manually installed
# ~/.local/bin/lake pinned to an older Lean).
#
# Usage: bash scripts/check_lake_toolchain.sh   (from packages/Foundry/)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIN_FILE="$ROOT/lean-toolchain"
if [[ ! -f "$PIN_FILE" ]]; then
  echo "check-toolchain: missing $PIN_FILE"
  exit 1
fi

PIN="$(tr -d '[:space:]' < "$PIN_FILE")"        # e.g. leanprover/lean4:v4.34.0-rc2
PIN_VER="${PIN##*:}"                            # e.g. v4.34.0-rc2
PIN_VER="${PIN_VER#v}"                          # e.g. 4.34.0-rc2

command -v lake >/dev/null 2>&1 || {
  echo "check-toolchain: 'lake' not found on PATH"
  exit 1
}

ACTUAL="$(lake --version 2>/dev/null)"          # "Lake version ... (Lean version 4.x.y-...)"
ACTUAL_VER="$(printf '%s' "$ACTUAL" | sed -n 's/.*Lean version \([^ )]*\).*/\1/p')"
if [[ -z "$ACTUAL_VER" ]]; then
  echo "check-toolchain: could not parse lake --version:"
  printf '%s\n' "$ACTUAL"
  exit 1
fi

if [[ "$ACTUAL_VER" != "$PIN_VER" ]]; then
  echo "check-toolchain: FAIL — lake reports Lean $ACTUAL_VER; lean-toolchain pins $PIN_VER"
  echo "check-toolchain: fix PATH shadowing (remove/rename stale binaries or prefix ~/.elan/bin)."
  exit 1
fi

echo "check-toolchain: OK — lake/lean $ACTUAL_VER matches lean-toolchain pin $PIN_VER"