#!/usr/bin/env bash
set -e

# Verify the entire Phase Mirror Loop pipeline
# 1. Run Lean build and tests
cd /home/multiplicity/Multiplicity/PhaseMirror/Prime
lake build && lake test

# 2. Generate Rust valuation array
cd materia_commons
python3 generate_rust_vals.py

# 3. Run Kani bounded model checking (requires nightly + kani installed)
cargo kani --all-features

# 4. Run Rust test suite (including example resolvent scan)
cargo test --all

# 5. Build WASM artifact
cargo +nightly build --release --target wasm32-unknown-unknown

echo "Verification complete: all steps succeeded."
