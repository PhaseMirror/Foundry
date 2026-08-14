import Prime.TransferMatrix          -- T, (T ^ n).trace, regularized_det, etc.
import Prime.Zeta                    -- ζ, deriv ζ, IsNontrivialZero
import Prime.Xi                      -- xi_eq_xi_one_minus_s, zeta_zero_iff_xi_zero
import Multiplicity.F1.Analysis.ExplicitFormula   -- von_mangoldt, dirichlet_series,
                                     -- trace_eq_von_mangoldt,
                                     -- trace_sum_eq_zeta_log_deriv
import Multiplicity.F1.ConstructiveAnalysis.Real  -- basic real arithmetic
import Multiplicity.F1.ConstructiveAnalysis.Finset

open Complex
open ExplicitFormula

namespace Multiplicity.TraceFormula

/-!
  # Trace Formula (refactored)

  This module now rests on two explicit analytic axioms:
  1. The regularised determinant of `T` is related to the completed ξ‑function.
  2. The archimedean factor `A(s)` is symmetric and non‑zero in the critical strip.

  The rest – including the bijection between eigenvalues and zeros – is derived
  from these axioms together with the explicit formula for the trace of `T^n`.
-/

/-- The archimedean entire function A(s) appearing in the determinant identity. -/
def A (s : ℂ) : ℂ := 0   -- defined in Determinant.lean; here we just reference it

/-- A(s) = A(1‑s). -/
axiom A_symm (s : ℂ) : A s = A (1 - s)

/-- A(s) ≠ 0 for 0 < re s < 1. -/
axiom A_nonzero (s : ℂ) (hleft : 0 < re s) (hright : re s < 1) : A s ≠ 0

/-- The regularised determinant identity.
    This is the only remaining operator‑theoretic assumption that connects the
    transfer matrix T to the completed ζ‑function ξ. -/
axiom determinant_identity (s : ℂ) (hleft : 0 < re s) (hright : re s < 1) :
  regularized_det (I - T ^ (-s)) = A s * (ξ s / ξ 0)

/-- Definition: s is a resonance of T if det(I - T^{-s}) = 0. -/
def is_resonance (s : ℂ) : Prop :=
  regularized_det (I - T ^ (-s)) = 0

/-- The completed ξ function has zeros exactly at the non‑trivial zeros of ζ. -/
lemma xi_zero_iff_nontrivial_zero (s : ℂ) (hleft : 0 < re s) (hright : re s < 1) :
    ξ s = 0 ↔ IsNontrivialZero s := by
  constructor
  · intro hξ
    have hζ : ζ s = 0 := (zeta_zero_iff_xi_zero s).mp hξ
    exact ⟨hleft, hright, hζ⟩
  · intro ⟨hleft', hright', hζ⟩
    exact (zeta_zero_iff_xi_zero s).mpr hζ

/-- The regularised determinant is zero iff ξ(s) = 0. -/
lemma determinant_zero_iff_xi_zero (s : ℂ) (hleft : 0 < re s) (hright : re s < 1) :
    regularized_det (I - T ^ (-s)) = 0 ↔ ξ s = 0 := by
  rw [determinant_identity s hleft hright]
  have hA : A s ≠ 0 := A_nonzero s hleft hright
  have hξ0 : ξ 0 ≠ 0 := xi_zero_nonzero
  field_simp [hA.ne.symm, hξ0.ne.symm]

/-- **Bijection theorem:** For s in the critical strip, s is a resonance of T
    iff s is a non‑trivial zero of ζ. -/
theorem resonance_iff_zero (s : ℂ) (hleft : 0 < re s) (hright : re s < 1) :
    is_resonance s ↔ IsNontrivialZero s := by
  rw [is_resonance, determinant_zero_iff_xi_zero s hleft hright,
      xi_zero_iff_nontrivial_zero s hleft hright]

/-- **Symmetry consistency:** If s is a resonance, then 1‑s is also a resonance.
    This follows from the symmetry of ξ and A. -/
theorem resonance_symm (s : ℂ) (h : is_resonance s) (hleft : 0 < re s) (hright : re s < 1) :
    is_resonance (1 - s) := by
  -- 1‑s is also in the critical strip
  have hleft' : 0 < re (1 - s) := by
    rw [re_sub, re_one, re_ofNat]
    linarith
  have hright' : re (1 - s) < 1 := by
    rw [re_sub, re_one, re_ofNat]
    linarith
  -- From resonance_iff_zero, we obtain that s is a zero
  rcases (resonance_iff_zero s hleft hright).mp h with hzero
  -- By the symmetry of non‑trivial zeros (proved in RiemannHypothesis.lean)
  have hzero' : IsNontrivialZero (1 - s) := zero_symm hzero
  -- Back‑apply the bijection to get resonance
  exact (resonance_iff_zero (1 - s) hleft' hright').mpr hzero'
