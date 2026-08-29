import UniversalLogic.Types

set_option autoImplicit false

/-!
# Contractive Safety Projection (CSP) Banach Contraction & Certification
-/

namespace UniversalLogic

/-- Fixed-point scaled SlopeUB: (1000 - alpha) + (alpha * L_F) / 1000. -/
def compute_slope_ub (alpha lf : Nat) : Nat :=
  (1000 - alpha.min 1000) + (alpha.min 1000 * lf) / 1000

/-- Theorem (CSP Contraction): If L_F < 1000 and alpha > 0, then SlopeUB < 1000. -/
theorem csp_contraction_guarantee (alpha lf : Nat)
    (h_alpha_pos : alpha > 0)
    (h_alpha_le : alpha ≤ 1000)
    (h_lf : lf < 1000) :
    compute_slope_ub alpha lf < 1000 := by
  dsimp [compute_slope_ub]
  have h_amin : alpha.min 1000 = alpha := Nat.min_eq_left h_alpha_le
  rw [h_amin]
  have h_prod : alpha * lf < 1000 * alpha := by
    have : alpha * lf < alpha * 1000 := Nat.mul_lt_mul_of_pos_left h_lf h_alpha_pos
    omega
  have h_div : (alpha * lf) / 1000 < alpha := Nat.div_lt_of_lt_mul h_prod
  omega

/-- Safety Projector Pi_S on [0, 1000] interval. -/
def project_unit_interval (x : Int) : Nat :=
  if x < 0 then 0 else if x > 1000 then 1000 else x.toNat

/-- Theorem: Projection to unit interval is strictly within [0, 1000]. -/
theorem project_unit_interval_bounded (x : Int) :
    project_unit_interval x ≤ 1000 := by
  dsimp [project_unit_interval]
  split
  · omega
  · split
    · omega
    · rename_i h1 h2
      omega

end UniversalLogic
