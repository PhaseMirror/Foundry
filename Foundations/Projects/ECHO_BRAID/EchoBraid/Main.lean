import EchoBraid.Test
import EchoBraid.Export

/-!
# EchoBraid.Main

Executable entry point for the Echo Braid formalization project.
Runs the complete test harness and generates Markdown export documentation.
-/

def main : IO UInt32 := do
  let exitCode ← EchoBraid.runEchoBraidTests
  if exitCode == 0 then
    EchoBraid.exportDocs
  return exitCode
