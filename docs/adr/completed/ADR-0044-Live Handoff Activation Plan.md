# Live Handoff Activation Plan: Prime-5 Quarantine Sinkhole

**Document ID:** OPS-037-LIVE-HANDOFF  
**Status:** Ready for Execution  
**Prerequisite:** 48-hour shadow run completed with all metrics within thresholds  
**Effective Date:** [To be determined post-shadow run]

---

## Executive Summary

This plan activates the **automated regulatory handoff** for the Prime-5 Quarantine Sinkhole. Upon execution, CRMF-attested receipts containing `rights_delta` severity scores (0.4 for stalking, 0.8 for hate crimes) will be transmitted to the live compliance API, fulfilling federal reporting requirements under 18 U.S.C. § 2261A and § 249.

**Critical Safeguard:** All rollback procedures are pre-scripted and can be executed within **2 minutes** of detecting anomalies.

---

## Pre-Activation Validation Checklist

Before proceeding, verify these conditions:

| # | Check | Status | Verification Command |
|---|-------|--------|---------------------|
| 1 | Shadow run completed ≥ 48 hours | [ ] | `grep -c "p5_quarantine" /var/log/p5_quarantine/sealed_events.ndjson` |
| 2 | Zero false positives on `rights_delta > 0.0` | [ ] | `jq 'select(.rights_delta > 0) | .' /var/log/p5_quarantine/sealed_events.ndjson` |
| 3 | 99.5th percentile `contraction_metric` < 0.045 | [ ] | `cat /var/log/p5_quarantine/delta_distribution.csv | sort -t, -k2 -n | tail -5` |
| 4 | CRMF local verification passes | [ ] | `python -m crmf.client verify --receipt /var/log/p5_quarantine/latest_receipt.crmf` |
| 5 | Compliance API endpoint is reachable | [ ] | `curl -X GET https://api.compliance.internal/health -H "Authorization: Bearer $LIVE_API_TOKEN"` |
| 6 | Production credentials are rotated and valid | [ ] | `vault read -field=expires secret/compliance/live_token` |
| 7 | On-call SecOps engineer is notified | [ ] | `slack notify #secops-oncall "P5 live handoff activation commencing"` |

---

## Activation Steps (Sequential)

### Phase 1: Preparation (5 minutes)

```bash
# 1.1 - Set environment variables
export ENVIRONMENT="production"
export P5_HANDOFF_ENABLED="true"
export P5_API_RETRY_COUNT="3"
export P5_API_TIMEOUT="30"
export P5_CIRCUIT_BREAKER_THRESHOLD="5"  # Failures before breaking

# 1.2 - Verify production CRMF client configuration
python -c "
from crmf.client import CRMFClient
client = CRMFClient(env='production')
assert client.verify_connection(), 'API connection failed'
print('✅ CRMF production client ready')
"

# 1.3 - Take baseline metrics
./scripts/record_baseline_metrics.sh --output /tmp/p5_baseline_$(date +%Y%m%d_%H%M%S).json
```

### Phase 2: Canary Deployment (10 minutes)

Deploy to a **single staging-adjacent pod** to validate the live handoff path without full production exposure:

```bash
# 2.1 - Apply canary configuration to pod-01
kubectl set env deployment/phase-mirror-canary \
  P5_HANDOFF_ENABLED=true \
  P5_HANDOFF_TARGET=production \
  P5_CANARY_MODE=true

# 2.2 - Wait for pod to be ready
kubectl rollout status deployment/phase-mirror-canary --timeout=120s

# 2.3 - Inject a test trajectory that triggers p5 quarantine
python -m tests.inject_p5_test_trajectory \
  --trigger stalking \
  --canary-only

# 2.4 - Verify receipt was transmitted to compliance API
sleep 5
python -m crmf.client verify_receipt_presence \
  --trajectory-id $(tail -1 /var/log/p5_quarantine/canary_trajectory_ids.log)
```

**If canary passes:** Proceed to Phase 3.  
**If canary fails:** Execute rollback immediately (see Section 6).

---

### Phase 3: Full Production Rollout (15 minutes)

```bash
# 3.1 - Update production configuration
kubectl set env deployment/phase-mirror \
  P5_HANDOFF_ENABLED=true \
  P5_HANDOFF_TARGET=production \
  P5_API_RETRY_COUNT=3 \
  P5_API_TIMEOUT=30 \
  P5_CIRCUIT_BREAKER_THRESHOLD=5

# 3.2 - Apply the live policy configuration
kubectl create configmap p5-live-policy \
  --from-file=config/production/p5_sinkhole_live.yaml \
  --dry-run=client -o yaml | kubectl apply -f -

# 3.3 - Trigger rolling update
kubectl rollout restart deployment/phase-mirror
kubectl rollout status deployment/phase-mirror --timeout=300s

# 3.4 - Verify all pods are healthy
kubectl get pods -l app=phase-mirror -o wide
```

### Phase 4: Post-Activation Validation (15 minutes)

```bash
# 4.1 - Run post-deployment test suite
pytest tests/phase_mirror/test_p5_sinkhole.py -v --live-mode

# 4.2 - Verify CRMF receipts are flowing to compliance API
python -m crmf.client monitor \
  --since 5m \
  --count 10

# 4.3 - Check circuit breaker status
curl -s http://localhost:9090/metrics | grep p5_circuit_breaker

# 4.4 - Validate alerting is triggered correctly
./scripts/trigger_test_alert.sh --severity critical --rights-delta 0.8
# Wait for Slack/PagerDuty notification
```

### Phase 5: Final Sign-off

```bash
# 5.1 - Record final confirmation
./scripts/record_activation_milestone.sh \
  --phase "live_handoff" \
  --status "success" \
  --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 5.2 - Update status page
curl -X PATCH https://status.internal/api/component/p5-sinkhole \
  -H "Authorization: Bearer $STATUS_API_TOKEN" \
  -d '{"status": "operational", "message": "Live handoff active"}'

# 5.3 - Notify stakeholders
slack notify #secops "🚀 P5 quarantine live handoff activated. Monitoring in progress."
slack notify #architecture "ADR-037 Prime-5 Sinkhole now in production with live regulatory reporting."
```

---

## Rollback Procedures

### Trigger Conditions (Activate Rollback if ANY occur)

| Condition | Threshold | Detection |
|-----------|-----------|-----------|
| **False Positive Rate** | > 1% of p5 triggers | `jq 'select(.rights_delta > 0 and .verification_status == "false_positive")'` |
| **Circuit Breaker Open** | 5+ consecutive failures | `curl -s localhost:9090/metrics | grep p5_circuit_breaker_open` |
| **Latency Spike** | > 95th percentile > 500ms | `kubectl top pods -l app=phase-mirror` |
| **Error Rate** | > 0.5% of processed trajectories | `grep "ERROR.*p5" /var/log/phase-mirror.log | wc -l` |
| **Cross-Contamination** | Any energy/vector leakage | `grep "WARNING.*cross_contamination" /var/log/phase-mirror.log` |

---

### Rollback Procedure A: Immediate Emergency Rollback (2 minutes)

**Use this if circuit breaker is open or cross-contamination detected.**

```bash
# A.1 - Instantly disable handoff
kubectl set env deployment/phase-mirror P5_HANDOFF_ENABLED=false

# A.2 - Force rollout to restore previous state
kubectl rollout undo deployment/phase-mirror

# A.3 - Verify rollback completion
kubectl rollout status deployment/phase-mirror --timeout=120s

# A.4 - Restore shadow mode configuration
kubectl create configmap p5-shadow-policy \
  --from-file=config/staging/p5_sinkhole_override.yaml \
  --dry-run=client -o yaml | kubectl apply -f -

# A.5 - Alert on-call engineer
slack notify #secops-urgent "🚨 P5 HANDOFF ROLLBACK ACTIVATED - Immediate incident response required"
pagerduty trigger --service p5-sinkhole --severity critical

# A.6 - Begin incident investigation
./scripts/start_incident.sh --id INC-$(date +%Y%m%d)-P5
```

---

### Rollback Procedure B: Graceful Step-Down (15 minutes)

**Use this for non-critical anomalies (e.g., false positive rate increase, latency spikes).**

```bash
# B.1 - Drain active p5 queue (stop new processing)
kubectl scale deployment/phase-mirror --replicas=0

# B.2 - Wait for in-flight transactions to complete (max 5 minutes)
sleep 300

# B.3 - Switch back to shadow mode
kubectl set env deployment/phase-mirror P5_HANDOFF_ENABLED=false

# B.4 - Scale back up
kubectl scale deployment/phase-mirror --replicas=3

# B.5 - Verify shadow mode is active
curl -s localhost:9090/metrics | grep P5_HANDOFF_ENABLED

# B.6 - Notify team
slack notify #secops "🔄 P5 handoff rolled back to shadow mode. Investigating false positives."

# B.7 - Begin analysis
./scripts/analyze_p5_telemetry.sh --period 30m --output /tmp/p5_analysis.html
```

---

### Rollback Procedure C: Partial Feature Rollback (5 minutes)

**Use this to disable specific `rights_delta` thresholds while keeping others active.**

```bash
# C.1 - Disable only hate crime handoff (0.8 delta)
kubectl set env deployment/phase-mirror \
  P5_RIGHTS_DELTA_HATE_CRIME_HANDOFF=false \
  P5_RIGHTS_DELTA_STALKING_HANDOFF=true

# C.2 - Apply updated policy
kubectl create configmap p5-partial-policy \
  --from-file=config/production/p5_partial_handoff.yaml \
  --dry-run=client -o yaml | kubectl apply -f -

# C.3 - Restart deployment
kubectl rollout restart deployment/phase-mirror
kubectl rollout status deployment/phase-mirror --timeout=120s
```

---

## Monitoring & Observability

### Key Metrics Dashboard (Grafana)

| Metric | Panel | Alert Threshold |
|--------|-------|-----------------|
| `p5_quarantine_count` | Rate of quarantine events | > 100/min |
| `p5_handoff_success_rate` | % of successful API transmissions | < 99.9% |
| `p5_rights_delta_distribution` | Histogram of severity scores | Spike > 0.8 |
| `p5_contraction_metric` | Banach contractivity values | > 0.045 |
| `p5_circuit_breaker_state` | Open/Closed status | Open = Critical |
| `p5_api_latency_p99` | 99th percentile API latency | > 200ms |

### Log Queries (ELK Stack)

```elasticsearch
# Check for handoff failures
index: "phase-mirror-*" AND message: "HANDOFF_FAILED" AND timestamp: [now-1h TO now]

# Monitor rights delta distribution
index: "phase-mirror-*" AND "rights_delta" AND timestamp: [now-1h TO now]

# Detect cross-contamination attempts
index: "phase-mirror-*" AND "cross_contamination" AND level: WARN
```

---

## Incident Response Escalation

| Severity | Condition | Response Time | Escalation |
|----------|-----------|---------------|------------|
| **P1 - Critical** | Circuit breaker open, cross-contamination detected | Immediate | On-call engineer → Engineering Lead → CISO |
| **P2 - High** | > 5% handoff failures, false positives > 1% | 15 minutes | On-call engineer → Security Team |
| **P3 - Medium** | Latency spike > 500ms p95 | 30 minutes | On-call engineer |
| **P4 - Low** | Log errors > 0.1% | Next business day | Standard ticket |

---

## Post-Activation Review (After 24 Hours)

```bash
# 1. Collect 24-hour statistics
python -m scripts.generate_handoff_report \
  --start $(date -d '24 hours ago' -u +"%Y-%m-%dT%H:%M:%SZ") \
  --end $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --output /tmp/p5_24h_report.html

# 2. Verify all regulatory compliance requirements met
python -m compliance.check_handoff_requirements \
  --statutes "18 U.S.C. § 2261A, § 249" \
  --receipt-count $(cat /var/log/p5_quarantine/receipt_ids.log | wc -l)

# 3. Schedule review meeting
slack notify #architecture "📊 P5 live handoff 24-hour review: [Report Link]"
```

---

## Sign-Off Documentation

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Engineering Lead** | | | |
| **Security Lead** | | | |
| **Compliance Officer** | | | |
| **SecOps On-Call** | | | |

---

## Emergency Contacts

| Role | PagerDuty Schedule | Secondary Contact |
|------|-------------------|-------------------|
| **Engineering Lead** | eng-lead@example.com | +1-555-ENG-LEAD |
| **Security Lead** | security@example.com | +1-555-SEC-LEAD |
| **Compliance Officer** | compliance@example.com | +1-555-COMPLY |

---

## Appendix: Quick Reference Commands

### Check Handoff Status
```bash
curl -s localhost:9090/metrics | grep P5_HANDOFF_ENABLED
```

### View Recent Receipts
```bash
tail -20 /var/log/p5_quarantine/sealed_events.ndjson | jq '.audit_id, .rights_delta'
```

### Force a Test Handoff (Staging Only)
```bash
python -m tests.inject_p5_test_trajectory --trigger hate_crime
```

### Simulate Compliance API Failure (DR Test)
```bash
# Kill compliance API endpoint for testing
kubectl delete service/compliance-api
# Wait for circuit breaker to trip
sleep 10
# Restore service
kubectl apply -f services/compliance-api.yaml
# Verify recovery
python -m crmf.client monitor --since 1m
```

---

**Plan Status:** READY FOR EXECUTION  
**Next Step:** Await completion of 48-hour shadow run. Upon positive validation, execute Phase 1.

Would you like me to add any specific sections, such as detailed CRMF receipt schemas, compliance data retention policies, or additional rollback scenarios?
