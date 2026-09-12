import ADR0035.Core
import ADR0035.LayerBGate
import ADR0035.Proofs
import ADR0035.Examples

/-!
# ADR0035.Test

Self-contained executable test suite for ADR-0035 formal invariants.
-/

namespace ADR0035

def runTests : IO UInt32 := do
  IO.println "============================================================"
  IO.println "  ADR-0035: GLOBAL RESEARCH PLATFORM FORMAL TEST HARNESS    "
  IO.println "============================================================"

  let mut passed : Nat := 0
  let mut failed : Nat := 0

  let st0 := defaultInitialState

  -- Test 1: Layer B missing forces fail-closed minting
  let mintRes1 := attemptPublicMint st0 sampleMSCCert
  if mintRes1 == none then
    IO.println "  [PASS] Test 1: attemptPublicMint rejected fail-closed (Layer B missing)"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 1: attemptPublicMint did not fail closed on missing Layer B"
    failed := failed + 1

  -- Test 2: Unratified Layer B tag forces fail-closed minting
  let stUnratified := { st0 with layerBTag := some sampleUnratifiedTag }
  let mintRes2 := attemptPublicMint stUnratified sampleMSCCert
  if mintRes2 == none then
    IO.println "  [PASS] Test 2: attemptPublicMint rejected fail-closed (Layer B unratified)"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 2: attemptPublicMint authorized an unratified Layer B tag"
    failed := failed + 1

  -- Test 3: Local verification generates private witness only
  let (stLocal, witness) := localVerificationStep st0 "42904c3c..." "e3b0c442..."
  if witness.isPrivateOnly && witness.witnessId == 1 then
    IO.println "  [PASS] Test 3: Local verification generated PrivateWitness (isPrivateOnly=true)"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 3: Local verification produced non-private witness"
    failed := failed + 1

  -- Test 4: Local verification preserves zero token count
  if stLocal.tokensMintedCount == 0 then
    IO.println "  [PASS] Test 4: Local verification preserved zero minted token invariant"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 4: Local verification incremented token count"
    failed := failed + 1

  -- Test 5: Verification service inactive without Layer B
  let stService := attemptActivateVerificationService st0
  if !stService.isPublicVerificationActive then
    IO.println "  [PASS] Test 5: Public verification service remains inactive (fail-closed)"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 5: Public verification service activated without Layer B"
    failed := failed + 1

  -- Test 6: FeMoco 69 qudit envelope and production mode lock preserved
  if stLocal.femocoQuditEnvelope == 69 && stLocal.isProductionModeLocked then
    IO.println "  [PASS] Test 6: Production Mode Lock & FeMoco 69-qudit envelope preserved"
    passed := passed + 1
  else
    IO.println "  [FAIL] Test 6: FeMoco envelope or mode lock corrupted"
    failed := failed + 1

  IO.println "============================================================"
  IO.println s!"  TOTAL: {passed} PASSED, {failed} FAILED"
  IO.println "============================================================"

  if failed == 0 then
    return 0
  else
    return 1

end ADR0035
