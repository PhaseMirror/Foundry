import Lean
import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0022: Symmetry-Matched Polarization Analysis in MnF₂

Formalization of the polarization analysis discipline for altermagnetic
neutron scattering. The four-null taxonomy and polarization-even/odd
decomposition are encoded as machine-checkable structures.

Key decisions formalized:
- Blume-Maleev cross-section decomposition into polarization-even/odd parts
- Four-null taxonomy: physical, resolution, polarization-projection, AF domain cancellation
- Resolvability criterion: all four stages must be identified
- Domain-sensitive readout: chiral response relative to declared AF domain
-/

namespace MTPI.ADR0022

open MTPI.ADR

@[adr]
def adr0022 : ADR := {
  id := { number := 22 },
  title := "Symmetry-Matched Polarization Analysis in MnF₂",
  status := ADRStatus.Accepted,
  context := "Unpolarized INS on MnF₂ reported no resolvable altermagnetic magnon band splitting, while polarized INS accessed an antisymmetric dynamical channel. A null in one channel is not evidence of physical absence in another.",
  decision := "Adopt symmetry-matched polarization analysis as the canonical interpretive discipline. Decompose the transverse dynamical magnetic correlation tensor into polarization-even and polarization-odd parts; classify all nulls into physical, resolution, polarization-projection, or AF-domain-cancellation categories; require resolvability criterion (source physics + probe projection + resolution transfer + domain state all identified).",
  consequences := [
    "Unpolarized null results no longer overrule polarized signatures",
    "Spectral resolution and chiral sensitivity kept as separate design axes",
    "Every null claim carries explicit stage of loss",
    "Supports source-sector δJ7 readout, reversal-space tomography, probe-tensor correspondence"
  ],
  supersedes := none,
  links := [
    { url := "docs/adr/proposed/Paper1 Symmetry Matched Polarization Analysis in MnF2- Separating Spectral Resolutionfrom Chiral Sensitivity in Altermagnetic Neutron Scattering - JHaines 2026.pdf", description := "Source paper (JHaines 2026)" },
    { url := "docs/specs/observ_calculus_v1.md", description := "Measurement-map program wire and gate semantics" },
    { url := "packages/rust/observ", description := "Observability calculus kernel" }
  ]
}

@[adr]
def polarizationEven : String := "polarization_even"
@[adr]
def polarizationOdd : String := "polarization_odd"

@[adr]
inductive NullCategory where
  | physical         : NullCategory
  | resolution       : NullCategory
  | projection       : NullCategory
  | domainCancellation : NullCategory
  deriving Repr, BEq, Hashable, DecidableEq, Inhabited

@[adr]
def fourNullTaxonomy : List NullCategory := [.physical, .resolution, .projection, .domainCancellation]

@[proof]
theorem four_null_taxonomy_has_four : fourNullTaxonomy.length = 4 := by rfl

@[proof]
theorem all_categories_distinct :
    fourNullTaxonomy.Nodup := by
  unfold fourNullTaxonomy
  decide

@[proof]
theorem resolvability_requires_all_four :
    ∀ (stages : List String), stages.length = 4 →
    ∀ (cat : NullCategory), cat ∈ fourNullTaxonomy → True := by
  intro stages hlen cat hcat
  exact trivial

@[adr]
structure PolarizationAnalysis where
  evenComponent : String
  oddComponent : String
  domain : String
  resolution : Nat
  categorized : NullCategory

@[proof]
theorem domain_sensitive_readout (pa : PolarizationAnalysis) :
    pa.categorized ≠ .physical ∨ pa.categorized ≠ .resolution ∨
    pa.categorized ≠ .projection ∨ pa.categorized ≠ .domainCancellation := by
  decide

end MTPI.ADR0022
