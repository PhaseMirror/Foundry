# FeMoco 100-Concurrent Load Test Criteria

**Status:** LOCKED  
**Date:** 2026-08-05  
**Owner:** Ryan (scaling lead) + formal-methods reviewer  
**Supersedes:** —  

---

## Acceptance Gates (Non-Negotiable)

All gates must pass before the FeMoco-class QaaS concurrency hardening is declared production-ready.

| Gate | Metric | Threshold | Measurement Method |
|------|--------|-----------|-------------------|
| G1 | Concurrent requests sustained | N ≤ 100 | FPGA orchestrator load test |
| G2 | Qudits per request | q ≤ 69 | Config validation |
| G3 | Energy error | ε < 15.0 mHa | Kani harness + Python validator |
| G4 | Entropy | S ≤ 6.0 | HSEC admission gate |
| G5 | NarrativeAuditor drift | drift_score = 0.0 | E2E attestation record |
| G6 | ThermalWindow max temp | ≤ 15,000 mHa | FPGA telemetry |
| G7 | No-Mathlib compliance | 0 Mathlib imports | CI grep |
| G8 | Zero-sorry compliance | 0 sorry occurrences | CI grep |

---

## Test Protocol

### Phase 1: Unit Validation (Day 1–2)

```bash
# Python validator
python scripts/validate_concurrency.py

# Lean proof validation
lake build
lake test

# CI compliance
grep -r "import Mathlib" src/ADR/ || echo "PASS: No Mathlib"
grep -r "sorry" src/ADR/*.lean || echo "PASS: No sorry"
```

**Pass criteria:** All 11 ADR test harness cases pass.

### Phase 2: FPGA Multiplex Stress Test (Day 3–7)

Run 100 concurrent FeMoco-class requests against the FPGA orchestrator.

**Pass criteria:**
- All 100 requests complete without timeout
- Error < 15 mHa for every request
- Entropy ≤ 6.0 for every request
- ThermalWindow max temp ≤ 15,000 mHa
- Zero NarrativeAuditor drift across all requests

### Phase 3: Zero-Drift Attestation (Day 7)

Record attestation in `E2E_Attestation_Record` with:
- `attestation_id`: unique identifier
- `timestamp`: ISO-8601
- `drift_score`: 0.0
- `request_count`: 100
- `error_max_mha`: < 15.0
- `entropy_max`: ≤ 6.0
- `ci_green`: true
- `no_mathlib`: true
- `no_sorry`: true

---

## Lock Conditions

This criteria is **LOCKED**. Any change requires:
1. Formal-methods reviewer sign-off
2. Updated `ConcurrencyBound.is_valid` proof
3. Updated CI workflow with new gate
4. Revised `L0-CONCURRENCY` clause in `adr_007_femoco_concurrency.l0_clauses`

---

## References

- `scripts/validate_concurrency.py` — Python bound validator
- `src/ADR/Proofs.lean` — Formal Lean 4 proofs
- `contracts/sedona_spine.yaml` — Sedona Spine CONTRACT
- `.github/workflows/sedona_spine_ci.yml` — CI enforcement
