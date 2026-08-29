#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "================================================================================"
echo "  PROJECT ZETACELL: 3-STAGE CONSTITUTIONAL VALIDATION HARNESS                   "
echo "================================================================================"
echo ""

echo ">>> [STAGE 1/3] Running Lean 4 Machine-Checked Formal Verification..."
cd "$DIR/lean"
lake build
lake exe zeta_test
echo ""

echo ">>> [STAGE 2/3] Running Rust Unit and Integration Test Suites..."
cd "$DIR/rust"
cargo test
echo ""

echo ">>> [STAGE 3/3] Running ZETACELL Daemon & Comparative Ablation Suite..."
cargo run --bin zeta_daemon
echo ""

echo "================================================================================"
echo "  ALL ZETACELL VERIFICATION GATES PASSED (100% PRODUCTION COHERENCE)            "
echo "================================================================================"
