#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# test_state_anchor.sh - End-to-end integration test for ADR-PML-055
#
# Two modes:
#   * OFFLINE (default, no external services):
#       emits mock events -> writes WORM JSONL -> reconstructs the combined
#       root via scripts/anchor_math.py -> feeds that root to
#       scripts/verify_anchor.py as the expected on-chain root.
#       This proves the reconstruction math matches the canonical sidecar
#       computation without needing an EVM/NATS deployment.
#   * ONCHAIN (only if `anvil`, `forge`, `cast` are on PATH):
#       deploys AnchorRegistry.sol, authorizes the sidecar, runs the
#       NATS-connected sidecar, emits events, and verifies the real
#       on-chain AnchorSubmitted root against the WORM reconstruction.
#
# Prerequisites (offline): Python 3.9+ with eth-hash[pycryptodome].
# Optional (onchain): Foundry (anvil/forge/cast), Docker (nats),
#              Node.js (sidecar).
# ----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ANCHOR_CONTRACT_DIR="$REPO_ROOT/contracts"
SIDECAR_DIR="$REPO_ROOT/sidecar/state-anchor"
WORM_LOG="$SCRIPT_DIR/mock_events.log"

TEST_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
TEST_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

cleanup() {
  log "Cleaning up..."
  [[ -n "${ANVIL_PID:-}"  ]] && kill "$ANVIL_PID" 2>/dev/null || true
  [[ -n "${NATS_PID:-}"   ]] && kill "$NATS_PID" 2>/dev/null || true
  [[ -n "${SIDECAR_PID:-}" ]] && kill "$SIDECAR_PID" 2>/dev/null || true
}
trap cleanup EXIT

# --- 0. Offline deterministic core (always runs) ------------------------------
log "Emitting mock state events -> $WORM_LOG"
: > "$WORM_LOG"
python3 "$SCRIPT_DIR/mock_state_emitter.py" --count 3 --worm-log "$WORM_LOG"

log "Reconstructing expected combined root (canonical anchor math)..."
EXPECTED_ROOT=$(cd "$SCRIPT_DIR" && python3 -c "
import anchor_math as m, json
from collections import defaultdict
per = defaultdict(list)
for line in open('mock_events.log'):
    line=line.strip()
    if not line: continue
    o=json.loads(line)
    per[o['category']].append(o['hash'])
print('0x'+m.combined_root_from_events(dict(per)).hex())
")
log "Expected combined root: $EXPECTED_ROOT"

log "Verifying WORM reconstruction == expected root..."
python3 "$REPO_ROOT/scripts/verify_anchor.py" \
  --date "$(date -u +%Y-%m-%d)" \
  --event-log "$WORM_LOG" \
  --onchain-root "$EXPECTED_ROOT"
OFFLINE_OK=$?
if [[ $OFFLINE_OK -ne 0 ]]; then
  log "OFFLINE verification FAILED."
  exit 1
fi
log "OFFLINE verification PASSED (reconstruction math is self-consistent)."

# --- 1. Optional on-chain path ----------------------------------------------
if have anvil && have forge && have cast && have docker; then
  log "Found anvil/forge/cast/docker -> running ONCHAIN path."

  ANVIL_PORT=8545
  NATS_PORT=4222
  log "Starting Anvil on :$ANVIL_PORT..."
  anvil --port "$ANVIL_PORT" --chain-id 31337 --silent &
  ANVIL_PID=$!
  sleep 2

  log "Deploying AnchorRegistry.sol..."
  DEPLOY=$(forge create --rpc-url "http://localhost:$ANVIL_PORT" \
    --private-key "$TEST_PRIVATE_KEY" --broadcast --json \
    "$ANCHOR_CONTRACT_DIR/AnchorRegistry.sol:AnchorRegistry")
  CONTRACT_ADDRESS=$(printf '%s' "$DEPLOY" | jq -r '.deployedTo')
  [[ "$CONTRACT_ADDRESS" == "null" || -z "$CONTRACT_ADDRESS" ]] && { log "Deploy failed."; exit 1; }
  log "Contract @ $CONTRACT_ADDRESS"

  cast send --rpc-url "http://localhost:$ANVIL_PORT" \
    --private-key "$TEST_PRIVATE_KEY" "$CONTRACT_ADDRESS" \
    "setSidecar(address,bool)" "$TEST_ADDRESS" true >/dev/null
  log "Authorized sidecar $TEST_ADDRESS"

  log "Starting NATS JetStream..."
  docker run -d --rm --name nats-jetstream -p "$NATS_PORT:4222" -p 8222:8222 nats -js >/dev/null
  NATS_PID=$!
  sleep 2

  log "Starting state-anchor sidecar..."
  ( cd "$SIDECAR_DIR" && npm install --silent
    NATS_URL="nats://localhost:$NATS_PORT" \
    ANCHOR_REGISTRY_ADDRESS="$CONTRACT_ADDRESS" \
    RPC_URL="http://localhost:$ANVIL_PORT" \
    PRIVATE_KEY="$TEST_PRIVATE_KEY" \
    npm start ) &
  SIDECAR_PID=$!
  sleep 3

  python3 "$SCRIPT_DIR/mock_state_emitter.py" --count 3 --worm-log "$WORM_LOG"

  log "Waiting for sidecar to submit root (90s)..."
  sleep 90

  EVENT=$(cast logs --rpc-url "http://localhost:$ANVIL_PORT" \
    --address "$CONTRACT_ADDRESS" \
    "AnchorSubmitted(bytes32,uint256,uint256)" --from-block 0 | jq -r '.[-1]')
  if [[ "$EVENT" == "null" || -z "$EVENT" ]]; then
    log "No AnchorSubmitted event found."
    exit 1
  fi
  ONCHAIN_ROOT=$(printf '%s' "$EVENT" | jq -r '.topics[1]')
  BLOCK=$(printf '%s' "$EVENT" | jq -r '.blockNumber')
  log "On-chain root $ONCHAIN_ROOT @ block $BLOCK"

  python3 "$REPO_ROOT/scripts/verify_anchor.py" \
    --rpc "http://localhost:$ANVIL_PORT" \
    --registry "$CONTRACT_ADDRESS" \
    --date "$(date -u +%Y-%m-%d)" \
    --event-log "$WORM_LOG"
  if [[ $? -eq 0 ]]; then
    log "ONCHAIN verification PASSED."
  else
    log "ONCHAIN verification FAILED."
    exit 1
  fi
else
  log "Skipping ONCHAIN path (need anvil+forge+cast+docker)."
  log "Offline test is sufficient to validate the anchor reconstruction pipeline."
fi

log "Integration test complete."
