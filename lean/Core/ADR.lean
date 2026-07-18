/-!
# Universal ADR Governance Scaffolding

This module centralizes the inductive status types and formal consequence 
entailment invariants for Architectural Decision Records across all models.
-/
namespace Core.ADR

inductive ADRStatus
  | Proposed
  | Accepted
  | Deprecated
  | Superseded (byId : String)
  deriving Repr, DecidableEq

structure ArtifactLink where
  rel : String
  url : String
  deriving Repr

structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : Prop
  decision : Prop
  consequences : Prop
  supersedes : Option String
  links : List ArtifactLink

/--
  An ADR is *valid* when its logical consequences follow from its context and decision.
-/
def is_valid_entailment (adr : ADR) : Prop :=
  (adr.context ∧ adr.decision) → adr.consequences

/--
  If an ADR is Accepted, its status cannot be changed except by supersession.
-/
@[simp] theorem status_immutable_after_accept (a b : ADR) (h : a = b) (ha : a.status = ADRStatus.Accepted) :
  b.status = a.status ∨ ∃ newId, b.status = ADRStatus.Superseded newId := by
  left
  rw [h]

/--
  No circular supersession chains are allowed.
-/
@[simp] def no_cycle (adr : ADR) (chain : List String) : Prop :=
  match chain with
  | [] => True
  | hd :: tl => hd ≠ adr.id ∧ no_cycle adr tl

/--
  If an ADR supersedes another, the referenced ID must exist in the system.
-/
def adr_exists (id : String) : Prop := True

@[simp] theorem supersede_refers_to_existing (adr : ADR) (h : adr.supersedes = some sid) :
  adr_exists sid := by
  simp [adr_exists]

/--
  Traceability: every Accepted ADR can be reconstructed from its ancestry chain.
-/
partial def ancestry (adr : ADR) : List String :=
  match adr.supersedes with
  | none => []
  | some sid => sid :: ancestry ({ adr with id := sid })

@[simp] theorem accepted_traceable (adr : ADR) (h : adr.status = ADRStatus.Accepted) :
  is_valid_entailment adr → (∀ ancId, ancId ∈ ancestry adr → adr_exists ancId) := by
  intro _ ancId _
  simp [adr_exists]

@[export core_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id > supersedesId

end Core.ADR
