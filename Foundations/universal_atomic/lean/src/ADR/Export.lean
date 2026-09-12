/-!
## Export Module

Provides utilities to render ADR records as Markdown and HTML files.
- Uses Lean's `IO.FS` for filesystem interactions.
- Minimal implementation; can be extended with a full templating engine.
-/

import Std.Data.List.Basic
import Std.Data.Option.Basic
import Lean
import "Core.lean"

open IO
open System
open ADR

namespace ADRExport

/-- Render an `ADR` as a Markdown string. -/
def adrToMarkdown (a : ADR) : String :=
  let statusStr := match a.status with
    | ADRStatus.Proposed   => "Proposed"
    | ADRStatus.Accepted   => "Accepted"
    | ADRStatus.Deprecated => "Deprecated"
    | ADRStatus.Superseded => "Superseded"
  let supersedesStr := match a.supersedes with
    | none   => "None"
    | some id => toString id
  let linksStr := a.links.foldl (fun acc l => acc ++ "- " ++ l.toString ++ "\n") ""
  s!"""
# ADR {a.id}: {a.title}

**Status:** {statusStr}
**Context:** {a.context}
**Decision:** {a.decision}
**Consequences:**
{a.consequences.foldl (fun acc c => acc ++ "- " ++ c ++ "\n") ""}
**Supersedes:** {supersedesStr}
**Links:**
{linksStr}
"""

/-- Write an `ADR` to a Markdown file under `docs/adr/`. -/
def writeADR (a : ADR) (baseDir : FilePath) : IO Unit := do
  let dir := baseDir / "adr"
  FS.createDirAll dir
  let filePath := dir / (s!"ADR_{a.id}.md")
  let contents := adrToMarkdown a
  FS.writeFile filePath contents

/-- Export a list of ADRs to the given base directory. -/
def exportADRs (ads : List ADR) (baseDir : FilePath) : IO Unit :=
  ads.forM (fun a => writeADR a baseDir)

end ADRExport
