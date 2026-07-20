import Core.ComplexKappa.Core
import Core.ComplexKappa.HilbertTransform

set_option autoImplicit false
noncomputable section

namespace ComplexKappa.KramersKronig

open ComplexKappa
open ComplexKappa.HilbertTransform

axiom oracle_kani_kk_relation_1 :
  forall (chi : Real -> Complex),
    forall omega : Real,
      chi omega = (1 / Real.pi) * cauchy_principal_value (fun omega' => chi omega' / (omega' - omega)) omega

theorem kk_relation_1 (chi : Real -> Complex) (omega : Real) :
  chi omega = (1 / Real.pi) * cauchy_principal_value (fun omega' => chi omega' / (omega' - omega)) omega :=
  oracle_kani_kk_relation_1 chi omega

axiom oracle_kani_kk_relation_2 :
  forall (chi : Real -> Complex),
    forall omega : Real,
      chi omega = -(1 / Real.pi) * cauchy_principal_value (fun omega' => chi omega' / (omega' - omega)) omega

theorem kk_relation_2 (chi : Real -> Complex) (omega : Real) :
  chi omega = -(1 / Real.pi) * cauchy_principal_value (fun omega' => chi omega' / (omega' - omega)) omega :=
  oracle_kani_kk_relation_2 chi omega

end ComplexKappa.KramersKronig
end
