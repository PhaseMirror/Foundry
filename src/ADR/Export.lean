/-!
# Export ADRs to Markdown and HTML
-/

open ADR
open System

namespace ADR.Export

def renderMarkdown (a : ADR) : String :=
  s!"""
## ADR {a.id.value}: {a.title}

**Status**: {a.status}\n
**Context**\n{a.context}\n
**Decision**\n{a.decision}\n
**Consequences**\n{String.intercalate "\n- " a.consequences}\n
**Risk Level**: {a.riskLevel}\n
**Links**\n{String.intercalate "\n- " (a.links.map (fun l => s!"[{l.description}]({l.uri})"))}\n"""

def exportAll (ads : List ADR) : IO Unit := do
  let outDir ← IO.FS.currentDir >>= fun d => pure (d / "docs" / "adr")
  IO.FS.createDirAll outDir
  ads.forM fun a => do
    let file := outDir / s!"ADR_{a.id.value}.md"
    IO.FS.writeFile file (renderMarkdown a)

end ADR.Export
