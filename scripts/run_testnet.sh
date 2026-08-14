#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIME_DIR="$(dirname "$SCRIPT_DIR")/Prime"
SIDECAR_DIR="$PRIME_DIR/sidecar/state-anchor"

echo "=== PhaseMirror Testnet Bootstrap (ADR-PML-051/055/050) ==="

# 1. Prerequisites
command -v anvil >/dev/null 2>&1 || { echo >&2 "anvil not found. Install Foundry: curl -L https://foundry.paradigm.xyz | bash && foundryup"; exit 1; }
command -v forge >/dev/null 2>&1 || { echo >&2 "forge not found. Install Foundry: curl -L https://foundry.paradigm.xyz | bash && foundryup"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo >&2 "docker not found. Install Docker first."; exit 1; }
command -v cargo >/dev/null 2>&1 || { echo >&2 "cargo not found. Install Rust first."; exit 1; }
command -v node >/dev/null 2>&1 || { echo >&2 "node not found. Install Node.js >= 18 first."; exit 1; }

# 2. Start Anvil
echo "[1/6] Starting Anvil..."
pkill -f "anvil --port 8545" 2>/dev/null || true
anvil --port 8545 --chain-id 31337 --block-time 2 > "$PRIME_DIR/anvil.log" 2>&1 &
ANVIL_PID=$!
sleep 3

# 3. Deploy contracts
echo "[2/6] Deploying contracts..."
cd "$PRIME_DIR/contracts"
forge build --skip-dependencies

# Generate deploy script output (using forge script)
cat > /tmp/deploy_pqc.s.sol <<'EOF'
pragma solidity ^0.8.24;
import "script/DeployAnchor.s.sol";
contract DeployScriptRun is DeployScript {}
EOF

# Fallback: deploy via cast + pre-built bytecode if script fails.
echo "[deploy] Attempting forge script..."
if ! forge script /tmp/deploy_pqc.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast 2>/dev/null; then
  echo "[deploy] forge script failed; using cast + known bytecode fallback"
  # AnchorRegistry bytecode (compiled locally)
  ANCHOR_BYTES=$(forge inspect AnchorRegistry bytecode || true)
  if [ -z "$ANCHOR_BYTES" ] || [ "$ANCHOR_BYTES" = "0x" ]; then
    echo "[deploy] cannot obtain bytecode; please run forge build first"
    exit 1
  fi
  ANCHOR_ADDRESS=$(cast deploy --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 "$ANCHOR_BYTES" 2>/dev/null || true)
fi

# Resolve deployed address from cast
ANCHOR_ADDRESS=$(cast call --rpc-url http://127.0.0.1:8545 0x5FbDB2315678afecb367f032d93F642f64180aa3 "latestRoot()" 2>/dev/null | head -1 || true)
if [ -z "$ANCHOR_ADDRESS" ] || [ "$ANCHOR_ADDRESS" = "0x" ]; then
  # Last resort: hardcoded deployer-known address from anvil default
  ANCHOR_ADDRESS="0x5FbDB2315678afecb367f032d93F642f64180aa3"
fi
echo "[deploy] AnchorRegistry at $ANCHOR_ADDRESS"

# 4. Start NATS
echo "[3/6] Starting NATS..."
docker rm -f phase-mirror-nats 2>/dev/null || true
docker run -d --name phase-mirror-nats -p 4222:4222 nats:latest -js >/dev/null 2>&1 || true
sleep 2

# 5. Build Rust binary
echo "[4/6] Building batch_anchor + dilithium-signer..."
cd "$PRIME_DIR"
cargo build --release -p recursive-prover -p dilithium-signer

# 6. Configure sidecar
echo "[5/6] Configuring sidecar..."
cat > "$SIDECAR_DIR/.env" <<EOF
NATS_URL=nats://localhost:4222
RPC_URL=http://localhost:8545
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ANCHOR_REGISTRY_ADDRESS=$ANCHOR_ADDRESS
BATCH_ANCHOR_BIN=$PRIME_DIR/target/release/batch_anchor
DILITHIUM_ENABLED=true
DILITHIUM_SK_PATH=/tmp/dilithium_sk.bin
DILITHIUM_SIGNER_BIN=$PRIME_DIR/target/release/dilithium-signer
EOF

# Generate Dilithium keypair
"$PRIME_DIR/target/release/dilithium-signer" keygen \
  --sk-path /tmp/dilithium_sk.bin \
  --pk-path /tmp/dilithium_pk.bin

# Register Dilithium key on-chain (cast send)
echo "[6/6] Registering Dilithium key on-chain..."
cast send "$ANCHOR_ADDRESS" \
  "registerDilithiumKey(bytes)" \
  "$(cat /tmp/dilithium_pk.bin | xxd -p -c 10000)" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --timeout 30 2>/dev/null || echo "[warn] registerDilithiumKey failed (contract may not have the method yet)"

echo ""
echo "=== Bootstrap complete ==="
echo "Anvil PID: $ANVIL_PID"
echo "AnchorRegistry: $ANCHOR_ADDRESS"
echo "NATS: nats://localhost:4222"
echo "Sidecar .env: $SIDECAR_DIR/.env"
echo ""
echo "To run the sidecar:"
echo "  cd $SIDECAR_DIR && npm run build && npx ts-node index.ts"
echo ""
echo "To stop:"
echo "  kill $ANVIL_PID && docker rm -f phase-mirror-nats"
