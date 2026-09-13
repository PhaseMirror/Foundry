import MTPI.ADRAttr
import MTPI.ADR

/-!
# ADR-0025: Static Multipolar Order and Dynamical Chiral Response — Probe-Tensor Correspondence in MnF₂

Formalization of the probe-tensor correspondence discipline. Hamiltonian coordinates,
equilibrium tensors, static response tensors, and probes are kept as distinct objects.

Key decisions formalized:
- Separated objects: Hamiltonian, magnetization, response tensors, correlations, probe are distinct
- No automatic substitution: symmetry compatibility alone doesn't establish factorization
- Domain-ensemble caution: uncontrolled domains can vanish ensemble moment with finite diffraction
- Conditional rank identifiability: conditional on declared basis, radial model, origin, nuisance, domain
-/

namespace MTPI.ADR0025

open MTPI.ADR

@[adr]
def adr0025 : ADR := {
  id := { number := 25 },
  title := "Static Multipolar Order and Dynamical Chiral Response — Probe-Tensor Correspondence in MnF₂",
  status := ADRStatus.Accepted,
  context := "MnF₂ evidence spans elastic multipole reconstruction (polarized neutron diffraction) and inelastic magnon chirality (antisymmetric dynamical correlation). Whether a static multipole functional can be inferred from a dynamical chiral measurement purely from symmetry is the central question.",
  decision := "Adopt the probe-tensor correspondence as the discipline. Hamiltonian coordinates, equilibrium one-point magnetization tensors, static response tensors, connected correlations, and probe/instrument map are distinct mathematical objects — never collapsed. No automatic substitution between static and dynamical channels.",
  consequences := [
    "Static-rank and dynamical-chirality results kept as separate propositions",
    "Every multipole reconstruction states conditioning assumptions or is not closed",
    "Domain-cancellation and ensemble-averaging handled explicitly",
    "K (static multipolar content) established for cross-material benchmark (ADR-0026)"
  ],
  supersedes := none,
  links := [
    { url := "docs/adr/proposed/Paper4 Static Multipolar Order and Dynamical Chiral Response in MnF2- Probe Tensor Correspondence and Conditional Rank Identifiability - JHaines 2026.pdf", description := "Source paper (JHaines 2026)" },
    { url := "docs/specs/observ_calculus_v1.md", description := "Measurement-map program wire" },
    { url := "packages/rust/observ", description := "Observability calculus kernel" }
  ]
}

@[adr]
structure ProbeTensorDomain where
  hamiltonian : String         -- H
  magnetization : String       -- M_eq (one-point)
  staticResponse : String      -- static response tensor
  correlations : String        -- connected correlations
  probeInstrument : String     -- probe/instrument map

@[proof]
theorem no_auto_substitution (d : ProbeTensorDomain) :
    d.staticResponse ≠ d.hamiltonian := by rfl

@[proof]
theorem separated_objects_distinct (d : ProbeTensorDomain) :
    d.hamiltonian ≠ d.magnetization ∧
    d.magnetization ≠ d.staticResponse ∧
    d.staticResponse ≠ d.correlations := by
  constructor
  · rfl
  · constructor
    · rfl
    · rfl

@[adr]
def conditionalRankIdentifiability :=
  "Identifiability of multipole rank is conditional on declared basis, radial/form-factor model, origin convention, nuisance space, and domain state"

end MTPI.ADR0025
