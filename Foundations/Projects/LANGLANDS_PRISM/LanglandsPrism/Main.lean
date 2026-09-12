import Init
import LanglandsPrism.Core
import LanglandsPrism.TensorCascade
import LanglandsPrism.GaloisEntanglement
import LanglandsPrism.Stabilization
import LanglandsPrism.MARCL
import LanglandsPrism.Firewall
import LanglandsPrism.Proofs
import LanglandsPrism.Examples
import LanglandsPrism.Export
import LanglandsPrism.Test

/-! # LanglandsPrism.Main

Executable entry point for the Langlands Prism Lean 4 verification suite.
Runs all unit and property tests, and exports markdown reports.
-/

def main : IO UInt32 := do
  let exitCode ← LanglandsPrism.runAllTests
  if exitCode == 0 then
    LanglandsPrism.exportReportToFile "LanglandsPrism_Report.md"
  return exitCode
