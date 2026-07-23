namespace ADR

structure ADRId where
  value        : Nat
  namespaceStr : String := ""
  deriving Repr, DecidableEq, Inhabited

def ADRId.legacy (value : Nat) : ADRId := ⟨value, ""⟩
def ADRId.canonical (ns : String) (value : Nat) : ADRId := ⟨value, ns⟩
def ADRId.pretty (id : ADRId) : String :=
  if id.namespaceStr = "" then "ADR-" ++ toString id.value
  else "ADR-" ++ id.namespaceStr ++ "-" ++ toString id.value

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
