#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIME_DIR="$(dirname "$SCRIPT_DIR")/Prime"
SIDECAR_DIR="$PRIME_DIR/sidecar/state-anchor"
PASS=0
FAIL=0

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== PhaseMirror Testnet Verification ==="
echo ""

# 1. Anvil
echo "[Anvil]"
check "anvil process running" pgrep -f "anvil --port 8545"
check "RPC responds" curl -s -X POST --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' http://127.0.0.1:8545 | grep -q result

# 2. NATS
echo "[NATS]"
check "nats container running" docker ps --format '{{.Names}}' | grep -q phase-mirror-nats
check "nats port exposed" docker port phase-mirror-nats 4222/tcp | grep -q 0.0.0.0:4222
check "nats server info" nats server info --server nats://localhost:4222 >/dev/null 2>&1 || true

# 3. Contracts
echo "[Contracts]"
source "$SIDECAR_DIR/.env" 2>/dev/null || true
if [ -n "${ANCHOR_REGISTRY_ADDRESS:-}" ]; then
  check "anchor registry has code" cast code --rpc-url http://127.0.0.1:8545 "$ANCHOR_REGISTRY_ADDRESS" | grep -qv '0x'
  LATEST=$(cast call --rpc-url http://127.0.0.1:8545 "$ANCHOR_REGISTRY_ADDRESS" "latestRoot()" 2>/dev/null || echo "0x")
  if [ "$LATEST" != "0x" ] && [ "$LATEST" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    echo "  [INFO] latest anchor root: $LATEST"
  fi
else
  echo "  [WARN] ANCHOR_REGISTRY_ADDRESS not set; skipping contract checks"
fi

# 4. Rust binaries
echo "[Rust binaries]"
check "batch_anchor binary exists" test -x "$PRIME_DIR/target/release/batch_anchor"
check "dilithium-signer binary exists" test -x "$PRIME_DIR/target/release/dilithium-signer"

# 5. Sidecar env
echo "[Sidecar configuration]"
check ".env file exists" test -f "$SIDECAR_DIR/.env"
if [ -f "$SIDECAR_DIR/.env" ]; then
  check "DILITHIUM_ENABLED is set" grep -q 'DILITHIUM_ENABLED=' "$SIDECAR_DIR/.env"
  check "DILITHIUM_SK_PATH is set" grep -q 'DILITHIUM_SK_PATH=' "$SIDECAR_DIR/.env"
fi

# 6. Quick Dilithium round-trip
echo "[Dilithium round-trip]"
if [ -x "$PRIME_DIR/target/release/dilithium-signer" ] && [ -f /tmp/dilithium_sk.bin ] && [ -f /tmp/dilithium_pk.bin ]; then
  MSG="0x$(echo -n 'phase-mirror-verification' | sha256sum | cut -d' ' -f1)"
  SIG=$( "$PRIME_DIR/target/release/dilithium-signer" sign --sk-path /tmp/dilithium_sk.bin --msg-hex "$MSG" 2>/dev/null || true )
  if [ -n "$SIG" ]; then
    VERIFY=$( "$PRIME_DIR/target/release/dilithium-signer" verify --pk-path /tmp/dilithium_pk.bin --msg-hex "$MSG" --sig-hex "$SIG" 2>/dev/null || true )
    if [ "$VERIFY" = "Signature verified" ]; then
      echo "  [PASS] Dilithium sign/verify round-trip"
      PASS=$((PASS + 1))
    else
      echo "  [FAIL] Dilithium verification returned: $VERIFY"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  [FAIL] Dilithium signing produced no output"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  [WARN] Skipping round-trip (missing binary or keys)"
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
