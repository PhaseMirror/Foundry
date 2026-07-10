#!/bin/bash
set -e

echo "Building PIRTM-Formal..."
lake build

# Check for sorry in all source files
if grep -r "sorry" src/ 2>/dev/null; then
    echo "ERROR: Found 'sorry' in source files. All proofs must be complete."
    exit 1
fi

# Check for mathlib imports
if grep -r "import Mathlib" src/ 2>/dev/null; then
    echo "ERROR: Found Mathlib import. Only core Init allowed."
    exit 1
fi

echo "All proofs verified. No sorry. Production grade."