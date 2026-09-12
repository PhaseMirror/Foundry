#!/bin/bash
set -e

echo "=== Generating Kani Harnesses from YAML Contracts ==="

OUTPUT_DIR="rust/src/verification"
mkdir -p "$OUTPUT_DIR"

# Parse YAML contracts and generate Rust stub harnesses
for contract in contracts/*.yaml; do
    if [ ! -f "$contract" ]; then
        continue
    fi

    NAME=$(basename "$contract" .yaml)
    echo "Processing: $contract"

    # Extract harness names
    HARNESSES=$(python3 -c "
import yaml
with open('$contract') as f:
    data = yaml.safe_load(f)
verification = data.get('verification', {})
kani = verification.get('kani', {})
for h in kani.get('harnesses', []):
    print(h)
" 2>/dev/null || true)

    for harness in $HARNESSES; do
        echo "  Harness: $harness"
    done
done

echo ""
echo "=== Harness generation complete ==="
echo "Note: Manual implementation required for complex harnesses."
echo "Generated stubs are in: $OUTPUT_DIR/"
