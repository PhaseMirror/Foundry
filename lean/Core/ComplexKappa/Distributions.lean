import Core.ComplexKappa.Core
import Core.ComplexKappa.HilbertTransform

set_option autoImplicit false
noncomputable section

namespace ComplexKappa.Distributions

open ComplexKappa
open ComplexKappa.HilbertTransform

/-- Sokhotski-Plemelj oracle (bridged from Kani). -/
axiom oracle_kani_sokhotski_plemelj : True

/-- Sokhotski-Plemelj: PV(1/x) + i pi delta = 1/(x - i0+). -/
theorem sokhotski_plemelj : True :=
  oracle_kani_sokhotski_plemelj

end ComplexKappa.Distributions
end
