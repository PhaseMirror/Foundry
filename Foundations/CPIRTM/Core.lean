/-!
# Foundations.CPIRTM.Core — Scaled Discrete Metric & Lipschitz Contractivity

Formalizes the discrete metric space on Nat, fixed-point scale (10000 = 1.0),
Lipschitz continuity conditions, and strict contraction operators.
-/

namespace Foundations.CPIRTM

/-- Fixed point scale: 10000 = 1.0. -/
def scale : Nat := 10000

/-- Discrete absolute metric distance between two Nat values. -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

/-- Discrete Lipschitz continuity condition on Nat:
    dist(f x, f y) * scale ≤ κ * dist(x, y) -/
def LipschitzWith (κ : Nat) (f : Nat → Nat) : Prop :=
  ∀ x y : Nat, dist (f x) (f y) * scale ≤ κ * dist x y

/-- Strict discrete contractivity condition: κ < 10000 and LipschitzWith κ f. -/
def is_contractive (f : Nat → Nat) (κ : Nat) : Prop :=
  κ < scale ∧ LipschitzWith κ f

/-- Theorem: Distance from a point to itself is zero. -/
theorem dist_self (x : Nat) : dist x x = 0 := by
  dsimp [dist]
  split <;> omega

/-- Theorem: Distance is symmetric. -/
theorem dist_comm (x y : Nat) : dist x y = dist y x := by
  dsimp [dist]
  split <;> split <;> omega

/-- Theorem: Identity map is 1-Lipschitz (κ = 10000). -/
theorem id_lipschitz_scale : LipschitzWith scale id := by
  intro x y
  dsimp [id, scale]
  rw [Nat.mul_comm]
  omega

/-- Theorem: Constant map is strictly contractive (κ = 0). -/
theorem const_is_contractive (c : Nat) : is_contractive (fun _ => c) 0 := by
  constructor
  · decide
  · intro x y
    dsimp [dist, scale]
    have h0 : (if c ≥ c then c - c else c - c) = 0 := by
      split <;> omega
    rw [h0]
    omega

end Foundations.CPIRTM
