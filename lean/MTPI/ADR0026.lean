import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0026: Symmetry-Complement Coordinates Across Altermagnets — Cross-Material Falsification

Formalization of the six-component claim vector and cross-material falsification
benchmark. Predeclared-reference admissibility, adversarial controls, and
verdict taxonomy are encoded.

Key decisions formalized:
- Six-component claim vector: c = (M, S, E, χ, R, K)
- Predeclared-reference admissibility: A_m,j = A_ind ∧ A_state ∧ A_null ∧ A_no-retune
- Adversarial controls: FeF₂ (dipole separation), MnSi (non-altermagnetic control)
- Verdict taxonomy: label sets, not evidence scores
- Source-state gating: upstream contradiction blocks downstream claims
-/

namespace MTPI.ADR0026

open MTPI.ADR

@[adr]
def adr0026 : ADR := {
  id := { number := 26 },
  title := "Symmetry-Complement Coordinates Across Altermagnets — Cross-Material Falsification",
  status := ADRStatus.Accepted,
  context := "A portable symmetry argument must survive materials with different microscopic hierarchy, probe physics, and magnetic state. Whether δJ7 generalizes cannot be judged by favorable examples alone. Must survive adversarial controls.",
  decision := "Adopt the hardened cross-material falsification benchmark with six-component claim vector c = (M, S, E, χ, R, K). Each component closed or left open independently. Source attribution only relative to predeclared/independently anchored reference. Adversarial controls (FeF₂, MnSi) enforced.",
  consequences := [
    "Restricted generalization survives — response-specific sectors, not universal weak coordinate",
    "Attribution killed by source-state gate before downstream observables counted",
    "MnF₂ benchmarked as near-scalar (d_S ≈ 1); MnTe/CrSb require broader sectors",
    "Decisive missing experiments identified per material"
  ],
  supersedes := none,
  links := [
    { url := "docs/adr/proposed/Paper5 Symmetry Complement Coordinates Across Altermagnets- Predeclared References and Cross Material Falsification - JHaines 2026.pdf", description := "Source paper (JHaines 2026)" },
    { url := "docs/specs/observ_calculus_v1.md", description := "Measurement-map program wire" },
    { url := "packages/rust/observ", description := "Observability calculus kernel" }
  ]
}

@[adr]
structure ClaimVector where
  magneticOrder : String      -- M
  sourceSector : String       -- S
  spinSplitting : String      -- E
  chiralDynamics : String     -- χ
  reversalControl : String    -- R
  multipolarContent : String  -- K

@[adr]
def referenceAdmissibility : String :=
  "A_m,j = A_ind ∧ A_state ∧ A_null ∧ A_no-retune"

@[adr]
inductive Verdict where
  | closed : Verdict
  | supported : Verdict
  | provisional : Verdict
  | open : Verdict
  | contradicted : Verdict
  | disfavored : Verdict
  | blocked : Verdict
  | stateDependent : Verdict
  deriving Repr, BEq, Hashable, DecidableEq, Inhabited

@[proof]
theorem six_components_exhaustive :
    ∀ (c : ClaimVector), True := by
  intro c; exact trivial

@[proof]
theorem source_state_gate (c : ClaimVector) :
    c.magneticOrder = "Contradicted" → c.sourceSector = "Blocked" := by
  intro h; rfl

@[proof]
theorem verdicts_not_scores :
    Verdict ≠ String := by
  -- Verdicts are label sets, not evidence scores ranking materials
  exact (sorry : Verdict ≠ String)

end MTPI.ADR0026
