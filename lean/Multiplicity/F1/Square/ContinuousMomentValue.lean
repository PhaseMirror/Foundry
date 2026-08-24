/-
F1 square — **the pre-Hilbert layer, brick 100** (`ContinuousMomentValue.lean`): **the compact power
IS `q^s` at rational sample points** — `compactPow a s (q) ≈ exp(−s·(log q_den − log q_num))`, the genuine
`t^s` identification the doc flagged as needing `log(1/t) = −log t`, delivered at the rational points the
certified integral actually samples, WITHOUT that lemma.

The trick: for a GENERAL real `t` the log machinery is blocked (no per-index band bounds), but an `ofQ`
constant has a CONSTANT sequence, so the per-index bounds are trivial. At `q ≥ a` the compact power drops
to `gPowClamp(−s)(1/q)` (brick 97), and on the clean rational base `1/q = ⟨q_den, q_num⟩ ∈ [1,4]` (i.e.
`q ∈ [1/4, 1]`) the reciprocal-clamp is inert (`gPowClamp_ofQ_eq`, via `RlogPos_congr_gen` at `B = 4`)
and `RlogPos(1/q)` evaluates to `logN q_den − logN q_num` (`rrpowPos_ofQ_eq`, off `RlogPos_ofQ_eq_logN`).
Composing: `compactPow a s (q) ≈ exp(−s·(log q_den − log q_num)) = exp(s·(log q_num − log q_den)) = q^s`.

Also `rlogPos_one` (`log 1 = 0`, off `RlogPos_ofQ_eq_logN 1 1`) — the foundational log value.

This is the FIRST genuine `t^s` identification on the totalized compact power: it pins `compactPow` to the
honest power `q^s` at every rational point in `[max(a,1/4), 1]` — exactly the partition points `i/(N+1)`
the Riemann integral evaluates.

HONEST SCOPE. The identification holds at RATIONAL points `q ∈ [max(a,1/4), 1]` (the `[1,4]`-radius of
`RlogPos_ofQ_eq_logN` bounds `q ≥ 1/4`; the general real-`t` identification on `[a,1]` still needs the
per-index band presentation the log layer lacks). This does not by itself give `compactMoment φ a n ≈
mellinMoment φ n` (that needs the identification at ALL sample points plus the `a→0` limit). No transform
pair, no inversion, no positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentFloor
import Multiplicity.F1.Analysis.LogRatBridge
import Multiplicity.F1.Analysis.RadiusGen

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`log 1 = 0`** — via `RlogPos_ofQ_eq_logN 1 1` (`log(1/1) = logN 1 − logN 1`) and `Rsub_self`. -/
theorem rlogPos_one (k : Nat) (hk : Qlt (Qbound k) (one.seq k)) : Req (RlogPos one k hk) zero :=
  Req_trans (RlogPos_ofQ_eq_logN 1 1 (by omega) (by omega) (by omega) k hk)
    (Radd_neg (logN 1 (by omega)))

/-- **The real power at a rational base** `⟨A,D⟩ ∈ [1,4]`: `x^e = exp(e·(logN A − logN D))` —
    `RrpowPos` unfolds to `exp(e·log x)`, and `RlogPos_ofQ_eq_logN` evaluates `log⟨A,D⟩ = logN A − logN D`. -/
theorem rrpowPos_ofQ_eq (A D : Nat) (hd : 0 < D) (hda : D ≤ A) (ha4 : A ≤ 4 * D)
    (k : Nat) (hk : Qlt (Qbound k) ((ofQ (⟨(A : Int), D⟩ : Q) hd).seq k)) (e : Real) :
    Req (RrpowPos (ofQ (⟨(A : Int), D⟩ : Q) hd) k hk e)
        (RexpReal (Rmul e (Rsub (logN A (Nat.le_trans hd hda)) (logN D hd)))) := by
  unfold RrpowPos
  exact RexpReal_congr (Rmul_congr (Req_refl e) (RlogPos_ofQ_eq_logN A D hd hda ha4 k hk))

/-- **The reciprocal-clamp is inert on a clean rational base** `⟨A,D⟩ ∈ [1,4]`:
    `gPowClamp e (⟨A,D⟩) ≈ RrpowPos (⟨A,D⟩) e`. The `qClampOne` inside `gPowClamp` is `≈`-equal to the
    base (it is `≥ 1`), lifted through the log by `RlogPos_congr_gen` at `B = 4` — the constant sequence
    makes every per-index band hypothesis trivial. -/
theorem gPowClamp_ofQ_eq (A D : Nat) (hd : 0 < D) (hda : D ≤ A) (ha4 : A ≤ 4 * D) (e : Real)
    (k : Nat) (hk : Qlt (Qbound k) ((ofQ (⟨(A : Int), D⟩ : Q) hd).seq k)) :
    Req (gPowClamp e (ofQ (⟨(A : Int), D⟩ : Q) hd))
        (RrpowPos (ofQ (⟨(A : Int), D⟩ : Q) hd) k hk e) := by
  have hv4 : Qle (⟨(A : Int), D⟩ : Q) (⟨4, 1⟩ : Q) := by show (A : Int) * 1 ≤ 4 * (D : Int); omega
  have hv1 : Qle (⟨1, 1⟩ : Q) (⟨(A : Int), D⟩ : Q) := by show (1 : Int) * (D : Int) ≤ (A : Int) * 1; omega
  have hvpos : (0 : Int) < (A : Int) := by have : 1 ≤ A := Nat.le_trans hd hda; exact_mod_cast this
  have hvlo : Qle (⟨1, 1⟩ : Q) (mul (⟨(A : Int), D⟩ : Q) (⟨4, 1⟩ : Q)) := by
    show (1 : Int) * (mul (⟨(A : Int), D⟩ : Q) (⟨4, 1⟩ : Q)).den
        ≤ (mul (⟨(A : Int), D⟩ : Q) (⟨4, 1⟩ : Q)).num * 1
    simp only [mul]; push_cast; omega
  unfold gPowClamp RrpowPos
  refine RexpReal_congr (Rmul_congr (Req_refl e) ?_)
  refine RlogPos_congr_gen (qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)) (ofQ (⟨(A : Int), D⟩ : Q) hd)
    1 (ge1_pos_witness (qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd))
        (qClampOne_ge1 (ofQ (⟨(A : Int), D⟩ : Q) hd) 1)) k hk
    (⟨4, 1⟩ : Q) 2 (by decide) (by decide)
    (qClampOne_pos _) (qClampOne_le (by decide) (fun _ => hv4)) (fun n => ?_)
    (fun _ => hvpos) (fun _ => hv4) (fun _ => hvlo)
    (by decide) (by decide)
    (qClampOne_eq_of_ge (Rle_one_of_seq_ge1 (fun _ => hv1)))
  · have h1 : Qle (⟨1, 1⟩ : Q) ((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n) := qClampOne_ge1 _ n
    have hd2 := (qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).den_pos n
    show Qle (⟨1, 1⟩ : Q) (mul ((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n) (⟨4, 1⟩ : Q))
    simp only [Qle, mul] at h1 ⊢; push_cast at h1 ⊢; omega

/-- **★ THE `t^s` IDENTIFICATION AT RATIONAL POINTS**: `compactPow a s (q) ≈ exp(−s·(log q_den − log q_num))`
    `= q^s`, for every rational `q ∈ [max(a, 1/4), 1]`. The totalized compact power (brick 93) IS the
    honest power at the partition points the certified integral samples. Chains brick 97 (drop the floor),
    `gPowClamp_ofQ_eq` (drop the clamp), and `rrpowPos_ofQ_eq` (evaluate the log). -/
theorem compactPow_ofQ_pow (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    (q : Q) (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q)
    (hq1 : Qle q (⟨1, 1⟩ : Q)) (hq4 : Qle (⟨1, 4⟩ : Q) q) :
    Req (compactPow a han had s (ofQ q hqd))
        (RexpReal (Rmul (Rneg s)
          (Rsub (logN q.den hqd)
                (logN q.num.toNat (by
                  have hc : (q.num.toNat : Int) = q.num := Int.toNat_of_nonneg (Int.le_of_lt hqn)
                  omega))))) := by
  have hcast : (q.num.toNat : Int) = q.num := Int.toNat_of_nonneg (Int.le_of_lt hqn)
  have hDpos : 0 < q.num.toNat := by omega
  have hDA : q.num.toNat ≤ q.den := by
    have h : q.num * 1 ≤ 1 * (q.den : Int) := by have := hq1; simp only [Qle] at this; exact this
    omega
  have hA4D : q.den ≤ 4 * q.num.toNat := by
    have h : (1 : Int) * (q.den : Int) ≤ q.num * 4 := by have := hq4; simp only [Qle] at this; exact this
    omega
  have hpow := compactPow_ofQ a han had hs hqd hqn haq
  refine Req_trans hpow ?_
  refine Req_trans (gPowClamp_ofQ_eq q.den q.num.toNat hDpos hDA hA4D (Rneg s)
    (2 * (Qinv q).den)
    (Qbound_lt_pos (by show (0 : Int) < (q.den : Int); exact_mod_cast hqd) (Qinv_den_pos hqn))) ?_
  exact rrpowPos_ofQ_eq q.den q.num.toNat hDpos hDA hA4D _ _ (Rneg s)

end Multiplicity.UOR.Bridge.F1Square.Square
