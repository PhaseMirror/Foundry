import ADR.Export
import ADR.Examples


open ADR.Examples
open ADR.Export

/-- Canonical human-readable output directory for the verified ADR set. -/
def docsDir : System.FilePath := System.FilePath.mk "docs" / "adr"

/-- `adrExport`: regenerate `docs/adr/{README.md,registry.json,<id>.{md,html,json}}`
from the machine-checked `unifiedRegistry`. Deterministic; safe to run in CI. -/
def main : IO Unit := do
  exportADRSet unifiedRegistry docsDir
  IO.println s!"Exported {unifiedRegistry.adrs.length} ADRs to {docsDir}"