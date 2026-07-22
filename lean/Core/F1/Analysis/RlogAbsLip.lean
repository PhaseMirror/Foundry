/-
F1 square — Track 1, item 6 substrate: **symmetric (absolute-value) log-Lipschitz** `|log x − log y| ≤ |x−y|`
(`RlogAbsLip.lean`).

The Mellin-integral layer needs a *symmetric* Lipschitz bound `|f x − f y| ≤ L·|x−y|` for all `x, y` — but
constructive reals have no total order, so a `case x≤y / y≤x` split is unavailable. The resolution: the
directed log-difference bound `RlogPos_sub_le_Rdiv` (`LogDiffBound.lean`) holds for ALL `x, y ∈ [1,B]`
(no ordering hypothesis), so both directions

    log x − log y ≤ (x/y) − 1 ≤ |x−y|        log y − log x ≤ (y/x) − 1 ≤ |x−y|

follow independently, and `Rabs_le_of_both` assembles the absolute bound — with the *rational* constant
`L = 1`, so it feeds the integral directly. The crux step `(x/y) − 1 ≤ |x−y|` is itself symmetric
(`Rdiv_sub_one_le_abs`): `(x−y)/y ≤ |x−y|·(1/y) ≤ |x−y|·1`, via `x ≤ |x|` and `1/y ≤ 1`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogDiffBound

namespace UOR.Bridge.F1Square.Analysis

/-- `1 ≤ x` (as reals) from the per-index envelope `∀n, 1 ≤ x.seq n`. -/
theorem Rle_one_of_seq_ge1 {x : Real} (h : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n)) : Rle one x := by
  intro n
  rw [one_seq]
  exact Qle_trans (x.den_pos n) (h n) (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- `1/y ≤ 1` for `y ≥ 1`: from `1·(1/y) ≤ y·(1/y) ≈ 1`. -/
theorem Rinv_le_one {y : Real} {ky : Nat} (hy : Qlt (Qbound ky) (y.seq ky)) (hy1 : Rle one y) :
    Rle (Rinv y ky hy) one :=
  Rle_trans (Rle_of_Req (Req_symm (Rone_mul (Rinv y ky hy))))
    (Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rinv y ky hy) hy1) (Rle_of_Req (Rmul_Rinv_self hy)))

/-- **`(x/y) − 1 ≤ |x−y|`** for `y ≥ 1` — the symmetric ratio bound. Identity `(x/y)−1 = (x−y)·(1/y)`,
    then `(x−y)·(1/y) ≤ |x−y|·(1/y) ≤ |x−y|·1`. No ordering of `x, y` needed. -/
theorem Rdiv_sub_one_le_abs {x y : Real} {ky : Nat} (hy : Qlt (Qbound ky) (y.seq ky))
    (hy1 : Rle one y) :
    Rle (Rsub (Rdiv x y ky hy) one) (Rabs (Rsub x y)) := by
  have hid : Req (Rsub (Rdiv x y ky hy) one) (Rmul (Rsub x y) (Rinv y ky hy)) :=
    Req_trans (Rsub_congr (Req_refl _) (Req_symm (Rmul_Rinv_self hy)))
      (Req_symm (Rmul_sub_distrib_right x y (Rinv y ky hy)))
  have step1 : Rle (Rmul (Rsub x y) (Rinv y ky hy)) (Rmul (Rabs (Rsub x y)) (Rinv y ky hy)) :=
    Rmul_le_Rmul_right (Rnonneg_Rinv y ky hy) (Rle_Rabs_self (Rsub x y))
  have step2 : Rle (Rmul (Rabs (Rsub x y)) (Rinv y ky hy)) (Rmul (Rabs (Rsub x y)) one) :=
    Rmul_le_Rmul_left (Rnonneg_Rabs _) (Rinv_le_one hy hy1)
  exact Rle_trans (Rle_of_Req hid)
    (Rle_trans step1 (Rle_trans step2 (Rle_of_Req (Rmul_one _))))

/-- **Symmetric log-Lipschitz** `|log x − log y| ≤ |x − y|` for `x, y ∈ [1, B]` (small radius `B²`) —
    rational constant `L = 1`, ready for the Mellin integral. Both directions from the unordered
    `RlogPos_sub_le_Rdiv`, joined by `Rabs_le_of_both`. -/
theorem Rlog_abs_lipschitz (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B) (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B) (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩) :
    Rle (Rabs (Rsub (RlogPos x kx hx) (RlogPos y ky hy))) (Rabs (Rsub x y)) := by
  have hx1 : Rle one x := Rle_one_of_seq_ge1 hxge1
  have hy1 : Rle one y := Rle_one_of_seq_ge1 hyge1
  -- leg 1:  log x − log y ≤ (x/y) − 1 ≤ |x−y|
  have leg1 : Rle (Rsub (RlogPos x kx hx) (RlogPos y ky hy)) (Rabs (Rsub x y)) :=
    Rle_trans (RlogPos_sub_le_Rdiv x y kx hx ky hy B hBd hBge hxpos hxhiB hxge1 hypos hyhiB hyge1
        hρ2 hσ2 hρσ hσhalf)
      (Rdiv_sub_one_le_abs hy hy1)
  -- leg 2:  log y − log x ≤ (y/x) − 1 ≤ |y−x| = |x−y|
  have leg2 : Rle (Rsub (RlogPos y ky hy) (RlogPos x kx hx)) (Rabs (Rsub x y)) :=
    Rle_trans (RlogPos_sub_le_Rdiv y x ky hy kx hx B hBd hBge hypos hyhiB hyge1 hxpos hxhiB hxge1
        hρ2 hσ2 hρσ hσhalf)
      (Rle_trans (Rdiv_sub_one_le_abs hx hx1)
        (Rle_of_Req (Req_trans (Rabs_congr (Req_symm (Rneg_Rsub x y))) (Rabs_Rneg (Rsub x y)))))
  exact Rabs_le_of_both leg1 (Rle_trans (Rle_of_Req (Rneg_Rsub (RlogPos x kx hx) (RlogPos y ky hy))) leg2)

end UOR.Bridge.F1Square.Analysis
