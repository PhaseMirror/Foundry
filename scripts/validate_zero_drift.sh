#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "[SEDONA SPINE] Initializing Zero-Drift Invariant Gate"
echo "=================================================="

# Step 1: Verify Lean 4 Core
echo "==> Verifying Lean 4 Formalization..."
cd lean
lake build Core.OFA.OperatorFirstArithmetic
cd ..
echo "✔ Lean core verified successfully."

# Step 2: Build Rust Engine and WASM Target
echo "==> Building Rust Engine & WASM Bindings..."
cargo build --release
wasm-pack build crates/pirtm-engine --target nodejs --release
echo "✔ Rust & WASM build completed."

# Step 3: Run Invariant Integration Tests
echo "==> Executing Zero-Drift Test Suite..."
cargo test --test ofa_integration --release
echo "✔ All zero-drift invariants upheld. Pipeline cleared."
