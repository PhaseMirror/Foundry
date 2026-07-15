import Kernel

/-!
# ElasticTether — restoring force bounds

Formalizes the elastic-tether (spring) dynamics: `F = k·x`, monotone in displacement,
zero at rest, and bounded by `k·cap`. No `Mathlib`, no `sorry`.
-/
namespace ElasticTether

open proofs.Kernel

/-- Hookean restoring force `F = k·x`. -/
def springForce (k x : Nat) : Nat := k * x

/-- No force at the equilibrium point. -/
theorem force_zero_at_rest (k : Nat) : springForce k 0 = 0 := by simp [springForce]

/-- The force grows monotonically with displacement. -/
theorem force_monotone (k x y : Nat) (h : x ≤ y) :
    springForce k x ≤ springForce k y := by simp [springForce]; omega

/-- The force stays within `k·cap` when displacement is capped. -/
theorem force_bounded (k x cap : Nat) (h : x ≤ cap) :
    springForce k x ≤ k * cap := by simp [springForce]; omega

end ElasticTether
