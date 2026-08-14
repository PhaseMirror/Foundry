import MTPI.ADR
import MTPI.Proofs
import MTPI.Examples

def main : IO Unit := do
  let adr := MTPI.Examples.mtpi_adr_001
  if adr.status == MTPI.ADRStatus.Accepted then
    IO.println "Test Passed: MTPI ADR successfully anchored as Accepted."
  else
    IO.println "Test Failed: Invariant breached."
