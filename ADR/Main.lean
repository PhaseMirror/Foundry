import ADR.Export
import ADR.Examples


open ADR.Examples.Governance
open ADR.Export

def main : IO Unit := do
  for adr in unifiedADRList do
    IO.println (adrToMarkdown adr)
    IO.FS.writeFile (FilePath.mk "docs/adr" / s!"{adr.id}.md") (adrToMarkdown adr)
  IO.println s!"Exported {unifiedADRList.length} ADRs to docs/adr/"
