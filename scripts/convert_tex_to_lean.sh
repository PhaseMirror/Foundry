#!/usr/bin/env bash

# convert_tex_to_lean.sh – run from repository root
# Finds all .tex files and creates a corresponding .lean file with the same base name.
# The .lean file contains the original LaTeX content as comments and a placeholder theorem.

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

log_success() { echo "[SUCCESS] $1"; }
log_failure() { echo "[FAILURE] $1"; }

find "$ROOT_DIR" -type f -name "*.tex" | while read -r tex_path; do
  dir=$(dirname "$tex_path")
  base=$(basename "$tex_path" .tex)
  lean_path="$dir/$base.lean"

  if [[ -f "$lean_path" ]]; then
    log_failure "$lean_path already exists, skipping"
    continue
  fi

  echo "-- Converted from $tex_path" > "$lean_path"
  while IFS= read -r line; do
    echo "-- $line" >> "$lean_path"
  done < "$tex_path"

  echo "\n-- Placeholder theorem to ensure the file compiles" >> "$lean_path"
  echo "theorem placeholder_${base} : True := trivial" >> "$lean_path"

  log_success "Converted $tex_path to $lean_path"
done

echo "All .tex files processed."
