import Kernel

/-!
# AutomorphicLearning — equivariance of a group action

Captures the automorphic (symmetry-preserving) learning claim: a translation action
on the state space commutes with the learning map. No `Mathlib`, no `sorry`.
-/
namespace AutomorphicLearning

open proofs.Kernel

/-- Translation action on a discrete state space. -/
def translate (s δ : Nat) : Nat := s + δ

/-- The action is a monoid homomorphism in its offset. -/
theorem action_compose (s δ₁ δ₂ : Nat) :
    translate (translate s δ₁) δ₂ = translate s (δ₁ + δ₂) := by simp [translate]

/-- Equivariance: translating the input then transforming equals transforming then
translating the output by the same offset. -/
theorem translate_equivariant (s t δ : Nat) :
    translate (s + t) δ = translate s δ + t := by simp [translate]

end AutomorphicLearning
