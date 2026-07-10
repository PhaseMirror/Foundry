/-!
# ADR Markdown Exporter
-/
import ADR.Core

namespace ADRSystem.Export
open ADRSystem

def exportToMarkdown (adr : ADR) : String :=
  s!"# ADR {adr.id}: {adr.title}\n\n" ++
  s!"**Status:** {repr adr.status}\n\n" ++
  s!"## Context\n{adr.context}\n\n" ++
  s!"## Decision\n{adr.decision}\n\n" ++
  s!"## Consequences\n" ++
  String.join (adr.consequences.map (fun c => s!"- {c}\n"))

def main : IO Unit := do
  IO.println "ADR export functionality ready (run via lake exe adr_export)"

end ADRSystem.Export
