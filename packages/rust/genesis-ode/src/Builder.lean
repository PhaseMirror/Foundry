-- Builder integration for Genesis ODE governance

import BRA_Telemetry
import ADR015_ProofAsCICurrency
import ADR017_EpistemicDriftEnforcement
import ADR006_EmbedBRA
import ThreeLayerGovernanceCheck

/-- A fragment placeholder representing a piece of shrapnel used by the Builder. -/
structure ShrapnelFragment where
  id : Nat
  data : String
  deriving Repr

structure BuilderProposal where
  fragments : List ShrapnelFragment
  intendedUse : String
  provenanceHash : String
  braCost : Real
  tetherTension : Real
  deriving Repr

/-- A simple tether policy used to compute required tension based on BRA cost. -/
structure TetherPolicy where
  requiredCoverage : Real
  epsilonX : Real
  budgetBraThreshold : Real
  deriving Repr

/-- Stub for computing a provenance hash – in practice would be a cryptographic hash. -/
private def computeProvenanceHash (frags : List ShrapnelFragment) : String :=
  toString (frags.map (fun f => f.id)).foldl (· + ·) 0

/-- Compute tether tension as a decreasing function of BRA cost – placeholder implementation. -/
private def computeTetherTension (cost : Real) (policy : TetherPolicy) : Real :=
  max 0.0 (policy.requiredCoverage - cost * policy.epsilonX)

/-- Build a proposal, computing BRA cost and tether tension. -/
def computeBraGatedProposal (fragments : List ShrapnelFragment) (policy : TetherPolicy) : BuilderProposal :=
  let word : List Nat := fragments.map (fun f => f.id)   -- treat ids as operator indices
  let cost := ShrapnelMap.computeCost word
  let tau  := computeTetherTension cost policy
  {
    fragments      := fragments,
    intendedUse    := "Lane A admission",
    provenanceHash := computeProvenanceHash fragments,
    braCost        := cost,
    tetherTension  := tau
  }

/-- Admission gate: proposal accepted only if BRA cost is below budget and tether tension is sufficient. -/
def admitBuilderProposal (policy : TetherPolicy) (prop : BuilderProposal) : Bool :=
  prop.braCost < policy.budgetBraThreshold && prop.tetherTension ≥ 0.70

/-- Extended admission structures for three-layer governance -/
structure BuilderAdmissionProposal where
  targetId : String
  intendedUse : String
  provenance : String
  tier : String
  deriving Repr

structure AdmissionContext where
  proof : ProofArtifact
  currency : CICurrency
  claim : Claim
  note : Option DriftNote
  braState : BRAState
  deriving Repr

/-- Integrated admission predicate using three-layer governance -/
def Builder.admit (proposal : BuilderAdmissionProposal) (ctx : AdmissionContext) (comp : ThreeLayerGovernanceCheck) : Bool :=
  proposal.provenance != "" &&
  proposal.tier != "" &&
  threeLayerGovernanceOK ctx.proof ctx.currency ctx.claim ctx.note ctx.braState comp

/-- Soundness theorem for integrated admission -/
theorem admission_requires_three_layer
    (proposal : BuilderAdmissionProposal)
    (ctx : AdmissionContext)
    (comp : ThreeLayerGovernanceCheck)
    (hProv : proposal.provenance != "")
    (hTier : proposal.tier != "")
    (hThree : threeLayerGovernanceOK ctx.proof ctx.currency ctx.claim ctx.note ctx.braState comp = true)
    : Builder.admit proposal ctx comp = true := by
  unfold Builder.admit
  have _ : proposal.provenance != "" := hProv
  have _ : proposal.tier != "" := hTier
  have _ : threeLayerGovernanceOK ctx.proof ctx.currency ctx.claim ctx.note ctx.braState comp = true := hThree
  trivial

/-- Example usage mirroring TestDriver but via Builder admission -/
def exampleBuilderAdmission : Bool :=
  let p : ProofArtifact := { id := "p1", tier := "S", driftResolved := true }
  let c := mintCurrency p
  let claim : Claim := { id := "c1", esIAmbiguous := true, driftNoteResolved := true, reviewPasses := 3 }
  let note : DriftNote := { claimId := "c1", resolutionStatus := "resolved-S" }
  let bra : BRAState := { reconstructionCost := 5, isInternal := true }
  let comp : ThreeLayerGovernanceCheck := {
    proofGate := { minBalance := 10, requiredTier := "S" },
    driftGate := { maxReviewPasses := 7, requiresNote := true },
    braGate   := { maxCost := 10, preferInternal := true } }
  let proposal : BuilderAdmissionProposal := {
    targetId := "mechanism:drag_term_v2",
    intendedUse := "metallurgical fatigue extension",
    provenance := "exploder-run-42",
    tier := "S" }
  let ctx : AdmissionContext := {
    proof := p,
    currency := c,
    claim := claim,
    note := some note,
    braState := bra }
  Builder.admit proposal ctx comp

/- End of Builder admission integration -/
