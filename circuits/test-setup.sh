#!/bin/bash
# SPDX-License-Identifier: UNLICENSED
# Script to initialize circuit test infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/test"

echo "Setting up MTPI Circuit Test Infrastructure..."
echo "Test directory: ${TEST_DIR}"

# Create test directory structure
mkdir -p "${TEST_DIR}"
mkdir -p "${TEST_DIR}/.cache"
mkdir -p "${TEST_DIR}/logs"

echo "✓ Created test directory structure"
echo "✓ Test infrastructure ready"
echo ""
echo "Next steps:"
echo "  1. Run: pnpm run test:circuits"
echo "  2. Or run individual tests: node circuits/test/<circuit-name>.test.js"
