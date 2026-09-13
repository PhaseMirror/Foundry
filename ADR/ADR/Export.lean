import ADR.Core
import ADR.Examples

/-!
# Markdown Exporter
Converts verified ADR structures into compliance-ready markdown documents.
-/

namespace ADR.Export

def statusToString : ADRStatus → String
  | .Proposed => "Proposed"
  | .Accepted => "Accepted"
  | .Deprecated => "Deprecated"
  | .Superseded id => s!"Superseded by {id}"

def generateMarkdown (adr : ADR) : String :=
  s!"# ADR-{adr.id}: {adr.title}\n\n" ++
  s!"**Status:** {statusToString adr.status}\n\n" ++
  s!"## Links\n" ++
  String.join (adr.links.map (fun l => s!"* **[{l.relation}]** {l.target}\n"))

end ADR.Export
