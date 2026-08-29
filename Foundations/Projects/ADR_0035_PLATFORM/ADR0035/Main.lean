import ADR0035.Test
import ADR0035.Export

def main : IO UInt32 := do
  let exitCode ← ADR0035.runTests
  if exitCode == 0 then
    ADR0035.exportDocumentation
  return exitCode
