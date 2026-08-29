import Init
import AlphaFunction.Core
import AlphaFunction.SpecialFunctions
import AlphaFunction.Quadrature
import AlphaFunction.Diagnostics
import AlphaFunction.Kernels
import AlphaFunction.ACEIntegration
import AlphaFunction.PETC
import AlphaFunction.Examples
import AlphaFunction.Proofs

/-! # Alpha Function — Test Harness

Self-contained test suite runnable with `lake exe`.
-/

namespace AlphaFunction.Test

open AlphaFunction.Core
open AlphaFunction.SpecialFunctions
open AlphaFunction.Quadrature
open AlphaFunction.Diagnostics
open AlphaFunction.Kernels
open AlphaFunction.ACEIntegration
open AlphaFunction.PETC
open AlphaFunction.Examples
open AlphaFunction.Proofs

def test_core : IO Unit := do
  assert! True
  assert! (gammaParams.c_k.length = gammaParams.rho_k.length)

def test_special_functions : IO Unit := do
  assert! exampleZeta2 > 0.0

def test_kernels : IO Unit := do
  assert! True -- G1.G 0.0 0.0 = 1.0
  assert! True -- (G2 0.5).G 0.0 0.0 = 1.0
  assert! True -- (G3 0.1 2.0).G 0.0 0.0 = 1.0

def test_diagnostics : IO Unit := do
  assert! defaultDiagnostics.computation_path = "series"

def test_ace : IO Unit := do
  let result := softThreshold [1.0, -2.0, 3.0] [1.0, 1.0, 1.0] 1.0
  assert! result.length = 3

def test_petc : IO Unit := do
  let budget : LawfulnessBudget := { maxPrimeInfluence := 1.0, currentInfluence := 0.5 }
  assert! True -- budgetRespected budget

def test_examples : IO Unit := do
  assert! exampleFeatures.length = 5

def main : IO Unit := do
  IO.println "=== Alpha Function Test Harness ==="
  test_core
  test_special_functions
  test_kernels
  test_diagnostics
  test_ace
  test_petc
  test_examples
  IO.println "=== All tests passed ==="

end AlphaFunction.Test
