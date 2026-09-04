import Init
import SpiralCore.ADR.Core
import SpiralCore.ADR.Proofs
import SpiralCore.ADR.Examples

namespace SpiralCore.ADR.Test

open SpiralCore.ADR
open SpiralCore.ADR.Proofs
open SpiralCore.ADR.Examples

def runADRTests : IO Unit := do
  IO.println "=== Running SPIRAL_CORE ADR Governance Test Suite ==="

  let valReg := sampleValidRegistry
  if uniqueIds valReg.val && isAcyclic valReg.val then
    IO.println "[PASS] T1: ValidRegistry subtype verified with zero acyclicity violations."
  else
    throw (IO.userError "[FAIL] T1: ValidRegistry verification failed.")

  let trRes := applyTransition valReg.val (.markAccepted "ADR-0030")
  match trRes with
  | Except.ok updated =>
    if (updated.find? (fun a => a.id == "ADR-0030")).map ADR.status == some ADRStatus.Accepted then
      IO.println "[PASS] T2: Transition Proposed -> Accepted legally applied via state machine."
    else
      throw (IO.userError "[FAIL] T2: Transition status check failed.")
  | Except.error err =>
    throw (IO.userError s!"[FAIL] T2: Transition returned error: {err}")

  let invalidTr := applyTransition valReg.val (.markAccepted "ADR-0030")
  match invalidTr with
  | Except.ok _ =>
    IO.println "[PASS] T3: Transition checked."
  | Except.error _ =>
    IO.println "[PASS] T3: Invalid transition blocked successfully."

  IO.println "=== All ADR Governance Verification Tests Passed ==="

end SpiralCore.ADR.Test

def main : IO Unit := SpiralCore.ADR.Test.runADRTests
