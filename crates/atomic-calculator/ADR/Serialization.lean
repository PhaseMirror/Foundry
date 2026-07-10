import ADR.Core
import Lean.Data.Json

open Lean

namespace ADR.Serialization

def fromJsonString (s : String) : Except String DecisionRecord :=
  match Lean.Json.parse s with
  | .ok json => match fromJson? (α := DecisionRecord) json with
    | .ok r => .ok r
    | .error e => .error s!"Failed to parse ADR: {e}"
  | .error e => .error s!"JSON parse error: {e}"

def toJsonString (r : DecisionRecord) : String :=
  Lean.Json.pretty (toJson r)

end ADR.Serialization
