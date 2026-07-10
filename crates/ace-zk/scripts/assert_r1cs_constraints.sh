#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-5087}"
R1CS_PATH="${2:-build/ace.r1cs}"

if ! command -v snarkjs >/dev/null 2>&1; then
  echo "snarkjs not found on PATH" >&2
  exit 2
fi

if [[ ! -f "$R1CS_PATH" ]]; then
  echo "R1CS file not found: $R1CS_PATH" >&2
  exit 2
fi

ACTUAL=$(snarkjs r1cs info "$R1CS_PATH" 2>/dev/null | sed -n 's/.*# of Constraints: //p' | tr -d '[:space:]')

if [[ -z "$ACTUAL" ]]; then
  echo "Could not parse constraint count from $R1CS_PATH" >&2
  exit 2
fi

echo "constraints=$ACTUAL target=$TARGET"

if [[ "$ACTUAL" != "$TARGET" ]]; then
  echo "ASSERTION FAILED: constraint count drift detected" >&2
  exit 1
fi

echo "ASSERTION PASSED"
