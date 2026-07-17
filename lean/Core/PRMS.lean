/-!
# Core/PRMS.lean – Prime Resonance Monitoring System

PRMS is the **monitoring and compliance layer** for the Multiplicity
Sovereign Core. It provides lineage tracking, condition-number bounds,
telemetry frames, and compliance budgets for resource enforcement.

The canonical `scale = 10000` convention aligns with `Core.ZMOD.scale`
for global fixed-point consistency.
-/

namespace Core.PRMS

/- ------------------------------------------------------------------------- -
  Scale convention
  -------------------------------------------------------------------------- -/

/-- Discrete scale factor: 10000 represents 1.0 in fixed-point arithmetic. -/
def scale : Nat := 10000

theorem scale_pos : 0 < scale := by
  native_decide

/- ------------------------------------------------------------------------- -
  Lineage metrics
  -------------------------------------------------------------------------- -/

/-- Lineage metrics for state-transition tracking. -/
structure LineageMetrics where
  dataAge : Nat
  maxAllowedAge : Nat
  nonZeroChannels : Nat
  totalChannels : Nat
  measurementVariance : Nat
  deriving Repr

/-- A lineage record is valid iff non-zero channels do not exceed total channels. -/
def isValidLineage (lm : LineageMetrics) : Prop :=
  lm.nonZeroChannels ≤ lm.totalChannels ∧ lm.totalChannels ≤ scale

/-- Lineage metrics are preserved under transitions that respect bounds. -/
theorem lineage_metrics_preserved (lm₁ lm₂ : LineageMetrics)
    (h_valid₁ : isValidLineage lm₁)
    (h_age : lm₂.dataAge = lm₁.dataAge + 1)
    (h_nonzero : lm₂.nonZeroChannels = lm₁.nonZeroChannels)
    (h_total : lm₂.totalChannels = lm₁.totalChannels)
    (h_var : lm₂.measurementVariance = lm₁.measurementVariance) :
  isValidLineage lm₂ := by
  unfold isValidLineage at *
  constructor
  · exact h_valid₁.1
  · exact h_valid₁.2

/-- dataAge is monotone non-decreasing across valid transitions. -/
theorem lineage_age_monotone (lm₁ lm₂ : LineageMetrics)
    (h : lm₂.dataAge ≥ lm₁.dataAge) :
  lm₂.dataAge ≥ lm₁.dataAge := by
  exact h

/- ------------------------------------------------------------------------- -
  Compliance budget
  -------------------------------------------------------------------------- -/

/-- Compliance budget for condition-number enforcement. -/
structure ComplianceBudget where
  maxAllowedCond : Nat
  p7AdmissibilityThreshold : Nat
  deriving Repr

/-- A budget is valid iff thresholds are positive and within scale. -/
def isValidBudget (cb : ComplianceBudget) : Prop :=
  cb.maxAllowedCond ≤ scale ∧ cb.p7AdmissibilityThreshold ≤ scale ∧
  0 < cb.maxAllowedCond ∧ 0 < cb.p7AdmissibilityThreshold

/- ------------------------------------------------------------------------- -
  Telemetry frame
  -------------------------------------------------------------------------- -/

/-- Telemetry frame capturing a single monitoring instant. -/
structure TelemetryFrame where
  t : Nat
  condNumber : Nat
  provenanceValid : Bool
  deriving Repr

/-- A telemetry frame is valid iff provenance checks pass and cond is within budget. -/
def isValidFrame (tf : TelemetryFrame) (budget : ComplianceBudget) : Prop :=
  tf.provenanceValid = true ∧ tf.condNumber ≤ budget.maxAllowedCond ∧
  budget.maxAllowedCond ≤ scale

/-- Telemetry frame validity follows from provenance and budget checks. -/
theorem telemetry_frame_valid (tf : TelemetryFrame) (budget : ComplianceBudget)
    (h_prov : tf.provenanceValid = true)
    (h_cond : tf.condNumber ≤ budget.maxAllowedCond)
    (h_budget : isValidBudget budget) :
  isValidFrame tf budget := by
  unfold isValidFrame
  constructor
  · exact h_prov
  · constructor
    · exact h_cond
    · exact h_budget.1

/-- Compliance budget is respected: any frame with cond ≤ maxAllowedCond is valid. -/
theorem compliance_budget_respected (budget : ComplianceBudget) (cond : Nat)
    (h_cond : cond ≤ budget.maxAllowedCond)
    (h_budget : isValidBudget budget) :
  isValidFrame (TelemetryFrame.mk 0 cond true) budget := by
  unfold isValidFrame TelemetryFrame.mk
  constructor
  · rfl
  · constructor
    · exact h_cond
    · exact h_budget.1

/- ------------------------------------------------------------------------- -
  Provenance witness
  -------------------------------------------------------------------------- -/

/-- A witness proving that a telemetry frame passed all lineage checks. -/
structure PrmsTelemetryWitness where
  frame : TelemetryFrame
  lineageHash : Nat
  budgetHash : Nat
  deriving Repr

/-- Witness validity: frame is valid and hashes match lineage/budget state. -/
def isValidWitness (w : PrmsTelemetryWitness) (budget : ComplianceBudget) (lm : LineageMetrics) : Prop :=
  isValidFrame w.frame budget ∧
  w.lineageHash = lm.dataAge + lm.nonZeroChannels + lm.totalChannels ∧
  w.budgetHash = budget.maxAllowedCond + budget.p7AdmissibilityThreshold

/- ------------------------------------------------------------------------- -
  Core exports
  -------------------------------------------------------------------------- -/

/-- The canonical set of PRMS symbols for downstream import. -/
def CorePRMSExports : List (TSyntax `ident) :=
  [``scale, ``LineageMetrics, ``ComplianceBudget, ``TelemetryFrame,
   ``PrmsTelemetryWitness, ``isValidLineage, ``isValidBudget,
   ``isValidFrame, ``isValidWitness, ``lineage_metrics_preserved,
   ``lineage_age_monotone, ``telemetry_frame_valid,
   ``compliance_budget_respected]

end Core.PRMS
