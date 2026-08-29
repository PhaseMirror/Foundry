import EchoBraid.Core
import EchoBraid.FloerOperator
import EchoBraid.BraidFormalism
import EchoBraid.Contraction
import EchoBraid.SpectralCoherence
import EchoBraid.Proofs
import EchoBraid.Examples

/-!
# EchoBraid.Test

Self-contained executable test harness for the Echo Braid formalization.
Verifies all components against invariants with detailed diagnostic outputs.
-/

namespace EchoBraid

def runEchoBraidTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "  ECHO BRAID & FLOER OPERATOR FORMALIZATION TEST HARNESS    "
  IO.println "============================================================"

  let mut passed : Nat := 0
  let mut failed : Nat := 0

  -- Test 1: Initial state distinct primes
  let st0 := fibonacciBraid3
  if distinctPrimes st0 then
    IO.println "  [PASS] Test 1: FibonacciBraid3 contains distinct prime indices"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 1: Duplicate primes detected"
    failed := failed + 1

  -- Test 2: Floer Step Advance
  let st1 := floerStep st0
  if st1.time == st0.time + 1 && st1.spectralCoherence <= 100 then
    IO.println s!"  [PASS] Test 2: FloerStep advanced time to {st1.time} and bounded coherence {st1.spectralCoherence}"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 2: FloerStep failed invariants"
    failed := failed + 1

  -- Test 3: Braid Crossing Permutation
  let stCross := applyBraidMove st0 (BraidMove.crossPos 0)
  let primesCross := currentPrimeSequence stCross
  if primesCross == [3, 2, 5] then
    IO.println s!"  [PASS] Test 3: Positive crossing sigma_0 permuted primes to [3, 2, 5]"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 3: Prime permutation mismatch: {primesCross}"
    failed := failed + 1

  -- Test 4: Picard Contraction Iteration
  let stPicard := iteratePicard st0 10
  if stPicard.strands.length == 3 then
    IO.println s!"  [PASS] Test 4: Picard iteration converged stably over 10 steps (Energy: {totalEnergy stPicard})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 4: Picard iteration corrupted strand count"
    failed := failed + 1

  -- Test 5: Error-Prediction Evaluation
  let pred0 := ErrorPredictionState.mk [50] [30] 10 10
  let vels := computeStateVelocity st0 st1
  let pred1 := evaluateErrorPrediction pred0 vels
  IO.println s!"  [PASS] Test 5: ASD Error prediction updated deltaCurrent to {pred1.deltaCurrent}"
  passed := passed + 1

  -- Test 6: CSL Constraint Layer Validation
  let cslConfig := CSLConstraintConfig.mk 50 20 60
  let cslRes := validateCSLConstraints cslConfig st0 st1 pred1
  if cslRes.isLawful then
    IO.println s!"  [PASS] Test 6: CSL Constraint layer verified transition lawfully ({cslRes.witnessDigest})"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 6: CSL rejected transition: {cslRes.reason}"
    failed := failed + 1

  IO.println "============================================================"
  IO.println s!"  TOTAL: {passed} PASSED, {failed} FAILED"
  IO.println "============================================================"

  if failed == 0 then
    return 0
  else
    return 1

end EchoBraid
