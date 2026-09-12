/-!
# ADR Foundations Core

Defines the fundamental ADR data model used across the PIRTM project.
-/

abbrev ADRId := Nat

namespace PIRTM.ADR

inductive ADRStatus where
  | Proposed   : ADRStatus
  | Accepted   : ADRStatus
  | Deprecated : ADRStatus
  | Superseded : ADRStatus
  deriving Repr, DecidableEq

structure ArtifactLink where
  uri   : String
  label : String
  deriving Repr

structure ADR where
  id          : ADRId
  title       : String
  status      : ADRStatus
  context     : String
  decision    : String
  consequences : List String
  supersedes  : Option ADRId
  links       : List ArtifactLink
  deriving Repr

end PIRTM.ADR
