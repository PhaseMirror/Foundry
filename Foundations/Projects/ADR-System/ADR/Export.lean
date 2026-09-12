import ADR.Core
/-!
# ADR Exporter
Generates markdown representations of verified ADRs.
-/

namespace ADR.Export

/-- Generates a Markdown string for a given ADR. -/
def toMarkdown (adr : ADR) : String :=
  s!"# {adr.id}: {adr.title}\n\n" ++
  s!"**Status:** {repr adr.status}\n\n" ++
  s!"## Context\n{adr.context}\n\n" ++
  s!"## Decision\n{adr.decision}\n\n" ++
  s!"## Consequences\n" ++
  String.join (adr.consequences.map (fun c => s!"- {c}\n"))

end ADR.Export
