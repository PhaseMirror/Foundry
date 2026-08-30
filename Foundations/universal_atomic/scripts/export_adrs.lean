import UAC.ADR.PhaseAAlignment
import UAC.ADR.Export
open System (IO)
open UAC.ADR

def sampleADR : ADR := {
  id := "001",
  title := "Phase A Alignment",
  status := ADRStatus.Accepted,
  context := "Initial alignment of repository",
  decision := "Adopt Phase A",
  consequences := ["All modules validated"],
  supersedes := none,
  links := []
}

/-- Export the sample ADR to  – called as the Lean . -/
def main : IO Unit := do
  exportAll [sampleADR] "docs/adr_md"
  IO.println "ADR markdown exported."

#eval main
