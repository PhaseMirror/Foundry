#!/usr/bin/env bash
# Build every artifact of the certified-graph-learning stack (ADR-0027).
#
# Produces:
#   - the Lean 4 certificate core (`lake build`)
#   - the Rust certificate-runtime crate (`cargo build` + `cargo test`)
#
# Kani verification is intentionally NOT here; it lives in verify.sh so
# that a quick edit-compile-test cycle stays fast.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEAN_DIR="$ROOT/lean"
RUST_DIR="$ROOT/rust"

echo "== Lean certificate core =="
(cd "$LEAN_DIR" && lake build)

echo "== Rust certificate-runtime =="
(cd "$RUST_DIR" && cargo build --workspace --all-targets && cargo test --workspace)

echo "build OK"