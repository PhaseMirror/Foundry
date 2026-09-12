import MTPI.ADR
import MTPI.Proofs
import MTPI.Examples

open MTPI
open MTPI.Examples

def main : IO Unit := do
  let adr := mtpi_adr_045
  if adr.status == ADRStatus.Accepted then
    IO.println "Test Passed: ADR-045 successfully anchored as Accepted & Verified."
  else
    IO.println "Test Failed: Invariant breached."
