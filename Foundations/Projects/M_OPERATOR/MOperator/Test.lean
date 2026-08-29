import MOperator.Core
import MOperator.Algebra
import MOperator.CSLDynamics
import MOperator.Proofs
import MOperator.Examples

/-! # MOperator.Test

Executable test harness for the Multiplicity Operator formalization suite.
Verifies all mathematical invariants with comprehensive diagnostics.
-/

namespace MOperator

def runAllTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "  THE MULTIPLICITY OPERATOR (M) TEST HARNESS (LEAN 4)       "
  IO.println "============================================================"

  let mut passed : Nat := 0
  let mut failed : Nat := 0

  -- Test 1: Multiplicity Constants Verification
  if PHI_FP == 1618 && LAMBDA_M_FP == 618 && DELTA_I_FP == 382 then
    IO.println "  [PASS] Test 1: Fundamental constants (Phi=1.618, Lambda_m=0.618, Delta_I=0.382) verified"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 1: Fundamental constants mismatch"
    failed := failed + 1

  -- Test 2: Drift Zero at Fixed Point Target
  let d0 := vectorDistSq phiVector phiVector
  if d0 == 0 then
    IO.println "  [PASS] Test 2: Ethical drift at Phi fixed point is identically zero"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 2: Drift at target was {d0}"
    failed := failed + 1

  -- Test 3: Cubic Repair Operator Vanishing at Target
  let repair := cubicRepairVector phiVector phiVector 500
  if repair == zeroVector then
    IO.println "  [PASS] Test 3: Cubic repair restoring force vanishes at target equilibrium"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 3: Cubic repair non-zero at target"
    failed := failed + 1

  -- Test 4: Linear Repair Operator Vanishing at Target
  let linRepair := linearRepairVector phiVector phiVector 500
  if linRepair == zeroVector then
    IO.println "  [PASS] Test 4: Linear repair restoring force vanishes at target equilibrium"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 4: Linear repair non-zero at target"
    failed := failed + 1

  -- Test 5: Single CSL Step Monotonic Clock
  let st0 := initialPerturbedState
  let st1 := cslStepCubic st0 phiVector 300
  if st1.time == st0.time + 1 && st1.position != st0.position then
    IO.println s!"  [PASS] Test 5: CSL Step advanced clock to {st1.time} and updated state point lawfully"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 5: CSL step time or state update failure"
    failed := failed + 1

  -- Test 6: Bounding Domain Clamping Invariant
  let largeVec : MVector3 := ⟨15000, -20000, 30000⟩
  let clamped := clampVector largeVec (10 * Int.ofNat FP_DEN)
  if clamped.x == 10000 && clamped.y == -10000 && clamped.z == 10000 then
    IO.println "  [PASS] Test 6: Absorbing domain clamp confines coordinates strictly within [-10, 10]"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 6: Clamping invariant violation"
    failed := failed + 1

  -- Test 7: Quantum Bayesian Update Posterior Normalization
  let pPost := quantumBayesianUpdate 300 600
  if pPost == 500 then -- 300 / 600 = 0.500 -> 500 in fixed point
    IO.println s!"  [PASS] Test 7: Quantum Bayesian update normalized posterior correctly: {pPost}/1000"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 7: Bayesian update failed: {pPost}"
    failed := failed + 1

  -- Test 8: Prime-Indexed Transformation Operator Evaluation
  let mVal := 1000 -- M = 1.000
  let p7_eval := evaluateMOperator mVal 7 100 0
  let p11_eval := evaluateMOperator mVal 11 100 0
  if p11_eval > p7_eval && p7_eval > 7000 then
    IO.println s!"  [PASS] Test 8: Prime transformation operator evaluated (p=7: {p7_eval}, p=11: {p11_eval})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 8: Prime operator evaluation error"
    failed := failed + 1

  -- Test 9: Multi-Step CSL Simulation Boundedness (20 steps)
  let (finalSt, hist) := runCSLSimulation 20
  if finalSt.time == 20 && hist.length == 20 && finalSt.position.x > 0 then
    IO.println s!"  [PASS] Test 9: 20-step CSL simulation completed stably (Final Drift: {finalSt.drift})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 9: CSL simulation failed"
    failed := failed + 1

  -- Test 10: Non-Linear Regularization Boundedness
  let rnl100 := nonlinearRegularization 10000 ALPHA_NL_FP
  if rnl100 <= ALPHA_NL_FP && rnl100 >= 0 then
    IO.println s!"  [PASS] Test 10: Non-linear regularization R_nl bounded by alpha ({rnl100} <= {ALPHA_NL_FP})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 10: Non-linear regularization bound violation"
    failed := failed + 1

  IO.println "============================================================"
  IO.println s!"  TOTAL: {passed} PASSED, {failed} FAILED"
  IO.println "============================================================"

  if failed == 0 then return 0 else return 1

end MOperator
