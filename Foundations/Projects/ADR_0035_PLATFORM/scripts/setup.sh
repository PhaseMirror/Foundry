#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "  ADR-0035: GLOBAL RESEARCH PLATFORM SETUP ENVIRONMENT      "
echo "============================================================"

# Check toolchains
command -v lean >/dev/null 2>&1 || { echo "[!] Lean 4 not found. Please install elan."; exit 1; }
command -v lake >/dev/null 2>&1 || { echo "[!] Lake not found. Please install Lake."; exit 1; }

echo "[+] Toolchains detected:"
echo "    Lean: $(lean --version)"
echo "    Lake: $(lake --version)"

echo "[+] Building ADR-0035 formal package..."
lake build

echo "[+] Setup complete. Run ./scripts/verify_all.sh to execute verification."
