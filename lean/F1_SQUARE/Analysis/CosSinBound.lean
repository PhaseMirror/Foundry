/-
F1 square — **`|cos x| ≤ 1` and `|sin x| ≤ 1`** as constructive reals, in the form `cos² ≤ 1`, `sin² ≤ 1`.
The immediate order-theoretic corollary of the Pythagorean identity `cos² + sin² = 1`
(`Rcos_sq_add_sin_sq`): a square is `≥ 0`, so each summand is `≤` the sum `= 1`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.CosSinAdd
import F1Square.Analysis.ROrder

namespace UOR.Bridge.F1Square.Analysis

/-- A square is non-negative (Bishop): `0 ≤ y·y`. -/
theorem Rnonneg_Rmul_self (y : Real) : Rnonneg (Rmul y y) := by
  intro n
  show Qle (neg (Qbound n)) (mul (y.seq (Ridx y y n)) (y.seq (Ridx y y n)))
  have hsq : 0 ≤ (y.seq (Ridx y y n)).num * (y.seq (Ridx y y n)).num := by
    rcases Int.le_total 0 (y.seq (Ridx y y n)).num with h | h
    · exact Int.mul_nonneg h h
    · have h' : (0 : Int) ≤ -(y.seq (Ridx y y n)).num := by omega
      have hp := Int.mul_nonneg h' h'
      have he : -(y.seq (Ridx y y n)).num * -(y.seq (Ridx y y n)).num
          = (y.seq (Ridx y y n)).num * (y.seq (Ridx y y n)).num := by ring_uor
      omega
  refine Qle_trans (b := (⟨0, 1⟩ : Q)) (by decide) ?_ ?_
  · simp only [Qle, Qbound, neg]; omega
  · simp only [Qle, mul]; omega

/-- `a ≤ a + b` when `b ≥ 0`. (Bishop `≤` through `Radd`'s `2n+1` reindex.) -/
theorem Rle_self_Radd_right {a b : Real} (hb : Rnonneg b) : Rle a (Radd a b) := by
  intro n
  show Qle (a.seq n) (add (add (a.seq (2 * n + 1)) (b.seq (2 * n + 1))) ⟨2, n + 1⟩)
  have s1 : Qle (a.seq n) (add (a.seq (2 * n + 1)) (add (Qbound n) (Qbound (2 * n + 1)))) :=
    Qle_add_of_Qabs_sub (a.den_pos n) (a.den_pos (2 * n + 1))
      (add_den_pos (Qbound_den_pos n) (Qbound_den_pos (2 * n + 1))) (a.reg n (2 * n + 1))
  refine Qle_trans (add_den_pos (a.den_pos (2 * n + 1))
      (add_den_pos (Qbound_den_pos n) (Qbound_den_pos (2 * n + 1)))) s1 ?_
  refine Qle_trans (b := add (a.seq (2 * n + 1)) (add (b.seq (2 * n + 1)) ⟨2, n + 1⟩))
    (add_den_pos (a.den_pos (2 * n + 1)) (add_den_pos (b.den_pos (2 * n + 1)) (Nat.succ_pos _)))
    ?_ (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  refine Qadd_le_add (Qle_refl _) ?_
  exact Qle_trans (b := add (neg (Qbound (2 * n + 1))) ⟨2, n + 1⟩)
    (add_den_pos (neg_den_pos (Qbound_den_pos _)) (Nat.succ_pos _))
    (Qeq_le (by simp only [Qeq, add, Qbound, neg]; push_cast; ring_uor))
    (Qadd_le_add (hb (2 * n + 1)) (Qle_refl _))

/-- `b ≤ a + b` when `a ≥ 0`. -/
theorem Rle_self_Radd_left {a b : Real} (ha : Rnonneg a) : Rle b (Radd a b) :=
  Rle_trans (Rle_self_Radd_right ha) (Rle_of_Req (Radd_comm b a))

/-- **`cos² x ≤ 1`** (hence `|cos x| ≤ 1`): `cos² ≤ cos² + sin² = 1`. -/
theorem Rcos_sq_le_one (x : Real) : Rle (Rmul (Rcos x) (Rcos x)) one :=
  Rle_trans (Rle_self_Radd_right (Rnonneg_Rmul_self (Rsin x))) (Rle_of_Req (Rcos_sq_add_sin_sq x))

/-- **`sin² x ≤ 1`** (hence `|sin x| ≤ 1`): `sin² ≤ cos² + sin² = 1`. -/
theorem Rsin_sq_le_one (x : Real) : Rle (Rmul (Rsin x) (Rsin x)) one :=
  Rle_trans (Rle_self_Radd_left (Rnonneg_Rmul_self (Rcos x))) (Rle_of_Req (Rcos_sq_add_sin_sq x))

end UOR.Bridge.F1Square.Analysis
