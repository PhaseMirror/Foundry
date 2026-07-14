namespace MTPI

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq

structure ArtifactLink where
  uri : String
  hash : String

structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option String
  links : List ArtifactLink
  h_no_self_supersession : supersedes ≠ some id

end MTPI
