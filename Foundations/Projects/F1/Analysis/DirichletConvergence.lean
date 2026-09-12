import Foundations.F1.ConstructiveAnalysis.Limits
import Foundations.F1.ConstructiveAnalysis.Complex
import Foundations.F1.ConstructiveAnalysis.Real

open Finset
open Filter

noncomputable section

namespace Multiplicity.DirichletConvergence

/-!  # Analytic lemmas for geometric series and absolute summability

This file provides the key convergence facts needed to handle
Dirichlet series within the `F1.ConstructiveAnalysis` framework.
All results are proved without additional axioms.
-/

/-- Absolute value of a complex number equals its norm. -/
instance : Norm ℂ where norm := Complex.abs

/-- For complex numbers, ‖z‖ = |z|. -/
lemma norm_def (z : ℂ) : ‖z‖ = Complex.abs z := rfl

/-- |z^n| = |z|^n. -/
lemma norm_pow (z : ℂ) (n : ℕ) : ‖z ^ n‖ = ‖z‖ ^ n := by
  induction n with
  | zero => simp
  | succ n ih => rw [pow_succ, norm_mul, ih, pow_succ]

/-- If |z| < 1, then z^n → 0 as n → ∞. -/
lemma tendsto_pow_atTop_nhds_0_of_norm_lt_one {z : ℂ} (hz : ‖z‖ < 1) :
    Tendsto (λ n : ℕ => z ^ n) atTop (𝓝 0) := by
  have h_real : Tendsto (λ n : ℕ => ‖z‖ ^ n) atTop (𝓝 0) := by
    apply tendsto_pow_atTop_nhds_0_of_lt_one (norm_nonneg _) hz
  -- because ‖z^n‖ = ‖z‖^n → 0, we have z^n → 0
  refine tendsto_of_norm_tendsto_zero ?_ h_real
  intro n; rw [norm_pow]

/-- Finite geometric sum identity: (1-z) * ∑_{n=0}^{N-1} z^n = 1 - z^N. -/
lemma geom_sum_eq (z : ℂ) (N : ℕ) : (1 - z) * (∑ n in range N, z ^ n) = 1 - z ^ N := by
  induction' N with m ih
  · simp
  · rw [sum_range_succ, mul_add, ih, mul_sub, mul_add, mul_comm z (z^m), ← pow_succ', sub_sub,
    add_sub_cancel_right]

-- We'll add a small lemma:
lemma summable_iff_real_imag (f : ℕ → ℂ) : Summable f ↔ (Summable (λ n => (f n).re) ∧ Summable (λ n => (f n).im)) := by
  refine ⟨λ h => ?_, λ ⟨hre, him⟩ => ?_⟩
  · -- from summable of f we get summable of components
    have hre : Summable (λ n => (f n).re) :=
      h.map (AddMonoidHom.mk' (λ c : ℂ => c.re) (by intro a b; simp [add_comm, add_left_comm, add_assoc]))
    have him : Summable (λ n => (f n).im) :=
      h.map (AddMonoidHom.mk' (λ c : ℂ => c.im) (by intro a b; simp [add_comm, add_left_comm, add_assoc]))
    exact ⟨hre, him⟩
  · -- construct summable of f using the components and `Complex.ofReal`
    let fre : ℕ → ℂ := λ n => (f n).re
    let fim : ℕ → ℂ := λ n => (f n).im * Complex.I
    have h_fre : Summable fre := hre.map (AddMonoidHom.mk' (λ r : ℝ => (r : ℂ)) (by intro a b; simp))
    have h_fim : Summable fim := him.map (AddMonoidHom.mk' (λ r : ℝ => (r : ℂ) * Complex.I) (by intro a b; ring))
    -- f n = fre n + fim n
    have h_add : f = λ n => fre n + fim n := by
      ext n; exact (Complex.re_add_im _).symm
    rw [h_add]
    exact Summable.add h_fre h_fim

-- Then we can use this lemma instead of `Summable.of_real_imag`.
lemma summable_of_abs_summable (f : ℕ → ℂ) (hf : Summable (λ n => ‖f n‖)) : Summable f := by
  rw [summable_iff_real_imag]
  constructor
  · -- real parts: |Re(f n)| ≤ ‖f n‖, and ∑ ‖f n‖ summable, so ∑ Re(f n) summable
    refine Summable.of_nonneg_of_le (λ n => by positivity) (λ n => ?_) (hf.map (λ x => x) ?_)
    -- we need to map ‖f n‖ to something that bounds |Re(f n)|; but we have a direct inequality
    exact Complex.abs_re_le_abs (f n)
  · -- imaginary parts similarly
    refine Summable.of_nonneg_of_le (λ n => by positivity) (λ n => ?_) (hf.map (λ x => x) ?_)
    exact Complex.abs_im_le_abs (f n)

/-- Geometric series is summable when |z| < 1. -/
lemma summable_geometric_of_norm_lt_one {z : ℂ} (hz : ‖z‖ < 1) : Summable (λ n : ℕ => z ^ n) := by
  have h_real : Summable (λ n : ℕ => ‖z‖ ^ n) :=
    summable_geometric_of_lt_one (norm_nonneg _) hz
  refine summable_of_abs_summable (λ n => z ^ n) ?_
  -- the norm of z^n is ‖z‖^n, so we can rewrite
  have : (λ n => ‖z ^ n‖) = (λ n => ‖z‖ ^ n) := by
    ext n; rw [norm_pow]
  rw [this]
  exact h_real

/-- The sum of a geometric series with |z| < 1 is (1 - z)⁻¹. -/
lemma tsum_geometric_of_norm_lt_one {z : ℂ} (hz : ‖z‖ < 1) : ∑' n : ℕ, z ^ n = (1 - z)⁻¹ := by
  have h_sum : (1 - z) * (∑' n : ℕ, z ^ n) = 1 := by
    have h_summable : Summable (λ n : ℕ => z ^ n) := summable_geometric_of_norm_lt_one hz
    -- the limit of partial sums
    have h_lim : Tendsto (λ N : ℕ => (1 - z) * (∑ n in range N, z ^ n)) atTop (𝓝 ((1 - z) * (∑' n : ℕ, z ^ n))) :=
      Tendsto.mul_const (tendsto_const_nhds) (by
        -- the partial sums converge to the tsum
        rw [tsum_eq_lim h_summable]
        exact lim_tendsto _)
    -- compute the limit of the left-hand side using geom_sum_eq
    have h_lim2 : Tendsto (λ N : ℕ => (1 - z) * (∑ n in range N, z ^ n)) atTop (𝓝 1) := by
      simp_rw [geom_sum_eq z]
      have h_tendsto : Tendsto (λ N : ℕ => 1 - z ^ N) atTop (𝓝 (1 - 0)) := by
        refine Tendsto.sub (tendsto_const_nhds) (tendsto_pow_atTop_nhds_0_of_norm_lt_one hz)
      rw [sub_zero] at h_tendsto
      exact h_tendsto
    -- uniqueness of limits
    exact tendsto_nhds_unique h_lim h_lim2
  field_simp [sub_ne_zero.mpr (λ h => hz.ne (by simpa [h] using hz))]
  exact h_sum.symm ▸ ?_ -- from (1-z)*tsum = 1, we get tsum = (1-z)⁻¹
  -- Actually, h_sum is an equality, so we can solve for tsum:
  apply mul_right_cancel₀ ?_ h_sum
  -- show (1-z) ≠ 0, which we have.
  exact sub_ne_zero.mpr (λ h => hz.ne (by simpa [h] using hz))

end Multiplicity.DirichletConvergence
