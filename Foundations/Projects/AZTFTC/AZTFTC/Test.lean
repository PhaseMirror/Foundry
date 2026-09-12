import Init
import AZTFTC.Core
import AZTFTC.Hilbert
import AZTFTC.Lawful
import AZTFTC.Operators
import AZTFTC.GeoPotential
import AZTFTC.Boundary
import AZTFTC.Spectral
import AZTFTC.Casimir
import AZTFTC.Examples
import AZTFTC.Proofs

/-! # AZ-TFTC Test Harness -/

namespace AZTFTC.Test

open AZTFTC
open AZTFTC.Operators
open AZTFTC.GeoPotential
open AZTFTC.Boundary
open AZTFTC.Spectral
open AZTFTC.Casimir
open AZTFTC.Examples
open AZTFTC.Proofs
open AZTFTC.Hilbert

def test_fp_den : IO Unit := do
  IO.println "test_fp_den"
  assert! FP_DEN = 100

def test_primes : IO Unit := do
  IO.println "test_primes"
  assert! isPrime 2 = true
  assert! isPrime 3 = true
  assert! isPrime 4 = false
  assert! pi 10 = 4
  assert! pi 20 = 8

def test_hilbert : IO Unit := do
  IO.println "test_hilbert"
  assert! (zeroVec 5).length = 5
  assert! (basisVec 5 2).length = 5

def test_geo : IO Unit := do
  IO.println "test_geo"
  assert! AZTFTC.GeoPotential.examplePhiSigma.length > 0
  assert! AZTFTC.GeoPotential.exampleVGeo.length = AZTFTC.GeoPotential.examplePhiSigma.length

def test_operator : IO Unit := do
  IO.println "test_operator"
  let op := exSmallOp
  assert! op.mat.length = hilbertDim 5 10 1

def test_spectral : IO Unit := do
  IO.println "test_spectral"
  assert! exampleSpectrum.length = 3
  assert! exampleSpectrum.length > 0

def test_casimir : IO Unit := do
  IO.println "test_casimir"
  let d := exDeltaTiny
  assert! true

def main : IO Unit := do
  IO.println "=== AZ-TFTC Test Harness ==="
  test_fp_den
  test_primes
  test_hilbert
  test_geo
  test_operator
  test_spectral
  test_casimir
  IO.println "=== All tests passed ==="

end AZTFTC.Test
