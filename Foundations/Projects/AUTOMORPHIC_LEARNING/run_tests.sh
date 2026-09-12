#!/usr/bin/env bash
# Run all tests for automorphic learning
set -euo pipefail

echo "=== Automorphic Learning Test Suite ==="
echo ""

# 1. Python tests
echo "--- Python tests ---"
cd "$(dirname "$0")/automorphic-py"
if command -v pytest &> /dev/null; then
    pytest tests/ -v --tb=short 2>&1
else
    echo "pytest not found, installing..."
    pip install pytest pytest-cov
    pytest tests/ -v --tb=short 2>&1
fi
echo ""

# 2. Kani harnesses (if available)
echo "--- Kani harnesses ---"
if command -v kani &> /dev/null; then
    cd "$(dirname "$0")/automorphic-core"
    for harness in kani/*.rs; do
        echo "Running $harness..."
        kani "$harness" 2>&1 || echo "Kani harness failed: $harness"
    done
else
    echo "kani not found, skipping harness verification"
fi
echo ""

# 3. Rust tests (if cargo available)
echo "--- Rust tests ---"
if command -v cargo &> /dev/null; then
    cd "$(dirname "$0")/automorphic-core"
    cargo test 2>&1 | tail -20
else
    echo "cargo not found, skipping Rust tests"
fi
echo ""

echo "=== Test Suite Complete ==="
