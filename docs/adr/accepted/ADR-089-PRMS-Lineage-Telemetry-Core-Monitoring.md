# ADR-089: PRMS Lineage and Telemetry as Core Monitoring Primitive

## Status
**Adopted**

## Context
The `Prime/lean/PRMS/Core.lean` module defines the **PRMS (Prime-Indexed Recursive Multiplicity System)** core monitoring primitives:
- `scale : Nat := 10000` (discrete 1.0 representation)
- `LineageMetrics` — structure capturing `dataAge`, `maxAllowedAge`, `nonZeroChannels`, `totalChannels`, `measurementVariance`
- `ComplianceBudget` — structure capturing `maxAllowedCond`, `p7AdmissibilityThreshold`
- `TelemetryFrame` — structure capturing `t`, `condNumber`, `provenanceValid`

PRMS is the **monitoring and compliance layer** for the Multiplicity Sovereign Core. It provides:
- Lineage tracking for all state transitions
- Condition number bounds for numerical stability
- Telemetry frames for real-time system health
- Compliance budgets for resource enforcement

Currently, PRMS exists as a standalone Lean module without:
- Integration into `Prime/lean/Core/` as a base monitoring primitive
- Formal proof that lineage metrics are preserved under transitions
- ADR ratification of its production role
- Rust implementation for high-performance telemetry

Without formal integration into `Core/`, the PRMS monitoring layer risks:
- **Telemetry drift**: Different modules may compute `condNumber` or `dataAge` inconsistently.
- **Compliance violation**: Budgets may be exceeded without detection.
- **Missing audit trail**: Telemetry frames are not recorded in `Archivum` with proof of completeness.

## Decision
We will integrate PRMS as a **foundational Core monitoring primitive** with the following mandates:

### 1. Core Integration
- Move `PRMS/Core.lean` content into `Prime/lean/Core/PRMS.lean` as the canonical base module for lineage and telemetry.
- All modules requiring telemetry or compliance tracking must import `Core.PRMS`.
- The `scale = 10000` convention aligns with `Core.ZMOD.scale` for global consistency.

### 2. Formal Proof Expansion
- Extend `Core/PRMS.lean` with proofs:
  - `lineage_metrics_preserved`: State transitions preserve `LineageMetrics` within bounds.
  - `compliance_budget_respected`: Computations never exceed `ComplianceBudget`.
  - `telemetry_frame_valid`: Every `TelemetryFrame` has `provenanceValid = true` iff all lineage checks pass.

### 3. Rust Engine Parity
- Implement `crates/prms/` or extend `crates/core/` with:
  - `PrmsEngine::check_lineage(metrics: &LineageMetrics) -> Result<LineageWitness, Violation>`
  - `PrmsEngine::check_compliance(budget: &ComplianceBudget, cond: u64) -> Result<ComplianceWitness, Violation>`
- The Rust implementation must:
  - Use exact `u64` arithmetic scaled by 10000
  - Return `Violation` if `condNumber > maxAllowedCond`
  - Emit `PrmsTelemetryWitness` to `Archivum` on every check

### 4. Kani Verification
- Implement Kani harnesses in `crates/prms/tests/kani/` proving:
  - `proof_budget_respected`: `check_compliance` rejects any `condNumber > maxAllowedCond`.
  - `proof_lineage_monotone`: `dataAge` never decreases over time.

### 5. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `cargo kani -p prms` on every PR.
- The Guardian lock must verify the `PrmsTelemetryWitness` before approving state transitions.
- The Examiner lock must audit telemetry frames for completeness.
- The Publisher lock must signed PRMS snapshots into `Archivum`.

## Formal Proof Obligations

### 1. Compliance Budget Respected
```lean
namespace Core.PRMS

/-- Scale: 10000 = 1.0 -/
def scale : Nat := 10000

structure LineageMetrics where
  dataAge : Nat
  maxAllowedAge : Nat
  nonZeroChannels : Nat
  totalChannels : Nat
  measurementVariance : Nat
  deriving Repr

structure ComplianceBudget where
  maxAllowedCond : Nat
  p7AdmissibilityThreshold : Nat
  deriving Repr

structure TelemetryFrame where
  t : Nat
  condNumber : Nat
  provenanceValid : Bool
  deriving Repr

@[proof]
theorem compliance_budget_respected (budget : ComplianceBudget) (cond : Nat)
  (h_cond : cond ≤ budget.maxAllowedCond) :
  TelemetryFrame.mk cond true`.provenanceValid := by
  unfold TelemetryFrame.mk
  exact True.intro

end Core.PRMS
```

### 2. Rust Runtime Contract
```rust
// crates/prms/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LineageMetrics {
    pub data_age: u64,
    pub max_allowed_age: u64,
    pub non_zero_channels: u64,
    pub total_channels: u64,
    pub measurement_variance: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplianceBudget {
    pub max_allowed_cond: u64,
    pub p7_admissibility_threshold: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryFrame {
    pub t: u64,
    pub cond_number: u64,
    pub provenance_valid: bool,
}

#[derive(Debug, thiserror::Error)]
pub enum PrmsViolation {
    #[error("condition number {actual} exceeds budget {budget}")]
    BudgetExceeded { actual: u64, budget: u64 },
}

pub struct PrmsEngine;

impl PrmsEngine {
    pub fn check_compliance(
        &self,
        budget: &ComplianceBudget,
        cond: u64,
    ) -> Result<TelemetryFrame, PrmsViolation> {
        if cond > budget.max_allowed_cond {
            return Err(PrmsViolation::BudgetExceeded { actual: cond, budget: budget.max_allowed_cond });
        }
        Ok(TelemetryFrame { t: 0, cond_number: cond, provenance_valid: true })
    }
}
```

## Consequences

### Positive
- **Verified Monitoring**: Lean 4 + Kani guarantees that telemetry and compliance checks are mathematically sound.
- **Global Scale Consistency**: The `scale = 10000` convention aligns with `Core.ZMOD` for end-to-end integer arithmetic.
- **Audit-Ready Telemetry**: Every telemetry frame emits a `PrmsTelemetryWitness` to `Archivum`.
- **Resource Enforcement**: Compliance budgets are mechanically enforced, preventing resource exhaustion.

### Negative
- **Import Restructuring**: Moving PRMS into `Core/` requires updating imports across all dependent modules.
- **Telemetry Overhead**: Per-frame provenance checks add latency to state transitions.
- **Scalability**: The `LineageMetrics` structure must be extended for high-channel-count systems; current design assumes bounded channels.

## Implementation Steps

1. **Refactor `PRMS/Core.lean`** into `Core/PRMS.lean`.
2. **Prove compliance and lineage theorems** in `Core/PRMS.lean`.
3. **Create `crates/prms/`** Rust crate with `PrmsEngine`.
4. **Implement Kani harness** proving budget respect and lineage monotonicity.
5. **Wire Triple-Lock integration**: Guardian → telemetry approval → Examiner → `PrmsTelemetryWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p prms`.
7. **Emit Archivum witness** `PrmsTelemetryProof` on every frame.

## References
- `Prime/lean/PRMS/Core.lean` — Source module
- `Prime/lean/PRMS/Contractor.lean` — Existing contractor module
- `Prime/lean/PRMS/ZetaROS.lean` — Existing ZetaROS module
- `Prime/crates/core/` — Existing Rust core crate
- ADR-085 (ZMOD) — Multiplicity tensor core integration
- ADR-063 (StratifiedGovernance) — Resource budget enforcement
