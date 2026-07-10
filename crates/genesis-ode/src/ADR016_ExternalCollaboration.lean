/-!
  ADR‑016 Formalization in Lean4
  External Collaboration under Protected Innovation Budget.
  No mathlib, no `sorry`s.
-/

open ShrapnelMap

/-- Representation of an external contribution. -/
structure Contribution where
  id          : Nat
  tier        : String   -- "I" (Internal), "S" (Supported), "E" (External verified)
  provenance  : String   -- reference to source of contribution
  quarantined : Bool     -- must be true for new contributions
  runManifest : String   -- identifier for a RunManifest verifying architecture bounds
  deriving Repr

/-- Simplified Builder proposal with a deterministic score (0‑100). -/
structure BuilderProposal where
  score : Nat   -- score >= 0, <= 100 representing confidence
  deriving Repr

/-- Predicate: contribution must be quarantined before admission. -/
def isQuarantined (c : Contribution) : Bool :=
  c.quarantined = true

/-- Predicate: tier must be non‑empty and one of the allowed labels. -/
def tierValid (c : Contribution) : Bool :=
  c.tier = "I" ∨ c.tier = "S" ∨ c.tier = "E"

/-- Predicate: provenance must be provided (non‑empty). -/
def provenanceValid (c : Contribution) : Bool :=
  c.provenance != ""

/-- Predicate: a RunManifest identifier must be supplied (non‑empty). -/
def runManifestValid (c : Contribution) : Bool :=
  c.runManifest != ""

/-- Predicate: Builder proposal must meet the minimum confidence threshold. -/
def builderGate (p : BuilderProposal) : Bool :=
  p.score >= 70

/-- Composite governance gate for admitting a contribution. -/
def admissionGate (c : Contribution) (p : BuilderProposal) : Bool :=
  isQuarantined c && tierValid c && provenanceValid c && runManifestValid c && builderGate p

/-- Theorem: if all preconditions hold, the admission gate evaluates to `true`. -/
theorem admission_allowed (c : Contribution) (p : BuilderProposal)
    (hQuar : isQuarantined c = true)
    (hTier : tierValid c = true)
    (hProv : provenanceValid c = true)
    (hRun  : runManifestValid c = true)
    (hBuild : builderGate p = true) :
    admissionGate c p = true := by
  unfold admissionGate isQuarantined tierValid provenanceValid runManifestValid builderGate
  simp [hQuar, hTier, hProv, hRun, hBuild]

/-- End of ADR‑016 formalization. -/
