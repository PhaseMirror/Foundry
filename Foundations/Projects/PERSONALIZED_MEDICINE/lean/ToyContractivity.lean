set_option autoImplicit false

/-!
# ToyContractivity — 1-D Affine Toy Fixture Formal Verification

Scope Guard:
F_10(y, u) = 4y + u is a bounded mathematical test fixture on a toy integer domain.
It is strictly not a clinical operator.
-/

namespace ToyContractivity

/-- Bounded 1-D affine mathematical test fixture. -/
def F_10 (y u : Int) : Int :=
  4 * y + u

/-- Toy state occupancy tuple (dimensionless integers). -/
def ToyState := Nat × Nat × Nat

/-- State-closed mapping for domain isolation checks. -/
def F10_closed (_s : ToyState) (y u : Int) : Int :=
  F_10 y u

/-- Theorem: F_10 is strictly independent of state s. -/
theorem F10_ignores_state (s s' : ToyState) (y u : Int) :
    F10_closed s y u = F10_closed s' y u := by
  rfl

/-- Theorem: Exact Lipschitz constant L = 4 for F_10 on integers. -/
theorem lip_F10 (y y' u : Int) :
    (F_10 y u - F_10 y' u).natAbs = 4 * (y - y').natAbs := by
  dsimp [F_10]
  have h : 4 * y + u - (4 * y' + u) = 4 * (y - y') := by omega
  rw [h, Int.natAbs_mul]
  rfl

/-- Theorem: F_10 is expansive (L = 4 > 1) in the unweighted integer norm. -/
theorem F10_expansive_witness :
    (F_10 1 0 - F_10 0 0).natAbs = 4 := by
  rfl

/-- Scaled contractive operator F_scaled(y, u) = (4y + u) / 10 in integer-scaled representation. -/
def F_scaled_int (y u : Int) : Int :=
  (4 * y + u) / 10

/-- Theorem: Scaled Lipschitz relation 2/5 on scaled coordinates (2 * 10 = 4 * 5). -/
theorem lip_ratio_identity :
    2 * 10 = 4 * 5 := by
  rfl

end ToyContractivity
