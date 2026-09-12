/-
F1 square — **the pre-Hilbert layer, brick 96** (`ContinuousMomentExp.lean`): **the compact power is
Lipschitz in the exponent** — `|compactPow a s x − compactPow a s' x| ≤ 4·|s − s'|·log(base)`, the
pointwise continuity in `s` that makes the continuous Mellin parameter (brick 93) a genuinely
*continuous* one, not merely a parametrized family.

At a fixed point `x` the compact power is `compactPow a s x = exp(−s·L_x)` where `L_x =
log(max(1/max(x,a),1))` is the log of the clamped reciprocal base (`compactBaseLog`, `≥ 0` since the
base is `≥ 1`). The `s`-difference is
`|exp(−s·L_x) − exp(−s'·L_x)| ≤ 4·|(−s·L_x) − (−s'·L_x)|·1 = 4·|s − s'|·L_x`, via the symmetric
exp-Lipschitz `RexpReal_abs_lipschitz` (`RexpAbsLip.lean`) with the bound `1` (each exponent `−s·L_x ≤
0`, so `exp ≤ 1`), then distributivity `(−s − (−s'))·L_x` and `|L_x| = L_x`. So `s ↦ compactPow a s x`
is `4·L_x`-Lipschitz at every `x`.

HONEST SCOPE. Pointwise continuity in the exponent, with the `x`-dependent constant `4·L_x`. The
UNIFORM (in `x`) constant — needed to carry continuity to the moment `compactMoment φ a s` by
integration — requires bounding `L_x ≤ log(1/a)` for all `x`, which needs the per-index `[1, 1/a]`-band
presentation of the clamped reciprocal (`RlogPos_le_sub_one`) and is NOT established here. No
transform pair, no inversion, no positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMoment
import Foundations.F1.Analysis.RexpAbsLip

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The clamped reciprocal base-log** `L_x = log(max(1/max(x,a), 1))` — the log of the base the
    compact power exponentiates. `≥ 0` (the base is `≥ 1`). This is the `s`-Lipschitz constant factor. -/
def compactBaseLog (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x : Real) : Real :=
  RlogPos (qClampOne (clampedInv a han had x)) 1
    (ge1_pos_witness (qClampOne (clampedInv a han had x)) (qClampOne_ge1 (clampedInv a han had x) 1))

/-- `L_x ≥ 0` — the base `max(1/max(x,a),1) ≥ 1`, so its log is non-negative. -/
theorem compactBaseLog_nonneg (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x : Real) :
    Rnonneg (compactBaseLog a han had x) :=
  Rnonneg_RlogPos _ _ _ (Rle_one_of_seq_ge1 (qClampOne_ge1 (clampedInv a han had x)))

set_option maxHeartbeats 1200000 in
/-- **The compact power is `4·L_x`-Lipschitz in the exponent** at every point `x`:
    `|compactPow a s x − compactPow a s' x| ≤ 4·|s − s'|·L_x` for `s, s' ≥ 0`. Via the exp-Lipschitz
    `RexpReal_abs_lipschitz` (bound `1`, since each exponent `−s·L_x ≤ 0`) and the distributive collapse
    `(−s·L_x) − (−s'·L_x) = (s' − s)·L_x`. -/
theorem compactPow_exp_lipschitz (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s s' : Real}
    (hs : Rnonneg s) (hs' : Rnonneg s') (x : Real) :
    Rle (Rabs (Rsub (compactPow a han had s x) (compactPow a han had s' x)))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rsub s s'))) (compactBaseLog a han had x)) := by
  have hL_nn : Rnonneg (compactBaseLog a han had x) := compactBaseLog_nonneg a han had x
  -- compactPow a s x = exp(−s·L)  (unfolding the irreducible gPowClamp)
  have key : ∀ σ : Real,
      Req (compactPow a han had σ x) (RexpReal (Rmul (Rneg σ) (compactBaseLog a han had x))) := by
    intro σ; unfold compactPow gPowClamp RrpowPos compactBaseLog; exact Req_refl _
  -- exp of a non-positive real is ≤ 1
  have hexp_le : ∀ σ : Real, Rnonneg σ →
      Rle (RexpReal (Rmul (Rneg σ) (compactBaseLog a han had x))) one := fun σ hσ =>
    Rle_trans (Rle_of_Req (RexpReal_congr (Rmul_neg_left σ (compactBaseLog a han had x))))
      (RexpReal_neg_le_one (Rmul σ (compactBaseLog a han had x)) (Rnonneg_Rmul hσ hL_nn))
  -- |(−s·L) − (−s'·L)| = |s − s'|·L
  have hAbsUV : Req (Rabs (Rsub (Rmul (Rneg s) (compactBaseLog a han had x))
        (Rmul (Rneg s') (compactBaseLog a han had x))))
      (Rmul (Rabs (Rsub s s')) (compactBaseLog a han had x)) := by
    have hswap : Req (Rsub (Rneg s) (Rneg s')) (Rsub s' s) :=
      Req_trans (Radd_congr (Req_refl (Rneg s)) (Rneg_neg s')) (Radd_comm (Rneg s) s')
    have hsub_abs : Req (Rabs (Rsub (Rneg s) (Rneg s'))) (Rabs (Rsub s s')) :=
      Req_trans (Rabs_congr hswap)
        (Req_trans (Rabs_congr (Req_symm (Rneg_Rsub s s'))) (Rabs_Rneg (Rsub s s')))
    refine Req_trans (Rabs_congr (Req_symm
      (Rmul_sub_distrib_right (Rneg s) (Rneg s') (compactBaseLog a han had x)))) ?_
    exact Req_trans (Rabs_Rmul _ _) (Rmul_congr hsub_abs (Rabs_of_nonneg hL_nn))
  -- assemble
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (key s) (key s')))) ?_
  refine Rle_trans (RexpReal_abs_lipschitz Rnonneg_one (hexp_le s hs) (hexp_le s' hs')) ?_
  refine Rle_of_Req (Req_trans (Rmul_one _) ?_)
  exact Req_trans (Rmul_congr (Req_refl _) hAbsUV) (Req_symm (Rmul_assoc _ _ _))

end Multiplicity.UOR.Bridge.F1Square.Square
