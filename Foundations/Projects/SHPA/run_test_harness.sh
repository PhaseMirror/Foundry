#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "================================================================================"
echo "  PROJECT SHPA: 3-STAGE STATELESS PRIME ATTESTATION VALIDATION HARNESS          "
echo "================================================================================"
echo ""

echo ">>> [STAGE 1/3] Running Lean 4 Machine-Checked Formal Verification..."
cd "$DIR/lean"
lake build
lake exe shpa_test
echo ""

echo ">>> [STAGE 2/3] Running Rust Unit and Integration Test Suites..."
cd "$DIR/rust"
cargo test
echo ""

echo ">>> [STAGE 3/3] Running SHPA Attestation Benchmark & Gap Auditor Daemon..."
cargo run --bin shpa_daemon
echo ""

echo "================================================================================"
echo "  ALL SHPA VERIFICATION GATES PASSED (100% PRODUCTION COHERENCE)                "
echo "================================================================================"
