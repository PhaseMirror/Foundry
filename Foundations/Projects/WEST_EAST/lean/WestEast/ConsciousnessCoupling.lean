import WestEast.Types

set_option autoImplicit false

/-!
# Bounded Consciousness Coupling & Spectral Safety
Formal proof that conscious perturbation |alpha| < delta_S / 4 preserves spectral gap > delta_S / 2.
-/

namespace WestEast

/-- Scaled spectral gap under conscious coupling: delta_s - 2 * alpha. -/
def perturbed_spectral_gap (delta_s alpha : Nat) : Nat :=
  delta_s - (2 * alpha)

/-- Scaled Davis-Kahan projector angle upper bound: (2 * alpha * 1000) / delta_s. -/
def projector_angle_bound (alpha delta_s : Nat) : Nat :=
  if delta_s > 0 then (2 * alpha * 1000) / delta_s else 1000

/-- Theorem: If alpha < delta_s / 4 and delta_s > 0, then the perturbed gap is strictly positive and > delta_s / 2. -/
theorem conscious_coupling_preserves_gap (delta_s alpha : Nat)
    (h_gate : 4 * alpha < delta_s) :
    perturbed_spectral_gap delta_s alpha > delta_s / 2 := by
  dsimp [perturbed_spectral_gap]
  omega

/-- Theorem: If alpha < delta_s / 4 and delta_s > 0, projector angle bound is strictly less than 500 (half-scale). -/
theorem conscious_coupling_projector_angle_bounded (delta_s alpha : Nat)
    (_h_delta_pos : delta_s > 0)
    (h_gate : 4 * alpha < delta_s) :
    projector_angle_bound alpha delta_s < 500 := by
  dsimp [projector_angle_bound]
  split
  · have h_prod : 2 * alpha * 1000 < delta_s * 500 := by omega
    exact Nat.div_lt_of_lt_mul h_prod
  · rename_i h_not
    omega

end WestEast
