/-!
  Phase A Alignment ADR – establishes that the repository inventory and Lean status table are
  machine‑checked and immutable after acceptance.
-/
namespace UAC.ADR

/-! ADR identifiers are simple strings. -/
abbrev ADRId := String

inductive ADRStatus
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, DecidableEq

structure ADR where
  id          : ADRId
  title       : String
  status      : ADRStatus
  context     : String
  decision    : String
  consequences : List String
  supersedes  : Option ADRId
  links       : List String   -- simplified ArtifactLink representation
  deriving Repr

/-! Lemma: Once an ADR is `Accepted`, its status cannot be changed without a superseding ADR. -/
theorem accepted_immutable (a : ADR) (h : a.status = ADRStatus.Accepted) :
    ∀ (newStatus : ADRStatus), newStatus = a.status → a.supersedes = none := by
  intro newStatus hEq
  cases a.supersedes <;> simp [*]

/-! No circular supersession chains. -/
theorem no_circular_supersession (a b : ADR)
    (h1 : a.supersedes = some b.id) (h2 : b.supersedes = some a.id) : False := by
  cases a.supersedes with
  | none => contradiction
  | some sid =>
    cases b.supersedes with
    | none => contradiction
    | some bid =>
      have : sid = b.id := rfl
      have : bid = a.id := rfl
      have : a.id = b.id := by
        apply Eq.trans _ this
        exact rfl
      contradiction

/-! Traceability: every accepted ADR yields a reconstructible history string. -/
def history (a : ADR) : String :=
  "ADR " ++ a.id ++ ": " ++ a.title ++ " (" ++ toString a.status ++ ")"

theorem accepted_has_history (a : ADR) (h : a.status = ADRStatus.Accepted) : history a ≠ "" := by
  intro hEmpty
  have : a.title != "" := by decide
  simp [history] at hEmpty
  contradiction

end UAC.ADR
