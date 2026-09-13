import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0017: Reinitialization — 90-Day Operating Plan and Volunteer Talent Model

Formalization of the bounded 13-week execution cycle for UOR Foundation
reinitialization under volunteer-led, no-funding assumption.

Key decisions formalized:
- One primary objective: governed, independently verifiable value-layer baseline
- Day Zero: two-week mobilization with six ownerless-proofed conditions
- Five workstreams maximum with WIP limits
- Accountability model with explicit RACI
- Volunteer talent model with contribution packets and negative evidence
- Action register A01-A26+
-/

namespace MTPI.ADR0017

open MTPI.ADR

@[adr]
def adr0017 : ADR := {
  id := { number := 17 },
  title := "Reinitialization — 90-Day Operating Plan and Volunteer Talent Model",
  status := ADRStatus.Accepted,
  context := "UOR Foundation must reinitialize under volunteer-led, no-funding assumption. The next unit of value is confidence: a bounded 13-week cycle producing a governed, independently verifiable value-layer baseline under strict WIP and ownership controls.",
  decision := "Adopt the 90-Day Operating Plan and Volunteer Talent Model. One primary objective (governed, independently verifiable value-layer baseline). Day Zero: two-week mobilization with six conditions (defined authority, clear scope, published public facts, volunteer capacity, release custody, named stewardship). Five workstreams maximum with RACI. Volunteer talent model with contribution packets. Action register A01-A26+.",
  consequences := [
    "Execution capped by WIP limits — scope cannot expand silently",
    "No-funding assumption binding — volunteer capacity is planning envelope",
    "Cycle either closes deliverables or fails exit rule loudly — no zombie state",
    "Decision cadence fixed up front and recorded"
  ],
  supersedes := none,
  links := [
    { url := "docs/papers/UOR_Final_90_Day_Operating_Plan_and_Talent_Model.docx", description := "Source document (UOR Foundation)" },
    { url := "docs/adr/accepted/0018-Executive Decision Brief.md", description := "Executive decision brief that gates this plan" },
    { url := "docs/adr/accepted/0019-Technology Portfolio Evidence and Risk.md", description := "Evidence basis for E0-E6 posture" }
  ]
}

@[adr]
def dayZeroConditions : List String := [
  "defined authority",
  "clear scope",
  "published public facts",
  "volunteer capacity",
  "release custody",
  "named stewardship"
]

@[proof]
theorem day_zero_six_conditions : dayZeroConditions.length = 6 := by rfl

@[adr]
def workstreams : List String := [
  "W1 Authority and public truth",
  "W2 Core Value Profile",
  "W3 Conformance and release",
  "W4 Explanation and participation",
  "W5 External validation"
]

@[proof]
theorem five_workstreams_max : workstreams.length = 5 := by rfl

@[adr]
def actionRegister : List String := [
  "A01-A26+" with ID, owner, and gate — nothing proceeds without registered action item"
]

end MTPI.ADR0017
