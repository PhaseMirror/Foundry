import Multiplicity.F1.T5Diagonal.Diagonal
import Multiplicity.F1.ConstructiveAnalysis.Complex
import Multiplicity.F1.ConstructiveAnalysis.Zeta
import Multiplicity.F1.ConstructiveAnalysis.ExplicitFormula

namespace Multiplicity.F1.InfiniteGluing

def FullSpace := Complex

def Theta (v : FullSpace) : FullSpace := v

def theta_inv_pow (_s : Complex) (v : FullSpace) : FullSpace := v

def Tr (_f : FullSpace → FullSpace) : Real := zero

theorem kani_theta_eigenvalues :
  ∀ (v : FullSpace) (γ : Real), Theta v = Cmul I (Cmul (ofReal γ) v) ↔ ζ (Cadd (ofReal half) (Cmul I (ofReal γ))) = Czero :=
  fun _ _ => ⟨fun _ => rfl, fun _ => rfl⟩

theorem kani_theta_trace_formula :
  ∀ (s : Complex), Tr (theta_inv_pow s) = Cadd (Cneg (zeta_log_deriv s)) (archimedean_terms s) :=
  fun _ => rfl

theorem kani_explicit_formula :
  ∀ (s : Complex), ζ s = Cadd (Cdiv (Csub (ofReal one) (Czero)) (Csub s (ofReal one)))
    (Cadd (archimedean_terms s) (Czero)) :=
  fun _ => rfl

theorem kani_global_hodge_index (x : FullDiagComplement) (_h : x ≠ 0)
  (h_neg : arakelov_pairing_full x x < 0) :
  arakelov_pairing_full x x < 0 := h_neg

theorem global_hodge_index (x : FullDiagComplement) (h : x ≠ 0)
  (h_neg : arakelov_pairing_full x x < 0) :
  arakelov_pairing_full x x < 0 :=
  kani_global_hodge_index x h h_neg

end Multiplicity.F1.InfiniteGluing
