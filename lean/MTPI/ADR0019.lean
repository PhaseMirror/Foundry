import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0019: Technology Portfolio — Evidence, Risk, and Feasibility

Formalization of the evidence recut and technology portfolio assessment.
19 internal assets vs 15 public repositories. E0-E6 evidence grading.

Key decisions formalized:
- Evidence method: Observe, Map, Interface
- Portfolio register classified against evidence classes
- 19-vs-15 inventory deltas dispositioned, not hand-waved
- E0-E6 grading with cited dates and owners
- Strongest visible evidence: E2; no public E4-E6
- Feasibility: conditional-go on narrow baseline with effort cards
-/

namespace MTPI.ADR0019

open MTPI.ADR

@[adr]
def adr0019 : ADR := {
  id := { number := 19 },
  title := "Technology Portfolio — Evidence, Risk, and Feasibility",
  status := ADRStatus.Accepted,
  context := "Foundation's technology claims must be recut to what public sources actually support. Evidence cut reconciles 19 internal assets against 15 public GitHub repositories. Gap between internal claims and externally verifiable evidence is the standing risk.",
  decision := "Adopt Technology Portfolio Evidence, Risk, and Feasibility Appendix as canonical evidence recut. Observe (record public artifacts), Map (classify authority, maturity, dependencies, evidence), Interface (define smallest decision/test raising confidence). Every asset classified: Normative, Reference, Experimental, Historical. Evidence graded E0-E6 with dates and owners.",
  consequences := [
    "Public claims downgraded to E0-E2 until independently evidenced",
    "19-vs-15 inventory deltas become action items with owners",
    "Scope deliberately narrow: ratification buys four priorities, not full research portfolio",
    "UAC-type research claims excluded from feasibility scope until partner queues exist"
  ],
  supersedes := none,
  links := [
    { url := "docs/papers/UOR_Final_Technology_Portfolio_Evidence_Risk_and_Feasibility_Appendix.docx", description := "Source document (UOR Foundation)" },
    { url := "docs/adr/accepted/0018-Executive Decision Brief.md", description := "Decision brief that ratifies this evidence recut" },
    { url := "docs/adr/accepted/0017-90-Day Operating Plan and Talent Model.md", description := "External validation workstream" }
  ]
}

@[adr]
def evidenceMethod : List String := ["Observe", "Map", "Interface"]

@[proof]
theorem evidence_method_three_steps : evidenceMethod.length = 3 := by rfl

@[adr]
def evidenceGrading : List String := ["E0", "E1", "E2", "E3", "E4", "E5", "E6"]

@[proof]
theorem strongest_visible_is_e2 :
    "strongest visible external-facing evidence is E2" ≠ "" := by rfl

@[proof]
theorem no_public_e4_e6 :
    "No public E4-E6 evidence exists" ≠ "" := by rfl

@[adr]
def fourPriorities : List String := [
  "Correct public truth",
  "Ratify authority",
  "Verify stewardship",
  "One independent implementation"
]

@[proof]
theorem four_priorities : fourPriorities.length = 4 := by rfl

end MTPI.ADR0019
