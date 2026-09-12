#!/usr/bin/env bash
set -euo pipefail

# Resolve the path to the main Hebrew project (two levels up)
PROJECT_ROOT=$(realpath ../../Hebrew)

echo "=== Building Lean project ==="
pushd "$PROJECT_ROOT/lean" > /dev/null
# Ensure elan is on PATH (if not already)
if ! command -v lake &> /dev/null; then
  echo "Lake not found – installing elan…"
  curl -L https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | bash -s -- --default-toolchain stable
  export PATH="$HOME/.elan/bin:$PATH"
fi
lake build
popd > /dev/null

echo "=== Verifying Rust with Kani ==="
pushd "$PROJECT_ROOT/rust" > /dev/null
# Install Kani if missing
if ! command -v cargo-kani &> /dev/null; then
  cargo install kani --locked
fi
cargo kani
popd > /dev/null

echo "All checks passed!"
