/-! 
# ADR Core
Defines the core data structures and types for the formally verified ADR system.
-/

namespace ADR

/-- Status of an Architecture Decision Record -/
inductive ADRStatus
| Proposed
| Accepted
| Deprecated
| Superseded
deriving Repr, DecidableEq

/-- A link to a related artifact -/
structure ArtifactLink where
  title : String
  url : String
deriving Repr

/-- The core Architecture Decision Record structure -/
structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option String
  links : List ArtifactLink
deriving Repr

end ADR
