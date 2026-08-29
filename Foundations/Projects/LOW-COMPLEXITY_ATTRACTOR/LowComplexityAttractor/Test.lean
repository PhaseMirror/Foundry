import Init
import LowComplexityAttractor.Core
import LowComplexityAttractor.Dynamics
import LowComplexityAttractor.ACE
import LowComplexityAttractor.PETC
import LowComplexityAttractor.Metrics
import LowComplexityAttractor.Statistics
import LowComplexityAttractor.ZK
import LowComplexityAttractor.Examples
import LowComplexityAttractor.Proofs

/-! # Low-Complexity Attractor — Test Harness

Self-contained test suite runnable with `lake exe`.
-/

namespace LowComplexityAttractor.Test

open LowComplexityAttractor.Core
open LowComplexityAttractor.Dynamics
open LowComplexityAttractor.ACE
open LowComplexityAttractor.PETC
open LowComplexityAttractor.Metrics
open LowComplexityAttractor.Statistics
open LowComplexityAttractor.ZK
open LowComplexityAttractor.Examples
open LowComplexityAttractor.Proofs

def test_core : IO Unit := do
  assert! phi > 1.0
  assert! eulersE > 1.0

def test_dynamics : IO Unit := do
  assert! (cubicRepair exampleCubicParams exampleState3D).values.length = 3

def test_ace : IO Unit := do
  assert! isSafe exampleCert

def test_petc : IO Unit := do
  assert! exampleTensor.modes.length = 3

def test_metrics : IO Unit := do
  assert! meanDrift exampleTrajectory >= 0.0
  assert! shannonEntropy [0.5, 0.5] >= 0.0

def test_statistics : IO Unit := do
  assert! permutationTest [1.0, 2.0] [3.0, 4.0] 10 >= 0.0
  assert! (bootstrapCI [1.0, 2.0, 3.0] 100 0.05).1 >= 0.0

def test_zk : IO Unit := do
  assert! verifyProximity exampleWitness

def main : IO Unit := do
  IO.println "=== Low-Complexity Attractor Test Harness ==="
  test_core
  test_dynamics
  test_ace
  test_petc
  test_metrics
  test_statistics
  test_zk
  IO.println "=== All tests passed ==="

end LowComplexityAttractor.Test
