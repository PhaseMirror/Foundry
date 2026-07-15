import Kernel

/-!
# EigenSolvers — Rayleigh-quotient bound for diagonal operators

Formalizes the elementary spectral bound used by the power-iteration eigen-solver:
the Rayleigh quotient of a non-negative vector with respect to a diagonal operator
`D` bounded by `b` is itself bounded by `b`. No `Mathlib`, no `sorry`.
-/
namespace EigenSolvers

open proofs.Kernel

/-- Rayleigh quotient numerator `Σ vᵢ·Dᵢ·vᵢ` (denominator assumed normalized to 1). -/
def rayleigh (D v : Nat → Nat) (n : Nat) : Nat :=
  lsum ((List.range n).map fun i => v i * D i * v i)

/-- Rayleigh quotient is bounded above by `b · Σ vᵢ²` when every `Dᵢ ≤ b`. -/
theorem rayleigh_bounded (D v : Nat → Nat) (n b : Nat) (hD : ∀ i, D i ≤ b) :
    rayleigh D v n ≤ b * lsum ((List.range n).map fun i => v i * v i) := by
  simp [rayleigh]
  induction n <;> simp [*] <;> omega

/-- Monotonicity in the operator bound. -/
theorem rayleigh_bound_monotone (D v : Nat → Nat) (n b₁ b₂ : Nat)
    (hD : ∀ i, D i ≤ b₁) (h : b₁ ≤ b₂) :
    rayleigh D v n ≤ b₂ * lsum ((List.range n).map fun i => v i * v i) := by
  apply Nat.le_trans (rayleigh_bounded D v n b₁ hD)
  omega

end EigenSolvers
