/-
F1 square — Track 1, item 0/3 substrate: **per-index bounds for the ratio `x/y`** (`RdivBounds.lean`).

The log-difference seam `log x − log y ≤ (x−y)/y` (the last analytic atom for `RrpowPos` Lipschitz,
`RrpowBounds.lean`) routes through the ratio `r = x/y = Rmul x (Rinv y)` and the (signed)
log-multiplicativity `log(y·r) = log y + log r`. That multiplicativity consumes per-index bounds on the
factor `r`. This file supplies them, reusing the `Rmul`/`Rinv` reindexing structure: `(Rmul x y).seq n`
multiplies *both* factors at the same `Ridx`, and `(Rinv y).seq m = Qinv (y.seq (RinvR y k m))`, so

    (Rdiv x y k hk).seq n = mul (x.seq J) (Qinv (y.seq (RinvR y k J))),  J = Ridx x (Rinv y k hk) n.

With `x, y ∈ [1, B]` pointwise, the ratio sits in `[1/B, B]` *even though* the two indices differ — the
bound only needs the `∀ n` envelope, not matching indices, which is exactly why the signed multiplicativity
(`Rlog_mul_signed`, accepting `[1/B, B]`) is the right consumer rather than the `≥ 1` `RlogPos_mul`.

The capstone `Rmul_y_Rdiv` (`y·(x/y) ≈ x`) is pure `Rmul` algebra over `Rmul_Rinv_self`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RealDiv
import Core.F1.Analysis.QOrder

namespace UOR.Bridge.F1Square.Analysis

/-- `a/b > 0` for `a` positive and `b` with positive denominator. -/
theorem Qdiv_num_pos {a b : Q} (ha : 0 < a.num) (hbd : 0 < b.den) :
    0 < (mul a (Qinv b)).num := by
  show 0 < a.num * (Qinv b).num
  exact Int.mul_pos ha (by show (0 : Int) < (b.den : Int); exact_mod_cast hbd)

/-- `Qinv b ≤ 1` for `b ≥ 1` (`b` positive). Antitonicity of `Qinv` at `1`, since `Qinv ⟨1,1⟩ = ⟨1,1⟩`. -/
theorem Qinv_le_one {b : Q} (hbn : 0 < b.num) (h1 : Qle (⟨1, 1⟩ : Q) b) :
    Qle (Qinv b) (⟨1, 1⟩ : Q) :=
  Qinv_antitone hbn (by decide) h1

/-- **`a/b ≤ B`** when `a ≤ B` and `b ≥ 1` (`a, b, B` positive): `a/b ≤ a·1 ≤ B`. -/
theorem Qdiv_le_B {a b B : Q} (had : 0 < a.den) (hBd : 0 < B.den) (hbn : 0 < b.num)
    (ha0 : 0 ≤ a.num) (haB : Qle a B) (hb1 : Qle (⟨1, 1⟩ : Q) b) :
    Qle (mul a (Qinv b)) B := by
  have hstep : Qle (mul a (Qinv b)) (mul B (⟨1, 1⟩ : Q)) :=
    Qmul_le_mul had hBd (Qinv_den_pos hbn) ha0 (Int.ofNat_nonneg _) haB (Qinv_le_one hbn hb1)
  refine Qle_trans (Qmul_den_pos hBd (by decide)) hstep (Qeq_le ?_)
  show B.num * 1 * (B.den : Int) = B.num * (B.den * 1 : Nat)
  push_cast; ring_uor

/-- **`1 ≤ (1/b)·B`** when `b ≤ B` (`b` positive): the reciprocal-side bound `B/b ≥ 1`. -/
theorem Qinv_mul_ge_one {b B : Q} (hbn : 0 < b.num) (hbB : Qle b B) :
    Qle (⟨1, 1⟩ : Q) (mul (Qinv b) B) := by
  have hbB' : b.num * (B.den : Int) ≤ B.num * (b.den : Int) := hbB
  have ht : (b.num.toNat : Int) = b.num := Int.toNat_of_nonneg (by omega)
  have ecomm : (b.den : Int) * B.num = B.num * (b.den : Int) := Int.mul_comm _ _
  show (1 : Int) * ((mul (Qinv b) B).den : Int) ≤ (mul (Qinv b) B).num * 1
  simp only [mul, Qinv]
  push_cast [ht]
  omega

/-- **`1 ≤ (a/b)·B`** when `a ≥ 1` and `b ≤ B` (`a, b, B` positive): `(a/b)·B ≥ (1/b)·B ≥ 1`. -/
theorem Qdiv_ge_invB {a b B : Q} (hbn : 0 < b.num) (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (ha1 : Qle (⟨1, 1⟩ : Q) a) (hbB : Qle b B) :
    Qle (⟨1, 1⟩ : Q) (mul (mul a (Qinv b)) B) := by
  -- `1/b ≤ a·(1/b)` since `a ≥ 1`
  have hpre : Qle (mul (⟨1, 1⟩ : Q) (Qinv b)) (mul a (Qinv b)) :=
    Qmul_le_mul_right (Int.ofNat_nonneg _) ha1
  have heq : Qeq (mul (⟨1, 1⟩ : Q) (Qinv b)) (Qinv b) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hstep : Qle (Qinv b) (mul a (Qinv b)) :=
    Qle_congr_left (by simp only [mul]; exact Nat.mul_pos Nat.one_pos (Qinv_den_pos hbn)) heq hpre
  have hmono : Qle (mul (Qinv b) B) (mul (mul a (Qinv b)) B) :=
    Qmul_le_mul_right hBn hstep
  exact Qle_trans (Qmul_den_pos (Qinv_den_pos hbn) hBd) (Qinv_mul_ge_one hbn hbB) hmono

/-! ### Per-index bounds on the ratio `Rdiv x y = Rmul x (Rinv y)`

`(Rdiv x y k hk).seq n = mul (x.seq J) (Qinv (y.seq (RinvR y k J)))` (both `Rmul` factors at the same
`Ridx`, `Rinv` reindexing inside), so each per-index bound is the matching `Q`-lemma at the envelope
hypotheses, indices supplied by unification. -/

/-- The ratio `x/y` is positive per index (`x` positive, `y` regular). -/
theorem Rdiv_seq_pos {x y : Real} {k : Nat} (hk : Qlt (Qbound k) (y.seq k))
    (hxpos : ∀ n, 0 < (x.seq n).num) :
    ∀ n, 0 < ((Rdiv x y k hk).seq n).num := fun _n =>
  Qdiv_num_pos (hxpos _) (y.den_pos _)

/-- The ratio `x/y ≤ B` per index, from `x ≤ B` and `y ≥ 1`. -/
theorem Rdiv_seq_le_B {x y : Real} {k : Nat} (hk : Qlt (Qbound k) (y.seq k)) {B : Q} (hBd : 0 < B.den)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n)) (hypos : ∀ n, 0 < (y.seq n).num) :
    ∀ n, Qle ((Rdiv x y k hk).seq n) B := fun _n =>
  Qdiv_le_B (x.den_pos _) hBd (hypos _) (Int.le_of_lt (hxpos _)) (hxhiB _) (hyge1 _)

/-- The ratio `x/y ≥ 1/B` per index (`(x/y)·B ≥ 1`), from `x ≥ 1` and `y ≤ B`. -/
theorem Rdiv_seq_ge_invB {x y : Real} {k : Nat} (hk : Qlt (Qbound k) (y.seq k)) {B : Q}
    (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hyhiB : ∀ n, Qle (y.seq n) B) (hypos : ∀ n, 0 < (y.seq n).num) :
    ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rdiv x y k hk).seq n) B) := fun _n =>
  Qdiv_ge_invB (hypos _) hBd hBn (hxge1 _) (hyhiB _)

/-- **`y·(x/y) ≈ x`** — pure `Rmul` algebra over `Rmul_Rinv_self`. Lets `RlogPos_congr`/`Rlog_mul_signed`
    rewrite `log x = log y + log(x/y)`, giving the log-difference identity the seam needs. -/
theorem Rmul_y_Rdiv {x y : Real} {k : Nat} (hk : Qlt (Qbound k) (y.seq k)) :
    Req (Rmul y (Rdiv x y k hk)) x := by
  show Req (Rmul y (Rmul x (Rinv y k hk))) x
  refine Req_trans (Rmul_comm y (Rmul x (Rinv y k hk)))
    (Req_trans (Rmul_assoc x (Rinv y k hk) y)
      (Req_trans (Rmul_congr (Req_refl x) (Rmul_comm (Rinv y k hk) y))
        (Req_trans (Rmul_congr (Req_refl x) (Rmul_Rinv_self hk)) (Rmul_one x))))

end UOR.Bridge.F1Square.Analysis
