/-!
# Core ADR Definitions
This module defines the basic structure of an Architecture Decision Record.
-/
namespace ADRSystem

/-- Represents the lifecycle state of an ADR. -/
inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, BEq, Inhabited

/-- Represents a link to an external artifact. -/
structure ArtifactLink where
  title : String
  url : String
  deriving Repr, BEq

/-- The formal structure of an ADR. -/
structure ADR where
  id : Nat
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option Nat
  links : List ArtifactLink
  deriving Repr, BEq

end ADRSystem
