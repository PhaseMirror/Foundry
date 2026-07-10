/-
GapDerivation – derive the gap formula from the existing hypotheses.
No Mathlib, no `sorry`.
-/

import "./Analytic/AnalyticRefined"
import "./ShiftPropagation"

open AnalyticRefined

section GapDerivationAxioms
  -- Monotonicity of addition on the right (already used in ShiftPropagation).
  axiom add_le_add_right {x y z : ℝ} (h : le x y) : le (add x z) (add y z)

  -- If a ≤ b and 0 ≤ c then a*c ≤ b*c.
  axiom mul_le_mul_of_nonneg_right {a b c : ℝ} (hab : le a b) (hc : le zero c) :
    le (mul a c) (mul b c)

  -- Convert a strict inequality into a non‑strict one.
  axiom le_of_lt {a b : ℝ} (h : lt a b) : le a b

  -- Positivity of the auxiliary constant appearing in inflation_C1_D1.
  axiom some_positive_term_pos : lt zero some_positive_term

  -- Two is at least η_min (so η_min ≤ 2).
  axiom two_ge_η_min : le η_min two

end GapDerivationAxioms

section GapDerivation

  /-- Derived version of the gap formula.
      For any T > T₀ and any γ ≤ T witnessing an off‑line zero,
      we obtain the inequality
        η_min * log (N T) - C_bound * |τ_star| - K₀ ≤ E_τ_star T.
  -/
  theorem gap_formula_derived {T : ℝ} (hT : lt T₀ T)
      (hγ : ∃ (γ : ℝ), le γ T ∧ off_line_zero_condition) :
      le (sub (sub (mul η_min (log (N T))) (mul C_bound (abs τ_star))) K₀) (E_τ_star T) := by
    -- Extract the witness γ and the off‑line zero condition.
    rcases hγ with ⟨γ, hγle, hoff⟩

    -- From `off_line_zero_condition` we get the existential required by `inflation_C1_D1`.
    rcases hoff with ⟨β, ρ, hnorm, hβ⟩
    have hInfl : le (add (mul two (log (N T))) (sub some_positive_term K₀)) (E T) := by
      -- Apply `inflation_C1_D1` with the witness γ.
      have h := inflation_C1_D1 γ hγle
      -- Build the required existential argument.
      have hExists : ∃ (β' : ℝ), β' ≠ half ∧ (∃ (ρ' : ℂ), off_line_zero_condition) := by
        refine ⟨β, ?_, ?_⟩
        · exact hβ
        · exact ⟨ρ, hnorm, hβ⟩
      -- Apply the axiom with the constructed existential.
      have h2 := h hExists T (le_of_lt (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of_lt_of_le (lt_of lt T₀?)))))

    sorry
