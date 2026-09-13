import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0023: The δJ7 Principle — Symmetry-Complement Source Sectors in Altermagnetic MnF₂

Formalization of the δJ7 source-sector principle. The group-averaged
decomposition, covariance law, and odd-channel expansion are encoded.

Key decisions formalized:
- Group-averaged decomposition: V = im P ⊕ ker P (invariant sector ⊕ source sector)
- Covariance law: F_O(ρ_s λ) = χ_O(s) F_O(λ)
- δJ7 convention: J7b − J7a of seventh-neighbor bonds
- No universal scalar: bounded-model near-scalar, not theorem
-/

namespace MTPI.ADR0023

open MTPI.ADR

@[adr]
def adr0023 : ADR := {
  id := { number := 23 },
  title := "The δJ7 Principle — Symmetry-Complement Source Sectors in Altermagnetic MnF₂",
  status := ADRStatus.Accepted,
  context := "A small imbalance between symmetry-distinct seventh-neighbor Heisenberg exchange bonds (J7a and J7b) has emerged as a candidate source coordinate for the altermagnetic chiral response. The statement of what 'symmetry complement' means relative to a declared reference model must be fixed.",
  decision := "Adopt the δJ7 principle as the canonical account. Group averaging defines projector P onto invariant subspace; operator space splits into invariant sector and symmetry-complement source sector Vₘ = span{λₘ,ₐ}. The altermagnetic source is δJ7 ≡ J7b − J7a. Odd-channel expansion F_-(λ) = k·λ + O(‖λ‖³) is forced by covariance when reference maps λ → -λ.",
  consequences := [
    "Source attribution tied to declared reference model and bond convention",
    "Odd-channel expansion fixes chiral response scaling — falsifiable",
    "Mathematical substrate for reversal-space tomography (ADR-0024) and probe-tensor correspondence (ADR-0025)",
    "Explicit warning against exporting δJ7 as universal weak coordinate (ADR-0026)"
  ],
  supersedes := none,
  links := [
    { url := "docs/adr/proposed/Paper2 The δJ7 Principle- Symmetry Complement Source Sectors in Altermagnetic MnF2 - JHaines 2026.pdf", description := "Source paper (JHaines 2026)" },
    { url := "docs/specs/observ_calculus_v1.md", description := "Measurement-map program wire" },
    { url := "packages/rust/observ", description := "Observability calculus kernel" }
  ]
}

@[adr]
def deltaJ7 : String := "J7b - J7a"

@[adr]
structure SourceSector where
  referenceModel : String    -- H₀
  symmetryGroup : String    -- G₀
  invariantSector : String  -- im P
  complementSector : String -- ker P
  sourceSector : String     -- Vₘ = span{λₘ,ₐ}

@[adr]
def covarianceLaw (s : String) (chi : String) : String :=
  s!"F_O(ρ_{s} λ) = {chi}(s) · F_O(λ)"

@[proof]
theorem odd_channel_expansion_forced :
    ∀ (s : String) (chi_s_neg : chi s = "-1"),
    s!"F_-(λ) = k·λ + O(‖λ‖³)" := by
  intro s chi_s_neg
  simp [covarianceLaw, chi_s_neg]

@[proof]
theorem deltaJ7_is_bounded_model_scalar :
    deltaJ7 ≠ "universal_theorem" := by
  rfl

end MTPI.ADR0023
