/-!
# Core ADR Types
Defines the dependent structures and inductives for formal Architecture Decision Records.
-/


namespace ADR

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded (by_id : String)
  deriving Repr, DecidableEq, Inhabited

structure ArtifactLink where
  relation : String
  target : String
  deriving Repr, DecidableEq

inductive PropToken where
  | atom (name : String)
  | and (p q : PropToken)
  | implies (p q : PropToken)
  deriving Repr, DecidableEq

structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : List PropToken
  decision : List PropToken
  consequences : List PropToken
  supersedes : Option String
  links : List ArtifactLink
  entailment_proof : ∀ c ∈ consequences, c ∈ context ∨ c ∈ decision
  deriving Repr

end ADR
