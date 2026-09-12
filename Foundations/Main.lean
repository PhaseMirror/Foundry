// Main.lean – entry point for lake_exe test
import Foundations.ADR.Test

open ADR

def runTests : IO Unit := do
  Test.runTests

#eval runTests
