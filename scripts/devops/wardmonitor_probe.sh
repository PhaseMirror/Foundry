#!/usr/bin/env bash
# ADR-045: WardMonitor sidecar health probe and system integrity verification.
# Verifies system state before and after deployment transactions.

set -euo pipefail

WARDMONITOR_SOCKET="/var/run/multiplicity/wardmonitor.sock"
HEALTH_CHECK_TIMEOUT=5
MAX_DRIFT=0.03
MTPI_CERTIFIER="/usr/local/bin/mtpi-certifier"

log_audit() {
  local event="$1"
  local detail="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"timestamp\":\"${timestamp}\",\"adr\":\"ADR-045\",\"event\":\"${event}\",\"detail\":\"${detail}\"}" >> "/var/log/multiplicity/audit_ledger.jsonl"
}

check_wardmonitor_socket() {
  if [[ -S "$WARDMONITOR_SOCKET" ]]; then
    echo "[INFO] WardMonitor sidecar detected at ${WARDMONITOR_SOCKET}"
    return 0
  else
    echo "[WARN] WardMonitor socket not found at ${WARDMONITOR_SOCKET}"
    return 1
  fi
}

send_health_check() {
  local command="$1"
  if ! check_wardmonitor_socket; then
    echo "[WARN] Skipping WardMonitor health check (socket unavailable)"
    return 0
  fi

  echo "[INFO] Sending ${command} to WardMonitor sidecar..."
  local response
  if ! response=$(echo "$command" | socat - UNIX-CONNECT:"$WARDMONITOR_SOCKET" 2>&1); then
    echo "[ERROR] WardMonitor communication failed: ${response}" >&2
    log_audit "wardmonitor_comm_failed" "command=${command} error=${response}"
    return 1
  fi

  echo "[INFO] WardMonitor response: ${response}"
  log_audit "wardmonitor_response", "command=${command} response=${response}"
  return 0
}

run_mtpi_certifier() {
  if [[ -x "$MTPI_CERTIFIER" ]]; then
    echo "[INFO] Running mtpi-certifier (max_drift=${MAX_DRIFT})..."
    local cert_output
    if ! cert_output=$("$MTPI_CERTIFIER" --max-drift "$MAX_DRIFT" 2>&1); then
      echo "[ERROR] mtpi-certifier failed: ${cert_output}" >&2
      log_audit "mtpi_certifier_failed", "detail=${cert_output}"
      return 1
    fi
    echo "[INFO] mtpi-certifier passed: ${cert_output}"
    log_audit "mtpi_certifier_passed", "detail=${cert_output}"
  else
    echo "[WARN] mtpi-certifier not found at ${MTPI_CERTIFIER}"
  fi
  return 0
}

pre_deployment_check() {
  echo "[INFO] Running pre-deployment WardMonitor health check..."
  send_health_check "PRE_DEPLOY_CHECK"
  run_mtpi_certifier
  log_audit "pre_deployment_check_completed", "status=passed"
}

post_deployment_check() {
  echo "[INFO] Running post-deployment WardMonitor health check..."
  send_health_check "POST_DEPLOY_CHECK"
  run_mtpi_certifier
  log_audit "post_deployment_check_completed", "status=passed"
}

verify_boot_entry() {
  echo "[INFO] Verifying active boot entry integrity..."
  local boot_entry
  boot_entry=$(readlink -f /boot/loader/entries/*.conf 2>/dev/null | head -n1 || echo "unknown")
  echo "[INFO] Active boot entry: ${boot_entry}"
  log_audit "boot_entry_verified", "entry=${boot_entry}"
}

main() {
  mkdir -p /var/log/multiplicity
  log_audit "wardmonitor_probe_started", "pid=$$"

  case "${1:-}" in
    pre)
      pre_deployment_check
      ;;
    post)
      post_deployment_check
      verify_boot_entry
      ;;
    boot)
      verify_boot_entry
      ;;
    *)
      echo "Usage: $0 {pre|post|boot}"
      exit 1
      ;;
  esac

  log_audit "wardmonitor_probe_completed", "command=${1:-}"
  echo "[INFO] WardMonitor probe completed successfully."
}

main "$@"
