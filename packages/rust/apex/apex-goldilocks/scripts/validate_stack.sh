#!/usr/bin/env bash
set -euo pipefail

# Apex-Goldilocks Coherence & Invariant Validator
# Purpose: Ensures the stack meets the Sedona Spine mandate (no floats in L0)
# and satisfies the PIRTM-lang Phase A-C requirements.

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛡️  Apex-Goldilocks Stack Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. L0 Invariant: Zero Float Policy
echo -e "\n[PHASE 1] Static Analysis: L0 Float Leakage Check..."
# We check core crates for any direct f32/f64 usage.
# Exclude build.rs and generated artifacts.
if grep -rnE "f32|f64" crates/ | grep -v "build.rs" | grep -v ".json" | grep -v "hologram-app" | grep -v "holoapp-cli" | grep -q ".rs"; then
    echo "❌ CRITICAL: Float leakage detected in L0 core crates!"
    grep -rnE "f32|f64" crates/ | grep -v "build.rs" | grep -v ".json" | grep -v "hologram-app" | grep -v "holoapp-cli" | grep ".rs"
    exit 1
else
    echo "✅ L0 Float Invariant Satisfied."
fi

# 2. Workspace Build & Test
echo -e "\n[PHASE 2] Workspace Integrity: Build & Unit Tests..."
cargo test --workspace

# 3. Functional Audit: Boundary Lattice
echo -e "\n[PHASE 3] Combinatorial Audit: 12,288 Invariants..."
cargo run -q -p apex-goldilocks-cli -- audit-lattice

# 4. Phase C Verification: ACE Stability
echo -e "\n[PHASE 4] Phase C: ACE Stability Invariant Verification..."
# Verify a stable set (Total Norm 0.8 < 1.0 - GovC 0.05)
cargo run -q -p apex-goldilocks-cli -- verify-stability --total-norm 800000 --gov-c 50000

# 5. Scientific Experiment Runner
echo -e "\n[PHASE 5] Generating Scientific Validation Report..."
python3 scripts/run_experiment.py

echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 STACK VALIDATION SUCCESSFUL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
