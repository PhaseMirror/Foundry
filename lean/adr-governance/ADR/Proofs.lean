import ADR.Core

/-!
# ADR Proofs and Invariants
This module contains the formal theorems guaranteeing ADR integrity,
including layout consistency and provenance tracking.
-/
namespace ADR.Proofs

open ADR

/-- An ADR state transition is valid only under specific conditions. -/
inductive ValidTransition : ADRStatus → ADRStatus → Prop
  | propose_accept : ValidTransition ADRStatus.Proposed ADRStatus.Accepted
  | accept_supersede : ValidTransition ADRStatus.Accepted ADRStatus.Superseded
  | accept_deprecate : ValidTransition ADRStatus.Accepted ADRStatus.Deprecated

/-- Theorem: Once Accepted, status is immutable without a valid transition (e.g., superseding). -/
theorem accepted_is_immutable_without_transition (s : ADRStatus) (h : s = ADRStatus.Accepted) :
  ∀ s', ValidTransition s s' → s' = ADRStatus.Superseded ∨ s' = ADRStatus.Deprecated := by
  intro s' h_trans
  cases h_trans
  · contradiction -- propose_accept cannot originate from Accepted
  · exact Or.inl rfl
  · exact Or.inr rfl

/-- A simple semantic entailment model for consequences.
    In a full production system, this would use an embedded logic DSL. -/
def consequence_entailed (_decision : String) (_consequence : String) : Bool :=
  -- Dummy implementation: assume all consequences are entailed for the skeleton
  true

/-- Theorem: All consequences must be entailed by the decision. -/
def AllConsequencesEntailed (adr : ADR) : Prop :=
  ∀ c, c ∈ adr.consequences → consequence_entailed adr.decision c = true

/-- Theorem: defaultLayout root contains no spaces. -/
theorem default_layout_no_spaces :
  defaultLayout.root_name = "materia_commons" ∧
  defaultLayout.lean_dir = "lean" ∧
  ∀ dir, dir ∈ defaultLayout.impl_dirs → ¬dir.contains ' ' := by
  apply And.intro
  · rfl
  · apply And.intro
    · rfl
    · intro dir hdir
      cases hdir with
      | head _ =>
          native_decide
      | tail _ ih =>
          cases ih with
          | head _ =>
              native_decide
          | tail _ ih2 =>
              cases ih2 with
              | head _ =>
                  native_decide
              | tail _ _ =>
                  contradiction

/-- Global provenance invariant holds for any ProvenancedRegistry by projection. -/
theorem all_adrs_have_provenance (pr : ProvenancedRegistry) :
  ∀ (a : ADR), a ∈ pr.registry → ∀ (l : ArtifactLink), l ∈ a.links → l.provenance.isSome := by
  exact pr.valid

end ADR.Proofs
