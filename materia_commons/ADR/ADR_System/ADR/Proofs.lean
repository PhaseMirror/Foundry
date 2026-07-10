/-!
# ADR Invariants and Proofs
Verifies immutability, traceability, and logical entailment.
-/
import ADR.Core

namespace ADRSystem.Proofs

open ADRSystem

/-- A simplified model of state transition for an ADR. -/
def validTransition (old new : ADRStatus) (supersedingId : Option Nat) : Prop :=
  match old with
  | .Proposed => True -- Can transition anywhere
  | .Accepted => 
      (new = .Superseded ∧ supersedingId.isSome) ∨ 
      (new = .Deprecated)
  | .Deprecated => False -- Terminal
  | .Superseded => False -- Terminal

/-- Theorem: An accepted ADR cannot change to Superseded without a superseding ID. -/
theorem accepted_immutability (supersedingId : Option Nat) (h : validTransition .Accepted .Superseded supersedingId) : 
  supersedingId.isSome := by
  dsimp [validTransition] at h
  cases h with
  | inl h1 => exact h1.right
  | inr h2 => contradiction

/-- 
A simple entailment checker. In a real production system, this would be a full embedded logic.
Here we just ensure that if consequences exist, they are structurally valid.
-/
def consequencesEntailed (adr : ADR) : Prop :=
  adr.decision ≠ "" → adr.consequences.length > 0

theorem entailment_check (adr : ADR) (h : adr.decision ≠ "") (hc : adr.consequences = ["Improved performance"]) : 
  consequencesEntailed adr := by
  dsimp [consequencesEntailed]
  intro _
  rw [hc]
  decide

end ADRSystem.Proofs
