#!/usr/bin/env bash
# Foundations: Sorry Check Script
# Runs grep for `sorry` in all .lean files and fails if found.
# Usage: ./scripts/check_sorry.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Foundations Sorry Check ==="
echo "Scanning: $PROJECT_DIR/Foundations/"

SORRY_COUNT=0

while IFS= read -r file; do
    # Skip test files (they may import modules with sorry for documentation)
    if [[ "$file" == *"tests/"* ]]; then
        continue
    fi
    
    matches=$(grep -n "sorry" "$file" 2>/dev/null || true)
    if [ -n "$matches" ]; then
        echo "SORRY found in $file:"
        echo "$matches"
        SORRY_COUNT=$((SORRY_COUNT + 1))
    fi
done < <(find "$PROJECT_DIR/Foundations" -name "*.lean" -type f)

if [ "$SORRY_COUNT" -gt 0 ]; then
    echo ""
    echo "FAILED: Found sorry in $SORRY_COUNT file(s)"
    exit 1
else
    echo "PASSED: No sorry found in source files"
    exit 0
fi
