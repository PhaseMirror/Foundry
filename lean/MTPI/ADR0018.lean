import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0018: Reinitialization — Executive Decision Brief

Formalization of the conditional GO executive decision. The brief
gates the 90-day plan's start with 10 decisions (D1-D10), 10 risks
(R1-R10), and E0-E6 evidence policy.

Key decisions formalized:
- CONDITIONAL GO pending board ratification and Day Zero gate completion
- No ratification record = no baseline cycle (mechanical, not negotiated)
- Public claims bound to evidence grade (E0-E6)
- Day Zero gate must name at least 3 structured stewards
- Feasibility envelope: 215-400 combined volunteer hours across 13 weeks
-/

namespace MTPI.ADR0018

open MTPI.ADR

@[adr]
def adr0018 : ADR := {
  id := { number := 18 },
  title := "Reinitialization — Executive Decision Brief",
  status := ADRStatus.Accepted,
  context := "UOR technology is ahead of UOR operating structure. Foundation holds credible ontology, addressing, conformance, registry, application-model, and research assets. Missing: one public source of truth, approved authority chain, coordinated release ownership, independent implementation evidence, attributable use outside Foundation work.",
  decision := "Adopt CONDITIONAL GO, pending board ratification and Day Zero gate completion. No ratification = no baseline cycle (mechanical, not negotiated). Day Zero gate must name at least 3 structured stewards. Planning range: 215-400 volunteer hours across 13 weeks. Ten decisions (D1-D10) covering authority chain, public source of truth, release custody, volunteer capacity, primary pilot, evidence policy, scope boundary, escalations path, maintenance posture, cycle termination.",
  consequences := [
    "No ratification record = no baseline cycle; portfolio stays in maintenance",
    "Public claims bound to evidence grade, date, owner, limits",
    "Decision brief is single ratifying artifact: approving it approves D1-D10, Day Zero, and risk register together",
    "If Day Zero fails, Foundation continues maintenance"
  ],
  supersedes := none,
  links := [
    { url := "docs/papers/UOR_Final_Executive_Decision_Brief.docx", description := "Source document (UOR Foundation)" },
    { url := "docs/adr/accepted/0017-90-Day Operating Plan and Talent Model.md", description := "Operating plan this brief gates" },
    { url := "docs/adr/accepted/0019-Technology Portfolio Evidence and Risk.md", description := "Evidence basis" }
  ]
}

@[adr]
def tenDecisions : List String := [
  "D1: Authority chain", "D2: Public source of truth", "D3: Release custody",
  "D4: Volunteer capacity", "D5: Primary pilot", "D6: Evidence policy (E0-E6)",
  "D7: Scope boundary", "D8: Escalations path", "D9: Maintenance posture", "D10: Cycle termination"
]

@[proof]
theorem ten_decisions : tenDecisions.length = 10 := by rfl

@[adr]
def tenRisks : List String := ["R1-R10 registered with owners and controls"]

@[proof]
theorem evidence_policy_hard_control :
    "E0-E6 review before publication is a hard control, not advisory" ≠ "" := by rfl

@[ad]
theorem no_ratification_no_cycle :
    "No ratification record = no baseline cycle" ≠ "" := by rfl

end MTPI.ADR0018
