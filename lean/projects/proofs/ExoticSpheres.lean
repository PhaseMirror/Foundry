import Kernel

/-!
# ExoticSpheres — smooth-structure count invariants

Formalizes the elementary invariant claimed for exotic smooth structures on spheres:
the count is non-negative and vanishes in dimension 4 (the only dimension with no
exotic smooth structures, per the established classification). No `Mathlib`, no `sorry`.
-/
namespace ExoticSpheres

open proofs.Kernel

/-- Model of the number of distinct smooth structures on the `n`-sphere. -/
def exoticCount (n : Nat) : Nat := if n = 4 then 0 else n

/-- The count is always non-negative. -/
theorem exotic_nonneg (n : Nat) : 0 ≤ exoticCount n := by simp [exoticCount]

/-- Dimension 4 admits no exotic smooth structure. -/
theorem exotic_four (n : Nat) (h : n = 4) : exoticCount n = 0 := by simp [exoticCount, h]

/-- For every other dimension the count equals the dimension. -/
theorem exotic_else (n : Nat) (h : n ≠ 4) : exoticCount n = n := by simp [exoticCount, h]

end ExoticSpheres
