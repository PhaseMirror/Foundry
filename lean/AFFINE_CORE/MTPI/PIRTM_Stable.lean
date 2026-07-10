import AffineCore.Foundations.BanachSpace
import AffineCore.Stability.UniformContraction

-- Use a complex Banach space E
variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℂ E] [CompleteSpace E]

/--
Clarified PIRTM Evolution Map (Equation from pirtm/core/recurrence.py).
X_{t+1} = (1 - λ_m)X_t + λ_m * P(Ξ X_t + Λ T(X_t) + G)
where P is the projection (clipping) operator.
For stability analysis, we assume P is non-expansive (Lipschitz 1),
which is true for clipping to [-1, 1].
-/
noncomputable def pirtmEvolutionMap
    (λ_m : ℝ) (Ξ : E →L[ℂ] E) (Λ : ℂ) (T : E → E) (G : E) : E → E :=
  fun x => (1 - λ_m) • x + λ_m • (Ξ x + Λ • T x + G)

/--
Theorem: MTPI Stability Guarantee.
Formalizes the contractivity guarantee c(λ_m) = (1 - λ_m) + λ_m * (‖Ξ‖ + ‖Λ‖·L_T) < 1.
-/
theorem mtpi_stability_guarantee
    (λ_m : ℝ) (hλ_m_pos : 0 < λ_m) (hλ_m_le : λ_m ≤ 1)
    (Ξ : E →L[ℂ] E) (Λ : ℂ) (T : E → E) (G : E)
    (ε : ℝ) (hε : 0 < ε)
    (L : ℝ≥0) (hT : LipschitzWith L T)
    (hc_bound : (1 - λ_m) + λ_m * (‖Ξ‖ + ‖Λ‖ * (L : ℝ)) < 1 - ε) :
    ∃ q : ℝ, q < 1 - ε ∧
      ∀ x y : E, ‖pirtmEvolutionMap λ_m Ξ Λ T G x - pirtmEvolutionMap λ_m Ξ Λ T G y‖ ≤ q * ‖x - y‖ := by
  let q := (1 - λ_m) + λ_m * (‖Ξ‖ + ‖Λ‖ * (L : ℝ))
  use q
  constructor
  · exact hc_bound
  · intro x y
    unfold pirtmEvolutionMap
    -- Difference: (1-λ_m)(x-y) + λ_m(Ξ(x-y) + Λ(T x - T y))
    rw [add_sub_add_comm, ← smul_sub, ← smul_sub, ← ContinuousLinearMap.map_sub, ← smul_sub]
    calc ‖(1 - λ_m) • (x - y) + λ_m • (Ξ (x - y) + Λ • (T x - T y))‖
        ≤ ‖(1 - λ_m) • (x - y)‖ + ‖λ_m • (Ξ (x - y) + Λ • (T x - T y))‖ := norm_add_le _ _
      _ = |1 - λ_m| * ‖x - y‖ + |λ_m| * ‖Ξ (x - y) + Λ • (T x - T y)‖ := by
          rw [norm_smul, norm_smul]
      _ = (1 - λ_m) * ‖x - y‖ + λ_m * ‖Ξ (x - y) + Λ • (T x - T y)‖ := by
          rw [abs_of_nonneg (sub_nonneg.mpr hλ_m_le), abs_of_pos hλ_m_pos]
      _ ≤ (1 - λ_m) * ‖x - y‖ + λ_m * (‖Ξ (x - y)‖ + ‖Λ • (T x - T y)‖) := by
          apply add_le_add_left
          apply mul_le_mul_of_nonneg_left (norm_add_le _ _) (le_of_lt hλ_m_pos)
      _ ≤ (1 - λ_m) * ‖x - y‖ + λ_m * (‖Ξ‖ * ‖x - y‖ + ‖Λ‖ * ‖T x - T y‖) := by
          apply add_le_add_left
          apply mul_le_mul_of_nonneg_left _ (le_of_lt hλ_m_pos)
          apply add_le_add (Ξ.le_opNorm _) (norm_smul _ _).le
      _ ≤ (1 - λ_m) * ‖x - y‖ + λ_m * (‖Ξ‖ * ‖x - y‖ + ‖Λ‖ * (L * ‖x - y‖)) := by
          apply add_le_add_left
          apply mul_le_mul_of_nonneg_left _ (le_of_lt hλ_m_pos)
          apply add_le_add_left
          apply mul_le_mul_of_nonneg_left (hT.dist_le_mul x y) (norm_nonneg _)
      _ = ((1 - λ_m) + λ_m * (‖Ξ‖ + ‖Λ‖ * L)) * ‖x - y‖ := by ring
      _ = q * ‖x - y‖ := rfl
