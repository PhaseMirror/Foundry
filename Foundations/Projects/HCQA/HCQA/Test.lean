import Init
import HCQA.Core
import HCQA.Qudit
import HCQA.MAVQE
import HCQA.HSEC
import HCQA.QCFI
import HCQA.M3A
import HCQA.Hardware
import HCQA.Examples
import HCQA.Proofs

/-! # HCQA — Test Harness

Self-contained test suite runnable with `lake exe`.
-/

namespace HCQA.Test

open HCQA.Core
open HCQA.Qudit
open HCQA.MAVQE
open HCQA.HSEC
open HCQA.QCFI
open HCQA.M3A
open HCQA.Hardware
open HCQA.Examples
open HCQA.Proofs

def test_core : IO Unit := do
  assert! sr87Dim = 38
  assert! yb171Dim = 6

def test_qudit : IO Unit := do
  assert! compressionFactor 20 > 1.0
  assert! physicalQudits 20 20 = 10

def test_mavqe : IO Unit := do
  assert! exampleMAVQE.theta.length > 0

def test_hsec : IO Unit := do
  assert! sr87Encoding.synLevels > 0
  assert! overheadRatio 20 16 2 > 0.0

def test_qcfi : IO Unit := do
  assert! exampleQCFI.shotCount > 0

def test_m3a : IO Unit := do
  assert! exampleModule.modType matches ModuleType.computational sr87 6

def test_hardware : IO Unit := do
  assert! exampleHardware.readoutFidelity > 0.99

def main : IO Unit := do
  IO.println "=== HCQA Test Harness ==="
  test_core
  test_qudit
  test_mavqe
  test_hsec
  test_qcfi
  test_m3a
  test_hardware
  IO.println "=== All tests passed ==="

end HCQA.Test
