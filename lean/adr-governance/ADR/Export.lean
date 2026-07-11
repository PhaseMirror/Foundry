import ADR.Examples

open ADR
open ADR.Examples

def generateMarkdown (adr : ADR) : String :=
  s!"# ADR {adr.id}: {adr.title}\n\n" ++
  s!"**Status:** {repr adr.status}\n\n" ++
  s!"## Context\n{adr.context}\n\n" ++
  s!"## Decision\n{adr.decision}\n\n" ++
  s!"## Consequences\n" ++
  String.join (adr.consequences.map (λ c => s!"- {c}\n"))

def main : IO Unit := do
  let md := generateMarkdown uacRustEngineADR
  IO.println "Generated Markdown for ADR 1:"
  IO.println "---"
  IO.println md
  IO.println "---"
