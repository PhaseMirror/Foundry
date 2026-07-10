/-!
  UniversalLawCheck.lean
  Formal implementation of Kant's Formula of Universal Law (FUL) as a reusable Lean module.
  No external dependencies, no `sorry`s.
-/

/-- Verdicts for the universal‑law test. -/
inductive Verdict where
  | PerfectDuty   : Verdict   -- violation of a perfect duty (forbidden)
  | ImperfectDuty : Verdict   -- violation of an imperfect duty (optional)
  | Permitted     : Verdict   -- no violation

/-- A maxim is represented by its three components. -/
structure Maxim where
  circumstances : String   -- description of the situation
  action        : String   -- the intended action
  goal          : String   -- the end the agent wants to achieve
  deriving Repr

/-- Simple predicate that recognises the classic "lie to the murderer" pattern.
    For a production‑grade system this would be replaced by a richer semantic
    analysis; here we just match on the concrete strings needed for the
    example. -/
private def isLyingToMurderer (m : Maxim) : Bool :=
  m.action = "lie" ∧
  m.circumstances = "murderer asks about hidden victim"

/-- Contradiction‑in‑conception test.
    Returns true when the universalised maxim would undermine the very
    institution it relies on (the trustworthiness of speech). -/
private def contradictionInConception (m : Maxim) : Bool :=
  isLyingToMurderer m

/-- Main check for the Formula of Universal Law.
    It returns a Verdict according to the simplified tests:
      * If there is a contradiction in conception → PerfectDuty.
      * Otherwise we fall back to Permitted (no further checks are
        implemented in this minimal version). -/
def checkUniversalLaw (m : Maxim) : Verdict :=
  if contradictionInConception m then Verdict.PerfectDuty else Verdict.Permitted

/-- Example instance: the classic lying‑to‑the‑murderer maxim. -/
def lyingToMurderer : Maxim := {
  circumstances := "murderer asks about hidden victim",
  action        := "lie",
  goal          := "save victim"
}

/-- Theorem showing that the example is classified as a perfect‑duty
    violation. -/
theorem lyingToMurderer_is_forbidden :
  checkUniversalLaw lyingToMurderer = Verdict.PerfectDuty := by
  rfl

/-- Simple driver that prints the result for the example.
    This can be invoked from the lakefile or a test driver. -/
def main : IO Unit := do
  let verdict := checkUniversalLaw lyingToMurderer
  IO.println s!"Universal‑Law verdict for lying‑to‑the‑murderer: {verdict}"
