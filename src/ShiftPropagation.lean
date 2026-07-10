/-
Shift‑propagation derived inequality.
Rewrites Lemma 8.3 into a more convenient form:
  E T ≤ E_τ_star T + C_bound * |τ_star|.
No Mathlib, no `sorry`.
-/

import "./Analytic/AnalyticRefined"

open AnalyticRefined

-- Monotonicity of addition on the right (needed for the rewrite).
axiom add_le_add_right {x y z : ℝ} (h : le x y) : le (add x z) (add y z)

section ShiftPropagationDerived

  /-- From Lemma 8.3 we obtain the inequality
      `E T ≤ E_τ_star T + C_bound * |τ_star|` for `T > T₀`. -/
  theorem shift_propagation_form {T : ℝ} (hT : lt T₀ T) :
      le (E T) (add (E_τ_star T) (mul C_bound (abs τ_star))) := by
    -- Start from the original Lemma 8.3 axiom.
    have h₀ := lemma_8_3 T hT
    -- Unfold `sub` to an addition with a negated term.
    have h₁ : le (add (E T) (neg (mul C_bound (abs τ_star)))) (E_τ_star T) := by
      simpa [sub] using h₀
    -- Add the same positive term to both sides using the monotonicity axiom.
    have h₂ := add_le_add_right h₁ (mul C_bound (abs τ_star))
    -- Simplify the left‑hand side: `add (E T) (neg K) + K = E T`.
    simpa [add_comm, add_left_comm, add_assoc, add_left_neg, add_zero] using h₂

end ShiftPropagationDerived
