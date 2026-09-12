import LorenzAttractor.Core
import LorenzAttractor.Dynamics
import LorenzAttractor.FeedbackTensor
import LorenzAttractor.Proofs
import LorenzAttractor.Examples

/-! # LorenzAttractor.Test

Self-contained executable test harness for the Multiplicity-Enhanced Lorenz Attractor.
Verifies all mathematical invariants with comprehensive diagnostics.
-/

namespace LorenzAttractor

def runAllTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "  LORENZ ATTRACTOR FORMALIZATION TEST HARNESS (LEAN 4)      "
  IO.println "============================================================"

  let mut passed : Nat := 0
  let mut failed : Nat := 0

  -- Test 1: Parameter Conversion & Prime Encoding
  let pPrime := primeParams7_29_3
  let lParams := primeToLorenzParams pPrime
  if lParams.sigma == 7000 && lParams.rho == 29000 && lParams.betaNum == 3000 then
    IO.println "  [PASS] Test 1: Prime parameters (7, 29, 3) converted to fixed-point lawfully"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 1: Prime parameter conversion mismatch"
    failed := failed + 1

  -- Test 2: Theoretical Jacobian Trace Negativity
  let trCanon := theoreticalTrace canonicalParams
  let trPrime := theoreticalTrace lParams
  if trCanon < 0 && trPrime < 0 then
    IO.println s!"  [PASS] Test 2: Jacobian Trace is strictly negative (Canon: {trCanon}, Prime: {trPrime})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 2: Jacobian trace positivity detected"
    failed := failed + 1

  -- Test 3: Classical Velocity Evaluation at (1, 1, 1)
  let v0 := lorenzVelocity initialPoint111 canonicalParams
  if v0.x == 0 && v0.y > 0 && v0.z < 0 then
    IO.println s!"  [PASS] Test 3: Initial velocity at (1,1,1) matches Lorenz vector field: (dx={v0.x}, dy={v0.y}, dz={v0.z})"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 3: Classical velocity error: (dx={v0.x}, dy={v0.y}, dz={v0.z})"
    failed := failed + 1

  -- Test 4: Origin Stationary Equilibrium Invariant
  let vOrigin := lorenzVelocity ⟨0, 0, 0⟩ canonicalParams
  if vOrigin.x == 0 && vOrigin.y == 0 && vOrigin.z == 0 then
    IO.println "  [PASS] Test 4: Origin (0,0,0) is stationary equilibrium point (v=0)"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 4: Origin velocity non-zero: ({vOrigin.x}, {vOrigin.y}, {vOrigin.z})"
    failed := failed + 1

  -- Test 5: Tensor Coupling & Harmonic Oscillator
  let tensor := computeTensorCoupling initialPoint111
  let harmonic := computeHarmonicFeedback 0
  if tensor.tx >= 0 && harmonic.x != 0 then
    IO.println "  [PASS] Test 5: Tensor network interaction and harmonic feedback terms computed lawfully"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 5: Tensor coupling error"
    failed := failed + 1

  -- Test 6: Unified Step Monotonic Clock & State Update
  let st0 := exampleCanonicalState
  let st1 := unifiedStep st0 canonicalParams 500
  if st1.time == st0.time + 1 && st1.point != st0.point then
    IO.println s!"  [PASS] Test 6: UnifiedStep advanced time to {st1.time} and updated state point lawfully"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 6: UnifiedStep time or state update failure"
    failed := failed + 1

  -- Test 7: Stability Functional Monotonicity S(t)
  if st1.stabilityIntegral >= st0.stabilityIntegral then
    IO.println s!"  [PASS] Test 7: Stability functional S(t) increased monotonically (S0={st0.stabilityIntegral} -> S1={st1.stabilityIntegral})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 7: Stability functional decreased"
    failed := failed + 1

  -- Test 8: Absorbing Ball Clamping Invariant
  let largePoint : LorenzPoint := ⟨150000, -200000, 300000⟩
  let clamped := clampPoint largePoint (100 * Int.ofNat FP_DEN)
  if clamped.x == 100000 && clamped.y == -100000 && clamped.z == 100000 then
    IO.println "  [PASS] Test 8: Absorbing ball clamp confines coordinates strictly within [-100, 100]"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 8: Clamping invariant violation"
    failed := failed + 1

  -- Test 9: Multi-Step Trajectory Boundedness (20 steps)
  let (finalSt, hist) := runStabilizedSimulation 20
  let normFinal := pointNormSq finalSt.point
  if finalSt.time == 20 && hist.length == 20 && normFinal < 10000000 then
    IO.println s!"  [PASS] Test 9: 20-step Multiplicity-stabilized trajectory remained strictly bounded (NormSq: {normFinal})"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 9: Trajectory diverged or failed step count: normSq={normFinal}"
    failed := failed + 1

  -- Test 10: Prime-Encoded Trajectory Non-Divergence
  let (finalPrimeSt, primeHist) := runPrimeSimulation 20
  let normPrime := pointNormSq finalPrimeSt.point
  if finalPrimeSt.time == 20 && primeHist.length == 20 && normPrime < 10000000 then
    IO.println s!"  [PASS] Test 10: Prime-encoded (7,29,3) trajectory evolved stably over 20 steps (NormSq: {normPrime})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 10: Prime trajectory error"
    failed := failed + 1

  IO.println "============================================================"
  IO.println s!"  TOTAL: {passed} PASSED, {failed} FAILED"
  IO.println "============================================================"

  if failed == 0 then return 0 else return 1

end LorenzAttractor
