/-
F1 square — Track 1, item 6 substrate: **symmetric power-Lipschitz** `|x^e − y^e| ≤ 4·|e|·|x−y|` for a
**non-positive** exponent `e ≤ 0` on `[1,B]` (`RrpowAbsLip.lean`) — the actual Mellin integrand bound.

The theta–ζ Mellin transform `∫ t^{s/2−1}ψ(t) dt` has exponent `s/2−1 ∈ (−1,−1/2)` on the strip, i.e.
NEGATIVE. For `e ≤ 0` and `x ≥ 1`, `x^e ≤ 1` (`RrpowPos_le_one_of_nonpos`), so the segment bound in the
exp-Lipschitz is `M = 1` and the whole estimate collapses to the clean **rational** constant `4·|e|`:

    |x^e − y^e| = |exp(e·log x) − exp(e·log y)|
                ≤ 4·1·|e·log x − e·log y| = 4·|e|·|log x − log y| ≤ 4·|e|·|x − y|,

assembling `RexpReal_abs_lipschitz` (`M=1`) with `Rlog_abs_lipschitz` (`L=1`). No theta-decay argument is
needed — the negative exponent makes the power itself decreasing and bounded on `[1,∞)`. (Bounded-domain
`[1,B]`, `B ≤ ~5.8`, via the small-radius log bridge; the general-`B` extension is the `RadiusGen` port.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RexpAbsLip
import Core.F1.Analysis.RlogAbsLip
import Core.F1.Analysis.EtaVariation

namespace UOR.Bridge.F1Square.Analysis

/-- **`x^e ≤ 1`** for `x ≥ 1` and a non-positive exponent `e ≤ 0`: `e·log x ≤ 0` (`log x ≥ 0`), and
    `exp` of a non-positive real is `≤ 1`. -/
theorem RrpowPos_le_one_of_nonpos (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k))
    (hx1 : Rle one x) (e : Real) (he : Rle e zero) :
    Rle (RrpowPos x k hk e) one := by
  have hlogn : Rnonneg (RlogPos x k hk) := Rnonneg_RlogPos x k hk hx1
  have hprod : Rle (Rmul e (RlogPos x k hk)) zero :=
    Rle_trans (Rle_of_Req (Rmul_comm e (RlogPos x k hk)))
      (Rle_trans (Rmul_le_Rmul_left hlogn he) (Rle_of_Req (Rmul_zero (RlogPos x k hk))))
  have hnn : Rnonneg (Rneg (Rmul e (RlogPos x k hk))) :=
    Rnonneg_of_Rle_zero (Rle_trans (Rle_of_Req (Req_symm Rneg_zero)) (Rle_Rneg hprod))
  show Rle (RexpReal (Rmul e (RlogPos x k hk))) one
  exact Rle_trans
    (Rle_of_Req (RexpReal_congr (Req_symm (Rneg_neg (Rmul e (RlogPos x k hk))))))
    (RexpReal_neg_le_one (Rneg (Rmul e (RlogPos x k hk))) hnn)

/-- **Symmetric power-Lipschitz** `|x^e − y^e| ≤ 4·|e|·|x − y|` for `e ≤ 0`, `x, y ∈ [1, B]` (small
    radius `B²`). The Mellin integrand's base-Lipschitz with a clean rational constant `4·|e|`. -/
theorem RrpowPos_abs_lipschitz (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky)) (e : Real) (he : Rle e zero)
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
    Rle (Rabs (Rsub (RrpowPos x kx hx e) (RrpowPos y ky hy e)))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e)) (Rabs (Rsub x y))) := by
  have hx1 : Rle one x := Rle_one_of_seq_ge1 hxge1
  have hy1 : Rle one y := Rle_one_of_seq_ge1 hyge1
  have hMu : Rle (RrpowPos x kx hx e) one := RrpowPos_le_one_of_nonpos x kx hx hx1 e he
  have hMv : Rle (RrpowPos y ky hy e) one := RrpowPos_le_one_of_nonpos y ky hy hy1 e he
  -- |u − v| ≤ |e|·|x−y|, where u = e·log x, v = e·log y
  have hAbsuv : Rle (Rabs (Rsub (Rmul e (RlogPos x kx hx)) (Rmul e (RlogPos y ky hy))))
      (Rmul (Rabs e) (Rabs (Rsub x y))) :=
    Rle_trans (Rle_of_Req (Req_trans
        (Rabs_congr (Req_symm (Rmul_sub_distrib e (RlogPos x kx hx) (RlogPos y ky hy))))
        (Rabs_Rmul e (Rsub (RlogPos x kx hx) (RlogPos y ky hy)))))
      (Rmul_le_Rmul_left (Rnonneg_Rabs e)
        (Rlog_abs_lipschitz x y kx hx ky hy B hBd hBge hxpos hxhiB hxge1 hypos hyhiB hyge1
          hρ2 hσ2 hρσ hσhalf))
  -- exp-Lipschitz with M = 1, then drop ·1 and rearrange the constant
  refine Rle_trans (RexpReal_abs_lipschitz Rnonneg_one hMu hMv) ?_
  refine Rle_trans (Rle_of_Req (Rmul_one _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hAbsuv) ?_
  exact Rle_of_Req (Req_symm (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e) (Rabs (Rsub x y))))

end UOR.Bridge.F1Square.Analysis
