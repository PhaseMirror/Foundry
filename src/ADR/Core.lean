/-!
# Core ADR definitions
-/
import .CompactClosed
namespace ADR

structure ADRId where
  value : Nat
  deriving Repr, DecidableEq, Inhabited

inductive RiskLevel where
  | Critical | High | Medium | Low
  deriving Repr, DecidableEq

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq

structure ArtifactLink where
  uri : String
  description : String
  deriving Repr

structure ADR where
  id           : ADRId
  title        : String
  status       : ADRStatus
  context      : String
  decision     : String
  consequences : List String
  supersedes   : Option ADRId := none
  links        : List ArtifactLink := []
  riskLevel    : RiskLevel := RiskLevel.Medium
  deriving Repr

instance : LT ADRId where
  lt a b := a.value < b.value

end ADR
