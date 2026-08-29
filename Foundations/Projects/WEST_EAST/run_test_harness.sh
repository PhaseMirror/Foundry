#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "================================================================================"
echo "  PROJECT WEST_EAST (PIRTM/DRMM 2.0): 3-STAGE CONSTITUTIONAL VALIDATION HARNESS "
echo "================================================================================"
echo ""

echo ">>> [STAGE 1/3] Running Lean 4 Machine-Checked Formal Verification..."
cd "$DIR/lean"
lake build
lake exe we_test
echo ""

echo ">>> [STAGE 2/3] Running Rust Unit and Integration Test Suites..."
cd "$DIR/rust"
cargo test
echo ""

echo ">>> [STAGE 3/3] Running WEST_EAST Pilot Benchmark Daemon & Auditor..."
cargo run --bin we_daemon
echo ""

echo "================================================================================"
echo "  ALL WEST_EAST VERIFICATION GATES PASSED (100% PRODUCTION COHERENCE)           "
echo "================================================================================"
