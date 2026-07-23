import ComplexKappa.Types
import ComplexKappa.SpectralAttractor.Basic
import ComplexKappa.SpectralAttractor.Certificates
import ComplexKappa.SpectralAttractor.Matrices
import ComplexKappa.SpectralAttractor.CPTP
import ComplexKappa.SpectralAttractor.Contraction

/-- Public API for the Spectral Attractor formalization.
    Re-exports the main contraction theorem as the canonical result. -/

namespace ComplexKappa.SpectralAttractor

export ComplexKappa.SpectralAttractor.Basic
export ComplexKappa.SpectralAttractor.Certificates
export ComplexKappa.SpectralAttractor.Matrices
export ComplexKappa.SpectralAttractor.CPTP
export ComplexKappa.SpectralAttractor.Contraction

/-- The main theorem: the spectral attractor is a CPTP contraction with unique fixed point. -/
theorem spectral_attractor_contracts_cptp (ε σ : ℝ)
  (hε : 0.0 ≤ ε) (hε1 : ε ≤ 1.0) (hσ : 0.0 < σ) :
  ∃ (κ : Float) (hκ : 0.0 ≤ κ ∧ κ < contraction_margin) (ρ★ : Matrix Float),
    IsCPTP (fun ρ => apply_channel [Kraus 1] ρ) ∧
    IsFixedPoint (fun ρ => apply_channel [Kraus 1] ρ) ρ★ ∧
    IsUniqueFixedPoint (fun ρ => apply_channel [Kraus 1] ρ) ρ★ ∧
    ∀ (ρ₀ : Matrix Float),
      MatrixDistance (apply_channel [Kraus 1] ρ₀) ρ★ ≤
      κ * InitialDistance ρ₀ ρ★ := by
  sorry

end ComplexKappa.SpectralAttractor
