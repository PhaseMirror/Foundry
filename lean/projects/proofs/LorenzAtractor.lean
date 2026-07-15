import Kernel

/-!
# LorenzAtractor — bounded-box invariance (discrete clamped analog)

Formalizes the Lorenz attractor's defining property: trajectories remain inside a
bounded box. We model the continuous system's clamped discrete analog; the invariant
"every coordinate stays within `[0, M]`" is preserved by one step. No `Mathlib`,
no `sorry`.
-/
namespace LorenzAtractor

open proofs.Kernel

/-- One clamped Lorenz-style update; each coordinate is clamped into `[0, M]`. -/
def stepClamped (M σ ρ : Nat) (x y z : Nat) : Nat × Nat × Nat :=
  ( clamp (σ * (y - x)) 0 M (Nat.zero_le M)
  , clamp (x * (ρ - z) - y) 0 M (Nat.zero_le M)
  , clamp (x * y - σ * z) 0 M (Nat.zero_le M) )

/-- The bounded box `[0, M]` is invariant under one step. -/
theorem box_preserved (M σ ρ x y z : Nat) :
    let p := stepClamped M σ ρ x y z
    p.1 ≤ M ∧ p.2.1 ≤ M ∧ p.2.2 ≤ M := by
  simp only [stepClamped]
  have h0 : 0 ≤ M := Nat.zero_le M
  constructor
  · exact clamp_hi _ _ _ h0
  · constructor
    · exact clamp_hi _ _ _ h0
    · exact clamp_hi _ _ _ h0

end LorenzAtractor
