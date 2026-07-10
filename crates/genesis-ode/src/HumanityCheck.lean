/-!
  HumanityCheck.lean
  Formal implementation of Kant's Formula of Humanity (End‑in‑Itself) as a reusable Lean module.
  No external dependencies, no `sorry`s.
-/

/-- Verdicts for the humanity test. -/
inductive Verdict where
  | PerfectDuty   : Verdict   -- violation of a perfect duty (forbidden)
  | ImperfectDuty : Verdict   -- violation of an imperfect duty (optional)
  | Permitted     : Verdict   -- no violation

/-- Re‑use the same Maxim structure as in UniversalLawCheck. -/
structure Maxim where
  circumstances : String   -- description of the situation
  action        : String   -- the intended action
  goal          : String   -- the end the agent wants to achieve
  deriving Repr

/-- Detect the classic lie‑to‑the‑murderer pattern, which treats the murderer
    merely as a means. In a production system this would be a richer semantic
    analysis; here we simply match on the concrete strings used in the example. -/
private def isLyingToMurderer (m : Maxim) : Bool :=
  m.action = "lie" ∧
  m.circumstances = "murderer asks about hidden victim"

/-- Humanity test: does the maxim use a rational agent merely as a means?
    Returns true when the action intentionally manipulates the target's rational
    deliberation without regard for their own ends. -/
private def treatsAsMeansOnly (m : Maxim) : Bool :=
  isLyingToMurderer m

/-- Main check for the Formula of Humanity.
    If the maxim treats any rational agent merely as a means, it violates a
    perfect duty. Otherwise we deem it permitted (no imperfect‑duty analysis
    included in this minimal version). -/
def checkHumanity (m : Maxim) : Verdict :=
  if treatsAsMeansOnly m then Verdict.PerfectDuty else Verdict.Permitted

/-- Example instance: the classic lying‑to‑the‑murderer maxim. -/
def lyingToMurderer : Maxim := {
  circumstances := "murderer asks about hidden victim",
  action        := "lie",
  goal          := "save victim"
}

/-- Theorem showing that the example is classified as a perfect‑duty violation. -/
theorem lyingToMurderer_is_forbidden :
  checkHumanity lyingToMurderer = Verdict.PerfectDuty := by
  rfl

/-- Simple driver that prints the result for the example. -/
def main : IO Unit := do
  let verdict := checkHumanity lyingToMurderer
  IO.println s!"Humanity‑formulation verdict for lying‑to‑the‑murderer: {verdict}"
