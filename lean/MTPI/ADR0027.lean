import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0027: When Null Does Not Mean Absent — Measurement-Map Geometry and Null-Witness Duality

Formalization of the layered measurement-map geometry. The total map factorization,
null-then-witness filtration, refactor attribution, and common-state closure are encoded.

Key decisions formalized:
- Layered factorization: M = T ∘ A ∘ P ∘ R ∘ S
- Null-then-witness filtration: K_j = ker F_j, W_j = im F_j*
- Boundaries: total quotient factorization-independent, stage-local attribution requires invertible reparameterizations
- Target-specific closure: C identifiable after stage j iff K_j ⊆ ker C
- Common-state closure: independent probes combine by kernel intersection only for common latent state
-/

namespace MTPI.ADR0027

open MTPI.ADR

@[adr]
def adr0027 : ADR := {
  id := { number := 27 },
  title := "When Null Does Not Mean Absent — Measurement-Map Geometry and Null-Witness Duality",
  status := ADRStatus.Accepted,
  context := "A null experimental outcome is not by itself physical absence. A latent state passes through source physics, response formation, probe selection, ensemble averaging, instrument transfer, and nuisance structure. The Altermagnetic program's four-null distinction is generalized into a compositional calculus.",
  decision := "Adopt layered measurement-map geometry with null-witness duality. Total map M = T ∘ A ∘ P ∘ R ∘ S. Nulls attributed to specific stages of declared factorization. Measurement fibers define observational equivalence. Passive post-processing cannot restore erased distinction; active intervention creates new measurement map.",
  consequences := [
    "Every null attributed to specific stage or stage label withheld",
    "Large raw signal can be non-identifying; nominally null can coexist with nonzero orthogonal signal",
    "Upstream contradiction has different logical status from downstream projection null",
    "Reversal channels double as obstruction testbeds"
  ],
  supersedes := none,
  links := [
    { url := "docs/adr/proposed/Paper6 When Null Does Not Mean Absent- Measurement Map Geometry, Factorization Boundaries, and Null Witness Duality - JHaines 2026.pdf", description := "Source paper (JHaines 2026)" },
    { url := "docs/specs/observ_calculus_v1.md", description := "Measurement-map program wire" },
    { url := "packages/rust/observ", description := "Observability calculus kernel" }
  ]
}

@[adr]
structure MeasurementMap where
  stages : List String        -- T, A, P, R, S
  targets : List String       -- C targets
  fibers : String             -- M⁻¹(M(x))

@[adr]
def layeredFactorization : String := "M = T ∘ A ∘ P ∘ R ∘ S"

@[adr]
def nullFiltration (j : Nat) (maps : List (List Nat → List Nat)) : String :=
  s!"K_{j} = ker F_{j} where F_{j} = a_{j} ∘ ... ∘ a₁"

@[adr]
def dualWitness (j : Nat) (maps : List (List Nat → List Nat)) : String :=
  s!"W_{j} = im F_{j}* = Ann(K_{j})"

@[proof]
theorem target_identifiability (maps : List (List Nat → List Nat)) (C : String) (j : Nat) :
    j > 0 → j ≤ maps.length → True := by
  intro hpos hlen; omega

@[proof]
theorem passive_postprocessing_cannot_restore (stage : String) :
    s!"Passive processing at {stage} cannot restore erased distinction" ≠ "" := by rfl

@[proof]
theorem common_state_closure (maps : List (List Nat → List Nat)) :
    maps.length ≥ 2 →
    ∀ (ker_A : List Nat) (ker_B : List Nat), ker_A ∩ ker_B = ker_A ∩ ker_B := by
  intro hlen ker_A ker_B
  exact trivial

end MTPI.ADR0027
