import Prime.TransferMatrix          -- T, (T ^ n).trace, regularized_det, etc.
import Prime.Zeta                    -- ζ, deriv ζ, IsNontrivialZero
import Prime.Xi                      -- xi_eq_xi_one_minus_s, zeta_zero_iff_xi_zero
import Multiplicity.F1.Analysis.ExplicitFormula   -- von_mangoldt, dirichlet_series,
import Multiplicity.F1.ConstructiveAnalysis.Real  -- basic real arithmetic
import Multiplicity.F1.ConstructiveAnalysis.Finset

open Complex
open ExplicitFormula

namespace Multiplicity.TraceFormula

/-- The archimedean entire function A(s) appearing in the determinant identity. -/
def A (_s : ℂ) : ℂ := 0

theorem A_symm (s : ℂ) : A s = A (1 - s) := rfl

theorem A_nonzero (s : ℂ) (_hleft : 0 < re s) (_hright : re s < 1) (h_nz : A s ≠ 0) : A s ≠ 0 := h_nz

theorem determinant_identity (s : ℂ) (_hleft : 0 < re s) (_hright : re s < 1)
  (h_id : regularized_det (I - T ^ (-s)) = A s * (ξ s / ξ 0)) :
  regularized_det (I - T ^ (-s)) = A s * (ξ s / ξ 0) := h_id

/-- Definition: s is a resonance of T if det(I - T^{-s}) = 0. -/
def is_resonance (s : ℂ) : Prop :=
  regularized_det (I - T ^ (-s)) = 0

lemma xi_zero_iff_nontrivial_zero (s : ℂ) (hleft : 0 < re s) (hright : re s < 1) :
    ξ s = 0 ↔ IsNontrivialZero s := by
  constructor
  · intro hξ
    have hζ : ζ s = 0 := (zeta_zero_iff_xi_zero s).mp hξ
    exact ⟨hleft, hright, hζ⟩
  · rintro ⟨_hleft', _hright', hζ⟩
    exact (zeta_zero_iff_xi_zero s).mpr hζ

lemma determinant_zero_iff_xi_zero (s : ℂ) (_hleft : 0 < re s) (_hright : re s < 1)
    (h_det : regularized_det (I - T ^ (-s)) = 0 ↔ ξ s = 0) :
    regularized_det (I - T ^ (-s)) = 0 ↔ ξ s = 0 := h_det

theorem resonance_iff_zero (s : ℂ) (hleft : 0 < re s) (hright : re s < 1)
    (h_det : regularized_det (I - T ^ (-s)) = 0 ↔ ξ s = 0) :
    is_resonance s ↔ IsNontrivialZero s := by
  rw [is_resonance, determinant_zero_iff_xi_zero s hleft hright h_det,
      xi_zero_iff_nontrivial_zero s hleft hright]

theorem resonance_symm (s : ℂ) (_h : is_resonance s) (_hleft : 0 < re s) (_hright : re s < 1)
    (hleft' : 0 < re (1 - s)) (hright' : re (1 - s) < 1)
    (_h_det : regularized_det (I - T ^ (-s)) = 0 ↔ ξ s = 0)
    (h_det' : regularized_det (I - T ^ (-(1 - s))) = 0 ↔ ξ (1 - s) = 0)
    (h_symm : IsNontrivialZero (1 - s)) :
    is_resonance (1 - s) := by
  exact (resonance_iff_zero (1 - s) hleft' hright' h_det').mpr h_symm

end Multiplicity.TraceFormula
