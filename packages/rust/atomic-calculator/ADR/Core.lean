import Lean
import Lean.Data.Json

open Lean

namespace ADR

/-- Status of an ADR: proposed, accepted, deprecated, superseded. -/
inductive Status where
  | proposed
  | accepted
  | deprecated
  | superseded (supersededBy : String)
  deriving DecidableEq, Repr, ToJson, FromJson, Inhabited

/-- The complete Architecture Decision Record. -/
structure DecisionRecord where
  id          : String
  title       : String
  status      : Status
  context     : String
  decision    : String
  consequences : String
  date        : String
  authors     : List String
  tags        : List String   := []
  links       : List String   := []
  version     : Nat           := 1
  deriving DecidableEq, Repr, Inhabited, ToJson, FromJson

/-- Constructors that ensure mandatory fields are non-empty. -/
def mkADR (id title context decision consequences date authors : String) (status : Status) : DecisionRecord :=
  { id := id, title := title, status := status, context := context, decision := decision,
    consequences := consequences, date := date, authors := authors.splitOn "," }

end ADR
