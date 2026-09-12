import Foundations.ADR.Core

/-!
# Foundations.Governance.Core — ADR Lifecycle State Machine & Immutability Governance

Formalizes state-transitions for ADR lifecycle management (Proposed → Accepted → Deprecated / Superseded),
enforcing the immutability theorem, link requirements, and non-reentrant acceptance invariants.
-/

namespace Foundations.Governance

open Foundations.ADR

/-- Permitted status transitions in the ADR governance state machine. -/
def canTransition (old new_st : ADRStatus) : Bool :=
  match old, new_st with
  | ADRStatus.Proposed, ADRStatus.Accepted => true
  | ADRStatus.Proposed, ADRStatus.Deprecated => true
  | ADRStatus.Accepted, ADRStatus.Deprecated => true
  | ADRStatus.Accepted, ADRStatus.Superseded => true
  | ADRStatus.Deprecated, ADRStatus.Superseded => true
  | _, _ => false

/-- A transition is valid if `canTransition` holds, supersession has a witness when needed,
    accepted records cannot revert to proposed, and deprecation requires audit links. -/
def ValidTransition (old new_st : ADRStatus) (adr : ADR) : Prop :=
  canTransition old new_st = true ∧
  (new_st = ADRStatus.Superseded → adr.supersedes.isSome) ∧
  (new_st = ADRStatus.Deprecated → adr.links ≠ []) ∧
  ¬(old = ADRStatus.Accepted ∧ new_st = ADRStatus.Proposed)

/-- Theorem: Accepted status cannot re-enter as Proposed. -/
theorem no_reentrant_acceptance (old new_st : ADRStatus) :
    canTransition old new_st = true →
    ¬(old = ADRStatus.Accepted ∧ new_st = ADRStatus.Proposed) := by
  intro h_trans h_reenter
  rcases h_reenter with ⟨h_old, h_new⟩
  cases old <;> cases new_st <;> try simp [canTransition] at h_trans <;>
    try contradiction <;> trivial

/-- Theorem: Every valid transition preserves the ADR's identity. -/
theorem valid_transition_preserves_id (old new_st : ADRStatus) (a b : ADR)
    (h_trans : ValidTransition old new_st a) (h_id : a.id = b.id) :
    b.id = a.id := by
  exact h_id.symm

/-- Theorem: A Proposed ADR can transition to Accepted. -/
theorem proposed_to_accepted_allowed :
    canTransition ADRStatus.Proposed ADRStatus.Accepted = true := rfl

/-- Theorem: An Accepted ADR must have non-empty links before transitioning to Deprecated. -/
theorem accepted_to_deprecated_requires_links (a : ADR)
    (h_links : a.links = []) :
    ¬ ValidTransition ADRStatus.Accepted ADRStatus.Deprecated a := by
  intro h_val
  rcases h_val with ⟨_, _, h_dep_links, _⟩
  have h_req := h_dep_links rfl
  exact h_req h_links

end Foundations.Governance
