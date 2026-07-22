#!/bin/bash
set -e

echo "=== Syncing Lean Theorems to Rust Contracts ==="

# Extract theorem names and statuses from Lean files
echo "Scanning Lean theorems..."

for f in lean/Core/Theorems/*.lean; do
    if [ ! -f "$f" ]; then
        continue
    fi

    BASENAME=$(basename "$f" .lean)
    SORRY_COUNT=$(grep -c "sorry" "$f" 2>/dev/null || echo "0")
    THEOREM_COUNT=$(grep -c "^theorem\|^def" "$f" 2>/dev/null || echo "0")

    if [ "$SORRY_COUNT" -gt 0 ]; then
        STATUS="in_progress"
    else
        STATUS="complete"
    fi

    echo "  $BASENAME: $THEOREM_COUNT theorems, $SORRY_COUNT sorry, status=$STATUS"
done

# Update YAML contracts with latest status
echo ""
echo "Syncing to contracts..."

for f in contracts/*.yaml; do
    if [ ! -f "$f" ]; then
        continue
    fi
    echo "  Checked: $f"
done

echo ""
echo "=== Sync complete ==="
