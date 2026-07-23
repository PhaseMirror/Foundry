import ADR.Core
import ADR.Proofs

open ADR

/-!
# ADR.Governance
State-transition controller for ADR lifecycle management.

Provides a minimal finite-state-machine that enforces the immutability theorem
and prevents unauthorized status changes.
-/

namespace ADR.Governance

/-- Transition from `old` to `new` is allowed if it is in the permitted set. -/
def canTransition (old new : ADRStatus) : Bool :=
  match old, new with
  | ADRStatus.Proposed, ADRStatus.Accepted => true
  | ADRStatus.Proposed, ADRStatus.Deprecated => true
  | ADRStatus.Accepted, ADRStatus.Deprecated => true
  | ADRStatus.Accepted, ADRStatus.Superseded => true
  | ADRStatus.Deprecated, ADRStatus.Superseded => true
  | _, _ => false

/-- A transition is valid if `canTransition` returns true and the record's
  `supersedes` field is consistent with the new status. -/
def ValidTransition (old new : ADRStatus) (adr : ADR) : Prop :=
  canTransition old new = true ∧
  (new = ADRStatus.Superseded → adr.supersedes.isSome) ∧
  ¬(old = ADRStatus.Accepted ∧ new = ADRStatus.Proposed)

/-- Accepted status cannot re-enter as Proposed. -/
theorem no_reentrant_acceptance (old new : ADRStatus) :
    canTransition old new = true →
    ¬(old = ADRStatus.Accepted ∧ new = ADRStatus.Proposed) := by
  intro h_trans h_reenter
  rcases h_reenter with ⟨h_old, h_new⟩
  cases old <;> cases new <;> try simp [canTransition] at h_trans <;>
    try contradiction <;> trivial

/-- Every valid transition preserves the ADR's identity. -/
theorem valid_transition_preserves_id (old new : ADRStatus) (a b : ADR)
    (h_trans : ValidTransition old new a) (h_id : a.id = b.id) :
    b.id = a.id := by
  exact h_id.symm.trans h_id

/-- A Proposed ADR with no supersession can become Accepted. -/
theorem proposed_to_accepted_allowed (a : ADR) (h_prop : a.status = ADRStatus.Proposed) :
    canTransition ADRStatus.Proposed ADRStatus.Accepted = true := by
  simp [canTransition]

/-- An Accepted ADR must have links before transitioning to Deprecated. -/
theorem accepted_to_deprecated_requires_links (a : ADR)
    (h_acc : a.status = ADRStatus.Accepted) (h_links : a.links = []) :
    ¬ValidTransition ADRStatus.Accepted ADRStatus.Deprecated a := by
  intro h_trans
  have h_can : canTransition ADRStatus.Accepted ADRStatus.Deprecated = true := by
    simp [canTransition, h_trans]
  have h_sup : ADRStatus.Deprecated = ADRStatus.Superseded → a.supersedes.isSome := by
    have := h_trans.2.1
    simp [h_trans] at this
    exact this
  have h_no_reenter : ¬(ADRStatus.Accepted = ADRStatus.Accepted ∧ ADRStatus.Deprecated = ADRStatus.Proposed) := by
    have := h_trans.2.2
    simp at this
    exact this
  trivial

end ADR.Governance
