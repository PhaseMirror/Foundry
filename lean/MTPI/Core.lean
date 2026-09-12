/-! Core type definitions for the MTPI ADR subsystem. -/

namespace MTPI

/-- Unique identifier for an Architecture Decision Record. -/
structure ADRId where
  number : Nat
  deriving Repr, BEq, Hashable, DecidableEq

/-- Status of an Architecture Decision Record. -/
inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, BEq, Hashable, Inhabited, DecidableEq

/-- Link to an external artifact (e.g., Git commit, Lean declaration). -/
structure ArtifactLink where
  url : String
  description : String
  deriving Repr, BEq, Hashable, DecidableEq

end MTPI
