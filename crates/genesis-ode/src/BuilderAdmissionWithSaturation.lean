/-!
  BuilderAdmissionWithSaturation.lean
  Wiring ADR‑018 (Governance Saturation & Utilitarian Triage) into Builder admission.
  No external dependencies, no `sorry`s.
-/

import Builder
import ADR018_GovernanceSaturation
import ThreeLayerGovernanceCheck

open Builder

/-- Admission with saturation awareness.
    Parameters:
    * `load` and `thr` describe the current governance load and thresholds.
    * `minScore` is the minimum utility score required when saturated.
    The function first checks for saturation. If saturated, it applies the
    utilitarian triage (`shouldProceedUnderSaturation`). Only proposals that
    satisfy the triage are passed to the original three‑layer gate (`Builder.admit`).
    When not saturated the check falls back directly to `Builder.admit`.
-/

def admitWithSaturation
    (proposal : BuilderAdmissionProposal)
    (ctx : AdmissionContext)
    (comp : ThreeLayerGovernanceCheck)
    (load : GovernanceLoad)
    (thr : SaturationThresholds)
    (minScore : Nat) : Bool :=
  if governanceSaturated load thr then
    let driftResolved : Bool :=
      match ctx.note with
      | some _ => true
      | none   => false
    let score := utilityScore ctx.proof ctx.braState driftResolved
    if shouldProceedUnderSaturation load thr score minScore then
      Builder.admit proposal ctx comp
    else
      false
  else
    Builder.admit proposal ctx comp

/-- Theorem: under saturation, low‑utility proposals are blocked. -/
theorem high_utility_required_under_saturation
    (proposal : BuilderAdmissionProposal)
    (ctx : AdmissionContext)
    (comp : ThreeLayerGovernanceCheck)
    (load : GovernanceLoad) (thr : SaturationThresholds)
    (minScore : Nat)
    (hSat : governanceSaturated load thr = true)
    (hLow : utilityScore ctx.proof ctx.braState (match ctx.note with | some _ => true | none => false) < minScore) :
    admitWithSaturation proposal ctx comp load thr minScore = false := by
  unfold admitWithSaturation
  rw [hSat]
  have hScore : utilityScore ctx.proof ctx.braState (match ctx.note with | some _ => true | none => false) >= minScore = false := by
    decide
  simp [hScore, hLow] at *

/-- Theorem: when not saturated the admission reduces to the original three‑layer check. -/
theorem not_saturated_reduces_to_three_layer
    (proposal : BuilderAdmissionProposal)
    (ctx : AdmissionContext)
    (comp : ThreeLayerGovernanceCheck)
    (load : GovernanceLoad) (thr : SaturationThresholds)
    (minScore : Nat)
    (hNotSat : governanceSaturated load thr = false) :
    admitWithSaturation proposal ctx comp load thr minScore = Builder.admit proposal ctx comp := by
  unfold admitWithSaturation
  rw [hNotSat]
  rfl
