import ADR.Core

/-! 
# Markdown Exporter
-/

namespace ADR.Export

def exportMarkdown (adr : ADRRecord) : String :=
  s!"# {adr.id}: {adr.title}\n\n" ++
  s!"**Status**: {repr adr.status}\n\n" ++
  s!"## Context\n{adr.context}\n\n" ++
  s!"## Decision\n{adr.decision}\n\n" ++
  s!"## Consequences\n" ++
  String.join (adr.consequences.map (fun c => s!"- {c}\n"))

end ADR.Export
