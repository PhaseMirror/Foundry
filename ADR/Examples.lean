import ADR.Core
import ADR.Proofs

/-!
# Architecture Decision Records (ADR) — Production Examples

This module defines three realistic, production-grade architectural decision records
governing the Multiplicity sovereign kernel:
1. **ADR-001:** Integer Jordan Bond arithmetic (Fixed-point N=1024, superseding float approximations).
2. **ADR-002:** Sedona Spine retention engine as sole source of truth for litigation hold risk.
3. **ADR-003:** Per-Triad Resonance Floors (Audit v2), superseding ADR-001's aggregate-only audit.

All records are bundled into a verified `ADRRegistry` with machine-checked invariant proofs.
-/

namespace ADR.Examples

open ADR

/-- **ADR-001:** Integer Jordan Bond Governance. -/
def adr001 : ADR where
  id := "ADR-001"
  title := "Integer Jordan Bond Governance"
  status := .Superseded
  context := "Floating-point non-determinism introduces drift and spoliation risk in state transitions across distributed nodes."
  decision := "Enforce fixed-point integer Jordan bond arithmetic scaled by N = 1024 at the kernel boundary."
  consequences := [
    "Arithmetic determinism guaranteed across heterogeneous nodes",
    "Floating point drift strictly eliminated"
  ]
  supersedes := none
  links := [
    ⟨"PhaseMirror.Care.Scale", .LeanDeclaration, "Canonical fixed-point scale N = 1024"⟩,
    ⟨"Care.lean", .SourceFile, "Integer fixed-point operations"⟩
  ]

/-- **ADR-002:** Sedona Spine Retention Engine Sole Source of Truth. -/
def adr002 : ADR where
  id := "ADR-002"
  title := "Sedona Spine Retention Engine Sole Source of Truth"
  status := .Accepted
  context := "Decentralized litigation hold rules risk spoliation drift if computed independently by UI or client agents."
  decision := "All ESI preservation risk logic must route exclusively through the Sedona Spine Rust Engine and WASM SDK."
  consequences := [
    "Zero drift in litigation hold calculations",
    "Mandatory provenance chain: Policy -> Event -> Kernel -> Witness"
  ]
  supersedes := none
  links := [
    ⟨"models/legalese-scopist/CONTRACT.md", .SpecificationDoc, "Preservation alert protocol"⟩,
    ⟨"models/legalese-scopist/", .SourceFile, "Rust Engine Core implementation"⟩
  ]

/-- **ADR-003:** Per-Triad Resonance Floors (Audit v2). -/
def adr003 : ADR where
  id := "ADR-003"
  title := "Per-Triad Resonance Floors (Audit v2)"
  status := .Accepted
  context := "Aggregate mean resonance floor in ADR-001 permitted averaging blind spots where individual triads could fall below viability."
  decision := "Strengthen viability audit to require every individual triad to meet or exceed ResFloor = 870."
  consequences := [
    "Eliminates averaging blind spot proved by averaging_blind_spot theorem",
    "Preserves backward compatibility with audit v1"
  ]
  supersedes := some "ADR-001"
  links := [
    ⟨"ADR/Theorems/CareViability.lean", .SourceFile, "Formalization of v2 thresholds and blind spot"⟩,
    ⟨"PhaseMirror.CareViability.phase_mirror_audit_v2", .LeanDeclaration, "Per-triad binary audit"⟩
  ]

/-- Canonical list of production example ADRs. -/
def sampleADRList : List ADR := [adr001, adr002, adr003]

/-! ## Embedded Formal Claims (Semantic Conflict Layer)

Only Accepted records carry claims. Each claim is a `PropTerm` over shared
atoms so that cross-record contradictions are detectable semantically, not
just syntactically.

- **ADR-002** commits to: ESI retention is routed through the Sedona Spine.
- **ADR-003** commits to: every triad meets ResFloor 870 ∧ no float arithmetic
  remains at the kernel boundary (the superseded ADR-001 regime is gone). -/

/-- Embedded claim of **ADR-002**. -/
def adr002_claim : PropTerm := .atom "ESIRetentionRoutedThroughSedonaSpine"

/-- Embedded claim of **ADR-003**. -/
def adr003_claim : PropTerm :=
  .and (.atom "EveryTriadMeetsResFloor870")
       (.not (.atom "FloatArithmeticAtKernelBoundary"))

/-- Claims asserted by the sample registry's accepted records. -/
def sampleClaims : List Claim :=
  [⟨"ADR-002", adr002_claim⟩, ⟨"ADR-003", adr003_claim⟩]

/-- Tailored environment witnessing joint satisfiability of the sample claims:
both accepted decisions hold simultaneously (retention routing is active,
all triads meet the floor, and float arithmetic is absent at the boundary). -/
def envSample : String → Bool
  | "ESIRetentionRoutedThroughSedonaSpine" => true
  | "EveryTriadMeetsResFloor870" => true
  | "FloatArithmeticAtKernelBoundary" => false
  | _ => false

/-- Both sample claims evaluate to `true` under `envSample`, certifying joint
satisfiability by pure computation (`rfl`). -/
theorem sample_claims_jointly_satisfied :
    (adr002_claim.evalB envSample && adr003_claim.evalB envSample) = true :=
  rfl

/-- Every embedded claim has an Accepted owner in `sampleADRList`. -/
theorem sample_claims_owned_by_accepted :
    ∀ c ∈ sampleClaims, ∃ a ∈ sampleADRList, a.id = c.owner ∧ a.status = .Accepted := by
  intro c hc
  simp [sampleClaims] at hc
  rcases hc with rfl | rfl
  · exact ⟨adr002, by simp [sampleADRList], rfl, rfl⟩
  · exact ⟨adr003, by simp [sampleADRList], rfl, rfl⟩

/-- Semantic coherence: no pair of distinct-owner claims in the sample
registry is contradictory. Discharged constructively via the jointly
satisfying environment `envSample`. -/
theorem sample_no_claim_conflicts :
    ∀ c₁ ∈ sampleClaims, ∀ c₂ ∈ sampleClaims,
      c₁.owner ≠ c₂.owner → ¬ Contradictory c₁.claim c₂.claim := by
  intro c₁ hc₁ c₂ hc₂ hne hcon
  simp [sampleClaims] at hc₁ hc₂
  rcases hc₁ with h | h <;> rcases hc₂ with g | g
  · subst h; subst g; exact absurd rfl hne
  · subst h; subst g
    exact hcon envSample sample_claims_jointly_satisfied
  · subst h; subst g
    exact contradictory_symm hcon envSample sample_claims_jointly_satisfied
  · subst h; subst g; exact absurd rfl hne

/-! ## Formal Invariant Discharges for the Sample Registry -/

/-- Identifiers in `sampleADRList` are unique.

**Constraint:** this is discharged by `decide`, which requires every `ADR.id`
in the list to be a concrete string literal and `ADR` to derive `DecidableEq`.
Registries loaded from external sources or built from computed IDs must
replace `decide` with a dedicated equality witness (e.g. a sort-and-check
lemma over the ID list) — `decide` will fail to elaborate otherwise. -/
theorem sample_unique_ids : (sampleADRList.map ADR.id).Nodup := by
  decide

/-- Helper lemma: `ADR-001` has no supersedes target in `sampleADRList`. -/
theorem no_step_from_001 (target : ADRId) :
    ¬ SupersedesRel sampleADRList "ADR-001" target := by
  rintro ⟨a, ha, ha_id, ha_sup⟩
  simp [sampleADRList] at ha
  rcases ha with (rfl | rfl | rfl)
  · revert ha_sup; intro h; nomatch h
  · revert ha_id; intro h; nomatch h
  · revert ha_id; intro h; nomatch h

/-- The supersession relation on `sampleADRList` is strictly acyclic. -/
theorem sample_acyclic : StrictAcyclic sampleADRList := by
  intro id ⟨parent, ⟨a, ha, ha_id, ha_sup⟩, hPath⟩
  simp [sampleADRList] at ha
  rcases ha with (rfl | rfl | rfl)
  · revert ha_sup; intro h; nomatch h
  · revert ha_sup; intro h; nomatch h
  · -- a = adr003, id = "ADR-003", parent = "ADR-001"
    have hparent : parent = "ADR-001" := by
      revert ha_sup; intro h; cases h; rfl
    have hid : id = "ADR-003" := by
      revert ha_id; intro h; cases h; rfl
    subst hparent hid
    have hNoPath := no_path_from_dead_end sampleADRList "ADR-001" "ADR-003" no_step_from_001 (by decide)
    exact hNoPath hPath

/-- Every superseded target exists in the sample registry. -/
theorem sample_supersedes_exist :
    ∀ a ∈ sampleADRList, ∀ sid, a.supersedes = some sid → ∃ target ∈ sampleADRList, target.id = sid := by
  intro a ha sid hsup
  simp [sampleADRList] at ha
  rcases ha with (rfl | rfl | rfl)
  · revert hsup; intro h; nomatch h
  · revert hsup; intro h; nomatch h
  · have hsid : sid = "ADR-001" := by
      revert hsup; intro h; cases h; rfl
    subst hsid
    exact ⟨adr001, by simp [sampleADRList, adr001], rfl⟩

/-- Every superseded target has status Superseded in the registry. -/
theorem sample_superseded_status_consistent :
    ∀ a ∈ sampleADRList, ∀ sid, a.supersedes = some sid →
      ∃ target ∈ sampleADRList, target.id = sid ∧ target.status = .Superseded := by
  intro a ha sid hsup
  simp [sampleADRList] at ha
  rcases ha with (rfl | rfl | rfl)
  · revert hsup; intro h; nomatch h
  · revert hsup; intro h; nomatch h
  · have hsid : sid = "ADR-001" := by
      revert hsup; intro h; cases h; rfl
    subst hsid
    exact ⟨adr001, by simp [sampleADRList, adr001], rfl, rfl⟩

/-- No conflicting decisions exist in the sample registry. -/
theorem sample_no_conflicts :
    ∀ a ∈ sampleADRList, ∀ b ∈ sampleADRList, ¬ ConflictsWith a b := by
  intro a ha b hb
  simp [sampleADRList] at ha hb
  rcases ha with (rfl | rfl | rfl) <;> rcases hb with (rfl | rfl | rfl) <;>
    intro ⟨hne, ha_acc, hb_acc, _⟩ <;>
    try contradiction

/-- Verified sample ADR registry instance. -/
def sampleRegistry : ADRRegistry where
  adrs := sampleADRList
  uniqueIds := sample_unique_ids
  acyclic := sample_acyclic
  supersedesExist := sample_supersedes_exist
  supersededStatusConsistent := sample_superseded_status_consistent
  noConflicts := sample_no_conflicts
  claims := sampleClaims
  claimsOwnedByAccepted := sample_claims_owned_by_accepted
  noClaimConflicts := sample_no_claim_conflicts

/-! ## Consequence Entailment Proofs for Sample ADRs -/

/-- Formal propositional terms for ADR-001 consequence entailment. -/
def adr001_P : PropTerm := .atom "KernelEnforcesIntegerScaleN1024"
def adr001_Q : PropTerm := .atom "DeterministicArithmeticAcrossNodes"

/-- ADR-001 consequence is logically entailed by decision rule. -/
theorem adr001_consequence_entailment :
    Entails [adr001_P, .implies adr001_P adr001_Q] adr001_Q :=
  entailment_modus_ponens adr001_P adr001_Q

end ADR.Examples
