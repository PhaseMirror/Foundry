import Init
import LorenzAttractor.Core
import LorenzAttractor.Dynamics
import LorenzAttractor.FeedbackTensor
import LorenzAttractor.Proofs
import LorenzAttractor.Examples
import LorenzAttractor.Export
import LorenzAttractor.Test

/-! # LorenzAttractor.Main

Executable entry point for the Multiplicity-Enhanced Lorenz Attractor Lean 4 verification suite.
Runs all unit and property tests, and exports markdown reports.
-/

def main : IO UInt32 := do
  let exitCode ← LorenzAttractor.runAllTests
  if exitCode == 0 then
    LorenzAttractor.exportReportToFile "LorenzAttractor_Report.md"
  return exitCode
