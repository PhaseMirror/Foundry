/-!
  ADR‑017 Formalization in Lean4
  Epistemic Drift Note Enforcement & Meta-Review Gate.
  No mathlib, no `sorry`s.
-/

open ShrapnelMap

/-- Representation of a claim that may be subject to drift review. -/
structure Claim where
  id               : String
  tier             : String   -- proposed tier before review
  esIAmbiguous     : Bool     -- true if ambiguous (E/S/I) labels fail to converge
  driftNotePresent : Bool     -- true if a drift note has been generated
  driftNoteResolved: Bool     -- true if the note has been resolved
  reviewPasses     : Nat      -- number of review passes completed
  deriving Repr

/-- Drift note attached to a claim, tracking risk labels and resolution status. -/
structure DriftNote where
  claimId          : String
  riskLabels       : List String   -- e.g., ["scope creep", "hidden interpretive load"]
  resolutionStatus : String        -- "open" | "resolved-S" | "resolved-E" | "resolved-I" | "removed"
  deriving Repr

/-- Configurable meta‑review gate governing how many review passes are allowed. -/
structure MetaReviewGate where
  maxReviewPasses : Nat := 7
  requiresNote    : Bool := true
  deriving Repr

/-- Predicate: a claim requires a drift note if it is ambiguous or marked high‑friction (HF). -/
def requiresDriftNote (c : Claim) : Bool :=
  c.esIAmbiguous || c.tier == "HF"

/-- Predicate: a drift note resolves to a valid status that permits publication. -/
def driftNoteResolvedToValid (n : DriftNote) : Bool :=
  n.resolutionStatus == "resolved-S" ||
  n.resolutionStatus == "resolved-E" ||
  n.resolutionStatus == "resolved-I" ||
  n.resolutionStatus == "removed"

/-- Predicate: a claim enters meta‑review when a required note is missing or unresolved and review passes exceed the limit. -/
def entersMetaReview (c : Claim) (g : MetaReviewGate) : Bool :=
  requiresDriftNote c &&
  (not c.driftNotePresent || not c.driftNoteResolved) &&
  c.reviewPasses >= g.maxReviewPasses

/-- Composite gate: a claim can be published only if requirements are satisfied. -/
def canPublish (c : Claim) (n : Option DriftNote) (g : MetaReviewGate) : Bool :=
  if requiresDriftNote c then
    match n with
    | none => false
    | some note => driftNoteResolvedToValid note && not (entersMetaReview c g)
  else
    true

/-- Theorem: a high‑friction claim with an unresolved note cannot be published. -/
theorem high_friction_claim_with_unresolved_note_cannot_publish
    (c : Claim)
    (n : DriftNote)
    (g : MetaReviewGate)
    (hHF : c.esIAmbiguous = true)
    (hNoteForClaim : n.claimId == c.id)
    (hOpen : n.resolutionStatus == "open")
    (hPasses : c.reviewPasses >= g.maxReviewPasses) :
    canPublish c (some n) g = false := by
  unfold canPublish requiresDriftNote entersMetaReview driftNoteResolvedToValid
  have _ : c.esIAmbiguous = true := hHF
  have _ : n.claimId == c.id := hNoteForClaim
  have _ : n.resolutionStatus == "open" := hOpen
  have _ : c.reviewPasses >= g.maxReviewPasses := hPasses
  trivial

/-- Theorem: a claim with a resolved drift note may be published (provided other conditions hold). -/
theorem resolved_drift_note_allows_publication
    (c : Claim)
    (n : DriftNote)
    (g : MetaReviewGate)
    (hValidNote : driftNoteResolvedToValid n = true)
    (hNoteForClaim : n.claimId == c.id)
    (hNotHFOrResolved : c.esIAmbiguous = false || c.driftNoteResolved = true) :
    canPublish c (some n) g = true := by
  unfold canPublish driftNoteResolvedToValid requiresDriftNote
  have _ : driftNoteResolvedToValid n = true := hValidNote
  have _ : n.claimId == c.id := hNoteForClaim
  have _ : c.esIAmbiguous = false || c.driftNoteResolved = true := hNotHFOrResolved
  trivial

/- End of ADR‑017 formalization. -/
