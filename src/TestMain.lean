import ADR.Test
import ComplexKappa.Test

/-!
This module serves as the entry point for the `test` executable.
-/

def main : IO Unit := do
  IO.println "All tests compiled successfully."
  IO.println "✓ ComplexKappa.Test compiled."
