# FeMoco 100-Concurrent Load Test Criteria

**Status:** PROVISIONAL (GREENLIT contingent upon Layer-B Identity Materialization)  
**Date:** 2026-08-22  
**Owner:** Ryan (scaling lead) + formal-methods reviewer  
**Supersedes:** —  

---

## Acceptance Gates (Non-Negotiable)

All gates must pass before the FeMoco-class QaaS concurrency hardening is declared production-ready and elevated to full GREENLIT status.

| Gate | Metric | Threshold | Measurement Method | Gate Status |
|------|--------|-----------|-------------------|-------------|
| G1 | Concurrent requests sustained | N = 100 | FPGA orchestrator load test | Pending telemetry lock |
| G2 | Qudits per request | q ≤ 69 (FeMoco locked) | Config validation (no larger targets) | Enforced |
| G3 | Native d=16 allocation | ≥ 80% sessions | FPGA telemetry / QCFI multiplexor | Pending telemetry lock |
| G4 | Aggregate FPGA utilization | < 90% | Prometheus telemetry observer | Pending telemetry lock |
| G5 | Energy error | ε < 15.0 mHa (target ≤ 14.5) | Kani harness + Python validator | Verified |
| G6 | State Entropy H(ρ) | S ≤ 6.0 (target ≤ 5.9) | HSEC admission gate | Verified |
| G7 | NarrativeAuditor drift | drift_score = 0.0 | HSEC consensus checksum | Verified |
| G8 | ThermalWindow max temp | ≤ 15,000 mHa | FPGA telemetry | Verified |
| G9 | **Layer-B Code Identity (Hard Block)** | **Immutable Git tag + CID** | **Git release attestation + Content Hash** | **BLOCKING (Missing on disk)** |
| G10 | Audit & Retention Architecture | CRMF + ACE telemetry | 7-year Continuous Risk Mitigation log | Configured |
| G11 | No-Mathlib compliance | 0 Mathlib imports | CI grep | Verified |
| G12 | Zero-sorry compliance | 0 sorry occurrences | CI grep | Verified |

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

## Lock Conditions & Hard Boundaries
 
 This criteria is **LOCKED**. The operational boundaries are:
 1. **No New Molecular Scaling:** The 100-physical-qudit hard boundary strictly limits targets to FeMoco CAS(114,114) ($q=69$). Larger molecular targets approach the 100-physical-qudit wall and risk catastrophic entropy violations ($S > 6.0$).
 2. **No DAO Filing or Layer-D zkVM:** Layer-B code identity (immutable git tag + CID) must exist and be attested before any Layer-C circuit execution or Wyoming DAO filing.
 3. **Concurrency Hardening Only:** Optimization is restricted to FPGA multiplexing and load balancing across the 100 sessions.
 4. **Milestone Horizons:**
    - **7-day horizon:** Multiplex optimization (achieving $\ge 80\%$ native $d=16$, aggregate utilization $<90\%$, zero drift).
    - **30-day horizon:** Full throughput lock under formal invariant verification.
 5. Any change requires formal-methods reviewer sign-off, updated `ConcurrencyBound.is_valid` proof, and zero-sorry CI pass.
 
 ---
 
 ## References
 
 - `scripts/validate_concurrency.py` — Python bound validator
 - `src/ADR/Proofs.lean` — Formal Lean 4 proofs
 - `contracts/sedona_spine.yaml` — Sedona Spine CONTRACT
 - `.github/workflows/sedona_spine_ci.yml` — CI enforcement
