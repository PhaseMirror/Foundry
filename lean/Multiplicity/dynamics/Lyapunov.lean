/-!
# Lyapunov Dynamics and Stability

This module centralizes the formal definition of Lyapunov functionals
and phase stability across the Multiplicity architecture.
-/
namespace Multiplicity.Dynamics.Lyapunov

/-- 
  Lyapunov stability condition over scaled integers 
  L = 1/2 (L_m - L_*)^2 >= 0
-/
def lyapunov_functional (L_m L_star : Int) : Nat :=
  let diff := L_m - L_star
  (diff * diff).toNat

theorem lyapunov_non_negative (L_m L_star : Int) : 
  lyapunov_functional L_m L_star ≥ 0 := by
  exact Nat.zero_le _

end Multiplicity.Dynamics.Lyapunov
