import AffineCore.Foundations.BanachSpace

-- Use a complex Banach space E
variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℂ E] [CompleteSpace E]

/--
The full evolution map Φ_t(x) = Ξ(t)·x + Λ_m(t)·T(x).
Formalizes the core dynamical system step.
-/
noncomputable def evolutionMap
    (Ξ : E →L[ℂ] E) (Λ : ℂ) (T : E → E) : E → E :=
  fun x => Ξ x + Λ • T x

/--
Theorem C2: Uniform contraction under the key stability inequality.
Formalizes Lm/Ks Theorem 2.
-/
theorem evolution_uniform_contraction
    (Ξ : E →L[ℂ] E) (Λ : ℂ) (T : E → E)
    (ε : ℝ) (hε : 0 < ε)
    (hΞ  : ‖Ξ‖ ≤ 1 - ε)          -- sup_t ‖Ξ(t)‖ ≤ 1 - ε
    (L : ℝ≥0) (hT : LipschitzWith L T)  -- T is L-Lipschitz
    (hT0 : T 0 = 0)               -- T(0) = 0
    (hc  : ‖Λ‖ * (L : ℝ) < ε) :   -- c = ‖Λ‖ · L_T < ε
    ∃ q : ℝ, q < 1 ∧
      ∀ x y : E, ‖evolutionMap Ξ Λ T x - evolutionMap Ξ Λ T y‖ ≤ q * ‖x - y‖ := by
  -- Contraction constant q = ‖Ξ‖ + ‖Λ‖ * L
  let q := ‖Ξ‖ + ‖Λ‖ * (L : ℝ)
  use q
  constructor
  · -- q < 1
    calc q = ‖Ξ‖ + ‖Λ‖ * (L : ℝ) := rfl
      _ < (1 - ε) + ε := by
          apply add_lt_add_of_le_of_lt hΞ hc
      _ = 1 := by ring
  · -- Lipschitz bound
    intro x y
    simp_rw [evolutionMap]
    rw [add_sub_add_comm, ← ContinuousLinearMap.map_sub, ← smul_sub]
    calc ‖Ξ (x - y) + Λ • (T x - T y)‖
        ≤ ‖Ξ (x - y)‖ + ‖Λ • (T x - T y)‖ := norm_add_le _ _
      _ ≤ ‖Ξ‖ * ‖x - y‖ + ‖Λ‖ * ‖T x - T y‖ := by
            apply add_le_add
            · exact Ξ.le_opNorm _
            · exact (norm_smul _ _).le
      _ ≤ ‖Ξ‖ * ‖x - y‖ + ‖Λ‖ * (L * ‖x - y‖) := by
            apply add_le_add_left
            apply mul_le_mul_of_nonneg_left
            · exact hT.dist_le_mul x y
            · exact norm_nonneg _
      _ = q * ‖x - y‖ := by ring
