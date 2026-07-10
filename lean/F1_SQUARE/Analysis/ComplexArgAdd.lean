/-
F1 square — v0.22.0 Track 1, brick (complex lift): toward **complex argument additivity**
`arg(zw) = arg z + arg w` (`Carg`), the imaginary half of `Clog` additivity.

Built on the real-argument arctan addition `RarctanR_add_real_via` (`ArctanTan.lean`) and the real
arctan map `vvalReal` (`ArtanhAdd.lean`). The route: the complex-division **ratio identity**
`Im(zw)/Re(zw) ≈ vvalReal(Im z/Re z, Im w/Re w)` (the tangent-addition identity at the value level),
then `RarctanR_congr` + the real addition law. This file collects the cancellation infrastructure and
the `vvalReal` real defining relation that the ratio identity needs.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.ArctanTan
import F1Square.Analysis.RArctanCongr
import F1Square.Analysis.ComplexArg
import F1Square.Analysis.ComplexLog

namespace UOR.Bridge.F1Square.Analysis

/-- **`exp w ≈ 1 ⟹ w ≈ 0`** — the kernel of general `exp`-injectivity (no non-negativity needed).
    `exp` is strictly monotone, so `exp w = exp 0 = 1` forces `w = 0`. Both order directions come from
    `RexpReal_reflects_le` with the non-negative argument fixed at `0`: `w ≤ 0` directly, and `0 ≤ w`
    from `exp(−w) ≈ 1` (since `exp(−w)·exp w = exp 0 = 1`). -/
theorem RexpReal_eq_one_imp_zero {w : Real} (h : Req (RexpReal w) one) : Req w zero := by
  have hle : Rle w zero :=
    RexpReal_reflects_le Rnonneg_zero (Rle_of_Req (Req_trans h (Req_symm RexpReal_zero)))
  have hnegexp : Req (RexpReal (Rneg w)) one := by
    have hprod : Req (RexpReal (Radd (Rneg w) w)) (Rmul (RexpReal (Rneg w)) (RexpReal w)) :=
      RexpReal_add (Rneg w) w
    have haddz : Req (Radd (Rneg w) w) zero := Req_trans (Radd_comm (Rneg w) w) (Radd_neg w)
    have h1 : Req (Rmul (RexpReal (Rneg w)) (RexpReal w)) one :=
      Req_trans (Req_symm hprod) (Req_trans (RexpReal_congr haddz) RexpReal_zero)
    exact Req_trans (Req_symm (Rmul_one (RexpReal (Rneg w))))
      (Req_trans (Rmul_congr (Req_refl _) (Req_symm h)) h1)
  have hlen : Rle (Rneg w) zero :=
    RexpReal_reflects_le Rnonneg_zero (Rle_of_Req (Req_trans hnegexp (Req_symm RexpReal_zero)))
  have hle0 : Rle zero w := by
    intro n
    have hh := hlen n
    show Qle (zero.seq n) (add (w.seq n) ⟨2, n + 1⟩)
    have e1 : (Rneg w).seq n = neg (w.seq n) := rfl
    rw [e1] at hh
    simp only [Qle, neg, add, zero_seq] at hh ⊢
    push_cast at hh ⊢
    simp only [Int.one_mul, Int.mul_one, Int.zero_mul, Int.neg_mul] at hh ⊢
    omega
  exact Rle_antisymm hle hle0

/-- **`exp` is injective** (general — no non-negativity): `exp X ≈ exp Y ⟹ X ≈ Y`. Via
    `exp(X−Y) = exp X·exp(−Y) ≈ exp Y·exp(−Y) = exp(Y−Y) = exp 0 = 1` (`RexpReal_add` both ways, no
    cancellation/positivity), then `RexpReal_eq_one_imp_zero`. Removes the `Rnonneg` restriction of
    `RexpReal_inj`. -/
theorem RexpReal_inj_gen {X Y : Real} (h : Req (RexpReal X) (RexpReal Y)) : Req X Y := by
  have hsub : Req (RexpReal (Rsub X Y)) one :=
    Req_trans (RexpReal_add X (Rneg Y))
      (Req_trans (Rmul_congr h (Req_refl _))
        (Req_trans (Req_symm (RexpReal_add Y (Rneg Y)))
          (Req_trans (RexpReal_congr (Radd_neg Y)) RexpReal_zero)))
  exact Req_of_Rsub_zero_loc (RexpReal_eq_one_imp_zero hsub)

set_option maxHeartbeats 1600000 in
/-- **★ the exp∘log inverse at a rational base** `exp(log q) = q` for `q ≥ 1` (the constructive
    `Rlog`). Instantiates the radius-general `Rexp_two_artanh_ofQ` at `τ = tmap q = (q−1)/(q+1)`,
    `g = q`, `K = (q+1)/2`, `M' = q.num + q.den`; the closed forms (`tmap_nonneg_lt_one` + `hnum`/
    `hdenI`/`hdenN`) discharge the parameter goals. Works at ANY rational `q ≥ 1` (no small-radius
    bound) — the base case of the real exp∘log inverse. -/
theorem Rexp_log_ratQ (q : Q) (hqd : 0 < q.den) (hqge : Qle (⟨1,1⟩:Q) q)
    (hxpos : ∀ n, 0 < ((ofQ q hqd).seq n).num)
    (hhi : ∀ n, Qle ((ofQ q hqd).seq n) q)
    (hlo : ∀ n, Qle (⟨1,1⟩:Q) (mul ((ofQ q hqd).seq n) q)) :
    Req (RexpReal (Rlog (ofQ q hqd) q hqd hqge hxpos hhi hlo)) (ofQ q hqd) := by
  have hqn : 0 ≤ q.num := by have := hqge; simp only [Qle] at this; push_cast at this; omega
  have hqn1 : (q.den:Int) ≤ q.num := by have := hqge; simp only [Qle] at this; push_cast at this; omega
  have hd0 : (0:Int) < q.den := by exact_mod_cast hqd
  obtain ⟨hτ0, hτlt0⟩ := tmap_nonneg_lt_one q hqd hqge
  have hnum : (tmap q).num = (q.num - (q.den:Int)) * q.den := by
    unfold tmap mul Qsub Qinv add neg; push_cast; ring_uor
  have hdenN : (tmap q).den = q.den * (q.num + (q.den:Int)).toNat := by
    unfold tmap mul Qsub Qinv add neg
    show q.den * 1 * (q.num * 1 + 1 * (q.den:Int)).toNat = q.den * (q.num + (q.den:Int)).toNat
    rw [show q.num * 1 + 1 * (q.den:Int) = q.num + (q.den:Int) by ring_uor, Nat.mul_one]
  have hdenI : ((tmap q).den : Int) = (q.den:Int) * (q.num + q.den) := by
    rw [hdenN]; push_cast [Int.toNat_of_nonneg (show (0:Int) ≤ q.num + q.den by omega)]; ring_uor
  have hτd : 0 < (tmap q).den := by rw [hdenN]; exact Nat.mul_pos hqd (by omega)
  have he2 : ((q.num.toNat + q.den : Nat):Int) = q.num + q.den := by
    push_cast [Int.toNat_of_nonneg hqn]; ring_uor
  have hρ0 : 0 ≤ (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q).num := by show 0 ≤ q.num - (q.den:Int); omega
  have hρd : 0 < (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q).den := by show 0 < q.num.toNat + q.den; omega
  have hρlt : (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q).num.toNat < (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q).den := by
    show (q.num - (q.den:Int)).toNat < q.num.toNat + q.den
    have h2 : ((q.num - (q.den:Int)).toNat : Int) = q.num - q.den := Int.toNat_of_nonneg (by omega)
    have : ((q.num - (q.den:Int)).toNat : Int) < ((q.num.toNat + q.den : Nat):Int) := by rw [h2, he2]; omega
    exact_mod_cast this
  have htle : Qle (tmap q) (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q) := by
    apply Qeq_le
    show (tmap q).num * ((q.num.toNat + q.den : Nat):Int) = (q.num - (q.den:Int)) * ((tmap q).den : Int)
    rw [hnum, hdenI, he2]; ring_uor
  have hb : Qle (Qabs (tmap q)) (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q) :=
    Qle_trans hτd (Qeq_le (Qabs_of_nonneg hτ0)) htle
  have hbridge : Rlog (ofQ q hqd) q hqd hqge hxpos hhi hlo
      = TwoArtanhConst (tmap q) (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q) hτd hρ0 hρd hρlt hb := rfl
  rw [hbridge]
  refine Rexp_two_artanh_ofQ (tmap q) (⟨q.num - (q.den:Int), q.num.toNat + q.den⟩ : Q) q
    (⟨q.num + (q.den:Int), 2 * q.den⟩ : Q) ((q.num + q.den).toNat)
    ((expM_U ((q.num + q.den).toNat) (2 * (q.num + q.den).toNat)).num.toNat)
    ((q.num + q.den).toNat * (q.num + q.den).toNat * (((expM_U ((q.num + q.den).toNat) (2 * (q.num + q.den).toNat)).num.toNat) + 2))
    hτd hτ0 ?_ hτlt0 hρ0 hρd hρlt hb hqd ?_ (by show 0 < 2 * q.den; omega) ?_ ?_ rfl ?_ ?_
  · show (tmap q).num * ((⟨1,1⟩:Q).den:Int) ≤ (⟨1,1⟩:Q).num * ((tmap q).den:Int)
    rw [hnum, hdenI]
    have hkey : (q.den:Int)*(q.num+q.den) - (q.num-q.den)*q.den = 2*(q.den*q.den) := by ring_uor
    have hnn : (0:Int) ≤ 2*(q.den*q.den) := by have := Int.mul_pos hd0 hd0; omega
    push_cast; omega
  · show Qeq (mul q (Qsub ⟨1,1⟩ (tmap q))) (add ⟨1,1⟩ (tmap q))
    simp only [Qeq, mul, Qsub, add, neg]; push_cast; rw [hnum, hdenI]; ring_uor
  · show 0 ≤ (⟨q.num + (q.den:Int), 2 * q.den⟩:Q).num; show 0 ≤ q.num + (q.den:Int); omega
  · apply Qeq_le
    show Qeq (⟨1,1⟩:Q) (mul (⟨q.num + (q.den:Int), 2 * q.den⟩:Q) (Qsub ⟨1,1⟩ (tmap q)))
    simp only [Qeq, mul, Qsub, add, neg]; push_cast; rw [hnum, hdenI]; ring_uor
  · show Qle (mul (⟨q.num + (q.den:Int), 2 * q.den⟩:Q) ⟨2,1⟩) ⟨((q.num + q.den).toNat : Int), 1⟩
    simp only [Qle, mul]
    push_cast [Int.toNat_of_nonneg (show (0:Int) ≤ q.num + q.den by omega)]
    simp only [Int.mul_one, Int.one_mul]
    have hkey : (q.num+q.den) * (2 * (q.den:Int)) - (q.num+q.den) * 2 = (q.num+q.den)*(2*q.den - 2) := by ring_uor
    have hnn : (0:Int) ≤ (q.num+q.den)*(2*q.den - 2) := Int.mul_nonneg (by omega) (by omega)
    omega
  · intro j
    refine Qeq_le ?_
    simp only [Qeq, add, mul]; rw [hdenN]; push_cast [Int.toNat_of_nonneg (show (0:Int) ≤ q.num + q.den by omega)]; ring_uor

/-- **Right cancellation for `Rmul`**: if `a·c ≈ b·c` and `c` is apart from `0` (a positive lower
    bound at index `k`), then `a ≈ b`. Via `(a−b)·c ≈ a·c − b·c ≈ 0` and `Rmul_eq_zero_cancel`. -/
theorem Rmul_right_cancel {a b c : Real} {k : Nat} (hk : Qlt (Qbound k) (c.seq k))
    (h : Req (Rmul a c) (Rmul b c)) : Req a b := by
  have hz : Req (Rmul (Rsub a b) c) zero :=
    Req_trans (Rmul_sub_distrib_right a b c)
      (Req_trans (Rsub_congr h (Req_refl (Rmul b c))) (Radd_neg (Rmul b c)))
  exact Req_of_Rsub_zero_loc (Rmul_eq_zero_cancel hk hz)

/-- **`(a/b)·b ≈ a`** (the division defining relation), for `b` apart from `0`: `Rdiv a b = a·(1/b)`,
    reassociate and cancel `b·(1/b) ≈ 1` (`Rmul_Rinv_self`). -/
theorem Rdiv_mul_cancel {a b : Real} {k : Nat} (hk : Qlt (Qbound k) (b.seq k)) :
    Req (Rmul (Rdiv a b k hk) b) a := by
  show Req (Rmul (Rmul a (Rinv b k hk)) b) a
  refine Req_trans (Rmul_assoc a (Rinv b k hk) b) ?_
  refine Req_trans (Rmul_congr (Req_refl a)
    (Req_trans (Rmul_comm (Rinv b k hk) b) (Rmul_Rinv_self hk))) ?_
  exact Rmul_one a

/-- The pure-`Q` algebra behind `vvalReal_rel`: `A·(1−U) − A·(1−W) = A·(W−U)`. -/
theorem vvalrel_alg (A U W : Q) :
    Qeq (Qsub (mul A (Qsub ⟨1, 1⟩ U)) (mul A (Qsub ⟨1, 1⟩ W))) (mul A (Qsub W U)) := by
  simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor

set_option maxHeartbeats 1200000 in
/-- **The `vvalReal` defining relation (abstract diagonal)**: for a real `V` whose `n`-th approximant
    is `vval(s.seq (f n), t.seq (f n))` (any reindex `f` with `n ≤ f n`), `V·(1 − s·t) ≈ s + t`, given
    `|s.seq m|, |t.seq m|, |vval(s.seq m, t.seq m)| ≤ ρ` (`ρ ≤ 1`, `ρ² ≤ ½`). The rational `vval_rel`
    (`a+b = vval a b·(1−ab)`) holds exactly at each diagonal index; the index mismatch between `V`'s
    argument depth and the `(1−st)` factor's depth is absorbed by regularity (`xreg_n_le`). The
    `vvalReal`-side input to the `arg(zw) = arg z + arg w` ratio identity. -/
theorem vvalReal_rel_via (s t V : Real) (ρ : Q) (f : Nat → Nat) (hf : ∀ n, n ≤ f n)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρ1 : Qle ρ ⟨1, 1⟩) (hρ2 : Qle (mul ρ ρ) ⟨1, 2⟩)
    (hbs : ∀ m, Qle (Qabs (s.seq m)) ρ) (hbt : ∀ m, Qle (Qabs (t.seq m)) ρ)
    (hbw : ∀ m, Qle (Qabs (vval (s.seq m) (t.seq m))) ρ)
    (hVseq : ∀ n, V.seq n = vval (s.seq (f n)) (t.seq (f n))) :
    Req (Rmul V (Rsub one (Rmul s t))) (Radd s t) := by
  refine Req_of_lin_bound (C := 8) ?_
  intro n
  have hJn : n ≤ Ridx V (Rsub one (Rmul s t)) n := Ridx_ge _ _ n
  have hPn : n ≤ f (Ridx V (Rsub one (Rmul s t)) n) := Nat.le_trans hJn (hf _)
  have hLn : n ≤ Ridx s t (2 * Ridx V (Rsub one (Rmul s t)) n + 1) :=
    Nat.le_trans hJn (Nat.le_trans (by omega) (Ridx_ge s t _))
  have hae : (Rmul V (Rsub one (Rmul s t))).seq n
      = mul (vval (s.seq (f (Ridx V (Rsub one (Rmul s t)) n)))
                  (t.seq (f (Ridx V (Rsub one (Rmul s t)) n))))
          (Qsub ⟨1, 1⟩ (mul (s.seq (Ridx s t (2 * Ridx V (Rsub one (Rmul s t)) n + 1)))
                            (t.seq (Ridx s t (2 * Ridx V (Rsub one (Rmul s t)) n + 1))))) := by
    show mul (V.seq (Ridx V (Rsub one (Rmul s t)) n))
        ((Rsub one (Rmul s t)).seq (Ridx V (Rsub one (Rmul s t)) n)) = _
    rw [hVseq]; rfl
  rw [hae, show (Radd s t).seq n = add (s.seq (2 * n + 1)) (t.seq (2 * n + 1)) from rfl]
  generalize hPdef : f (Ridx V (Rsub one (Rmul s t)) n) = P at hPn ⊢
  generalize hLdef : Ridx s t (2 * Ridx V (Rsub one (Rmul s t)) n + 1) = L at hLn ⊢
  -- now: |A·(1 − s_L t_L) − (s_{2n+1} + t_{2n+1})| ≤ 8/(n+1), A = vval(s_P, t_P)
  have hposP : 0 < (s.seq P).den * (t.seq P).den - (s.seq P).num * (t.seq P).num :=
    vval_inner_pos ρ (s.seq P) (t.seq P) hρd hρ0 (s.den_pos P) (t.den_pos P) (hbs P) (hbt P) hρ2
  have hAd : 0 < (vval (s.seq P) (t.seq P)).den := vval_den_pos _ _ hposP
  have hmLd : 0 < (mul (s.seq L) (t.seq L)).den := Qmul_den_pos (s.den_pos L) (t.den_pos L)
  have hmPd : 0 < (mul (s.seq P) (t.seq P)).den := Qmul_den_pos (s.den_pos P) (t.den_pos P)
  have hLd : 0 < (mul (vval (s.seq P) (t.seq P)) (Qsub ⟨1, 1⟩ (mul (s.seq L) (t.seq L)))).den :=
    Qmul_den_pos hAd (Qsub_den_pos (by decide) hmLd)
  have hmid : 0 < (add (s.seq P) (t.seq P)).den := add_den_pos (s.den_pos P) (t.den_pos P)
  have hRd : 0 < (add (s.seq (2 * n + 1)) (t.seq (2 * n + 1))).den :=
    add_den_pos (s.den_pos _) (t.den_pos _)
  -- abbreviation bounds
  have hAle1 : Qle (Qabs (vval (s.seq P) (t.seq P))) (⟨1, 1⟩ : Q) := Qle_trans hρd (hbw P) hρ1
  have hsP1 : Qle (Qabs (s.seq P)) (⟨1, 1⟩ : Q) := Qle_trans hρd (hbs P) hρ1
  have htL1 : Qle (Qabs (t.seq L)) (⟨1, 1⟩ : Q) := Qle_trans hρd (hbt L) hρ1
  -- vval_rel: s_P + t_P = A·(1 − s_P t_P)
  have hvr : Qeq (add (s.seq P) (t.seq P))
      (mul (vval (s.seq P) (t.seq P)) (Qsub ⟨1, 1⟩ (mul (s.seq P) (t.seq P)))) :=
    vval_rel (s.seq P) (t.seq P) hposP
  -- term1: |LHS − (s_P + t_P)| ≤ 4/(n+1)
  have hkey : Qeq (Qsub (mul (vval (s.seq P) (t.seq P)) (Qsub ⟨1, 1⟩ (mul (s.seq L) (t.seq L))))
        (add (s.seq P) (t.seq P)))
      (mul (vval (s.seq P) (t.seq P)) (Qsub (mul (s.seq P) (t.seq P)) (mul (s.seq L) (t.seq L)))) :=
    Qeq_trans (Qsub_den_pos (Qmul_den_pos hAd (Qsub_den_pos (by decide) hmLd))
        (Qmul_den_pos hAd (Qsub_den_pos (by decide) hmPd)))
      (Qsub_congr (Qeq_refl _) hvr)
      (vvalrel_alg (vval (s.seq P) (t.seq P)) (mul (s.seq L) (t.seq L)) (mul (s.seq P) (t.seq P)))
  have hYbound : Qle (Qabs (Qsub (mul (s.seq P) (t.seq P)) (mul (s.seq L) (t.seq L)))) (⟨4, n + 1⟩ : Q) := by
    refine Qle_trans (add_den_pos (Qmul_den_pos (Qabs_den_pos (s.den_pos P))
        (Qabs_den_pos (Qsub_den_pos (t.den_pos P) (t.den_pos L))))
        (Qmul_den_pos (Qabs_den_pos (t.den_pos L)) (Qabs_den_pos (Qsub_den_pos (s.den_pos P) (s.den_pos L)))))
      (Qabs_mul_diff (s.den_pos P) (t.den_pos P) (s.den_pos L) (t.den_pos L)) ?_
    refine Qle_trans (add_den_pos (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
        (Qmul_den_pos Nat.one_pos (Nat.succ_pos n)))
      (Qadd_le_add
        (Qmul_le_mul (Qabs_den_pos (s.den_pos P)) (by decide)
          (Qabs_den_pos (Qsub_den_pos (t.den_pos P) (t.den_pos L))) (Qabs_num_nonneg _)
          (Qabs_num_nonneg _) hsP1 (xreg_n_le t hPn hLn))
        (Qmul_le_mul (Qabs_den_pos (t.den_pos L)) (by decide)
          (Qabs_den_pos (Qsub_den_pos (s.den_pos P) (s.den_pos L))) (Qabs_num_nonneg _)
          (Qabs_num_nonneg _) htL1 (xreg_n_le s hPn hLn))) ?_
    apply Qeq_le
    show Qeq (add (mul ⟨1, 1⟩ ⟨2, n + 1⟩) (mul ⟨1, 1⟩ ⟨2, n + 1⟩)) (⟨4, n + 1⟩ : Q)
    simp only [Qeq, mul, add]; push_cast; ring_uor
  have hterm1 : Qle (Qabs (Qsub (mul (vval (s.seq P) (t.seq P)) (Qsub ⟨1, 1⟩ (mul (s.seq L) (t.seq L))))
        (add (s.seq P) (t.seq P)))) (⟨4, n + 1⟩ : Q) := by
    refine Qle_trans (Qabs_den_pos (Qmul_den_pos hAd (Qsub_den_pos hmPd hmLd)))
      (Qeq_le (Qabs_Qeq hkey)) ?_
    rw [Qabs_mul]
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hmPd hmLd)))
      (Qmul_le_mul_right (Qabs_num_nonneg _) hAle1) ?_
    exact Qle_trans (Qabs_den_pos (Qsub_den_pos hmPd hmLd))
      (Qeq_le (Qone_mul _)) hYbound
  -- term2: |(s_P + t_P) − (s_{2n+1} + t_{2n+1})| ≤ 4/(n+1)
  have hterm2 : Qle (Qabs (Qsub (add (s.seq P) (t.seq P))
        (add (s.seq (2 * n + 1)) (t.seq (2 * n + 1))))) (⟨4, n + 1⟩ : Q) := by
    have h2n : n ≤ 2 * n + 1 := by omega
    refine Qle_trans (add_den_pos
        (Qabs_den_pos (Qsub_den_pos (s.den_pos P) (s.den_pos (2 * n + 1))))
        (Qabs_den_pos (Qsub_den_pos (t.den_pos P) (t.den_pos (2 * n + 1)))))
      (Qabs_sub_add4 (s.den_pos P) (t.den_pos P) (s.den_pos (2 * n + 1)) (t.den_pos (2 * n + 1))) ?_
    refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n))
      (Qadd_le_add (xreg_n_le s (i := P) (j := 2 * n + 1) hPn h2n)
        (xreg_n_le t (i := P) (j := 2 * n + 1) hPn h2n)) ?_
    apply Qeq_le; exact Qadd_same_den_loc 2 2 (n + 1)
  -- triangle through (s_P + t_P)
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hLd hmid))
      (Qabs_den_pos (Qsub_den_pos hmid hRd)))
    (Qabs_sub_triangle hLd hmid hRd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hterm1 hterm2) ?_
  apply Qeq_le; exact Qadd_same_den_loc 4 4 (n + 1)

/-- **The arctan ratio cross-identity** (pure real algebra): if `s·a ≈ b`, `t·c ≈ d`, and
    `V·(1 − s·t) ≈ s + t` (the `vvalReal` defining relation), then `V·(a·c − b·d) ≈ a·d + b·c`. With
    `a = Re z, b = Im z, c = Re w, d = Im w` and `s = Im z/Re z, t = Im w/Re w`, this is
    `vvalReal(ratio z, ratio w)·Re(zw) = Im(zw)` — one cross-multiplied side of
    `Im(zw)/Re(zw) = vvalReal(ratio z, ratio w)`. -/
theorem ratio_cross_via {s t V a b c d : Real}
    (hsa : Req (Rmul s a) b) (htc : Req (Rmul t c) d)
    (hVrel : Req (Rmul V (Rsub one (Rmul s t))) (Radd s t)) :
    Req (Rmul V (Rsub (Rmul a c) (Rmul b d))) (Radd (Rmul a d) (Rmul b c)) := by
  -- b·d ≈ (a·c)·(s·t)
  have hbd : Req (Rmul b d) (Rmul (Rmul a c) (Rmul s t)) :=
    Req_trans (Rmul_congr (Req_symm hsa) (Req_symm htc))
      (Req_trans (Rmul_assoc s a (Rmul t c))
        (Req_trans (Rmul_congr (Req_refl s) (Rmul_congr (Req_refl a) (Rmul_comm t c)))
          (Req_trans (Rmul_congr (Req_refl s) (Req_symm (Rmul_assoc a c t)))
            (Rmul_left_comm_loc s (Rmul a c) t))))
  -- a·c − b·d ≈ (a·c)·(1 − s·t)
  have hstep1 : Req (Rsub (Rmul a c) (Rmul b d)) (Rmul (Rmul a c) (Rsub one (Rmul s t))) :=
    Req_trans (Rsub_congr (Req_refl (Rmul a c)) hbd)
      (Req_symm (Req_trans (Rmul_sub_distrib (Rmul a c) one (Rmul s t))
        (Rsub_congr (Rmul_one (Rmul a c)) (Req_refl _))))
  -- V·(a·c − b·d) ≈ (a·c)·(s + t)
  have hstep2 : Req (Rmul V (Rsub (Rmul a c) (Rmul b d))) (Rmul (Rmul a c) (Radd s t)) :=
    Req_trans (Rmul_congr (Req_refl V) hstep1)
      (Req_trans (Rmul_left_comm_loc V (Rmul a c) (Rsub one (Rmul s t)))
        (Rmul_congr (Req_refl (Rmul a c)) hVrel))
  -- (a·c)·s ≈ b·c, (a·c)·t ≈ a·d
  have hacs : Req (Rmul (Rmul a c) s) (Rmul b c) :=
    Req_trans (Rmul_comm (Rmul a c) s)
      (Req_trans (Req_symm (Rmul_assoc s a c)) (Rmul_congr hsa (Req_refl c)))
  have hact : Req (Rmul (Rmul a c) t) (Rmul a d) :=
    Req_trans (Rmul_assoc a c t)
      (Req_trans (Rmul_congr (Req_refl a) (Rmul_comm c t)) (Rmul_congr (Req_refl a) htc))
  -- assemble
  exact Req_trans hstep2
    (Req_trans (Rmul_distrib (Rmul a c) s t)
      (Req_trans (Radd_congr hacs hact) (Radd_comm (Rmul b c) (Rmul a d))))

set_option maxHeartbeats 1200000 in
/-- **★ complex argument additivity** `arg(zw) = arg z + arg w` (principal sector). For `z, w` with
    `Re z, Re w, Re(zw)` apart from `0` and all three ratios `Im/Re` bounded by `ρ < 1/16`,
    `Carg(zw) = Carg z + Carg w`. The imaginary half of `Clog` additivity. Assembly: the ratio identity
    `Im(zw)/Re(zw) ≈ vvalReal(ratio z, ratio w)` (`ratio_cross_via` + `Rdiv_mul_cancel` cross-multiplied,
    cancelled by `Rmul_right_cancel`), bridged through `RarctanR_congr`, then the real arctan addition
    `RarctanR_add_real_via`. -/
theorem Carg_add (z w : Complex) (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hzw : Qlt (Qbound kzw) ((Cmul z w).re.seq kzw))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbs : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbt : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).im (Cmul z w).re kzw hzw).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs (vval ((Rdiv z.im z.re kz hkz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ) :
    Req (Carg (Cmul z w) kzw hzw ρ hρ0 hρd hlt hbzw)
        (Radd (Carg z kz hkz ρ hρ0 hρd hlt hbs) (Carg w kw hkw ρ hρ0 hρd hlt hbt)) := by
  have hρ2' : Qle (mul ρ ρ) (⟨1, 2⟩ : Q) := by
    have h := hρ2; simp only [Qle, Qsub, add, neg, mul] at h ⊢; push_cast at h ⊢; omega
  have hRge : ∀ k, k ≤ Rartanh_R ρ k := by
    intro k; unfold Rartanh_R
    have hk : 1 ≤ ρ.den * ρ.den + 4 * ρ.den := Nat.le_trans (by omega) (Nat.le_add_left _ _)
    calc k ≤ 1 * (k + 1) := by omega
      _ ≤ (ρ.den * ρ.den + 4 * ρ.den) * (k + 1) := Nat.mul_le_mul_right _ hk
  have hbvv : ∀ n, Qle (Qabs ((vvalReal (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw)
      ρ hρd hρ0 hρ2' hbs hbt).seq n)) ρ := fun n => hbw (12 * n + 11)
  have hVrel := vvalReal_rel_via (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw)
    (vvalReal (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw) ρ hρd hρ0 hρ2' hbs hbt)
    ρ (fun n => 12 * n + 11) (fun n => by show n ≤ 12 * n + 11; omega) hρ0 hρd hρ1 hρ2' hbs hbt hbw
    (fun _ => rfl)
  have goal_vval : Req (Rmul (vvalReal (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw)
        ρ hρd hρ0 hρ2' hbs hbt) (Cmul z w).re) ((Cmul z w).im) :=
    ratio_cross_via (Rdiv_mul_cancel hkz) (Rdiv_mul_cancel hkw) hVrel
  have hratio : Req (Rdiv (Cmul z w).im (Cmul z w).re kzw hzw)
        (vvalReal (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw) ρ hρd hρ0 hρ2' hbs hbt) :=
    Rmul_right_cancel hzw (Req_trans (Rdiv_mul_cancel hzw) (Req_symm goal_vval))
  have hcongr := RarctanR_congr (Rdiv (Cmul z w).im (Cmul z w).re kzw hzw)
    (vvalReal (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw) ρ hρd hρ0 hρ2' hbs hbt)
    ρ hρ0 hρd hlt hρ2 hbzw hbvv hratio
  have hadd := RarctanR_add_real_via (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw)
    (RarctanR (Rdiv z.im z.re kz hkz) ρ hρ0 hρd hlt hbs)
    (RarctanR (Rdiv w.im w.re kw hkw) ρ hρ0 hρd hlt hbt)
    (RarctanR (vvalReal (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw) ρ hρd hρ0 hρ2' hbs hbt)
      ρ hρ0 hρd hlt hbvv)
    ρ (fun n => 12 * Rartanh_R ρ n + 11) hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
    (fun n => by show n ≤ 12 * Rartanh_R ρ n + 11; exact Nat.le_trans (hRge n) (by omega))
    hbs hbt hbw (fun _ => rfl) (fun _ => rfl) (fun _ => rfl)
  exact Req_trans hcongr (Req_symm hadd)

set_option maxHeartbeats 1200000 in
/-- **★ complex logarithm additivity** `Clog(zw) = Clog z + Clog w` (principal sector). The capstone
    of substrate item 0: `Clog z = ½·log|z|² + i·arg z`, so its two halves are the real
    log-multiplicativity (modulus) and the argument addition (imaginary). The imaginary half is
    `Carg_add` (`arg(zw) = arg z + arg w`, fully discharged here). The modulus half is the
    `RlogPos`-multiplicativity `hmod` (`log|zw|² = log|z|² + log|w|²`, via `cnormSq_mul` +
    `Rlog_mul` — the general positive-real log-multiplicativity, supplied as the one explicit
    audit-visible hypothesis, exactly as the program isolates each classical/heavy input). Then
    `Clog(zw).re = ½·log|zw|² ≈ ½(log|z|²+log|w|²) = Clog z.re + Clog w.re` by `Rmul_distrib`, and the
    imaginary parts by `Carg_add`. -/
theorem Clog_add (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hzw : Qlt (Qbound kzw) ((Cmul z w).re.seq kzw))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbs : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbt : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).im (Cmul z w).re kzw hzw).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs (vval ((Rdiv z.im z.re kz hkz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ)
    (hmod : Req (RlogPos (cnormSq (Cmul z w)) knzw hknzw)
      (Radd (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw))) :
    Ceq (Clog (Cmul z w) knzw hknzw kzw hzw ρ hρ0 hρd hlt hbzw)
        (Cadd (Clog z knz hknz kz hkz ρ hρ0 hρd hlt hbs)
              (Clog w knw hknw kw hkw ρ hρ0 hρd hlt hbt)) :=
  ⟨Req_trans (Rmul_congr (Req_refl half) hmod)
      (Rmul_distrib half (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw)),
   Carg_add z w kz hkz kw hkw kzw hzw ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
     hbs hbt hbzw hbw⟩

end UOR.Bridge.F1Square.Analysis
