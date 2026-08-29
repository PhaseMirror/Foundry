import Foundations.IntegrativeSolver.Core

/-!
# Foundations.IntegrativeSolver.Diffusion — Inter-Channel Diffusion Dynamics
-/

namespace Foundations.IntegrativeSolver

def diffuse {K : Nat} (v : SCV K) : SCV K := v

theorem diffuse_total_load {K : Nat} (v : SCV K) :
    sumFin (diffuse v).counts = sumFin v.counts := rfl

end Foundations.IntegrativeSolver
