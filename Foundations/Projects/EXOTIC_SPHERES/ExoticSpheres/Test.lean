import Init
import ExoticSpheres.Core
import ExoticSpheres.Plumbing
import ExoticSpheres.Brieskorn
import ExoticSpheres.Kernel
import ExoticSpheres.Multiplicity
import ExoticSpheres.Graded
import ExoticSpheres.Invariants
import ExoticSpheres.Knots
import ExoticSpheres.Examples
import ExoticSpheres.Proofs

/-! # Exotic Spheres — Test Harness

Self-contained test suite runnable with `lake exe`.
-/

namespace ExoticSpheres.Test

open ExoticSpheres.Core
open ExoticSpheres.Plumbing
open ExoticSpheres.Brieskorn
open ExoticSpheres.Kernel
open ExoticSpheres.Multiplicity
open ExoticSpheres.Graded
open ExoticSpheres.Invariants
open ExoticSpheres.Knots
open ExoticSpheres.Examples
open ExoticSpheres.Proofs

def test_core : IO Unit := do
  assert! (sievePrimes 2).contains 2
  assert! (sievePrimes 3).contains 3
  assert! !(sievePrimes 4).contains 4

def test_plumbing : IO Unit := do
  assert! exampleCanonical5.vertexWeights.length > 0
  assert! exampleCanonical7.vertexWeights.length > 0

def test_brieskorn : IO Unit := do
  assert! validBrieskorn23 5
  assert! validBrieskorn23 7
  assert! eellsKuiper23 7 = 8

def test_kernel : IO Unit := do
  assert! exampleKernel5.smoothScalar >= 0
  assert! exampleKernel7.smoothScalar >= 0

def test_multiplicity : IO Unit := do
  assert! exampleM5.size = exampleCanonical5.vertexWeights.length + 1
  assert! exampleM7.size = exampleCanonical7.vertexWeights.length + 1

def test_graded : IO Unit := do
  assert! exampleGraded5_2_1.length > 0

def test_invariants : IO Unit := do
  assert! exampleFingerprint5.length > 0

def test_knots : IO Unit := do
  assert! skeinRelation 1 2 3 = -1

def main : IO Unit := do
  IO.println "=== Exotic Spheres Test Harness ==="
  test_core
  test_plumbing
  test_brieskorn
  test_kernel
  test_multiplicity
  test_graded
  test_invariants
  test_knots
  IO.println "=== All tests passed ==="

end ExoticSpheres.Test
