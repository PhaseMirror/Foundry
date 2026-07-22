/-
F1 square — Track 1, item 0/3 substrate: **the log-difference bound** `log x − log y ≤ x/y − 1`
(`LogDiffBound.lean`) — the analytic atom that discharges the `RrpowPos`-Lipschitz seam
(`RrpowPos_lip_of_log`, `RrpowBounds.lean`).

The route is the multiplicative identity `log x = log(y · (x/y)) = log y + log(x/y)`, so
`log x − log y = log(x/y) ≤ (x/y) − 1` (the general-real convexity bound `Rlog_le_sub_one_real`). The
two pieces in place:
* `Rmul_y_Rdiv` (`RdivBounds.lean`): `y·(x/y) ≈ x`, plus the ratio's per-index `[1/B, B]` envelope.
* `Rlog_mul_signed` (`RlogMulSigned.lean`): log-multiplicativity over `[1/B, B]` — the *signed* variant,
  not `RlogPos_mul`, precisely because `(x/y).seq n` can dip below `1` (the two reindexed points differ).

Bridging `RlogPos ↔ Rlog` (`RlogPos_eq_Rlog`), presenting `x` at radius `B²` (where `y·(x/y)` lands) and
`y` at `B`, gives `RlogPos x − RlogPos y ≈ Rlog(x/y) ≤ Rdiv x y − 1`. The companion `Rle_one_Rdiv`
(`x ≥ y ⟹ x/y ≥ 1`) supplies `Rnonneg (Rdiv x y − 1)`, so the pair feeds `RrpowPos_lip_of_log` directly.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RdivBounds
import Core.F1.Analysis.RlogMulSigned
import Core.F1.Analysis.RlogMulPos
import Core.F1.Analysis.RartanhBounds
import Core.F1.Analysis.RrpowBounds

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 2000000

/-- `Rsub (Radd A C) A ≈ C` — left-summand cancellation. -/
theorem Rsub_Radd_cancel_left (A C : Real) : Req (Rsub (Radd A C) A) C :=
  Req_trans (Radd_congr (Radd_comm A C) (Req_refl (Rneg A)))
    (Req_trans (Radd_assoc C A (Rneg A))
      (Req_trans (Radd_congr (Req_refl C) (Radd_neg A)) (Radd_zero C)))

/-- `1 ≤ p·q` from `1 ≤ p` and `1 ≤ q` (`p, q` with positive denominators). -/
theorem Qone_le_mul {p q : Q} (hp : Qle (⟨1, 1⟩ : Q) p) (hq : Qle (⟨1, 1⟩ : Q) q)
    (hpd : 0 < p.den) (_hqd : 0 < q.den) : Qle (⟨1, 1⟩ : Q) (mul p q) := by
  refine Qle_trans (by decide) (Qeq_le (show Qeq (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) by decide))
    (Qmul_le_mul (by decide) hpd (by decide) (by decide) (by decide) hp hq)

/-- `1 ≤ (a·c)·B²` from `1 ≤ a`, `1 ≤ c·B`, `1 ≤ B` — the lower bound for a product `Rmul y (x/y)` at
    radius `B²`, regrouped as `a·(c·B)·B`. -/
theorem Qprod_lo {a c B : Q} (ha1 : Qle (⟨1, 1⟩ : Q) a) (hcB : Qle (⟨1, 1⟩ : Q) (mul c B))
    (hB1 : Qle (⟨1, 1⟩ : Q) B) (had : 0 < a.den) (hcd : 0 < c.den) (hBd : 0 < B.den) :
    Qle (⟨1, 1⟩ : Q) (mul (mul a c) (mul B B)) := by
  have h1 : Qle (⟨1, 1⟩ : Q) (mul a (mul c B)) := Qone_le_mul ha1 hcB had (Qmul_den_pos hcd hBd)
  have h2 : Qle (⟨1, 1⟩ : Q) (mul (mul a (mul c B)) B) :=
    Qone_le_mul h1 hB1 (Qmul_den_pos had (Qmul_den_pos hcd hBd)) hBd
  refine Qle_congr_right (Qmul_den_pos (Qmul_den_pos had (Qmul_den_pos hcd hBd)) hBd) ?_ h2
  show (mul (mul a (mul c B)) B).num * ((mul (mul a c) (mul B B)).den : Int)
      = (mul (mul a c) (mul B B)).num * ((mul (mul a (mul c B)) B).den : Int)
  simp only [mul]; push_cast; ring_uor

/-- `B ≤ B²` for `B ≥ 1`. -/
theorem QB_le_B2 {B : Q} (hB1 : Qle (⟨1, 1⟩ : Q) B) (hBd : 0 < B.den) : Qle B (mul B B) := by
  have hBnn : (0 : Int) ≤ B.num := by have := hB1; simp only [Qle] at this; push_cast at this; omega
  have hab : Qle (mul (⟨1, 1⟩ : Q) B) (mul B B) := Qmul_le_mul_right hBnn hB1
  exact Qle_congr_left (by show 0 < 1 * B.den; exact Nat.mul_pos Nat.one_pos hBd)
    (by simp only [Qeq, mul]; push_cast; ring_uor) hab

/-! ### Per-index bounds on a product `Rmul a b` -/

/-- A product of positive sequences is positive per index. -/
theorem Rmul_seq_pos {a b : Real} (ha : ∀ n, 0 < (a.seq n).num) (hb : ∀ n, 0 < (b.seq n).num) :
    ∀ n, 0 < ((Rmul a b).seq n).num := fun _n =>
  Int.mul_pos (ha _) (hb _)

/-- A product is `≤ A·B` per index, from envelope bounds `a ≤ A`, `b ≤ B` (`a, b` non-negative). -/
theorem Rmul_seq_le {a b : Real} {A B : Q} (hAd : 0 < A.den)
    (ha0 : ∀ n, 0 ≤ (a.seq n).num) (hA : ∀ n, Qle (a.seq n) A)
    (hb0 : ∀ n, 0 ≤ (b.seq n).num) (hB : ∀ n, Qle (b.seq n) B) :
    ∀ n, Qle ((Rmul a b).seq n) (mul A B) := fun _n =>
  Qmul_le_mul (a.den_pos _) hAd (b.den_pos _) (ha0 _) (hb0 _) (hA _) (hB _)

/-- **`x/y ≥ 1`** when `x ≥ y` (`y` positive): cancel the positive factor `1/y` in `y·(x/y) ≈ x ≥ y`. -/
theorem Rle_one_Rdiv {x y : Real} {ky : Nat} (hy : Qlt (Qbound ky) (y.seq ky)) (hyx : Rle y x) :
    Rle one (Rdiv x y ky hy) := by
  show Rle one (Rmul x (Rinv y ky hy))
  exact Rle_trans (Rle_of_Req (Req_symm (Rmul_Rinv_self hy)))
    (Rmul_le_Rmul_right (Rnonneg_Rinv y ky hy) hyx)

/-- **The log-difference bound** `log x − log y ≤ (x/y) − 1` for `x, y ∈ [1, B]` (small radius `B²`).
    The seam atom for `RrpowPos` Lipschitz: `D = Rdiv x y − 1` then feeds `RrpowPos_lip_of_log`. -/
theorem RlogPos_sub_le_Rdiv (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
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
  -- bridges  RlogPos → Rlog
  have ex : Req (RlogPos x kx hx) (Rlog x (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2) :=
    RlogPos_eq_Rlog x kx hx (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2 hσ2
  have ey : Req (RlogPos y ky hy) (Rlog y B hBd hBge hypos hyhiB hyloB) :=
    RlogPos_eq_Rlog y ky hy B hBd hBge hypos hyhiB hyloB hρ2
  -- multiplicativity:  log y + log r ≈ log(y·r)
  have emul : Req (Radd (Rlog y B hBd hBge hypos hyhiB hyloB)
        (Rlog (Rdiv x y ky hy) B hBd hBge hrpos hrhi hrlo))
      (Rlog (Rmul y (Rdiv x y ky hy)) (mul B B) hB2d hB2ge hmpos hmhi hmlo) :=
    Rlog_mul_signed y (Rdiv x y ky hy) B hBd hBge hypos hyhiB hyloB hrpos hrhi hrlo
      hB2d hB2ge hmpos hmhi hmlo hρ2 hρσ hσhalf
  -- congruence:  log(y·r) ≈ log x   (since y·r ≈ x)
  have econg : Req (Rlog (Rmul y (Rdiv x y ky hy)) (mul B B) hB2d hB2ge hmpos hmhi hmlo)
      (Rlog x (mul B B) hB2d hB2ge hxpos hxhiB2 hxloB2) :=
    Rlog_congr (Rmul y (Rdiv x y ky hy)) x (mul B B) hB2d hB2ge hmpos hmhi hmlo
      hxpos hxhiB2 hxloB2 hσ2 (Rmul_y_Rdiv hy)
  -- assemble:  log x − log y ≈ log r ≤ r − 1
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

/-- **`RrpowPos` Lipschitz, seam discharged** — `xᵉ − yᵉ ≤ 4·(e·(x/y − 1))·xᵉ` for `x ≥ y`, both in
    `[1,B]`, `e ≥ 0`. The seam `RrpowPos_lip_of_log` is now closed by `RlogPos_sub_le_Rdiv` (the
    log-difference bound) and `Rle_one_Rdiv` (`x/y ≥ 1`, so the bound `D = Rdiv x y − 1 ≥ 0`). The base
    Lipschitz modulus for the general `t^{σ−1}` Mellin integrand: as `y → x`, `x/y − 1 → 0`. -/
theorem RrpowPos_lipschitz (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky)) (hyx : Rle y x) (e : Real) (he : Rnonneg e)
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
    Rle (Rsub (RrpowPos x kx hx e) (RrpowPos y ky hy e))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul e (Rsub (Rdiv x y ky hy) one)))
          (RrpowPos x kx hx e)) :=
  RrpowPos_lip_of_log x kx hx y ky hy e he (Rsub (Rdiv x y ky hy) one)
    (Rnonneg_Rsub_of_Rle (Rle_one_Rdiv hy hyx))
    (RlogPos_sub_le_Rdiv x y kx hx ky hy B hBd hBge hxpos hxhiB hxge1 hypos hyhiB hyge1
      hρ2 hσ2 hρσ hσhalf)

end UOR.Bridge.F1Square.Analysis
