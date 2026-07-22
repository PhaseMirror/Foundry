/-
F1 square — Track 1, item 6: **general-radius log-difference bound** (`LogDiffBoundGen.lean`).

`LogDiffBound.lean`'s `RlogPos_sub_le_Rdiv` carries the small-radius cap `ρ_B² ≤ 1/2` (so `B ≤ ~5.8`),
inherited from the presented-radius bridges. The Mellin integrand over `[1,∞)` has unbounded base, so the
cap must go. This file ports the seam discharge to **any** `B` using the `RadiusGen` K-acceleration layer:
`RlogPos_eq_Rlog_gen`, `Rlog_mul_gen` (signed), `Rlog_congr_gen` replace the capped bridges, and the
convexity bound `Rlog_le_sub_one_real` is already radius-free. The small-radius hypotheses are replaced by
the K-acceleration obligations `hKBF/hKBr` (radius `B`) and `hKBBF/hKBBr` (radius `B²`), each `decide`-able
for a concrete numeral `B` (every integration window `[m+1,m+2]` has `B = m+2`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RdivBounds
import Core.F1.Analysis.RadiusGen
import Core.F1.Analysis.RartanhBounds
import Core.F1.Analysis.LogDiffBound
import Core.F1.Analysis.RrpowAbsLip

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 2000000

/-- **General-radius log-difference bound** `log x − log y ≤ x/y − 1` for `x, y ∈ [1, B]`, ANY `B` — the
    small-radius cap lifted via K-acceleration. The Mellin-integrand seam over the full `[1,∞)`. -/
theorem RlogPos_sub_le_Rdiv_gen (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (B : Q) (K_B K_BB : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B) (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B) (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKBr : K_B ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (hKBBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_BB : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKBBr : K_BB ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Rle (Rsub (RlogPos x kx hx) (RlogPos y ky hy)) (Rsub (Rdiv x y ky hy) one) := by
  -- envelope facts
  have hBnn : (0 : Int) ≤ B.num := by have := hBge; simp only [Qle] at this; push_cast at this; omega
  have hB2d : 0 < (mul B B).den := Qmul_den_pos hBd hBd
  have hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B) := Qone_le_mul hBge hBge hBd hBd
  have hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B) := fun n => Qone_le_mul (hxge1 n) hBge (x.den_pos n) hBd
  have hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B) := fun n => Qone_le_mul (hyge1 n) hBge (y.den_pos n) hBd
  -- x at radius B²
  have hBleB2 : Qle B (mul B B) := QB_le_B2 hBge hBd
  have hxhiB2 : ∀ n, Qle (x.seq n) (mul B B) := fun n => Qle_trans hBd (hxhiB n) hBleB2
  have hxloB2 : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) (mul B B)) := fun n =>
    Qone_le_mul (hxge1 n) hB2ge (x.den_pos n) hB2d
  -- the ratio r = x/y and its [1/B,B] envelope
  have hrpos : ∀ n, 0 < ((Rdiv x y ky hy).seq n).num := Rdiv_seq_pos hy hxpos
  have hrhi : ∀ n, Qle ((Rdiv x y ky hy).seq n) B := Rdiv_seq_le_B hy hBd hxpos hxhiB hyge1 hypos
  have hrlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rdiv x y ky hy).seq n) B) :=
    Rdiv_seq_ge_invB hy hBd hBnn hxge1 hyhiB hypos
  -- the product m = y·r and its [·,B²] envelope
  have hmpos : ∀ n, 0 < ((Rmul y (Rdiv x y ky hy)).seq n).num := Rmul_seq_pos hypos hrpos
  have hmhi : ∀ n, Qle ((Rmul y (Rdiv x y ky hy)).seq n) (mul B B) :=
    Rmul_seq_le hBd (fun n => Int.le_of_lt (hypos n)) hyhiB (fun n => Int.le_of_lt (hrpos n)) hrhi
  have hmlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul y (Rdiv x y ky hy)).seq n) (mul B B)) := fun n =>
    Qprod_lo (hyge1 _) (hrlo _) hBge (y.den_pos _) ((Rdiv x y ky hy).den_pos _) hBd
  -- bridges  RlogPos → Rlog  (K-accelerated)
  have ex : Req (RlogPos x kx hx) (Rlog x (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2) :=
    RlogPos_eq_Rlog_gen x kx hx (mul B B) K_BB hB2d hB2ge hxpos hxhiB2 hxloB2 hKBBF hKBBr
  have ey : Req (RlogPos y ky hy) (Rlog y B hBd hBge hypos hyhiB hyloB) :=
    RlogPos_eq_Rlog_gen y ky hy B K_B hBd hBge hypos hyhiB hyloB hKBF hKBr
  -- multiplicativity  log y + log r ≈ log(y·r)
  have emul : Req (Radd (Rlog y B hBd hBge hypos hyhiB hyloB)
        (Rlog (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo))
      (Rlog (Rmul y (Rdiv x y ky hy)) (mul B B) hB2d hB2ge hmpos hmhi hmlo) :=
    Rlog_mul_gen y (Rdiv x y ky hy) B K_B K_BB hBd hBge hypos hyhiB hyloB hrpos hrhi hrlo
      hB2d hB2ge hmpos hmhi hmlo hρσ hKBF hKBBF hKBBr
  -- congruence  log(y·r) ≈ log x
  have econg : Req (Rlog (Rmul y (Rdiv x y ky hy)) (mul B B) hB2d hB2ge hmpos hmhi hmlo)
      (Rlog x (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2) :=
    Rlog_congr_gen (Rmul y (Rdiv x y ky hy)) x (mul B B) K_BB hB2d hB2ge hmpos hmhi hmlo
      hxpos hxhiB2 hxloB2 hKBBF hKBBr (Rmul_y_Rdiv hy)
  -- assemble
  have hAC : Req (Radd (Rlog y B hBd hBge hypos hyhiB hyloB)
        (Rlog (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo))
      (Rlog x (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2) := Req_trans emul econg
  have hrearr : Req (Rsub (Rlog x (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2)
        (Rlog y B hBd hBge hypos hyhiB hyloB))
      (Rlog (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo) :=
    Req_trans (Rsub_congr (Req_symm hAC) (Req_refl (Rlog y B hBd hBge hypos hyhiB hyloB)))
      (Rsub_Radd_cancel_left (Rlog y B hBd hBge hypos hyhiB hyloB)
        (Rlog (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo))
  have hbridge : Req (Rsub (RlogPos x kx hx) (RlogPos y ky hy))
      (Rlog (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo) :=
    Req_trans (Rsub_congr ex ey) hrearr
  exact Rle_trans (Rle_of_Req hbridge)
    (Rlog_le_sub_one_real (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo)

/-- **General-radius symmetric log-Lipschitz** `|log x − log y| ≤ |x − y|` for `x, y ∈ [1, B]`, ANY `B`
    (rational `L = 1`). Both directions from the unordered `RlogPos_sub_le_Rdiv_gen`. -/
theorem Rlog_abs_lipschitz_gen (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (B : Q) (K_B K_BB : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B) (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B) (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKBr : K_B ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (hKBBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_BB : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKBBr : K_BB ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Rle (Rabs (Rsub (RlogPos x kx hx) (RlogPos y ky hy))) (Rabs (Rsub x y)) := by
  have leg1 : Rle (Rsub (RlogPos x kx hx) (RlogPos y ky hy)) (Rabs (Rsub x y)) :=
    Rle_trans (RlogPos_sub_le_Rdiv_gen x y kx hx ky hy B K_B K_BB hBd hBge hxpos hxhiB hxge1
        hypos hyhiB hyge1 hρσ hKBF hKBr hKBBF hKBBr)
      (Rdiv_sub_one_le_abs hy (Rle_one_of_seq_ge1 hyge1))
  have leg2 : Rle (Rsub (RlogPos y ky hy) (RlogPos x kx hx)) (Rabs (Rsub x y)) :=
    Rle_trans (RlogPos_sub_le_Rdiv_gen y x ky hy kx hx B K_B K_BB hBd hBge hypos hyhiB hyge1
        hxpos hxhiB hxge1 hρσ hKBF hKBr hKBBF hKBBr)
      (Rle_trans (Rdiv_sub_one_le_abs hx (Rle_one_of_seq_ge1 hxge1))
        (Rle_of_Req (Req_trans (Rabs_congr (Req_symm (Rneg_Rsub x y))) (Rabs_Rneg (Rsub x y)))))
  exact Rabs_le_of_both leg1 (Rle_trans (Rle_of_Req (Rneg_Rsub (RlogPos x kx hx) (RlogPos y ky hy))) leg2)

/-- **General-radius symmetric power-Lipschitz** `|x^e − y^e| ≤ 4·|e|·|x − y|` for `e ≤ 0`, `x, y ∈ [1, B]`,
    ANY `B`. The Mellin integrand base-bound over the full `[1,∞)`, rational constant `4·|e|`. -/
theorem RrpowPos_abs_lipschitz_gen (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky)) (e : Real) (he : Rle e zero)
    (B : Q) (K_B K_BB : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B) (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B) (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKBr : K_B ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (hKBBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_BB : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKBBr : K_BB ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Rle (Rabs (Rsub (RrpowPos x kx hx e) (RrpowPos y ky hy e)))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e)) (Rabs (Rsub x y))) := by
  have hMu : Rle (RrpowPos x kx hx e) one :=
    RrpowPos_le_one_of_nonpos x kx hx (Rle_one_of_seq_ge1 hxge1) e he
  have hMv : Rle (RrpowPos y ky hy e) one :=
    RrpowPos_le_one_of_nonpos y ky hy (Rle_one_of_seq_ge1 hyge1) e he
  have hAbsuv : Rle (Rabs (Rsub (Rmul e (RlogPos x kx hx)) (Rmul e (RlogPos y ky hy))))
      (Rmul (Rabs e) (Rabs (Rsub x y))) :=
    Rle_trans (Rle_of_Req (Req_trans
        (Rabs_congr (Req_symm (Rmul_sub_distrib e (RlogPos x kx hx) (RlogPos y ky hy))))
        (Rabs_Rmul e (Rsub (RlogPos x kx hx) (RlogPos y ky hy)))))
      (Rmul_le_Rmul_left (Rnonneg_Rabs e)
        (Rlog_abs_lipschitz_gen x y kx hx ky hy B K_B K_BB hBd hBge hxpos hxhiB hxge1
          hypos hyhiB hyge1 hρσ hKBF hKBr hKBBF hKBBr))
  refine Rle_trans (RexpReal_abs_lipschitz Rnonneg_one hMu hMv) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hAbsuv) ?_
  exact Rle_of_Req (Req_symm (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e) (Rabs (Rsub x y))))

end UOR.Bridge.F1Square.Analysis
