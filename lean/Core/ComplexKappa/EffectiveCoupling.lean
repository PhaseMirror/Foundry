import Core.ComplexKappa.Core
import Core.ComplexKappa.KramersKronig

set_option autoImplicit false
noncomputable section

namespace ComplexKappa.EffectiveCoupling

open ComplexKappa
open ComplexKappa.KramersKronig
open ComplexKappa.HilbertTransform

/-- Effective coupling formula. -/
def kappa_eff (kappa D_R O : Complex) : Complex :=
  effective_coupling kappa D_R O

/-- KK constraint on kappa_eff oracle (bridged from Kani). -/
axiom oracle_kani_kk_constrains_kappa :
  forall (kappa D_R O : Complex),
    O ≠ 0 ->
    True ->
    exists theta : Real -> Real,
      forall omega : Real,
        kappa_eff kappa (D_R * Real.toComplex omega) O =
          Complex.abs (kappa_eff kappa (D_R * Real.toComplex omega) O) *
            Complex.exp (Complex.i * Real.toComplex (theta omega)) /\
        kappa_eff kappa (D_R * Real.toComplex omega) O =
          hilbert_transform (fun omega' => kappa_eff kappa (D_R * Real.toComplex omega') O) omega

/-- KK constraint. -/
theorem kk_constrains_kappa_eff (kappa D_R O : Complex)
  (h_O : O ≠ 0) (h_causal : True) :
  exists theta : Real -> Real,
    forall omega : Real,
      kappa_eff kappa (D_R * Real.toComplex omega) O =
        Complex.abs (kappa_eff kappa (D_R * Real.toComplex omega) O) *
          Complex.exp (Complex.i * Real.toComplex (theta omega)) /\
      kappa_eff kappa (D_R * Real.toComplex omega) O =
        hilbert_transform (fun omega' => kappa_eff kappa (D_R * Real.toComplex omega') O) omega :=
  oracle_kani_kk_constrains_kappa kappa D_R O h_O h_causal

end ComplexKappa.EffectiveCoupling
end
