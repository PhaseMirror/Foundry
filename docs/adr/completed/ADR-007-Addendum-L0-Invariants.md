# ADR-007 Addendum: Production Concurrency Invariants

## Executive Summary

This addendum extends ADR-007 (Lean 4 Formal Verification Plan) with explicit L0-preserving clauses that gate the Universal Completion (UC) category expansion. The UC work is **deferred to ADR-008** and remains blocked until the FeMoco load test passes.

**Status**: ACTIVE
**Effective Date**: 2026-07-22
**Review Date**: 2026-07-29 (7 days from lock activation)

---

## L0 Invariants (Non-Negotiable)

### 1. No Mathlib

All Lean 4 specifications must import `Init` and `Std` only. `Mathlib` is explicitly forbidden in `lakefile.lean`.

**Enforcement**:
- CI workflow rejects any Mathlib imports
- `lakefile.lean` must not list Mathlib as a dependency
- All proofs must be discharged via Kani BMC harnesses (FFI-imported tokens)

**Rationale**:
- Mathlib introduces external dependencies that cannot be verified by our CI
- Lean's `Init` and `Std` libraries provide sufficient foundations for our specifications
- Kani BMC provides bit-precise verification without external dependencies

### 2. No `sorry`

Any `sorry`/`admit` in the `Core/Spec/` directory blocks CI deployment. Proofs are discharged via Kani BMC harnesses (FFI-imported tokens).

**Enforcement**:
- CI workflow scans all Lean files for `sorry`/`admit`
- Any occurrence blocks the deployment pipeline
- Exception: Explicit `sorry_count` tracking in documentation

**Rationale**:
- `sorry` represents incomplete proofs that cannot be trusted
- All proofs must be complete and verifiable
- Kani BMC provides automated proof discharge

### 3. Concurrency Bound

For any theoretical extension (e.g., Universal Completion), the completion algorithm (`rust/src/completion.rs`) **must** sustain:

| Parameter | Bound | Rationale |
|:---|:---|:---|
| **Concurrent Requests** | N ≤ 100 | Hardware concurrent limit |
| **Qudits per Request** | q ≤ 69 | Physical array size |
| **Energy Error** | ε < 15 mHa | Quantum accuracy bound |
| **Entropy** | S ≤ 6.0 | Thermal stability bound |

**Enforcement**:
- FeMoco 100-concurrent load test must pass all gates
- E2E attestation record must be signed
- ADR-008 approval required before UC work begins

**Rationale**:
- The mathematical core exists to serve the physical hardware
- UC category expansion must preserve L0 invariants
- Empirical testing is the gatekeeper for theoretical extensions

---

## Decision: Concurrency First

The Universal Completion category (UC) is deferred to ADR-008. UC work is frozen until the FeMoco_100_Concurrent_Load_Test passes.

**Rationale**:
- The free-monoid initiality required for the NNO conjecture is *already structurally present* in Operator-First Arithmetic
- We do not need a new category definition to unblock QaaS throughput
- The smallest viable step that preserves L0 invariants is to harden existing compilation, not expand theory

---

## Blocking Conditions

The following conditions **block** ADR-008 (UC category expansion):

| Condition | Status | Owner | Deadline |
|:---|:---|:---|:---|
| FeMoco load test passes | PENDING | Ryan | 2026-07-29 |
| E2E attestation signed | PENDING | Ryan + Formal | 2026-07-29 |
| ADR-008 approved | DEFERRED | Research | After attestation |

---

## Unblocking Sequence

1. **Day 1-3**: FPGA multiplex stress test (50 → 100 concurrent)
2. **Day 4**: Validate energy error < 15 mHa, entropy ≤ 6.0
3. **Day 5**: Verify NarrativeAuditor zero-drift
4. **Day 6**: Freeze code branch, run full CI
5. **Day 7**: Sign E2E attestation record
6. **Post-Day 7**: If gates pass, proceed to ADR-008

---

## Impact on Existing Work

### What Remains Unchanged
- All existing Lean proofs (zero sorry, zero Mathlib)
- All existing Kani harnesses (7/7 passing)
- All existing ADR contracts (4/4 valid)
- All existing Rust implementation (zero panic)

### What is Deferred
- UC category definition (ADR-008)
- NNO conjecture proof (pending concurrency validation)
- Morphism soundness Kani harness (pending concurrency validation)

### What is New
- FeMoco load test criteria (acceptance gates)
- Production mode lock (feature flag enforcement)
- UAC on-chain finality lock (contract validation)
- CI workflow enforcement (Mathlib/sorry rejection)

---

## Monitoring & Reporting

### Daily Status Updates
- **Location**: `docs/operations/PRODUCTION_LOCK.txt`
- **Frequency**: Daily during 7-day lock period
- **Owner**: Ryan + Formal-Methods

### Attestation Reporting
- **Location**: `docs/operations/E2E_Attestation_Record.md`
- **Trigger**: After load test completion
- **Signatories**: Ryan + Formal-Methods + DevOps

---

## Approval

| Role | Name | Date | Signature |
|:---|:---|:---|:---|
| Engineering Lead | _______________ | _______________ | _______________ |
| Product Owner | _______________ | _______________ | _______________ |
| Formal Methods | _______________ | _______________ | _______________ |
| Research Lead | _______________ | _______________ | _______________ |

---

*Document Version: 1.0*
*Last Updated: 2026-07-22*
*Status: ACTIVE*
*Parent Document: ADR-045-Lean4-Formalization.md*
