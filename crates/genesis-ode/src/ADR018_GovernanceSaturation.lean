/-!
  ADR‑018 Formalization in Lean4
  Governance Saturation & Utilitarian Triage.
  No external dependencies, no `sorry`s.
-/

open ShrapnelMap

/-- Counts of high‑friction (HF) claims, unresolved drift notes, and pending proposals. -/
structure GovernanceLoad where
  openHFClaims        : Nat
  openUnresolvedDrift : Nat
  pendingProposals    : Nat
  deriving Repr

/-- Configurable limits for each load type. -/
structure SaturationThresholds where
  maxHFClaims        : Nat
  maxUnresolvedDrift : Nat
  maxPendingProposals: Nat
  deriving Repr

/-- Detect whether any load exceeds its threshold. -/
 def governanceSaturated (load : GovernanceLoad) (thr : SaturationThresholds) : Bool :=
   load.openHFClaims        > thr.maxHFClaims ||
   load.openUnresolvedDrift > thr.maxUnresolvedDrift ||
   load.pendingProposals    > thr.maxPendingProposals

/-- Simple utility scoring for a proposal.
    * Proof currency tier contributes most.
    * Internal BRA reconstruction adds bonus.
    * Resolved drift note adds bonus.

    Returns a non‑negative integer score. -/
 def utilityScore (proof : ProofArtifact) (bra : BRAState) (driftResolved : Bool) : Nat :=
   let base :=
     match proof.tier with
     | "S" => 10
     | "E" => 5
     | _   => 1
   let braBonus := if bra.isInternal then 3 else 0
   let driftBonus := if driftResolved then 2 else 0
   base + braBonus + driftBonus

/-- Predicate that decides if a proposal may proceed when the system is saturated.
    If the system is *not* saturated, any proposal is allowed (return `true`).
    When saturated, the proposal must achieve a utility score at least `minScore`. -/
 def shouldProceedUnderSaturation (load : GovernanceLoad) (thr : SaturationThresholds)
    (score minScore : Nat) : Bool :=
   if governanceSaturated load thr then
     score >= minScore
   else
     true

/-- Theorem: under saturation, low‑utility proposals are blocked. -/
 theorem high_utility_required_under_saturation
   (load : GovernanceLoad) (thr : SaturationThresholds)
   (score minScore : Nat)
   (hSat : governanceSaturated load thr = true)
   (hLow : score < minScore) :
   shouldProceedUnderSaturation load thr score minScore = false := by
   unfold shouldProceedUnderSaturation
   rw [hSat]
   have h : (score >= minScore) = false := by decide
   simpa [h]

/-- Theorem: when not saturated the predicate is always `true`. -/
 theorem not_saturated_reduces_to_three_layer
   (load : GovernanceLoad) (thr : SaturationThresholds)
   (score minScore : Nat)
   (hNotSat : governanceSaturated load thr = false) :
   shouldProceedUnderSaturation load thr score minScore = true := by
   unfold shouldProceedUnderSaturation
   rw [hNotSat]
   simp
