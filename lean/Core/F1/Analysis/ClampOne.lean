/-
F1 square — Track 1, item 3 substrate: **`clampOne t = max(t, 1)`**, a total `Real → Real` that is
`≥ 1` everywhere, equals `t` on `[1, ∞)`, and is `1`-Lipschitz. This totalizes any integrand defined
only on `[1, ∞)` (the Mellin integrand `t^{s−1}·ψ(t)`, which needs `t ≥ 1` for `RrpowPos`/`thetaFn`)
into the form the certified-integration framework consumes (a *total* Lipschitz `Real → Real`); on each
unit interval `[n+1, n+2] ⊆ [1, ∞)` the clamp is inert, so the integral is unchanged.

`max(t, 1) = 1 + max(0, t − 1)` via `RmaxZero`; the Lipschitz bound rests on the absolute-value
reverse triangle inequality `||x| − |y|| ≤ |x − y|` and `½`-homogeneity, both proved here.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RabsLemmas

namespace UOR.Bridge.F1Square.Analysis

/-- `Qeq` commutes with `Qabs` (local copy). -/
private theorem Qabs_congr_loc {a b : Q} (h : Qeq a b) : Qeq (Qabs a) (Qabs b) := by
  have key : a.num.natAbs * b.den = b.num.natAbs * a.den := by
    unfold Qeq at h
    have hh := congrArg Int.natAbs h
    rw [Int.natAbs_mul, Int.natAbs_mul, Int.natAbs_ofNat, Int.natAbs_ofNat] at hh
    exact hh
  show ((a.num.natAbs : Int)) * (b.den : Int) = ((b.num.natAbs : Int)) * (a.den : Int)
  exact_mod_cast key

/-- **`|½z| = ½|z|`** — `Rabs` commutes with halving (`½ ≥ 0`), pointwise. -/
theorem Rabs_Rhalf (z : Real) : Req (Rabs (Rhalf z)) (Rhalf (Rabs z)) :=
  Req_of_seq_Qeq (fun n => by
    show Qeq (Qabs (mul (⟨1, 2⟩ : Q) (z.seq n))) (mul (⟨1, 2⟩ : Q) (Qabs (z.seq n)))
    rw [Qabs_mul]
    exact Qmul_congr (Qabs_of_nonneg (by show (0 : Int) ≤ 1; decide)) (Qeq_refl _))

set_option maxHeartbeats 800000 in
/-- **The reverse triangle inequality** `||x| − |y|| ≤ |x − y|` (lifts `Qabs_abs_sub` pointwise). -/
theorem Rabs_Rabs_sub_le (x y : Real) :
    Rle (Rabs (Rsub (Rabs x) (Rabs y))) (Rabs (Rsub x y)) := by
  intro n
  show Qle (Qabs (Qsub (Qabs (x.seq (2 * n + 1))) (Qabs (y.seq (2 * n + 1)))))
    (add (Qabs (Qsub (x.seq (2 * n + 1)) (y.seq (2 * n + 1)))) (⟨2, n + 1⟩ : Q))
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (y.den_pos _)))
    (Qabs_abs_sub (x.seq (2 * n + 1)) (y.seq (2 * n + 1)))
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **`½(z + z) = z`**. -/
theorem Rhalf_add_self (z : Real) : Req (Rhalf (Radd z z)) z := by
  refine Req_trans (Rhalf_Radd z z) ?_
  intro n
  have he : Qeq (Qsub (add (mul (⟨1, 2⟩ : Q) (z.seq (2 * n + 1)))
        (mul (⟨1, 2⟩ : Q) (z.seq (2 * n + 1)))) (z.seq n))
      (Qsub (z.seq (2 * n + 1)) (z.seq n)) := by
    simp only [Qeq, Qsub, add, neg, mul]; push_cast; ring_uor
  show Qle (Qabs (Qsub (add (mul (⟨1, 2⟩ : Q) (z.seq (2 * n + 1)))
      (mul (⟨1, 2⟩ : Q) (z.seq (2 * n + 1)))) (z.seq n))) (⟨2, n + 1⟩ : Q)
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos (z.den_pos _) (z.den_pos n)))
    (Qabs_congr_loc (Qeq_symm he)) ?_
  have hb1 : Qle (Qbound (2 * n + 1)) (⟨1, n + 1⟩ : Q) := by simp only [Qle, Qbound]; push_cast; omega
  refine Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (z.reg (2 * n + 1) n) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Qbound_den_pos n)) (Qadd_le_add hb1 (Qle_refl (Qbound n)))
    (Qeq_le (by simp only [Qeq, Qbound, add]; push_cast; ring_uor :
      Qeq (add (⟨1, n + 1⟩ : Q) (Qbound n)) (⟨2, n + 1⟩ : Q)))

/-- **`RmaxZero` is `1`-Lipschitz**: `|max(0,a) − max(0,b)| ≤ |a − b|`. -/
theorem RmaxZero_lipschitz (a b : Real) :
    Rle (Rabs (Rsub (RmaxZero a) (RmaxZero b))) (Rabs (Rsub a b)) := by
  have e2 : Req (Rabs (Rsub (RmaxZero a) (RmaxZero b)))
      (Rhalf (Rabs (Rsub (Radd a (Rabs a)) (Radd b (Rabs b))))) :=
    Req_trans (Rabs_congr (Req_symm (Rhalf_Rsub (Radd a (Rabs a)) (Radd b (Rabs b)))))
      (Rabs_Rhalf _)
  refine Rle_trans (Rle_of_Req e2) ?_
  have e3 : Req (Rsub (Radd a (Rabs a)) (Radd b (Rabs b)))
      (Radd (Rsub a b) (Rsub (Rabs a) (Rabs b))) := Rsub_Radd_Radd a (Rabs a) b (Rabs b)
  have hle : Rle (Rabs (Rsub (Radd a (Rabs a)) (Radd b (Rabs b))))
      (Radd (Rabs (Rsub a b)) (Rabs (Rsub a b))) :=
    Rle_trans (Rle_of_Req (Rabs_congr e3))
      (Rle_trans (Rabs_Radd (Rsub a b) (Rsub (Rabs a) (Rabs b)))
        (Radd_le_add (Rle_refl _) (Rabs_Rabs_sub_le a b)))
  exact Rle_trans (Rhalf_le_Rhalf hle) (Rle_of_Req (Rhalf_add_self (Rabs (Rsub a b))))

/-- **`clampOne t = max(t, 1)`** — total, `≥ 1`, inert on `[1, ∞)`, `1`-Lipschitz. -/
def clampOne (t : Real) : Real := Radd one (RmaxZero (Rsub t one))

/-- `clampOne` respects `≈`. -/
theorem clampOne_congr {s t : Real} (h : Req s t) : Req (clampOne s) (clampOne t) :=
  Radd_congr (Req_refl _) (RmaxZero_congr (Rsub_congr h (Req_refl _)))

/-- **`clampOne t ≥ 1`** everywhere. -/
theorem clampOne_ge_one (t : Real) : Rle one (clampOne t) :=
  Rle_self_Radd_right (Rnonneg_RmaxZero (Rsub t one))

/-- **`clampOne t = t` on `[1, ∞)`** (the clamp is inert where `t ≥ 1`). -/
theorem clampOne_eq_of_ge {t : Real} (ht : Rle one t) : Req (clampOne t) t := by
  refine Req_trans (Radd_congr (Req_refl _) (RmaxZero_of_nonneg (Rnonneg_Rsub_of_Rle ht))) ?_
  refine Req_trans (Radd_comm one (Rsub t one)) ?_
  refine Req_trans (Radd_assoc t (Rneg one) one) ?_
  exact Req_trans (Radd_congr (Req_refl t) (Req_trans (Radd_comm (Rneg one) one) (Radd_neg one)))
    (Radd_zero t)

/-- **`clampOne` is `1`-Lipschitz**: `|clampOne x − clampOne y| ≤ |x − y|`. -/
theorem clampOne_lipschitz (x y : Real) :
    Rle (Rabs (Rsub (clampOne x) (clampOne y))) (Rabs (Rsub x y)) := by
  have e1 : Req (Rsub (clampOne x) (clampOne y))
      (Rsub (RmaxZero (Rsub x one)) (RmaxZero (Rsub y one))) := by
    refine Req_trans (Rsub_Radd_Radd one (RmaxZero (Rsub x one)) one (RmaxZero (Rsub y one))) ?_
    refine Req_trans (Radd_congr (Radd_neg one) (Req_refl _)) ?_
    exact Req_trans (Radd_comm zero _) (Radd_zero _)
  have e2 : Req (Rsub (Rsub x one) (Rsub y one)) (Rsub x y) := by
    refine Req_trans (Rsub_Radd_Radd x (Rneg one) y (Rneg one)) ?_
    refine Req_trans (Radd_congr (Req_refl _) (Radd_neg (Rneg one))) ?_
    exact Radd_zero (Rsub x y)
  refine Rle_trans (Rle_of_Req (Rabs_congr e1)) ?_
  exact Rle_trans (RmaxZero_lipschitz (Rsub x one) (Rsub y one)) (Rle_of_Req (Rabs_congr e2))

end UOR.Bridge.F1Square.Analysis
