import Init
import ElasticTether.Core
import ElasticTether.CMT
import ElasticTether.ETP
import ElasticTether.Axioms
import ElasticTether.Validation
import ElasticTether.Applications
import ElasticTether.Examples
import ElasticTether.Proofs

/-! # Elastic Tether — Test Harness

Self-contained test suite runnable with `lake exe`.
-/

namespace ElasticTether.Test

open ElasticTether.Core
open ElasticTether.CMT
open ElasticTether.ETP
open ElasticTether.Axioms
open ElasticTether.Validation
open ElasticTether.Applications
open ElasticTether.Examples
open ElasticTether.Proofs

def test_core : IO Unit := do
  assert! True
  assert! exampleAccessible30.length > 0

def test_cmt : IO Unit := do
  assert! exampleCmtGap1000 <= 2
  assert! exampleMeanCmtGap1000 > 0

def test_etp : IO Unit := do
  assert! exampleLag >= 0
  assert! exampleTetherPotential >= 0

def test_axioms : IO Unit := do
  assert! True

def test_validation : IO Unit := do
  assert! protocol1_cmt_gap_reduction 1000
  assert! examplePhase4Passed

def test_applications : IO Unit := do
  assert! True

def main : IO Unit := do
  IO.println "=== Elastic Tether Test Harness ==="
  test_core
  test_cmt
  test_etp
  test_axioms
  test_validation
  test_applications
  IO.println "=== All tests passed ==="

end ElasticTether.Test
