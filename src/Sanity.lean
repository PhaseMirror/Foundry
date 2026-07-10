import Analytic.AnalyticRefined

open Analytic

/-- Lemma: `sub` is definitionally equal to `add x (neg y)`. -/
@[simp]
theorem sub_eq_add_neg (x y : ℝ) : sub x y = add x (neg y) := rfl

/-- Lemma: `sub x x = 0` for any `x : ℝ`. -/
@[simp]
theorem sub_self (x : ℝ) : sub x x = zero := by
  unfold sub
  have hcomm : add x (neg x) = add (neg x) x := add_comm x (neg x)
  calc
    sub x x = add x (neg x) := rfl
    _ = add (neg x) x := hcomm
    _ = zero := add_left_neg x
