import Init
import MOperator.Core
import MOperator.Algebra
import MOperator.CSLDynamics
import MOperator.Proofs
import MOperator.Examples
import MOperator.Export
import MOperator.Test

/-! # MOperator.Main

Executable entry point for the Multiplicity Operator Lean 4 formalization test harness.
Runs all tests and exports formal verification reports.
-/

def main : IO UInt32 := do
  let exitCode ← MOperator.runAllTests
  if exitCode == 0 then
    MOperator.exportReportToFile "MOperator_Report.md"
  return exitCode
