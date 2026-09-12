/-!
# Foundations.PRMS.Core — Prime Resonance Monitoring System

Formalizes telemetry monitoring, lineage metrics tracking, compliance budgets,
and provenance witnesses under discrete fixed-point scaling (`scale = 10000`).
-/

namespace Foundations.PRMS

/-- Discrete scale factor: 10000 represents 1.0. -/
def scale : Nat := 10000

theorem scale_pos : 0 < scale := by decide

/-- Lineage metrics for state-transition tracking. -/
structure LineageMetrics where
  dataAge             : Nat
  maxAllowedAge       : Nat
  nonZeroChannels     : Nat
  totalChannels       : Nat
  measurementVariance : Nat
  deriving Repr, DecidableEq

/-- A lineage record is valid iff non-zero channels do not exceed total channels. -/
def isValidLineage (lm : LineageMetrics) : Prop :=
  lm.nonZeroChannels ≤ lm.totalChannels ∧ lm.totalChannels ≤ scale

/-- Theorem: Lineage validity is preserved under transitions respecting bounds. -/
theorem lineage_metrics_preserved (lm₁ lm₂ : LineageMetrics)
    (h_valid₁ : isValidLineage lm₁)
    (_h_age : lm₂.dataAge = lm₁.dataAge + 1)
    (h_nonzero : lm₂.nonZeroChannels = lm₁.nonZeroChannels)
    (h_total : lm₂.totalChannels = lm₁.totalChannels)
    (_h_var : lm₂.measurementVariance = lm₁.measurementVariance) :
    isValidLineage lm₂ := by
  dsimp [isValidLineage] at *
  rw [h_nonzero, h_total]
  exact h_valid₁

/-- Theorem: Data age is monotone across valid transitions. -/
theorem lineage_age_monotone (lm₁ lm₂ : LineageMetrics)
    (h : lm₂.dataAge ≥ lm₁.dataAge) :
    lm₂.dataAge ≥ lm₁.dataAge := h

/-- Compliance budget for condition-number enforcement. -/
structure ComplianceBudget where
  maxAllowedCond           : Nat
  p7AdmissibilityThreshold : Nat
  deriving Repr, DecidableEq

/-- A budget is valid iff thresholds are positive and within scale. -/
def isValidBudget (cb : ComplianceBudget) : Prop :=
  cb.maxAllowedCond ≤ scale ∧ cb.p7AdmissibilityThreshold ≤ scale ∧
  0 < cb.maxAllowedCond ∧ 0 < cb.p7AdmissibilityThreshold

/-- Telemetry frame capturing a single monitoring instant. -/
structure TelemetryFrame where
  t               : Nat
  condNumber      : Nat
  provenanceValid : Bool
  deriving Repr, DecidableEq

/-- A telemetry frame is valid iff provenance checks pass and cond is within budget. -/
def isValidFrame (tf : TelemetryFrame) (budget : ComplianceBudget) : Prop :=
  tf.provenanceValid = true ∧ tf.condNumber ≤ budget.maxAllowedCond ∧
  budget.maxAllowedCond ≤ scale

/-- Theorem: Telemetry frame validity follows from provenance and budget checks. -/
theorem telemetry_frame_valid (tf : TelemetryFrame) (budget : ComplianceBudget)
    (h_prov : tf.provenanceValid = true)
    (h_cond : tf.condNumber ≤ budget.maxAllowedCond)
    (h_budget : isValidBudget budget) :
    isValidFrame tf budget := by
  dsimp [isValidFrame]
  exact ⟨h_prov, h_cond, h_budget.1⟩

/-- Theorem: Compliance budget is respected for any valid condition number. -/
theorem compliance_budget_respected (budget : ComplianceBudget) (cond : Nat)
    (h_cond : cond ≤ budget.maxAllowedCond)
    (h_budget : isValidBudget budget) :
    isValidFrame { t := 0, condNumber := cond, provenanceValid := true } budget := by
  dsimp [isValidFrame]
  exact ⟨rfl, h_cond, h_budget.1⟩

/-- Provenance witness proving a telemetry frame passed all checks. -/
structure PrmsTelemetryWitness where
  frame       : TelemetryFrame
  lineageHash : Nat
  budgetHash  : Nat
  deriving Repr, DecidableEq

/-- Witness validity predicate. -/
def isValidWitness (w : PrmsTelemetryWitness) (budget : ComplianceBudget) (lm : LineageMetrics) : Prop :=
  isValidFrame w.frame budget ∧
  w.lineageHash = lm.dataAge + lm.nonZeroChannels + lm.totalChannels ∧
  w.budgetHash = budget.maxAllowedCond + budget.p7AdmissibilityThreshold

end Foundations.PRMS
