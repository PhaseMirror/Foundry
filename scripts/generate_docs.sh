#!/usr/bin/env bash
set -e

# Generate Markdown documentation for Lean 4 Axioms
DOC_FILE="docs/RiemannZeta.md"
LEAN_FILE="lean/Core/f1_square/RiemannZeta.lean"

mkdir -p docs

echo "# Riemann Zeta Formal Axioms" > "$DOC_FILE"
echo "" >> "$DOC_FILE"
echo "This document is auto-generated from \`$LEAN_FILE\`." >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
echo "\`\`\`lean" >> "$DOC_FILE"

# Extract axioms from the Lean file
grep -E "^axiom " "$LEAN_FILE" >> "$DOC_FILE" || echo "-- No axioms found" >> "$DOC_FILE"

echo "\`\`\`" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"
echo "These axioms are currently used as placeholders for theorems that rely on analytic properties (Zero-Drift mandate)." >> "$DOC_FILE"

echo "Documentation generated at $DOC_FILE"
