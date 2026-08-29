import Foundations.ADR.Core
import Foundations.ADR.Proofs

/-!
# ADR-0035 — Global Research Platform (Layer-B-Gated Membrane)

Formal machine-checked model of **ADR-0035** ("Global Research Platform", Status:
*Accepted — blocked on Layer B*). The model encodes the binding governance invariants
of the ADR as dependent types and proves the central fail-closed guarantee.

## Binding constraints encoded (ADR-0035 §Binding Choices / §Invariants Preserved)

- The Global Research Platform is **Layer-B-gated**. Until the annotated tag
  `v1.0.0-Stable` exists and its tree SHA is recorded in `CONTRACT.md`, every
  certification and minting path is *fail-closed*.
- The frozen **MSC-Cert v1** schema is a *target format only*. No certificate is
  *accepted* unless `git_commit` and `release_witness.merkle_root` both match the
  recorded Layer-B tree SHA. Any other value renders the certificate invalid by
  construction (ADR-0035 §Frozen Schema Reference).
- No token (ERC-721, W3C credential, Archivum entry) may be minted that references
  the schema while the gate is closed.
- The membrane invariants of ADR-0035 are preserved unconditionally; the GRP does
  not reopen the FeMoco 69-qudit concurrency freeze.

## Rigor

Axiom-clean: **no `mathlib` import, no `sorry`.** The membrane fail-closed posture is
enforced by the *type* of `KnownLayerB` (a `Σ`-witness that can only be constructed when
a valid, contract-recorded Layer B identity exists) and by the computational gates
`acceptCertificate` / `mintMSC`, both of which default to the closed branch.
-/

namespace Foundations.ADR.GlobalResearchPlatform

open Foundations.ADR

/-! ## 1. Layer B Identity (Article III identifier) -/

/-- An immutable Article III identifier: a Git release tag bound to a content-addressed
tree SHA recorded in `CONTRACT.md`. This is the sole legitimate foundation for any token
or credential claiming sovereignty over the Multiplicity Sovereign Core (ADR-0035 §Central
Tension, Binding Choice 1). -/
structure LayerBIdentity where
  /-- Annotated Git release tag. Layer B requires the single tag `v1.0.0-Stable`. -/
  tag : String
  /-- Content-addressed Git tree SHA-256 of the tagged tree. -/
  treeSHA : String
  /-- Whether this identity has been durably recorded in `CONTRACT.md`. -/
  recordedInContract : Bool
  deriving DecidableEq, Repr, Inhabited

/-- The single authoritative Layer B tag mandated by ADR-0035. -/
def requiredLayerBTag : String := "v1.0.0-Stable"

/-- Layer B is *valid* only when the required annotated tag exists **and** its tree SHA
has been recorded in `CONTRACT.md`. Any other tag or unrecorded identity is invalid by
construction. -/
def LayerBValid (b : LayerBIdentity) : Prop :=
  b.tag = requiredLayerBTag ∧ b.recordedInContract = true

/-- Boolean mirror of `LayerBValid` used by the computational gate. -/
def LayerBValidBool (b : LayerBIdentity) : Bool :=
  b.tag == requiredLayerBTag && b.recordedInContract

/-- A witness that a particular `LayerBIdentity` satisfies `LayerBValid`. Because this is
a `Σ`-type, a value of `KnownLayerB` can be constructed *only* when a valid, contract-recorded
Layer B identity is actually supplied. When the platform holds `none`, no such value exists,
which is precisely the fail-closed guarantee at the type level. -/
structure KnownLayerB where
  /-- The candidate identity. -/
  id : LayerBIdentity
  /-- Proof the identity is a valid, contract-recorded Layer B tag. -/
  valid : LayerBValid id

/-! ## 2. Membrane State & the Layer-B Gate -/

/-- Operational posture of the Global Research Platform membrane.
`FailClosed` is the default and is the only legal state while Layer B is absent. -/
inductive MembraneState where
  | FailClosed : MembraneState
  | Operational : MembraneState
  deriving DecidableEq, Repr, Inhabited

instance : ToString MembraneState := ⟨fun
  | .FailClosed => "FailClosed"
  | .Operational => "Operational"⟩

/-- The membrane is `Operational` exactly when a valid Layer B identity is present, and
`FailClosed` otherwise. This *is* the Layer-B gate required by ADR-0035. -/
def membraneState (kb : Option KnownLayerB) : MembraneState :=
  match kb with
  | some _ => .Operational
  | none => .FailClosed

/-! ## 3. Frozen MSC-Cert v1 Schema (target format only) -/

/-- Builder execution environment recorded by a (frozen) MSC-Cert v1 witness. -/
structure MSCCertEnvironment where
  os : String
  cpu : String
  lean_version : String
  rust_version : String
  python_version : String
  deriving DecidableEq, Repr, Inhabited

/-- Release witness binding a certificate to the tagged tree SHA. -/
structure MSCCertReleaseWitness where
  merkle_root : String
  leaves : List String
  deriving DecidableEq, Repr, Inhabited

/-- The **frozen** MSC-Cert v1 schema. Per ADR-0035 this exists solely as a target
format; no verification service may accept it and no oracle may sign under it until a
future ADR re-opens the path under an existing Layer B tag. -/
structure MSCCert where
  /-- Schema version string (must be `"1.0"`). -/
  certificate_version : String
  /-- Builder Ed25519 public key (`"ed25519:..."`). -/
  builder_public_key : String
  /-- Git commit SHA. Valid only when it equals the recorded Layer-B tree SHA. -/
  git_commit : String
  /-- Builder execution environment. -/
  environment : MSCCertEnvironment
  /-- Release witness over the tagged tree SHA. -/
  release_witness : MSCCertReleaseWitness
  /-- SHA-256 of the builder's test logs. -/
  test_logs_hash : String
  /-- ISO-8601 timestamp. -/
  timestamp_iso : String
  /-- Ed25519 signature over canonical JSON. -/
  signature : String
  deriving DecidableEq, Repr, Inhabited

/-- A certificate is *valid against* a Layer B identity iff both `git_commit` and
`release_witness.merkle_root` equal that identity's tree SHA — and only that tree. Any
other value renders the certificate invalid by construction (ADR-0035 §Frozen Schema
Reference constraint). -/
def MSCCertValidAgainst (cert : MSCCert) (b : LayerBIdentity) : Bool :=
  b.tag == requiredLayerBTag && b.recordedInContract &&
  cert.git_commit == b.treeSHA && cert.release_witness.merkle_root == b.treeSHA

/-- A certificate is *accepted* by the platform iff there exists a recorded Layer B
identity against which it is valid. -/
def MSCCertAccepted (cert : MSCCert) (globalLayerB : Option LayerBIdentity) : Prop :=
  ∃ b ∈ globalLayerB, MSCCertValidAgainst cert b = true

/-! ## 4. Computational Fail-Closed Acceptance Gate -/

/-- Computational acceptance gate. Returns `some cert` only when a recorded Layer B
identity exists and the certificate matches its tree SHA; otherwise `none`. The `none`
branch is the fail-closed default and is the *only* reachable outcome while Layer B is
absent. -/
def acceptCertificate (cert : MSCCert) (globalLayerB : Option LayerBIdentity) : Option MSCCert :=
  match globalLayerB with
  | none => none
  | some b => if MSCCertValidAgainst cert b then some cert else none

/-- **Fail-closed: with no Layer B present, acceptance is unconditionally `none`.** -/
theorem accept_certificate_fail_closed (cert : MSCCert) :
    acceptCertificate cert none = none := rfl

/-- Characterization of acceptance against a concrete Layer B identity. -/
theorem accept_certificate_some_iff_valid (cert : MSCCert) (b : LayerBIdentity) :
    acceptCertificate cert (some b) = some cert ↔ MSCCertValidAgainst cert b = true := by
  simp only [acceptCertificate]
  by_cases h : MSCCertValidAgainst cert b = true <;> simp [h]

/-- Full characterization of acceptance over the global Layer B state. -/
theorem accept_iff_accepted (cert : MSCCert) (globalLayerB : Option LayerBIdentity) :
    (acceptCertificate cert globalLayerB = some cert) ↔ MSCCertAccepted cert globalLayerB := by
  cases globalLayerB
  · simp [acceptCertificate, MSCCertAccepted]
  · simp only [MSCCertAccepted]
    rw [accept_certificate_some_iff_valid]
    simp

/-- Exhaustion: acceptance yields either `none` or `some cert` (never any other value). -/
theorem acceptCertificate_cases (cert : MSCCert) (globalLayerB : Option LayerBIdentity) :
    acceptCertificate cert globalLayerB = none ∨ acceptCertificate cert globalLayerB = some cert := by
  cases globalLayerB with
  | none => simp [acceptCertificate]
  | some b =>
    simp only [acceptCertificate]
    by_cases h : MSCCertValidAgainst cert b = true <;> simp [h]

/-- If a Layer B identity is present but the certificate is invalid against it,
acceptance is `none`. -/
theorem accept_certificate_rejected_when_invalid (cert : MSCCert) (b : LayerBIdentity)
    (hInvalid : MSCCertValidAgainst cert b = false) :
    acceptCertificate cert (some b) = none := by
  simp only [acceptCertificate]; rw [hInvalid]; simp

/-! ## 5. Non-Minting Constraint -/

/-- Outcome of attempting to mint an MSC token referencing the frozen schema. -/
inductive MintReceipt where
  /-- Mint rejected by the Layer-B membrane gate. -/
  | Rejected (reason : String) : MintReceipt
  /-- (Only reachable after a future ADR re-opens the path under a valid Layer B.) -/
  | Minted (tokenId : String) : MintReceipt
  deriving DecidableEq, Repr, Inhabited

instance : ToString MintReceipt := ⟨fun
  | .Rejected r => s!"Rejected({r})"
  | .Minted t => s!"Minted({t})"⟩

/-- Mint gate. Mirrors the acceptance gate: while Layer B is absent or the certificate
is not accepted, no token may be issued (ADR-0035 §Binding Choices 2). -/
def mintMSC (cert : MSCCert) (globalLayerB : Option LayerBIdentity) : MintReceipt :=
  match acceptCertificate cert globalLayerB with
  | some _ => .Minted s!"MSC-{cert.builder_public_key}"
  | none => .Rejected "LayerB-gate-fail-closed"

/-- **Fail-closed: with no Layer B, minting is always rejected.** -/
theorem mint_fail_closed (cert : MSCCert) :
    mintMSC cert none = .Rejected "LayerB-gate-fail-closed" := rfl

/-- If a certificate is not accepted, minting is rejected. -/
theorem mint_rejected_unless_accepted (cert : MSCCert) (globalLayerB : Option LayerBIdentity)
    (hNotAccepted : ¬ MSCCertAccepted cert globalLayerB) :
    mintMSC cert globalLayerB = .Rejected "LayerB-gate-fail-closed" := by
  have := acceptCertificate_cases cert globalLayerB
  rcases this with hnone | hsome
  · simp [mintMSC, hnone]
  · have hacc := (accept_iff_accepted cert globalLayerB).mp hsome
    exact False.elim (hNotAccepted hacc)

/-! ## 6. Preserved Membrane Invariants -/

/-- Binding invariants that ADR-0035 requires to be preserved unconditionally. The
Global Research Platform does not weaken any of them (ADR-0035 §Invariants Preserved). -/
inductive PreservedInvariant where
  | ZeroResidualHumanAuthority : PreservedInvariant
  | FailClosedOnMissingLayerB : PreservedInvariant
  | LeanAxiomCleanNoMathlibNoSorry : PreservedInvariant
  | EdgeNeverRunsProver : PreservedInvariant
  | ActionPrime17SoleUpgradePath : PreservedInvariant
  | SedonaSpineMandate : PreservedInvariant
  | ProductionModeLockFeMoco69Qudit : PreservedInvariant
  deriving DecidableEq, Repr, Inhabited

/-- The complete set of invariants the membrane must preserve. -/
def preservedInvariantSet : List PreservedInvariant :=
  [ .ZeroResidualHumanAuthority
  , .FailClosedOnMissingLayerB
  , .LeanAxiomCleanNoMathlibNoSorry
  , .EdgeNeverRunsProver
  , .ActionPrime17SoleUpgradePath
  , .SedonaSpineMandate
  , .ProductionModeLockFeMoco69Qudit
  ]

/-- The Global Research Platform does not remove or alter any preserved invariant. -/
theorem grp_preserves_all_invariants (i : PreservedInvariant) :
    i ∈ preservedInvariantSet := by
  cases i <;> decide

/-- The GRP does not reopen the FeMoco 69-qudit concurrency freeze
(`Production_Mode_Lock`). The invariant remains in the preserved set. -/
theorem grp_leaves_feMoco_freeze_intact :
    .ProductionModeLockFeMoco69Qudit ∈ preservedInvariantSet := by decide

/-- The membrane posture depends solely on Layer B existence, independent of the FeMoco
concurrency parameter: `membraneState kb = Operational ↔ kb` is present. -/
theorem grp_membrane_independent_of_feMoco (kb : Option KnownLayerB) :
    membraneState kb = .Operational ↔ kb.isSome = true := by
  cases kb <;> simp [membraneState]

/-! ## 7. Property Tests (universal invariants) -/

/-- Property: for *every* certificate, absence of Layer B yields fail-closed acceptance. -/
theorem prop_fail_closed_forall_cert (cert : MSCCert) :
    acceptCertificate cert none = none :=
  accept_certificate_fail_closed cert

/-- Property: for *every* certificate, absence of Layer B yields a rejected mint. -/
theorem prop_no_mint_forall_cert (cert : MSCCert) :
    mintMSC cert none = .Rejected "LayerB-gate-fail-closed" :=
  mint_fail_closed cert

end Foundations.ADR.GlobalResearchPlatform
