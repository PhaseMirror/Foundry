
import ADR.Core
import ADR.Examples

namespace ADR

/--
Render a single ADR as markdown.
-/
def toMarkdown (a : ADR) : String :=
  let statusStr := match a.status with
    | ADRStatus.Proposed => "Proposed"
    | ADRStatus.Accepted => "Accepted"
    | ADRStatus.Deprecated => "Deprecated"
    | ADRStatus.Superseded => "Superseded"
  let supersedesStr := match a.supersedes with
    | none => "None"
    | some id => s!"ADR-{id.value}"
  let linksStr := match a.links with
    | [] => "None"
    | links => String.intercalate "\n" (links.map (fun (l : ArtifactLink) => s!"- [{l.artifactType}] {l.identifier}"))

  s!"# {a.id} — {a.title}\n\n" ++
  s!"**Status:** {statusStr}\n\n" ++
  s!"**Supersedes:** {supersedesStr}\n\n" ++
  s!"## Context\n\n{a.context}\n\n" ++
  s!"## Decision\n\n{a.decision}\n\n" ++
  s!"## Consequences\n\n" ++
  String.intercalate "\n" (a.consequences.map (fun c => s!"- {c}")) ++ "\n\n" ++
  s!"## Links\n\n{linksStr}\n"

/--
Write all example ADRs to the `docs/` folder.
-/
def exportToDocs : IO Unit := do
  let docsPath := "./docs"
  IO.FS.createDirAll docsPath
  let adrs := [adr0999, adr1001, adr1002, adr1003, adr1004, adr033]
  for adr in adrs do
    let filename := s!"{docsPath}/ADR-{adr.id.value}.md"
    let content := toMarkdown adr
    IO.FS.writeFile filename content
    IO.println s!"Exported {filename}"

/--
Print all example ADRs to stdout as markdown.
-/
def printAll : IO Unit := do
  let adrs := [adr0999, adr1001, adr1002, adr1003, adr1004, adr033]
  for adr in adrs do
    IO.println (toMarkdown adr)
    IO.println "---"

def main : IO Unit := do
  IO.println "=== ADR Export ==="
  exportToDocs
  IO.println ""
  IO.println "Export complete."

end ADR
