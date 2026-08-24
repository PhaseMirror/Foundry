/-
F1 square — **the pre-Hilbert layer, brick 102** (`ContinuousMomentOne.lean`): **the compact power at
exponent `1` is the identity at rational points** — `compactPow a 1 (q) ≈ q` for every rational
`q ∈ (a,1]`, the `t^1 = t` specialization completing the endpoint picture alongside brick 95's
`t^0 = 1`.

The engine is `Rexp_logN_sub`: `exp(logN A − logN D) ≈ A/D` for all `A, D ≥ 1` — `exp` turns the
log-difference into the rational quotient, via `RexpReal_add`, `Rexp_logN` (`exp(logN n) = n`), and
`RexpReal_neg_eq_recip` (`exp(−logN D) = 1/D`). This is the rational-value reader for the
`compactPow_ofQ_pow_all` (brick 101) closed form: at `s = 1` the exponent `−1·(log q_den − log q_num)`
collapses to `log q_num − log q_den`, and `Rexp_logN_sub` reads it off as `q_num/q_den = q`.

HONEST SCOPE. The `s = 1` value at rational points of `(a,1]`; `Rexp_logN_sub` is the reusable
exp-of-log-ratio reader the integer-`n` agreement and the moment identification will consume. No
transform pair, no inversion, no positivity, no `a → 0` limit yet. Step 4 is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentValueAll

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`exp(logN A − logN D) ≈ A/D`** for all `A, D ≥ 1` — the exp-of-log-ratio reader. `exp` splits the
    difference (`RexpReal_add`), `exp(logN A) = A` (`Rexp_logN`), `exp(−logN D) = 1/D`
    (`RexpReal_neg_eq_recip`), and the product `A·(1/D) = A/D`. No radius restriction. -/
theorem Rexp_logN_sub (A D : Nat) (hA : 1 ≤ A) (hD : 1 ≤ D) :
    Req (RexpReal (Rsub (logN A hA) (logN D hD))) (ofQ (⟨(A : Int), D⟩ : Q) hD) := by
  have hDp : 0 < D := by omega
  refine Req_trans (RexpReal_add (logN A hA) (Rneg (logN D hD))) ?_
  refine Req_trans (Rmul_congr (Rexp_logN A hA) (RexpReal_neg_eq_recip D hDp (Rexp_logN D hD))) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos hDp) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (mul (⟨(A : Int), 1⟩ : Q) (⟨1, D⟩ : Q)) (⟨(A : Int), D⟩ : Q)
    show ((A : Int) * 1) * (D : Int) = (A : Int) * ((1 * D : Nat) : Int); push_cast; ring_uor)

/-- **`compactPow a 1 (q) ≈ q`** at every rational `q ∈ (a,1]` — the `t^1 = t` specialization. At
    `s = 1` the brick-101 closed form `exp(−1·(log q_den − log q_num))` collapses to
    `exp(log q_num − log q_den) = q_num/q_den = q` (`Rexp_logN_sub`). -/
theorem compactPow_ofQ_one (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (q : Q) (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q) (hq1 : Qle q (⟨1, 1⟩ : Q)) :
    Req (compactPow a han had one (ofQ q hqd)) (ofQ q hqd) := by
  have hc : (q.num.toNat : Int) = q.num := Int.toNat_of_nonneg (Int.le_of_lt hqn)
  have hNpos : 1 ≤ q.num.toNat := by omega
  have hpow := compactPow_ofQ_pow_all a han had Rnonneg_one q hqd hqn haq hq1
  refine Req_trans hpow ?_
  have he : Req (Rmul (Rneg one) (Rsub (logN q.den hqd) (logN q.num.toNat hNpos)))
      (Rsub (logN q.num.toNat hNpos) (logN q.den hqd)) :=
    Req_trans (Rmul_neg_left one _)
      (Req_trans (Rneg_congr (Rone_mul _)) (Rneg_Rsub (logN q.den hqd) (logN q.num.toNat hNpos)))
  refine Req_trans (RexpReal_congr he) ?_
  refine Req_trans (Rexp_logN_sub q.num.toNat q.den hNpos hqd) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (⟨(q.num.toNat : Int), q.den⟩ : Q) q
    show (q.num.toNat : Int) * (q.den : Int) = q.num * (q.den : Int); rw [hc])

end Multiplicity.UOR.Bridge.F1Square.Square
