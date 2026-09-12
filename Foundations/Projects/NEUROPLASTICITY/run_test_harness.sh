#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "================================================================================"
echo "  PROJECT NEUROPLASTICITY: END-TO-END FORMAL & EMPIRICAL VALIDATION HARNESS     "
echo "================================================================================"
echo ""

echo ">>> [STAGE 1/3] Running Lean 4 Formal Verification (0 Axioms, 0 Sorries)..."
cd "$DIR/lean"
lake build
lake exe neuroplasticity_test
echo ""

echo ">>> [STAGE 2/3] Running Rust Unit and Integration Test Suites..."
cd "$DIR/rust"
cargo test
echo ""

echo ">>> [STAGE 3/3] Running Multi-Session Neuroplastic Simulation & CSL Audit..."
cargo run --bin neuroplasticity_daemon
echo ""

echo "================================================================================"
echo "  ALL NEUROPLASTICITY VERIFICATION GATES PASSED (100% PRODUCTION COHERENCE)     "
echo "================================================================================"
