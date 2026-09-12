/-
Copyright (c) 2026 Citizen Gardens / Multiplicity Foundation.
Released under Apache 2.0 license.

! ADR-0034-F1-Geometry Scaffolding — umbrella module
-/
import Foundations.SpectralAttractor.Tags
import Foundations.SpectralAttractor.Basic
import Foundations.SpectralAttractor.Certificates
import Foundations.SpectralAttractor.Matrices
import Foundations.SpectralAttractor.CPTP
import Foundations.SpectralAttractor.Contraction
import Foundations.SpectralAttractor.Energy
import Foundations.SpectralAttractor.Atlas
import Foundations.SpectralAttractor.Hyperplane
import Foundations.SpectralAttractor.AtlasDominance
import Foundations.SpectralAttractor.Tests

/-!
# ComplexKappa.SpectralAttractor

Umbrella re-export of the ADR-0034 spectral-attractor scaffolding.

Module map (import order matters; each layer consumes only earlier layers):

* `Tags`         — governance attributes `@[adr]`, `@[proof]`
* `Basic`        — locked constants: dim 9, ordinates, σ, carrier signatures
* `Certificates` — rational interval enclosures and their consequences
* `Matrices`     — H, L as explicit 9×9 matrices; indefinite proxy kernel
* `CPTP`         — Kraus data, dephasing channel, trace preservation
* `Contraction`  — contraction estimates for the attractor
* `Energy`       — integer-layer Lyapunov accounting: dissipation quanta,
                   division balance, squaring-orbit exponents, strict
                   energy descent (`orbitEnergy_step`)
* `Atlas`        — admissible tests, defect projections, compressed traces,
                   `compressedTrace_nonneg` (unconditional),
                   `atlas_positivity` (two named analytic obligations)
* `Hyperplane`   — hyperplane substrate, basis differences, proxy signature
* `AtlasDominance` — finite-stage coupled Weil kernel over ℤ: Gate B
                   (`WeilPSD_gramOf`, free), the capstone
                   (`coupledWeil_psd_iff_dominates`), and the AC-15/AC-16
                   interface bundle (`AtlasCoupling`,
                   `atlas_derived_dominance_stage`) whose single
                   hypothesis is the factorization identity

The namespace is `ComplexKappa.SpectralAttractor` throughout.
-/

namespace ComplexKappa.SpectralAttractor

/-- Sanity: the locked dimension is available through the umbrella. -/
example : dim = 9 := rfl

end ComplexKappa.SpectralAttractor
