import ADR.Export
import ADR.Examples


open ADR.Examples
open ADR.Export

def main : IO Unit := do
  IO.println "Exporting ADR-0022..."
  IO.println (generateMarkdown ADR0022)
