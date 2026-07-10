import AffineCore.Foundations.BanachSpace

-- The ambient space: a complex Banach space
variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℂ E] [CompleteSpace E]

/--
A prime-indexed family of bounded operators.
w_p(t): complex weights
U_p(t): bounded linear operators
-/
structure PrimeOperatorFamily (E : Type*) [NormedAddCommGroup E] [NormedSpace ℂ E] where
  weight : ℕ → ℂ         -- w_p(t)
  op     : ℕ → E →L[ℂ] E -- U_p(t)
  support_prime : ∀ p, weight p ≠ 0 → Nat.Prime p

open BigOperators
open Topology

/--
The weighted sum Ξ(t) = ∑' p, w_p(t) * U_p(t)
-/
noncomputable def Xi (F : PrimeOperatorFamily E) : E →L[ℂ] E :=
  ∑' p, (F.weight p • F.op p)

/--
Theorem A1: Absolute convergence in operator norm implies Ξ is bounded.
This formalizes Lm/Ks Theorem 1.
-/
theorem Xi_bounded
    (F : PrimeOperatorFamily E)
    (h_summable : Summable (fun p => ‖F.weight p‖ * ‖F.op p‖)) :
    ‖Xi F‖ ≤ ∑' p, ‖F.weight p‖ * ‖F.op p‖ := by
  calc ‖Xi F‖
      ≤ ∑' p, ‖F.weight p • F.op p‖ := norm_tsum_le_tsum_norm (by
          apply Summable.of_norm
          simp_rw [norm_smul]
          exact h_summable)
    _ ≤ ∑' p, ‖F.weight p‖ * ‖F.op p‖ := by
          apply tsum_le_tsum
          · intro p; exact norm_smul_le _ _
          · apply Summable.of_norm
            simp_rw [norm_smul]
            exact h_summable
          · exact h_summable

/--
A time-dependent prime-indexed family of bounded operators.
-/
def TimeDependentPrimeOperatorFamily (E : Type*) [NormedAddCommGroup E] [NormedSpace ℂ E] :=
  ℕ → PrimeOperatorFamily E

/--
The time-dependent weighted sum Ξ(t) = ∑' p, w_p(t) * U_p(t)
-/
noncomputable def Xi_t (F : TimeDependentPrimeOperatorFamily E) (t : ℕ) : E →L[ℂ] E :=
  Xi (F t)

/--
Theorem A1 (Time-dependent): Uniform convergence in operator norm implies Ξ(t) is uniformly bounded.
-/
theorem Xi_t_bounded
    (F : TimeDependentPrimeOperatorFamily E)
    (C : ℝ)
    (h_summable : ∀ t, Summable (fun p => ‖(F t).weight p‖ * ‖(F t).op p‖))
    (h_uniform : ∀ t, ∑' p, ‖(F t).weight p‖ * ‖(F t).op p‖ ≤ C) :
    ∀ t, ‖Xi_t F t‖ ≤ C := by
  intro t
  calc ‖Xi_t F t‖
      = ‖Xi (F t)‖ := rfl
    _ ≤ ∑' p, ‖(F t).weight p‖ * ‖(F t).op p‖ := Xi_bounded (F t) (h_summable t)
    _ ≤ C := h_uniform t
