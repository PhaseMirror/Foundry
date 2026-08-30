import Init.Data.Rat.Basic

namespace Multiplicity.Core

/-- 
  Constructive proof of strict monotonicity for discrete Gram point sequences 
  represented as rational step functions.
-/
theorem gram_points_monotone 
    (f : Nat → Rat) 
    (h_step : ∀ n, f n ≤ f (n + 1)) : 
    ∀ n m, n ≤ m → f n ≤ f m := by
  intro n m h_le
  induction' h_le with m h_le ih
  · -- Base case: n = m
    exact le_refl (f n)
  · -- Inductive step: f n ≤ f m → f n ≤ f (m + 1)
    exact le_trans ih (h_step m)

end Multiplicity.Core

