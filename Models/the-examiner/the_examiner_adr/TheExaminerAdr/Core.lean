/-!
# Core ADR Types for the-examiner
-/

namespace TheExaminerAdr

inductive ADRStatus where
  | Proposed : ADRStatus
  | Accepted : ADRStatus
  | Superseded (id : String) : ADRStatus
  | Deprecated : ADRStatus
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

def is_valid_entailment (adr : ADR) : Prop :=
  (adr.context ∧ adr.decision) → adr.consequences

end TheExaminerAdr
