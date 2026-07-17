/-! 
# Core ADR Types
Defines the `ADRStatus` and the `ADR` structure.
-/

namespace ADR

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq

structure ArtifactLink where
  url : String
  deriving Repr, DecidableEq

structure ADRRecord where
  id : String
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option String
  links : List ArtifactLink
  deriving Repr, DecidableEq

end ADR
