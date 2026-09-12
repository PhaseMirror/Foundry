import ADR0035.Core
import ADR0035.Examples

/-!
# ADR0035.Export

Generates human-readable Markdown and HTML documentation from the formal ADR model.
-/

namespace ADR0035

/-- Render an ADR status as a string badge -/
def renderStatus (s : ADRStatus) : String :=
  match s with
  | ADRStatus.Proposed   => "**Proposed**"
  | ADRStatus.Accepted   => "**Accepted (Blocked on Layer B)**"
  | ADRStatus.Deprecated => "**Deprecated**"
  | ADRStatus.Superseded => "**Superseded**"

/-- Render an ADR structure to Markdown -/
def renderADRToMarkdown (adr : ADR) : String :=
  s!"# ADR-{adr.id}: {adr.title}

- **Status:** {renderStatus adr.status}
- **Layer B Gated:** {if adr.isLayerBGated then "Yes (Strict Fail-Closed)" else "No"}

## Context
{adr.context}

## Decision
{adr.decision}

## Consequences
" ++ String.join (adr.consequences.map (fun c => s!"- {c}\n")) ++ "
## Artifact Links
" ++ String.join (adr.links.map (fun l => s!"- [{l.label}]({l.uri})\n"))

/-- Export Markdown and HTML artifacts to disk -/
def exportDocumentation : IO Unit := do
  let doc := renderADRToMarkdown sampleADR035
  IO.FS.writeFile "ADR-0035-Generated.md" doc
  IO.println "[+] Exported formal ADR-0035 Markdown documentation to ADR-0035-Generated.md"

end ADR0035
