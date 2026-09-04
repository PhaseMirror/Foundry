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

  -- T2: Legal transition Proposed -> Accepted
  let trRes := applyTransition valReg.val (.markAccepted "ADR-0030")
  match trRes with
  | Except.ok updatedValReg =>
    if (updatedValReg.val.find? (fun a => a.id == "ADR-0030")).map ADR.status == some ADRStatus.Accepted then
      IO.println "[PASS] T2: Transition Proposed -> Accepted legally applied; post-state satisfies ValidRegistry subtype."
      
      -- T3: Hard Negative Test — Try marking an ALREADY ACCEPTED record Accepted again.
      let illegalTr := applyTransition updatedValReg.val (.markAccepted "ADR-0030")
      match illegalTr with
      | Except.ok _ =>
        throw (IO.userError "[FAIL] T3: Illegal transition Accepted -> Accepted was incorrectly allowed!")
      | Except.error err =>
        if err == "Only Proposed ADRs can be marked Accepted" then
          IO.println "[PASS] T3: Illegal transition Accepted -> Accepted correctly rejected by state machine."
        else
          throw (IO.userError s!"[FAIL] T3: Unexpected error message returned: {err}")
    else
      throw (IO.userError "[FAIL] T2: Transition status check failed.")
  | Except.error err =>
    throw (IO.userError s!"[FAIL] T2: Transition returned error: {err}")

  IO.println "=== All ADR Governance Verification Tests Passed ==="

end SpiralCore.ADR.Test

def main : IO Unit := SpiralCore.ADR.Test.runADRTests
