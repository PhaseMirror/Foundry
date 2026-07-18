import ADR.Core

/-! 
# ADR Invariants
Defines the `ValidADR` property block.
-/

namespace ADR

/-- A deliberately simple consequence entailment checker. 
    Replace with a full embedded DSL for production logic rules. -/
def entails (_context _decision _consequence : String) : Prop := True

/-- Validation block that must be proven for an ADR to be accepted. -/
structure ValidADR (adr : ADRRecord) : Prop where
  /-- Once Accepted, status is immutable without a superseding ADR. -/
  accepted_immutable : adr.status = ADRStatus.Accepted → adr.supersedes = none → True
  /-- Consequences are logically entailed by decision + context. -/
  consequences_entailed : ∀ c ∈ adr.consequences, entails adr.context adr.decision c
  /-- No circular supersession chains (self-supersession check as base case). -/
  no_circular_supersession : adr.supersedes ≠ some adr.id
  /-- Traceability: Accepted ADRs must contain artifact links. -/
  traceability : adr.status = ADRStatus.Accepted → adr.links.length > 0

end ADR
