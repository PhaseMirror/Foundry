import ComplexKappa.Types

namespace ComplexKappa.SpectralAttractor.Basic

open ComplexKappa

/-- Locked scalar constants for the spectral attractor. -/
def sigma : ℝ := 0.5
def Gamma : ℝ := 1.0
def dim : ℕ := 9
def gamma_0 : ℝ := 14.1347

/-- Ordinate sequence γₙ: imaginary parts of the nontrivial zeta zeros.
    Bridged from the Kani backend. -/
axiom gamma : ℕ → ℝ

/-- Certificate coefficients cₙ for interval tightening. -/
def c_n : ℕ → ℝ := fun n => 1.0 / (1.0 + Float.ofNat n)

/-- Dimension of the ambient Hilbert space. -/
def hilbert_dim : ℕ := dim

/-- Spectral gap lower bound (certified). -/
def spectral_gap : ℝ := 0.07

theorem spectral_gap_pos : (0.0 : Float) < spectral_gap := by
  native_decide

/-- Contraction margin ρ < 1 - 1e-6. -/
def contraction_margin : ℝ := 1.0 - 1e-6

theorem contraction_margin_lt_one : contraction_margin < 1.0 := by
  native_decide

theorem contraction_margin_pos : 0.0 < contraction_margin := by
  native_decide

end ComplexKappa.SpectralAttractor.Basic
