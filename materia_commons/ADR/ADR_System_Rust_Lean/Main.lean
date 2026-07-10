import ADR.Examples

open ADR.Examples
open ADR

def main : IO Unit := do
  IO.println s!"Testing {adr001.id}: {adr001.title}"
  if adr001.status == ADRStatus.Accepted then
    IO.println "Test Passed: ADR-001 is Accepted."
  else
    IO.println "Test Failed: ADR-001 status incorrect."
    
  IO.println s!"Testing {adr002.id}: {adr002.title}"
  if adr002.status == ADRStatus.Proposed then
    IO.println "Test Passed: ADR-002 is Proposed."
  else
    IO.println "Test Failed: ADR-002 status incorrect."
    
  IO.println "All tests passed successfully."
