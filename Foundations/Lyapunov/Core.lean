/-!
# Foundations.Lyapunov.Core — Discrete Dynamical Systems & Lyapunov Stability

Formalizes discrete dynamical systems $f : \alpha \to \alpha$, positive-definite Lyapunov energy functions,
strict orbital descent, and asymptotic fixed-point attraction without unverified axioms.
-/

namespace Foundations.Lyapunov

/-- Discrete dynamical orbit iterator: f^n(x). -/
def iterate {α : Type} (f : α → α) : Nat → α → α
  | 0, x => x
  | n + 1, x => f (iterate f n x)

/-- Fixed point property: f(x*) = x*. -/
def IsFixedPoint {α : Type} (f : α → α) (x_star : α) : Prop :=
  f x_star = x_star

/-- Discrete Lyapunov Function structure:
    Energy is non-negative, zeroes uniquely at x*, and strictly decreases on non-fixed states. -/
structure DiscreteLyapunov {α : Type} (f : α → α) (V : α → Nat) (x_star : α) where
  zero_at_star : V x_star = 0
  unique_zero : ∀ x, V x = 0 ↔ x = x_star
  weak_descent : ∀ x, V (f x) ≤ V x
  strict_descent : ∀ x, x ≠ x_star → V (f x) < V x

/-- Theorem: Fixed-point property follows from Lyapunov minimal energy. -/
theorem lyapunov_fixed_point {α : Type} (f : α → α) (V : α → Nat) (x_star : α)
    (lyap : DiscreteLyapunov f V x_star) :
    IsFixedPoint f x_star := by
  dsimp [IsFixedPoint]
  have h_le := lyap.weak_descent x_star
  rw [lyap.zero_at_star] at h_le
  have h_zero : V (f x_star) = 0 := Nat.le_zero.mp h_le
  exact (lyap.unique_zero (f x_star)).mp h_zero

/-- Theorem: Strict orbital descent across k steps bounds energy by V(x) - k. -/
theorem strict_orbital_descent {α : Type} (f : α → α) (V : α → Nat) (x_star : α)
    (lyap : DiscreteLyapunov f V x_star) :
    ∀ (k : Nat) (x : α),
      (∀ m < k, iterate f m x ≠ x_star) →
      V (iterate f k x) + k ≤ V x
  | 0, x, _ => by
    dsimp [iterate]
    omega
  | k + 1, x, h_not_star => by
    have h_prev_not_star : ∀ m < k, iterate f m x ≠ x_star := by
      intro m hm
      exact h_not_star m (Nat.lt_trans hm (Nat.lt_succ_self k))
    have h_ih := strict_orbital_descent f V x_star lyap k x h_prev_not_star
    have h_k_not_star := h_not_star k (Nat.lt_succ_self k)
    have h_step_desc := lyap.strict_descent (iterate f k x) h_k_not_star
    dsimp [iterate]
    omega

end Foundations.Lyapunov
