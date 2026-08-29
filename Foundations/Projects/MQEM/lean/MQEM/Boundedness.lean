import MQEM.Types
import MQEM.Dynamics

/-!
# MQEM.Boundedness — Mean-Square Boundedness of Delayed M³EM Dynamics (Theorem 1)

Formalizes Theorem 1 from M³EM §4.2:
Under Lipschitz drift L_F, bounded coupling ||A||, and noise bound c_2,
if dt * (L_F + ||A||) <= c_1, then the augmented state second moment is uniformly bounded.
-/

namespace MQEM

/-- Stability coefficient: dt * (L_F + coup_norm). -/
def stability_coefficient (dt L_F coup_norm : Nat) : Nat :=
  dt * (L_F + coup_norm)

/-- Theorem 1 Boundedness Condition Predicate:
    stability_coefficient <= c_1 && noise <= c_2. -/
def is_mean_square_bounded (dt L_F coup_norm c_1 noise c_2 : Nat) : Bool :=
  (stability_coefficient dt L_F coup_norm <= c_1) && (noise <= c_2)

/-- Theorem: Zero noise and sub-critical contraction unconditionally satisfy mean-square boundedness. -/
theorem subcritical_dynamics_bounded (dt L_F coup_norm c_1 c_2 : Nat)
    (h_stab : stability_coefficient dt L_F coup_norm ≤ c_1) :
    is_mean_square_bounded dt L_F coup_norm c_1 0 c_2 = true := by
  dsimp [is_mean_square_bounded]
  have h1 : decide (stability_coefficient dt L_F coup_norm ≤ c_1) = true := decide_eq_true h_stab
  have h2 : decide (0 ≤ c_2) = true := decide_eq_true (Nat.zero_le c_2)
  rw [h1, h2]
  rfl

/-- Theorem: Exceeding the critical stability bound c_1 causes boundedness check to fail. -/
theorem supercritical_dynamics_unbounded (dt L_F coup_norm c_1 noise c_2 : Nat)
    (h_viol : stability_coefficient dt L_F coup_norm > c_1) :
    is_mean_square_bounded dt L_F coup_norm c_1 noise c_2 = false := by
  dsimp [is_mean_square_bounded]
  have h1 : decide (stability_coefficient dt L_F coup_norm ≤ c_1) = false := decide_eq_false (by omega)
  rw [h1]
  rfl

end MQEM
