/-
F1 square — **the exponential functional equation on ℝ** (the `[0,1]` case): `exp(p+q) ≈ exp p · exp q`
as constructive reals, for rationals `p, q` with `p, q, p+q ∈ [0,1]`.

This is the **lift to reals** of the exact finite Cauchy product (`expSum_mul_eq`) with its
`O(1/(M+1)!)` corner bound (`expSum_corner_le`). The product real `Rmul (Rexp p) (Rexp q)` evaluates
the partial sums at the reindex depth `M = Ridx + 1 ≥ n + 1`; there both the corner and the truncation
tail are `≤ 1/(n+1)`, so the diagonal gap is `≤ ⟨2,n+1⟩` — exactly the `Req` tolerance.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Binomial
import F1Square.Analysis.CosSin

namespace UOR.Bridge.F1Square.Analysis

/-- `(X − (X + c)) ≈ −c`. -/
theorem Qsub_add_self_left (X c : Q) : Qeq (Qsub X (add X c)) (neg c) := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- If `y ≤ x` then `x − y` has non-negative numerator. -/
theorem Qsub_num_nonneg {x y : Q} (h : Qle y x) : 0 ≤ (Qsub x y).num := by
  have h' : y.num * (x.den : Int) ≤ x.num * (y.den : Int) := h
  show 0 ≤ x.num * (y.den : Int) + (-y.num) * (x.den : Int)
  have hneg : (-y.num) * (x.den : Int) = -(y.num * (x.den : Int)) := by ring_uor
  rw [hneg]; omega

/-- **The diagonal gap bound**: for `a, b ≥ 0` with `a+b ≤ 1` and any sampling depth `M ≥ n+1`, the
    `n`-th diagonal gap `|S_{a+b}(n+1) − S_a(M)·S_b(M)|` is `≤ ⟨2,n+1⟩` — the truncation tail
    `|S(n+1) − S(M)| ≤ 1/(n+1)` (`expabs_bound`) plus the Cauchy corner `|S(M) − S·S| ≤ 1/(n+1)`
    (`expSum_corner_le`). This is the `Req` tolerance, with `M` left as a parameter (so `Rmul`'s reindex
    `Ridx + 1 ≥ n+1` instantiates it directly). -/
theorem exp_diag_gap {p q : Q} (hp0 : 0 ≤ p.num) (hpd : 0 < p.den) (hq0 : 0 ≤ q.num) (hqd : 0 < q.den)
    (hpq0 : 0 ≤ (add p q).num) (hpq1 : Qle (add p q) ⟨1, 1⟩) {n M : Nat} (hMge : n + 1 ≤ M) :
    Qle (Qabs (Qsub (expSum (add p q) (n + 1)) (mul (expSum p M) (expSum q M)))) ⟨2, n + 1⟩ := by
  have hpqd' := add_den_pos hpd hqd
  have hg : ∀ i j, 0 < (mul (expTerm p i) (expTerm q j)).den :=
    fun i j => Qmul_den_pos (expTerm_den_pos hpd i) (expTerm_den_pos hqd j)
  have hgnn : ∀ i j, 0 ≤ (mul (expTerm p i) (expTerm q j)).num :=
    fun i j => Int.mul_nonneg (expTerm_num_nonneg hp0 i) (expTerm_num_nonneg hq0 j)
  have hmul := expSum_mul_eq hpd hqd M
  have hcle := expSum_corner_le hp0 hpd hq0 hqd hpq1 M
  let corner := Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm p i) (expTerm q j)) M)
      (Fsum (fun j => mul (expTerm p i) (expTerm q j)) (M - i))) M
  have hcornerden : 0 < corner.den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => hg i j) M)
      (Fsum_den_pos (fun j => hg i j) (M - i))) M
  have hcorner_nn : 0 ≤ corner.num :=
    Fsum_num_nonneg (fun i => Qsub_num_nonneg
      (Fsum_mono_len (fun j => hgnn i j) (fun j => hg i j) (Nat.sub_le M i))) M
  have hEnP1 : 0 < (expSum (add p q) (n + 1)).den := expSum_den_pos hpqd' (n + 1)
  have hEM : 0 < (expSum (add p q) M).den := expSum_den_pos hpqd' M
  have hmuld : 0 < (mul (expSum p M) (expSum q M)).den :=
    Qmul_den_pos (expSum_den_pos hpd M) (expSum_den_pos hqd M)
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hEnP1 hEM))
      (Qabs_den_pos (Qsub_den_pos hEM hmuld)))
    (Qabs_sub_triangle hEnP1 hEM hmuld) ?_
  have hp1bound : Qle (Qabs (Qsub (expSum (add p q) (n + 1)) (expSum (add p q) M))) ⟨1, n + 1⟩ := by
    rw [Qabs_Qsub_comm]
    exact Qle_trans (fct_pos (n + 1 + 1)) (expabs_bound hpq0 hpqd' hpq1 hMge) (efct_reindex n)
  have hp2bound : Qle (Qabs (Qsub (expSum (add p q) M) (mul (expSum p M) (expSum q M)))) ⟨1, n + 1⟩ := by
    have hcongr : Qeq (Qsub (expSum (add p q) M) (mul (expSum p M) (expSum q M))) (neg corner) :=
      Qeq_trans (Qsub_den_pos hEM (add_den_pos hEM hcornerden))
        (QsubCongr (Qeq_refl (expSum (add p q) M)) hmul)
        (Qsub_add_self_left (expSum (add p q) M) corner)
    have heqabs : Qeq (Qabs (Qsub (expSum (add p q) M) (mul (expSum p M) (expSum q M)))) (Qabs corner) := by
      have h := Qabs_Qeq hcongr
      rw [Qabs_neg] at h; exact h
    have hcabs : Qle (Qabs corner) ⟨1, n + 1⟩ := by
      have h1 : Qle (Qabs corner) ⟨2, fct (M + 1)⟩ := Qabs_le_of_nonneg hcorner_nn hcle
      have hm : (fct (n + 1 + 1) : Int) ≤ (fct (M + 1) : Int) := by
        exact_mod_cast fct_mono (show n + 1 + 1 ≤ M + 1 by omega)
      have h2 : Qle (⟨2, fct (M + 1)⟩ : Q) ⟨2, fct (n + 1 + 1)⟩ := by
        show (2 : Int) * ((fct (n + 1 + 1) : Nat) : Int) ≤ 2 * ((fct (M + 1) : Nat) : Int)
        omega
      exact Qle_trans (fct_pos (M + 1)) h1
        (Qle_trans (fct_pos (n + 1 + 1)) h2 (efct_reindex n))
    exact Qle_congr_left (Qabs_den_pos hcornerden) (Qeq_symm heqabs) hcabs
  have hsum : Qeq (add (⟨1, n + 1⟩ : Q) ⟨1, n + 1⟩) ⟨2, n + 1⟩ := by
    simp only [Qeq, add]; push_cast; ring_uor
  exact Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n))
    (Qadd_le_add hp1bound hp2bound) (Qeq_le hsum)

/-- **The exponential functional equation on ℝ (the `[0,1]` case)**: for rationals `p, q ∈ [0,1]` with
    `p + q ≤ 1`, `exp(p+q) ≈ exp p · exp q` as constructive reals. The diagonal of the product `Rmul`
    samples the partial sums at depth `M = Ridx + 1 ≥ n+1`, where `exp_diag_gap` gives the `Req` bound. -/
theorem Rexp_add {p q : Q} (hp0 : 0 ≤ p.num) (hpd : 0 < p.den) (hp1 : Qle p ⟨1, 1⟩)
    (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩)
    (hpq0 : 0 ≤ (add p q).num) (hpqd : 0 < (add p q).den) (hpq1 : Qle (add p q) ⟨1, 1⟩) :
    Req (Rexp (add p q) hpq0 hpqd hpq1) (Rmul (Rexp p hp0 hpd hp1) (Rexp q hq0 hqd hq1)) := by
  intro n
  have hMge : n + 1 ≤ Ridx (Rexp p hp0 hpd hp1) (Rexp q hq0 hqd hq1) n + 1 := by
    have := Ridx_ge (Rexp p hp0 hpd hp1) (Rexp q hq0 hqd hq1) n; omega
  show Qle (Qabs (Qsub (expSum (add p q) (n + 1))
      (mul (expSum p (Ridx (Rexp p hp0 hpd hp1) (Rexp q hq0 hqd hq1) n + 1))
           (expSum q (Ridx (Rexp p hp0 hpd hp1) (Rexp q hq0 hqd hq1) n + 1))))) ⟨2, n + 1⟩
  exact exp_diag_gap hp0 hpd hq0 hqd hpq0 hpq1 hMge

end UOR.Bridge.F1Square.Analysis
