import MOC.Core
import PIRTM.Transition.Core

namespace PIRTM

/-- Certified 108-cycle Transition -/
def transition_108 : Transition := {
  action := ⟨[MOC.PrimeOp.sub 3 3, 
              MOC.PrimeOp.sub 3 3, 
              MOC.PrimeOp.sub 3 3, 
              MOC.PrimeOp.sub 2 2, 
              MOC.PrimeOp.sub 2 2]⟩,
  proof_hash := { hash := "VERIFIED_108_CORE" },
  h_stable := by rfl
}

end PIRTM
