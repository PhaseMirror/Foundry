# Production Mode Lock

**Status:** LOCKED  
**Date:** 2026-08-05  
**Owner:** Ryan (scaling lead) + formal-methods reviewer  

---

## Decision

Production concurrency hardening of FeMoco-class QaaS is the **single prioritized workstream** until the 100-request load-test attestation passes.

Universal Completion (UC) category definition is **deferred** until after load-test attestation. Any UC definition must:
1. Compile under existing no-Mathlib / no-sorry Lake rules
2. Explicitly cite the free-monoid initiality already present in Operator-First Arithmetic
3. Be governed by a new ADR that supersedes ADR-007

---

## Bound Constraints (Immutable Until Attestation)

| Parameter | Bound | Source |
|-----------|-------|--------|
| N (concurrent requests) | ≤ 100 | FPGA orchestrator config |
| q (qudits per request) | ≤ 69 | HSEC structure |
| ε (energy error) | < 15.0 mHa | ThermalWindow + Kani harness |
| S (entropy) | ≤ 6.0 | HSEC admission gate |
| NarrativeAuditor drift_score | = 0.0 | E2E attestation record |

---

## Owner Accountability

- **Ryan** owns the FPGA multiplex stress test execution.
- **Formal-methods reviewer** validates all Lean proofs and CI compliance.
- **E2E attestation record** must be populated before production mode is declared.

---

## Horizon

- **7 days:** FPGA multiplex optimization + load test execution
- **30 days:** Full throughput lock
- **Post-attestation:** Reopen UC category definition under new ADR

---

## Deferred Work

| Item | Deferral Reason |
|------|----------------|
| UC category definition | Unbound theoretical surface; risks Mathlib-style dependencies and sorry-prone scaffolding |
| Free-monoid / initial-object constructions | Already available in Operator-First and Lawful-Composition layers; no new ADR needed for production path |
| Lawful completion algebraic novelty | Unproven against existing constructions; defer until post-attestation |

---

## References

- `FeMoco_100_Concurrent_Load_Test_Criteria.md` — Locked acceptance gates
- `src/ADR/Proofs.lean` — Formal proofs of L0 invariants
- `contracts/sedona_spine.yaml` — Sedona Spine CONTRACT
