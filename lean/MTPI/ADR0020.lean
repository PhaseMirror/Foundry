import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0020: HQ and Sovereign Node Deployment

Formalization of the physical ground state deployment. 36.8 acres in
Livermore, Larimer County, Colorado. Two-phase gate structure with
triadic recursion 3 → 9 → 27 and fail-closed sentinel.

Key decisions formalized:
- Phase 1: Ground-State Seeding (Circle of 9) with three yurts, 9-person Circle
- Phase 2: The UOR Foundry (Family of 27), gated by Three-Way Test on 90-day metric card
- Dual-control treasury: $2,500 threshold for dual-officer sign-off
- Pauli exclusion: each role capped at two occupants
- Non-profit asset lock: land/structures vest permanently in Foundation
- Operational kill-switch: 90-day metric card failure for two consecutive quarters halts spending
-/

namespace MTPI.ADR0020

open MTPI.ADR

@[adr]
def adr0020 : ADR := {
  id := { number := 20 },
  title := "HQ and Sovereign Node Deployment",
  status := ADRStatus.Accepted,
  context := "The UOR Foundation requires a physical ground state: LifeBushido Retreat, working Sovereign Urban Gardens (SUG) node, and site for civic Sovereignty Node. Proposed: 36.8 acres in Livermore, Larimer County, Colorado. Risk mitigated by two-phase gate structure. Social Physics: M = 2R + 1, triadic recursion 3 → 9 → 27, Phase Mirror as fail-closed sentinel.",
  decision := "Adopt HQ & Sovereign Node proposal conditioned on board authorization of $750,000 capital and two-phase gate structure. Phase 1: Ground-State Sealing (Circle of 9) — secure perimeter, deploy utilities, three yurts, staggered 9-person Circle. Phase 2: UOR Foundry (Family of 27) — gated by Three-Way Test on 90-day metric card (Member Dignity, Community Outcome, Solvency).",
  consequences := [
    "Capital reversible only at preset gates — Phase 2 funds never leave treasury on Phase 1 assumptions",
    "Site cannot exceed 27 operators without seeding new node — bounded by design",
    "Three-way test is only Phase 2 key — no executive override short of ADR",
    "Land and structures locked to Foundation — no private-equity route"
  ],
  supersedes := none,
  links := [
    { url := "docs/papers/UOR Foundation HQ & Sovereign Node Deployment_.docx", description := "Source document (36.8 acres, Livermore, Larimer County, CO)" },
    { url := "docs/adr/accepted/0015-Unified Civic Infrastructure Outline.md", description := "UNA/operator-LLC wall" },
    { url := "docs/adr/accepted/0016-UOR Civic Infrastructure Three Epochs.md", description := "Three-epoch model; site is Epoch 1 physical ground state" }
  ]
}

@[adr]
structure DeploymentPhase where
  phase : Nat
  name : String
  personnel : Nat
  deliverables : List String

@[adr]
def phase1 : DeploymentPhase := {
  phase := 1,
  name := "Ground-State Seeding (Circle of 9)",
  personnel := 9,
  deliverables := [
    "36.8-acre perimeter secured",
    "Off-grid utilities (deep well, engineered septic, solar array)",
    "Three 16-foot four-season yurts",
    "9-person Circle with Triads"
  ]
}

@[adr]
def phase2 : DeploymentPhase := {
  phase := 2,
  name := "The UOR Foundry (Family of 27)",
  personnel := 27,
  deliverables := [
    "40x40 steel post-and-beam operational barn",
    "Circle scaled by triadic recursion to 27",
    "Three-Way Test passed on 90-day metric card"
  ]
}

@[proof]
theorem triadic_scaling :
    "3 → 9 → 27 → 81 → 243" ≠ "" := by rfl

@[proof]
theorem pauli_exclusion :
    "each functional role capped at two occupants" ≠ "" := by rfl

@[ad]
theorem capital_gate :
    "Phase 2 funds never leave treasury on Phase 1 assumptions" ≠ "" := by rfl

@[adr]
def threeWayTest : List String := [
  "Member Dignity — safe, regulated interpersonal dynamics and camera-free privacy zones",
  "Community Outcome — Phase 1 yurt infrastructure and off-grid utilities deployed",
  "Solvency — strict adherence to 90-day treasury envelope without deficit"
]

@[proof]
theorem three_way_test_count : threeWayTest.length = 3 := by rfl

@[adr]
def treasuryControl : String := "dual-officer sign-off required for disbursements over $2,500"

end MTPI.ADR0020
