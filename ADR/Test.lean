import ADR.Core
import ADR.Proofs
import ADR.Examples
import ADR.Export


open ADR
open ADR.Examples.Governance
open ADR.Export

def testImmutability : IO Unit := do
  let v : ValidTransition .Accepted .Superseded (some "0027") := ValidTransition.acceptToSupersede "0027"
  IO.println "✓ Immutability constraints satisfied: Accepted -> Superseded is valid."

def testAcyclicity : IO Unit := do
  let acyclic_proof : StrictAcyclic allAcceptedADRs := all_accepted_acyclic
  IO.println "✓ Registry acyclicity mathematically verified."

def testIntentionalFailure : IO Unit := do
  have h : ¬ ValidTransition .Accepted .Proposed none := by
    intro hvt
    cases hvt
  IO.println "✓ Type system correctly rejects Accepted -> Proposed transition."

def main : IO Unit := do
  IO.println "Starting Formal ADR Verification Harness..."
  testImmutability
  testAcyclicity
  testIntentionalFailure
  
  IO.println "\nExporting all ADRs to Markdown..."
  IO.println "-----------------------------------"
  for adr in allAcceptedADRs do
    IO.println (adrToMarkdown adr)
  IO.println "-----------------------------------"
  IO.println "All proofs checked and tests passed successfully."
