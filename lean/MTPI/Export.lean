import MTPI.ADR

open MTPI.ADR

/-! Export ADRs to human-readable Markdown and HTML. -/

namespace MTPI.Export

/-- Convert an ADR status to a human-readable string. -/
def statusToString : ADRStatus → String
  | ADRStatus.Proposed => "Proposed"
  | ADRStatus.Accepted => "Accepted"
  | ADRStatus.Deprecated => "Deprecated"
  | ADRStatus.Superseded => "Superseded"

/-- Convert an ADR to Markdown format. -/
def toMarkdown (adr : ADR) : String :=
  "# ADR-" ++ toString adr.id.number ++ ": " ++ adr.title ++ "\n\n" ++
  "**Status:** " ++ statusToString adr.status ++ "\n\n" ++
  "## Context\n" ++ adr.context ++ "\n\n" ++
  "## Decision\n" ++ adr.decision ++ "\n\n" ++
  "## Consequences\n" ++
  (adr.consequences.foldl (fun acc c => acc ++ "- " ++ c ++ "\n") "") ++
  "## Links\n" ++
  (adr.links.foldl (fun acc l => acc ++ "- [" ++ l.description ++ "](" ++ l.url ++ ")\n") "")

/-- Write an ADR to a Markdown file. -/
def writeMarkdown (adr : ADR) (path : String) : IO Unit := do
  IO.FS.writeFile path (toMarkdown adr)

/-- Convert an ADR to HTML format. -/
def toHTML (adr : ADR) : String :=
  "<html><body><h1>ADR-" ++ toString adr.id.number ++ ": " ++ adr.title ++ "</h1>" ++
  "<p><strong>Status:</strong> " ++ statusToString adr.status ++ "</p>" ++
  "<h2>Context</h2><p>" ++ adr.context ++ "</p>" ++
  "<h2>Decision</h2><p>" ++ adr.decision ++ "</p>" ++
  "<h2>Consequences</h2><ul>" ++
  (adr.consequences.foldl (fun acc c => acc ++ "<li>" ++ c ++ "</li>") "") ++
  "</ul><h2>Links</h2><ul>" ++
  (adr.links.foldl (fun acc l => acc ++ "<li><a href=\"" ++ l.url ++ "\">" ++ l.description ++ "</a></li>") "") ++
  "</ul></body></html>"

/-- Write an ADR to an HTML file. -/
def writeHTML (adr : ADR) (path : String) : IO Unit := do
  IO.FS.writeFile path (toHTML adr)

end MTPI.Export
