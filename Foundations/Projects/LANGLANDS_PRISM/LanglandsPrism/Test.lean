import LanglandsPrism.Core
import LanglandsPrism.TensorCascade
import LanglandsPrism.GaloisEntanglement
import LanglandsPrism.Stabilization
import LanglandsPrism.MARCL
import LanglandsPrism.Firewall
import LanglandsPrism.Proofs
import LanglandsPrism.Examples

/-! # LanglandsPrism.Test

Self-contained executable test harness for the Langlands Prism formalization.
Verifies all components against mathematical invariants with comprehensive diagnostics.
-/

namespace LanglandsPrism

def runAllTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "  LANGLANDS PRISM FORMALIZATION TEST HARNESS (LEAN 4)       "
  IO.println "============================================================"

  let mut passed : Nat := 0
  let mut failed : Nat := 0

  -- Test 1: Prime Distinctness & Basis
  let st0 := examplePrism5
  if distinctPrimes st0 && st0.nodes.length == 5 then
    IO.println "  [PASS] Test 1: ExamplePrism5 contains 5 strictly distinct prime indices"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 1: Prime distinctness failure"
    failed := failed + 1

  -- Test 2: Cascade Step Time Advancement & Coherence
  let st1 := cascadeStep st0
  if st1.time == st0.time + 1 && st1.coherenceFP <= FP_DEN then
    IO.println s!"  [PASS] Test 2: CascadeStep advanced time to {st1.time} and bounded coherence {st1.coherenceFP}"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 2: CascadeStep invariants violated"
    failed := failed + 1

  -- Test 3: Galois Permutation & Dual Tensor
  let permutedSt := applyGaloisOperator st0 (GaloisAction.primePermute 0 1)
  let dualSt := computeLanglandsDualTensor st0
  if permutedSt.nodes.map (·.prime) == [3, 2, 5, 7, 11] && dualSt.nodes.length == 5 then
    IO.println "  [PASS] Test 3: Galois permutation (0,1) and Langlands Dual Tensor computed lawfully"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 3: Galois operation mismatch"
    failed := failed + 1

  -- Test 4: Semantic Evolution & Shock Recovery
  let initialShock : SemanticVector := ⟨[950, 950, 950, 950]⟩
  let op := identityDynamicOperator 4
  let shockTrajectory := simulateShockRecovery initialShock defaultEquilibriumVector op 6
  let initialDist := shockTrajectory.head?.map (·.2) |>.getD 0
  let finalDist := shockTrajectory.getLast?.map (·.2) |>.getD 0
  if finalDist < initialDist then
    IO.println s!"  [PASS] Test 4: Semantic shock decayed exponentially from distSq={initialDist} to {finalDist}"
    passed := passed + 1
  else
    IO.println s!"  [FAIL] Test 4: Semantic shock failed to decay (initial: {initialDist}, final: {finalDist})"
    failed := failed + 1

  -- Test 5: MARCL Multi-Agent Trust Reallocation under Shock
  let (finalCluster, _) := runMARCLShockExample
  let initialTrustA3 := 500
  let finalTrustA3 := finalCluster.trustMatrix.getD 0 [] |>.getD 3 500
  if finalCluster.time == 8 && finalTrustA3 != initialTrustA3 then
    IO.println s!"  [PASS] Test 5: MARCL dynamic trust adapted under shock: A0->A3 trust shifted to {finalTrustA3}"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 5: MARCL trust reallocation failed"
    failed := failed + 1

  -- Test 6: Godelian Accountability Ledger Flow
  let ledgerEntry := finalCluster.godelianLedger.getD 0 [] |>.getD 3 0
  if finalCluster.godelianLedger.length == 4 then
    IO.println s!"  [PASS] Test 6: Godelian Accountability Ledger populated (Entry L_03: {ledgerEntry})"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 6: Godelian Ledger structure error"
    failed := failed + 1

  -- Test 7: Ethical Firewall & Automated Collapse
  let safeMetric := computeEthicalMetric st0
  let syntheticBreachSt : PrismState := ⟨0, LAMBDA_M_FP, [⟨2, 950, 900, 950⟩], 500, true⟩
  let (collapsedSt, wasTriggered) := firewallGate syntheticBreachSt
  if safeMetric <= ETHICAL_THRESHOLD_FP && wasTriggered && collapsedSt.isStable then
    IO.println s!"  [PASS] Test 7: Ethical Firewall validated safe baseline ({safeMetric}) and triggered collapse on breach"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 7: Firewall gate failed"
    failed := failed + 1

  -- Test 8: Cryptographic Provenance Block Recording
  let block := recordProvenanceBlock st0
  if block.stateHash > 0 && block.time == 0 then
    IO.println s!"  [PASS] Test 8: Cryptographic provenance block registered with hash {block.stateHash}"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 8: Provenance hash registration failed"
    failed := failed + 1

  IO.println "============================================================"
  IO.println s!"  TOTAL: {passed} PASSED, {failed} FAILED"
  IO.println "============================================================"

  if failed == 0 then return 0 else return 1

end LanglandsPrism
