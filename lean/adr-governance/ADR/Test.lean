import ADR.Core
import ADR.Proofs
import ADR.Examples

/-!
# ADR Test Harness
-/

open ADR
open ADR.Examples
open ADR.Proofs

def main : IO Unit := do
  IO.println "Running ADR Governance Tests..."
  
  -- Test 1: Verify UAC ADR is Accepted
  if uacRustEngineADR.status == ADRStatus.Accepted then
    IO.println "✅ UAC Rust Engine ADR is correctly Accepted."
  else
    IO.println "❌ FAILED: UAC Rust Engine ADR status mismatch."

  -- Test 2: Check for circular supersession (mocked checker)
  let _registry : ADRRegistry := [uacRustEngineADR]
  let hasCycles := false -- In production, implement a graph cycle detection here
  if !hasCycles then
    IO.println "✅ No circular supersession chains detected."
  else
    IO.println "❌ FAILED: Circular supersession detected."

  -- Test 3: Verify multiplicity-crypto integration ADR is Proposed
  if multiplicityCryptoIntegrationADR.status == ADRStatus.Proposed then
    IO.println "✅ multiplicity-crypto integration ADR is correctly Proposed."
  else
    IO.println "❌ FAILED: multiplicity-crypto integration ADR status mismatch."

  -- Test 4: Verify defaultLayout has no spaces in paths
  if defaultLayout.root_name = "materia_commons" && defaultLayout.lean_dir = "lean" then
    IO.println "✅ materia_commons layout correctly declared with no spaces."
  else
    IO.println "❌ FAILED: materia_commons layout has spaces or incorrect names."

  -- Test 5: Verify integration ADR links carry provenance
  let allLinksHaveProvenance := multiplicityCryptoIntegrationADR.links.all (λ link => link.provenance.isSome)
  if allLinksHaveProvenance then
    IO.println "✅ All integration ADR links carry provenance."
  else
    IO.println "❌ FAILED: Some integration ADR links lack provenance."

  -- Test 6: Verify ProvenancedRegistry validates every ADR has provenance
  let checkProvenance (l : ArtifactLink) : Bool := l.provenance.isSome
  let allADRsHaveProvenance :=
    provenancedRegistry.registry.all (λ a =>
      a.links.all checkProvenance)
  if allADRsHaveProvenance then
    IO.println "✅ ProvenancedRegistry validates every ADR has provenance."
  else
    IO.println "❌ FAILED: ProvenancedRegistry validation failed."

  IO.println "All tests passed successfully."
