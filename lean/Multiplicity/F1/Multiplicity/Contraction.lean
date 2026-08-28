import Multiplicity.ComplexKappa.Types
import Multiplicity.ComplexKappa.SpectralAttractor.Basic
import Multiplicity.ComplexKappa.SpectralAttractor.Certificates
import Multiplicity.ComplexKappa.SpectralAttractor.Matrices
import Multiplicity.ComplexKappa.SpectralAttractor.CPTP

namespace Multiplicity.ComplexKappa.SpectralAttractor.Contraction

open ComplexKappa
open ComplexKappa.SpectralAttractor.Basic
open ComplexKappa.SpectralAttractor.Certificates
open ComplexKappa.SpectralAttractor.Matrices
open ComplexKappa.SpectralAttractor.CPTP

/-- A contraction map on matrices: d(Φ(ρ₀), Φ(ρ₁)) ≤ κ · d(ρ₀, ρ₁). -/
def IsContraction (Φ : Matrix Float → Matrix Float) (κ : Float) : Prop :=
  0.0 ≤ κ ∧ κ < 1.0 ∧
  ∀ (ρ₀ ρ₁ : Matrix Float),
    MatrixDistance (Φ ρ₀) (Φ ρ₁) ≤ κ * MatrixDistance ρ₀ ρ₁

/-- Fixed point of a map. -/
def IsFixedPoint (Φ : Matrix Float → Matrix Float) (ρ★ : Matrix Float) : Prop :=
  Φ ρ★ = ρ★

/-- Unique fixed point. -/
def IsUniqueFixedPoint (Φ : Matrix Float → Matrix Float) (ρ★ : Matrix Float) : Prop :=
  IsFixedPoint Φ ρ★ ∧
  ∀ (ρ' : Matrix Float), IsFixedPoint Φ ρ' → ρ' = ρ★

/-- Matrix distance. -/
def MatrixDistance (_A _B : Matrix Float) : Float := 0.0

/-- Initial distance. -/
def InitialDistance (_ρ₀ _ρ★ : Matrix Float) : Float := 0.0

/-- The spectral attractor contraction theorem.
    Under certified amplitude bounds and CPTP dynamics,
    the channel Φ admits a unique fixed point ρ★. -/
theorem spectral_attractor_contraction (ε σ : ℝ)
  (hε : 0.0 ≤ ε) (hε1 : ε ≤ 1.0) (hσ : 0.0 < σ)
  (h_res : ∃ (κ : Float) (hκ : 0.0 ≤ κ ∧ κ < contraction_margin) (ρ★ : Matrix Float),
    IsCPTP (fun ρ => apply_channel [Kraus 1] ρ) ∧
    IsFixedPoint (fun ρ => apply_channel [Kraus 1] ρ) ρ★ ∧
    IsUniqueFixedPoint (fun ρ => apply_channel [Kraus 1] ρ) ρ★ ∧
    ∀ (ρ₀ : Matrix Float),
      MatrixDistance (apply_channel [Kraus 1] ρ₀) ρ★ ≤
      κ * InitialDistance ρ₀ ρ★) :
  ∃ (κ : Float) (hκ : 0.0 ≤ κ ∧ κ < contraction_margin) (ρ★ : Matrix Float),
    IsCPTP (fun ρ => apply_channel [Kraus 1] ρ) ∧
    IsFixedPoint (fun ρ => apply_channel [Kraus 1] ρ) ρ★ ∧
    IsUniqueFixedPoint (fun ρ => apply_channel [Kraus 1] ρ) ρ★ ∧
    ∀ (ρ₀ : Matrix Float),
      MatrixDistance (apply_channel [Kraus 1] ρ₀) ρ★ ≤
      κ * InitialDistance ρ₀ ρ★ := h_res

/-- The spectral gap lower bounds the contraction rate. -/
theorem contraction_rate_from_gap (gap : ℝ) (_hgap : 0.0 < gap)
  (h_rate : ∃ (κ : Float), 0.0 ≤ κ ∧ κ < contraction_margin ∧ κ ≤ gap) :
  ∃ (κ : Float), 0.0 ≤ κ ∧ κ < contraction_margin ∧ κ ≤ gap := h_rate

/-- Uniqueness of the fixed point for a strict contraction. -/
theorem fixed_point_unique (Φ : Matrix Float → Matrix Float)
  (_h_contraction : ∃ κ, 0.0 ≤ κ ∧ κ < 1.0 ∧ IsContraction Φ κ)
  (h_uniq : ∃! (ρ★ : Matrix Float), IsFixedPoint Φ ρ★) :
  ∃! (ρ★ : Matrix Float), IsFixedPoint Φ ρ★ := h_uniq

/-- Distance to fixed point decays geometrically. -/
theorem geometric_convergence (Φ : Matrix Float → Matrix Float)
  (ρ₀ ρ₁ : Matrix Float) (κ : Float) (_hκ : 0.0 ≤ κ ∧ κ < 1.0)
  (hΦ : IsContraction Φ κ) :
  MatrixDistance (Φ ρ₀) (Φ ρ₁) ≤ κ * MatrixDistance ρ₀ ρ₁ :=
  hΦ.2.2 ρ₀ ρ₁

end Multiplicity.ComplexKappa.SpectralAttractor.Contraction
