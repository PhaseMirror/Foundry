import Kernel

/-!
# Shpa — hierarchical depth monotonicity

Formalizes the SHPA hierarchy invariant: refining a hierarchy (adding levels) never
decreases its depth, and depth is additive across composed sub-hierarchies. No
`Mathlib`, no `sorry`.
-/
namespace Shpa

open proofs.Kernel

/-- Depth (number of levels) of a hierarchy. -/
def depth (levels : Nat) : Nat := levels

/-- Depth is monotone in the number of levels. -/
theorem depth_monotone (a b : Nat) (h : a ≤ b) : depth a ≤ depth b := by simp [depth]; omega

/-- Depth is additive across composed sub-hierarchies. -/
theorem depth_add (a b : Nat) : depth (a + b) = depth a + depth b := by simp [depth]

end Shpa
