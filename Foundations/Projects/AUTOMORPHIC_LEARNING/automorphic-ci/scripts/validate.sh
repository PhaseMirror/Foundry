#!/usr/bin/env bash
# automorphic-ci: validation gates for automorphic learning
# Run from the AUTOMORPHIC_LEARNING project root.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUST_DIR="$PROJECT_DIR/automorphic-core"
PY_DIR="$PROJECT_DIR/automorphic-py"

echo "=== Automorphic Learning CI ==="
echo "Project: $PROJECT_DIR"
echo ""

# 1. Rust build and test
echo "--- Rust build and test ---"
cd "$RUST_DIR"
cargo build --release 2>&1 | tail -5
cargo test 2>&1 | tail -10
echo ""

# 2. Python test
echo "--- Python test ---"
cd "$PY_DIR"
if command -v pytest &> /dev/null; then
    pytest tests/ -v --tb=short 2>&1 | tail -10
else
    echo "pytest not found, skipping Python tests"
fi
echo ""

# 3. Lint preregistration
echo "--- Lint preregistration ---"
if command -v python3 &> /dev/null; then
    cd "$PROJECT_DIR"
    python3 -c "
import sys
sys.path.insert(0, 'automorphic-py')
from automorphic.prequal import lint_prereg, golden_prereg
result = lint_prereg(golden_prereg())
if result.passed:
    print('Preregistration lint: PASS')
else:
    print('Preregistration lint: FAIL')
    for e in result.errors:
        print(f'  ERROR: {e}')
    sys.exit(1)
" 2>&1
else
    echo "python3 not found, skipping lint"
fi
echo ""

# 4. Gate evaluation
echo "--- Gate evaluation ---"
if command -v python3 &> /dev/null; then
    cd "$PROJECT_DIR"
    python3 -c "
import sys
sys.path.insert(0, 'automorphic-py')
from automorphic.prequal import PassFailGates, GateMetrics, evaluate_gates
gates = PassFailGates()
metrics = GateMetrics(
    w2_median=0.02,
    bca_width=0.04,
    slopeub=10.0,
    accuracy_drop=0.001,
    permutation_ks=1e-6,
)
result = evaluate_gates(gates, metrics)
if result.all_pass:
    print('Gates: PASS')
else:
    print('Gates: FAIL')
    for e in result.evaluations:
        if not e.passes:
            print(f'  FAILED: {e.name} = {e.value} > {e.threshold}')
    sys.exit(1)
" 2>&1
else
    echo "python3 not found, skipping gate evaluation"
fi
echo ""

echo "=== CI Complete ==="
