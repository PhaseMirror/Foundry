import ADR015_ProofAsCICurrency
import ADR017_EpistemicDriftEnforcement
import ADR006_EmbedBRA
import ThreeLayerGovernanceCheck

open Init

/-- Example driver that constructs sample entities and runs the three‑layer governance check. -/
def example : IO Unit := do
  let p : ProofArtifact := { id := "p1", tier := "S", driftResolved := true }
  let c := mintCurrency p
  let claim : Claim := { id := "c1", esIAmbiguous := true, driftNoteResolved := true, reviewPasses := 3 }
  let note : DriftNote := { claimId := "c1", resolutionStatus := "resolved-S" }
  let bra : BRAState := { reconstructionCost := 5, isInternal := true }
  let comp : ThreeLayerGovernanceCheck := {
    proofGate := { minBalance := 10, requiredTier := "S" },
    driftGate := { maxReviewPasses := 7, requiresNote := true },
    braGate   := { maxCost := 10, preferInternal := true } }
  let ok := threeLayerGovernanceOK p c claim (some note) bra comp
  IO.println s!"Governance check result: {ok}"
  pure ()

def main : IO Unit := example
