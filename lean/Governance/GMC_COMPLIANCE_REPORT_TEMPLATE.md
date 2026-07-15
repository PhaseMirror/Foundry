# GMC Compliance Report: [Engine Name / Variant]

**Date:** [YYYY-MM-DD]
**Target GCL:** [GCL-0 / GCL-1 / GCL-2]
**Commit Hash:** [Hash]

## 1. Safety Invariant Attestation
- [ ] **Fail-Closed:** Engine gates all transitions on valid, signed control vectors.
- [ ] **Drift Bounding:** Engine satisfies $\delta(t) \le 0.3\Xi$ under reference load.
- [ ] **Operator Integrity:** All $\hat{V}_{gov}$ operators in this build are verified PSD with $\|\hat{V}_{gov}\|_2 \le \kappa$.
- [ ] **No Unsafe Stale Use:** `stale_uses_unsafe` verified at zero in standard regression harness.

## 2. Verification Harness Results
*Executed on: [Environment/Hardware]*

| Metric | Measured | Required Bound | Status |
| :--- | :--- | :--- | :--- |
| **Max Drift ($\delta$)** | [Value] | $\le 0.45\Xi$ | [PASS/FAIL] |
| **Stale Unsafe Uses** | [Count] | == 0 | [PASS/FAIL] |
| **GovernorHalts** | [Count] | $\le$ Baseline | [PASS/FAIL] |
| **Step Latency** | [Value] | < 2x Baseline | [PASS/FAIL] |

## 3. Governance Observability Contract
- [ ] **Metrics:** Engine emits `drift`, `alpha`, `halt_status`, and `cache_health` via MCP.
- [ ] **Dashboard:** Health dashboard components (`governance_manifold_health.md`) are mapped.
- [ ] **Runbook:** Governance TTL invalidation and rollback procedures defined for this build.

## 4. Attestation Statement
By signing this report, the Engine Owner attests that the implementation satisfies the L0 invariants of the Governance Manifold Contract (GMC) and has passed all mandatory certification gates.

**Signed:** [Owner Name/Team]
**Approval:** [Governance Authority]

---
*This report is a mandatory build-time dependency. Deployment without a valid GMC Compliance Report is a violation of PhaseMirror architecture.*
