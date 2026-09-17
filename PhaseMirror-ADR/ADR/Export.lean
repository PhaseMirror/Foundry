/-!
# Markdown Exporter
Transforms verified Lean 4 ADR objects into Markdown for static site generation.
-/
import ADR.Core

namespace ADR.Export

open ADR

def statusToString : ADRStatus → String
  | .Proposed => "Proposed"
  | .Accepted => "Accepted"
  | .Deprecated => "Deprecated"
  | .Superseded => "Superseded"

def toMarkdown (a : ADR) : String :=
  s!"# ADR {a.id}: {a.title}\n\n" ++
  s!"**Status:** {statusToString a.status}\n\n" ++
  s!"## Context\n{a.context}\n\n" ++
  s!"## Decision\n{a.decision}\n\n" ++
  s!"## Consequences\n" ++
  String.join (a.consequences.map (λ c => s!"- {c}\n"))

end ADR.Export
