#!/usr/bin/env bash
# ADR-045: Automated Recursive DevOps for Multiplicity on openSUSE Tumbleweed
# Transactional OS State via transactional-update, Btrfs & Snapper Integration.
# CRMF/WORM audit ledger with LawfulRecursionHash verification.

set -euo pipefail

PRE_SNAPSHOT=""
POST_SNAPSHOT=""
ROLLBACK_ON_FAILURE=true
DEPLOY_CMD=""
AUDIT_LOG="/var/log/multiplicity/audit_ledger.jsonl"
CRMF_LEDGER="/var/log/multiplicity/crmf_worm.jsonl"
WARDMONITOR_SOCKET="/var/run/multiplicity/wardmonitor.sock"
MTPI_CERTIFIER="/usr/local/bin/mtpi-certifier"
MAX_DRIFT=0.03
LAWFUL_RECURSION_HASH=""

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] -- <deployment_command>

Options:
  --no-rollback       Disable automatic rollback on failure
  --pre NAME          Pre-snapshot name (default: adr-045-pre-<timestamp>)
  --post NAME         Post-snapshot name (default: adr-045-post-<timestamp>)
  --audit PATH        Audit log path (default: /var/log/multiplicity/audit_ledger.jsonl)
  --crmf PATH         CRMF WORM ledger path (default: /var/log/multiplicity/crmf_worm.jsonl)
  --hash HASH         LawfulRecursionHash for this deployment epoch
  --max-drift FLOAT   Maximum allowed manifold drift (default: 0.03)

Example:
  $0 --hash abc123 -- transactional-update pkg install zypper
EOF
  exit 1
}

log_audit() {
  local event="$1"
  local detail="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"timestamp\":\"${timestamp}\",\"adr\":\"ADR-045\",\"event\":\"${event}\",\"detail\":\"${detail}\"}" >> "$AUDIT_LOG"
}

log_crmf() {
  local event="$1"
  local detail="$2"
  local hash="$3"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"timestamp\":\"${timestamp}\",\"adr\":\"ADR-045\",\"lawful_recursion_hash\":\"${hash}\",\"event\":\"${event}\",\"detail\":\"${detail}\"}" >> "$CRMF_LEDGER"
}

verify_wardmonitor() {
  if [[ -S "$WARDMONITOR_SOCKET" ]]; then
    echo "[INFO] WardMonitor sidecar detected at ${WARDMONITOR_SOCKET}"
    if ! echo "HEALTH_CHECK" | socat - UNIX-CONNECT:"$WARDMONITOR_SOCKET" > /dev/null 2>&1; then
      echo "[ERROR] WardMonitor health check failed" >&2
      log_audit "wardmonitor_check_failed" "socket=${WARDMONITOR_SOCKET}"
      return 1
    fi
    echo "[INFO] WardMonitor health check passed."
  else
    echo "[WARN] WardMonitor socket not found at ${WARDMONITOR_SOCKET}; proceeding without sidecar verification."
  fi
  return 0
}

verify_mtpi_certifier() {
  if [[ -x "$MTPI_CERTIFIER" ]]; then
    echo "[INFO] Running mtpi-certifier validation..."
    local cert_output
    if ! cert_output=$("$MTPI_CERTIFIER" --max-drift "$MAX_DRIFT" 2>&1); then
      echo "[ERROR] mtpi-certifier validation failed: ${cert_output}" >&2
      log_audit "mtpi_certifier_failed" "detail=${cert_output}"
      return 1
    fi
    echo "[INFO] mtpi-certifier validation passed."
  else
    echo "[WARN] mtpi-certifier not found at ${MTPI_CERTIFIER}; skipping manifold drift check."
  fi
  return 0
}

verify_lawful_recursion_hash() {
  local hash="$1"
  if [[ -z "$hash" ]]; then
    echo "[WARN] No LawfulRecursionHash provided; proceeding without cryptographic epoch verification."
    return 0
  fi
  echo "[INFO] Verifying LawfulRecursionHash: ${hash}"
  if ! echo "$hash" | sha256sum -c --status /dev/stdin 2>/dev/null; then
    echo "[ERROR] LawfulRecursionHash verification failed for: ${hash}" >&2
    log_audit "lawful_recursion_hash_failed" "hash=${hash}"
    return 1
  fi
  echo "[INFO] LawfulRecursionHash verified."
  return 0
}

create_pre_snapshot() {
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  PRE_SNAPSHOT="${PRE_SNAPSHOT:-adr-045-pre-${ts}}"
  echo "[INFO] Creating pre-deployment Snapper snapshot: ${PRE_SNAPSHOT}"
  if ! snapper create --type pre --print-number --description "${PRE_SNAPSHOT}" > /tmp/snapper_pre_num 2>&1; then
    echo "[ERROR] Failed to create pre-snapshot" >&2
    log_audit "snapshot_create_failed" "pre=${PRE_SNAPSHOT}"
    exit 1
  fi
  local num
  num=$(cat /tmp/snapper_pre_num)
  PRE_SNAPSHOT="${num}"
  log_audit "snapshot_created" "type=pre number=${num} description=${PRE_SNAPSHOT}"
  echo "[INFO] Pre-snapshot #${num} created."
}

create_post_snapshot() {
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  POST_SNAPSHOT="${POST_SNAPSHOT:-adr-045-post-${ts}}"
  echo "[INFO] Creating post-deployment Snapper snapshot: ${POST_SNAPSHOT}"
  if ! snapper create --type post --pre-number "${PRE_SNAPSHOT}" --print-number --description "${POST_SNAPSHOT}" > /tmp/snapper_post_num 2>&1; then
    echo "[ERROR] Failed to create post-snapshot" >&2
    log_audit "snapshot_create_failed" "post=${POST_SNAPSHOT} pre=${PRE_SNAPSHOT}"
    exit 1
  fi
  local num
  num=$(cat /tmp/snapper_post_num)
  POST_SNAPSHOT="${num}"
  log_audit "snapshot_created" "type=post number=${num} pre=${PRE_SNAPSHOT} description=${POST_SNAPSHOT}"
  echo "[INFO] Post-snapshot #${num} created."
}

execute_transactional_update() {
  local cmd="$1"
  echo "[INFO] Executing transactional-update: ${cmd}"
  if ! transactional-update "${cmd}" 2>&1; then
    echo "[ERROR] transactional-update failed" >&2
    log_audit "transactional_update_failed" "cmd=${cmd}"
    return 1
  fi
  echo "[INFO] transactional-update succeeded."
  return 0
}

rollback() {
  echo "[WARN] Rolling back to pre-deployment snapshot #${PRE_SNAPSHOT}..."
  if ! snapper rollback "${PRE_SNAPSHOT}" 2>&1; then
    echo "[CRITICAL] Manual rollback required: snapper rollback ${PRE_SNAPSHOT}" >&2
    log_audit "rollback_failed" "pre=${PRE_SNAPSHOT}"
    log_crmf "rollback_failed" "pre=${PRE_SNAPSHOT}" "$LAWFUL_RECURSION_HASH"
    exit 2
  fi
  log_audit "rollback_succeeded" "pre=${PRE_SNAPSHOT}"
  log_crmf "rollback_succeeded" "pre=${PRE_SNAPSHOT}" "$LAWFUL_RECURSION_HASH"
  echo "[INFO] Rollback completed."
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-rollback) ROLLBACK_ON_FAILURE=false; shift ;;
    --pre) PRE_SNAPSHOT="$2"; shift 2 ;;
    --post) POST_SNAPSHOT="$2"; shift 2 ;;
    --audit) AUDIT_LOG="$2"; shift 2 ;;
    --crmf) CRMF_LEDGER="$2"; shift 2 ;;
    --hash) LAWFUL_RECURSION_HASH="$2"; shift 2 ;;
    --max-drift) MAX_DRIFT="$2"; shift 2 ;;
    --) shift; DEPLOY_CMD="$*"; break ;;
    *) usage ;;
  esac
done

if [[ -z "${DEPLOY_CMD}" ]]; then
  usage
fi

mkdir -p "$(dirname "${AUDIT_LOG}")"
mkdir -p "$(dirname "${CRMF_LEDGER}")"

log_audit "transaction_start" "cmd=${DEPLOY_CMD} hash=${LAWFUL_RECURSION_HASH}"
log_crmf "transaction_start" "cmd=${DEPLOY_CMD}" "$LAWFUL_RECURSION_HASH"

# Pre-deployment verification gates
verify_lawful_recursion_hash "$LAWFUL_RECURSION_HASH"
verify_wardmonitor
verify_mtpi_certifier

create_pre_snapshot

echo "[INFO] Executing deployment command: ${DEPLOY_CMD}"
if execute_transactional_update "${DEPLOY_CMD}"; then
  echo "[INFO] Deployment command succeeded."
  create_post_snapshot
  log_audit "transaction_succeeded" "pre=${PRE_SNAPSHOT} post=${POST_SNAPSHOT} hash=${LAWFUL_RECURSION_HASH}"
  log_crmf "transaction_succeeded" "pre=${PRE_SNAPSHOT} post=${POST_SNAPSHOT}" "$LAWFUL_RECURSION_HASH"
  exit 0
else
  echo "[ERROR] Deployment command failed" >&2
  log_audit "transaction_failed" "pre=${PRE_SNAPSHOT} cmd=${DEPLOY_CMD} hash=${LAWFUL_RECURSION_HASH}"
  log_crmf "transaction_failed" "pre=${PRE_SNAPSHOT} cmd=${DEPLOY_CMD}" "$LAWFUL_RECURSION_HASH"
  if [[ "${ROLLBACK_ON_FAILURE}" == "true" ]]; then
    rollback
    exit 2
  else
    echo "[WARN] Automatic rollback disabled. Manual intervention required."
    exit 1
  fi
fi
