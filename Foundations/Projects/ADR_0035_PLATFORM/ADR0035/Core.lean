/-!
# ADR0035.Core

Core formal types and inductive definitions for ADR-0035 (Global Research Platform).
Defines ADR data structures, Layer B tag constraints, MSC-Cert v1 schema, and platform states.
-/

namespace ADR0035

/-- Lifecycle status of an Architecture Decision Record -/
inductive ADRStatus where
  | Proposed   : ADRStatus
  | Accepted   : ADRStatus
  | Deprecated : ADRStatus
  | Superseded : ADRStatus
  deriving Repr, DecidableEq, Inhabited

/-- Traceability link connecting an ADR to repository artifacts or legal contracts -/
structure ArtifactLink where
  label : String
  uri   : String
  deriving Repr, DecidableEq, Inhabited

/--
ADR: Architecture Decision Record as a first-class verified dependent structure.
-/
structure ADR where
  id           : Nat
  title        : String
  status       : ADRStatus
  context      : String
  decision     : String
  consequences : List String
  supersedes   : Option Nat
  links        : List ArtifactLink
  isLayerBGated: Bool
  deriving Repr, DecidableEq, Inhabited

/--
Layer B Tag: Immutable Article III Git Tag and Content-Addressed Tree Anchor.
According to ADR-0035 & ADR-008, the tag `v1.0.0-Stable` must exist and be
recorded in `CONTRACT.md` before any public minting or certification may occur.
-/
structure LayerBTag where
  tagName             : String
  treeSHA             : String
  isRecordedInContract: Bool
  isArticleIIIMatching: Bool
  deriving Repr, DecidableEq, Inhabited

/-- Check if a Layer B Tag is valid and legally ratified -/
def isLayerBRatified (tag : LayerBTag) : Bool :=
  tag.tagName == "v1.0.0-Stable" &&
  tag.isRecordedInContract &&
  tag.isArticleIIIMatching &&
  tag.treeSHA.length == 40

/--
MSC-Cert v1 Schema: Calibration certificate format.
Frozen as a non-minting specification under ADR-009 & ADR-0035.
-/
structure MSCCertSchema where
  version       : String := "1.0"
  builderPubKey : String
  gitCommit     : String
  merkleRoot    : String
  testLogsHash  : String
  timestampIso  : String
  signature     : String
  deriving Repr, DecidableEq, Inhabited

/-- Global Research Platform Governance State -/
structure PlatformState where
  layerBTag                      : Option LayerBTag
  isPublicVerificationActive     : Bool
  tokensMintedCount              : Nat
  privateWitnessesGenerated      : Nat
  isProductionModeLocked         : Bool := true
  femocoQuditEnvelope            : Nat := 69
  deriving Repr, DecidableEq, Inhabited

/-- Default uninitialized platform state (Layer B missing) -/
def defaultInitialState : PlatformState := {
  layerBTag                  := none,
  isPublicVerificationActive := false,
  tokensMintedCount          := 0,
  privateWitnessesGenerated  := 0,
  isProductionModeLocked     := true,
  femocoQuditEnvelope        := 69
}

end ADR0035
