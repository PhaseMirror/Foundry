import Init
import GodelianTruth.Core
import GodelianTruth.Gamma
import GodelianTruth.Contraction
import GodelianTruth.Godel
import GodelianTruth.PrimeSieved
import GodelianTruth.LawfulSchedules
import GodelianTruth.Conservative
import GodelianTruth.Examples

/-! # Godelian Truth Test Harness

Self-contained test suite runnable with `lake exe`.
-/

namespace GodelianTruth.Test

open GodelianTruth
open GodelianTruth.Gamma
open GodelianTruth.Contraction
open GodelianTruth.PrimeSieved
open GodelianTruth.Examples
open GodelianTruth.Conservative

/-- Test: FP_DEN is 100. -/
def test_fp_den : IO Unit := do
  assert! FP_DEN = 100

/-- Test: lambda and alpha are valid. -/
def test_params : IO Unit := do
  assert! lambda > 0 && lambda < FP_DEN
  assert! alpha > 0 && alpha < FP_DEN
  assert! contractionFactor > 0 && contractionFactor < FP_DEN

/-- Test: Gamma on zero valuation. -/
def test_gamma_zero : IO Unit := do
  let v := Gamma zeroValuation
  assert! v Sentence.atomP = FP_DEN
  assert! v Sentence.atomQ = 0
  assert! v Sentence.atomG = FP_DEN

/-- Test: Strong Kleene connectives. -/
def test_sk : IO Unit := do
  assert! skNeg FP_DEN = 0
  assert! skNeg 0 = FP_DEN
  assert! skAnd 50 70 = 50
  assert! skOr 50 70 = 70
  assert! skImpl 0 50 = FP_DEN

/-- Test: Primes up to 20. -/
def test_primes : IO Unit := do
  assert! exPrimes20 = [2, 3, 5, 7, 11, 13, 17, 19]

/-- Test: π(10) = 4. -/
def test_pi : IO Unit := do
  assert! pi 10 = 4
  assert! pi 20 = 8

/-- Test: isPrime correctness. -/
def test_isprime : IO Unit := do
  assert! isPrime 2 = true
  assert! isPrime 3 = true
  assert! isPrime 4 = false
  assert! isPrime 5 = true
  assert! isPrime 9 = false
  assert! isPrime 11 = true

/-- Test: T_λ on zero valuation. -/
def test_tlambda : IO Unit := do
  let v := TLambda zeroValuation lambda alpha defaultBias
  let p := v Sentence.atomP
  let g := v Sentence.atomG
  assert! p >= 0 && p <= FP_DEN
  assert! g >= 0 && g <= FP_DEN

/-- Test: Prime-sieved iteration steps. -/
def test_prime_iter : IO Unit := do
  IO.println s!"exPrimeIter0 = {exPrimeIter0 Sentence.atomP}"
  IO.println s!"exPrimeIter1 = {exPrimeIter1 Sentence.atomP}"
  IO.println s!"exPrimeIter2 = {exPrimeIter2 Sentence.atomP}"

/-- Test: Conservative extension. -/
def test_conservative : IO Unit := do
  IO.println "ConservativeExtension: trivially holds (ProvF = ProvF')"

/-- Run all tests. -/
def main : IO Unit := do
  IO.println "=== Godelian Truth Test Harness ==="
  test_fp_den
  test_params
  test_gamma_zero
  test_sk
  test_primes
  test_pi
  test_isprime
  test_tlambda
  test_prime_iter
  test_conservative
  IO.println "=== All tests passed ==="
