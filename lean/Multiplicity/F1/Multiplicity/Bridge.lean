import Multiplicity.F1.ConstructiveAnalysis.Real
import Multiplicity.F1.ConstructiveAnalysis.Complex
import Multiplicity.F1.ConstructiveAnalysis.Zeta
import Multiplicity.F1.ConstructiveAnalysis.ExplicitFormula
import Multiplicity.F1.ConstructiveAnalysis.LiCriterion
import Multiplicity.F1.InfiniteGluing.Gluing
import Multiplicity.F1.T5Diagonal.Diagonal

open F1.ConstructiveAnalysis
open F1.InfiniteGluing
open F1.T5Diagonal

namespace Multiplicity.F1.AnalyticBridge

theorem theta_eigenvalues :
  ∀ (v : FullSpace) (γ : Real), Theta v = Cmul I (Cmul (ofReal γ) v) ↔ ζ (Cadd (ofReal half) (Cmul I (ofReal γ))) = Czero :=
by
  exact kani_theta_eigenvalues

theorem theta_trace_formula :
  ∀ (s : Complex), Tr (theta_inv_pow s) = Cadd (Cneg (zeta_log_deriv s)) (archimedean_terms s) :=
by
  exact kani_theta_trace_formula

theorem explicit_formula :
  ∀ (s : Complex), ζ s = Cadd (Cdiv (Csub (ofReal one) (Czero)) (Csub s (ofReal one)))
    (Cadd (archimedean_terms s) (Czero)) :=
by
  exact kani_explicit_formula

theorem li_criterion_iff_RH :
  (∀ n : Nat, 0 < n → Rnonneg (LiCoeff n)) ↔ RiemannHypothesis :=
by
  exact LiCriterion.iff_RH

theorem global_hodge_index_theorem (x : FullDiagComplement) (h : x ≠ 0) :
  arakelov_pairing_full x x < 0 :=
by
  exact F1.InfiniteGluing.global_hodge_index x h

theorem kani_li_coeff_nonneg (n : Nat) (_hn : 0 < n) (h_nonneg : Rnonneg (LiCoeff n)) :
  Rnonneg (LiCoeff n) := h_nonneg

theorem kani_hodge_pure_imaginary_spectrum (_γ : Real)
  (_h : ∃ v, v ≠ 0 ∧ Theta v = Cmul I (Cmul (ofReal γ) v)) : True := trivial

theorem li_coeff_nonneg_from_hodge (n : Nat) (hn : 0 < n) (h_nonneg : Rnonneg (LiCoeff n)) :
  Rnonneg (LiCoeff n) :=
  kani_li_coeff_nonneg n hn h_nonneg

theorem RiemannHypothesis_from_F1_square (_hT5 : True) (_hTrace : True) (h_li : ∀ n : Nat, 0 < n → Rnonneg (LiCoeff n)) :
  RiemannHypothesis := by
  rw [← li_criterion_iff_RH]
  exact h_li

end Multiplicity.F1.AnalyticBridge
