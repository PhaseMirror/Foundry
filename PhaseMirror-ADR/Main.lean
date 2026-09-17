import ADR.Export
import ADR.Examples

open ADR.Export
open ADR.Examples

def main : IO Unit := do
  IO.println "Exporting verified ADRs..."
  let docsDir := "docs"
  
  -- Example writing the Markdown for ADR 1 to standard out (or a file in practice)
  let adr1Md := toMarkdown adr1
  IO.println "-----------------"
  IO.println adr1Md
  
  let adr4Md := toMarkdown adr4
  IO.println "-----------------"
  IO.println adr4Md
  
  IO.println "-----------------"
  IO.println "Export complete."
