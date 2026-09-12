#!/usr/bin/env bash
set -euo pipefail

# Load environment variables (Infleqtion credentials, service endpoints)
if [[ -f .env ]]; then
  source .env
else
  echo "[warning] .env file not found. Using defaults where possible."
fi

# Configuration (can be overridden by .env)
NATS_URL=${NATS_URL:-"nats://localhost:4222"}
CRMF_ENDPOINT=${CRMF_ENDPOINT:-"http://localhost:8080/crmf"}
ACE_ENDPOINT=${ACE_ENDPOINT:-"http://localhost:8081/ace"}
ARCHIVUM_ENDPOINT=${ARCHIVUM_ENDPOINT:-"http://localhost:8082/archivum"}
INFLEQTION_HOST=${INFLEQTION_HOST:-"infleqtion.local"}
CONCURRENT=${CONCURRENT:-10}
DURATION=${DURATION:-600} # seconds (10 minutes)

# Use a real filesystem directory for logs (no crmf:// URI)
LOG_DIR="$(pwd)/hardware_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

echo "[info] Starting hardware shadow trial: $CONCURRENT concurrent runs for $DURATION seconds"

run_sidecar() {
  local id=$1
  echo "[sidecar $id] Starting..." >> "$LOG_DIR/sidecar_${id}.log"
  # Simulate sidecar work
  sleep $((RANDOM % 5 + 1))
  echo "[sidecar $id] Completed successfully" >> "$LOG_DIR/sidecar_${id}.log"
}

# Launch sidecar processes
for i in $(seq 1 $CONCURRENT); do
  run_sidecar $i &
 done

# Wait for completion or timeout
START=$(date +%s)
while true; do
  sleep 5
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if ! jobs -r > /dev/null 2>&1; then
    echo "[info] All sidecar jobs finished before timeout"
    break
  fi
  if [[ $ELAPSED -ge $DURATION ]]; then
    echo "[info] Timeout reached ($DURATION seconds). Killing remaining jobs."
    kill $(jobs -p) 2>/dev/null || true
    # Wait for all sidecar processes to exit before proceeding to sealing
    wait
    break
  fi
done

# CRMF sealing
if command -v crmf >/dev/null 2>&1; then
  crmf seal --endpoint "$CRMF_ENDPOINT" --input "$LOG_DIR" --output "$LOG_DIR/sealed.tar.gz"
else
  echo "[warning] crmf not available, using tar fallback"
  tar -czf "$LOG_DIR/sealed.tar.gz" -C "$LOG_DIR" .
fi

# ACE integrity check
if command -v ace >/dev/null 2>&1; then
  ace verify --endpoint "$ACE_ENDPOINT" --artifact "$LOG_DIR/sealed.tar.gz"
else
  echo "[warning] ace not available, assuming success"
fi

# Archivum upload
if command -v archivum >/dev/null 2>&1; then
  archivum upload --endpoint "$ARCHIVUM_ENDPOINT" --file "$LOG_DIR/sealed.tar.gz" --metadata "trial=shadow"
else
  echo "[warning] archivum not available, copying locally"
  cp "$LOG_DIR/sealed.tar.gz" "$LOG_DIR/archivum_placeholder.tar.gz"
fi

echo "[info] Hardware shadow trial completed. Artifacts stored in $LOG_DIR"
