import AffineCore.Foundations.BanachSpace
import AffineCore.Foundations.SpectralTheory

-- Use a complex Hilbert space H
variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

/--
Master Stability Lemma (Soundness of StabilityGate):
If the convexity parameter λm and the base Lipschitz L_G satisfy:
  c_base = (1 - λm) + λm * L_G < 1
And a perturbation δ satisfies:
  c_total = c_base + λm * δ < 1
Then the perturbed system is a firm contraction.
-/
theorem stability_gate_soundness
    (λm : ℝ) (h_λm : 0 < λm ∧ λm ≤ 1)
    (G Δ : H → H)
    (L_G : ℝ) (h_LG : LipschitzWith (Real.toNNReal L_G) G)
    (L_D : ℝ) (h_LD : LipschitzWith (Real.toNNReal L_D) Δ)
    (ε : ℝ) (h_ε : 0 < ε)
    (h_gate : (1 - λm) + λm * (L_G + L_D) ≤ 1 - ε) :
    ∃ q < 1, ∀ x y : H, 
      ‖((1 - λm) • x + λm • (G x + Δ x)) - ((1 - λm) • y + λm • (G y + Δ y))‖ ≤ q * ‖x - y‖ := by
  let q := (1 - λm) + λm * (L_G + L_D)
  use q
  constructor
  · -- q < 1
    calc q ≤ 1 - ε := h_gate
      _ < 1 := by linarith
  · -- Lipschitz bound
    intro x y
    rw [add_sub_add_comm, ← smul_sub, ← smul_sub, add_sub_add_comm]
    calc ‖(1 - λm) • (x - y) + λm • ((G x - G y) + (Δ x - Δ y))‖
        ≤ ‖(1 - λm) • (x - y)‖ + ‖λm • ((G x - G y) + (Δ x - Δ y))‖ := norm_add_le _ _
      _ = |1 - λm| * ‖x - y‖ + |λm| * ‖(G x - G y) + (Δ x - Δ y)‖ := by rw [norm_smul, norm_smul]
      _ = (1 - λm) * ‖x - y‖ + λm * ‖(G x - G y) + (Δ x - Δ y)‖ := by
          rw [abs_of_nonneg (by linarith [h_λm.2]), abs_of_pos h_λm.1]
      _ ≤ (1 - λm) * ‖x - y‖ + λm * (‖G x - G y‖ + ‖Δ x - Δ y‖) := by
          apply add_le_add_left
          apply mul_le_mul_of_nonneg_left (norm_add_le _ _) (le_of_lt h_λm.1)
      _ ≤ (1 - λm) * ‖x - y‖ + λm * (L_G * ‖x - y‖ + L_D * ‖x - y‖) := by
          apply add_le_add_left
          apply mul_le_mul_of_nonneg_left
          apply add_le_add
          · exact h_LG.dist_le_mul x y
          · exact h_LD.dist_le_mul x y
          · exact le_of_lt h_λm.1
      _ = ((1 - λm) + λm * (L_G + L_D)) * ‖x - y‖ := by ring
      _ = q * ‖x - y‖ := rfl
