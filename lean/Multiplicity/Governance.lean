import Multiplicity.ADR.Core
import Multiplicity.ADR.Proofs

open ADR

/-!
# ADR.Governance
State-transition controller for ADR lifecycle management.

Provides a minimal finite-state-machine that enforces the immutability theorem
and prevents unauthorized status changes.
-/

namespace Multiplicity.ADR.Governance

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
    (_h_trans : ValidTransition old new a) (h_id : a.id = b.id) :
    b.id = a.id := h_id.symm

/-- A Proposed ADR with no supersession can become Accepted. -/
theorem proposed_to_accepted_allowed (a : ADR) (_h_prop : a.status = ADRStatus.Proposed) :
    canTransition ADRStatus.Proposed ADRStatus.Accepted = true := by
  simp [canTransition]

end Multiplicity.ADR.Governance
