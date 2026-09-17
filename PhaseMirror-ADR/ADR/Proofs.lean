/-!
# ADR Invariants and Proofs
This module contains the formal verification of our ADR governance rules.
-/
import ADR.Core

namespace ADR.Proofs

open ADR

-- Theorem: Once Accepted, status is immutable without a superseding ADR
-- Modeled here as a state transition constraint.
inductive ValidTransition : ADRStatus → ADRStatus → Prop where
  | prop_to_acc : ValidTransition ADRStatus.Proposed ADRStatus.Accepted
  | acc_to_sup : ValidTransition ADRStatus.Accepted ADRStatus.Superseded
  | acc_to_dep : ValidTransition ADRStatus.Accepted ADRStatus.Deprecated

@[simp]
theorem no_accepted_to_proposed (h : ValidTransition ADRStatus.Accepted ADRStatus.Proposed) : False := by
  cases h

-- Theorem: No circular supersession (simplified check for a single step)
def NotSelfSuperseding (a : ADR) : Prop :=
  a.supersedes ≠ some a.id

theorem check_not_self_superseding (a : ADR) (h : a.supersedes = none) : NotSelfSuperseding a := by
  intro h_contra
  rw [h] at h_contra
  contradiction

end ADR.Proofs
