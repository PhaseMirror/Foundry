/-
F1 square — Track 1, item 6 substrate: **symmetric exp-Lipschitz** `|exp u − exp v| ≤ 4·M·|u−v|`
(`RexpAbsLip.lean`), the exp-side mirror of `Rlog_abs_lipschitz` (`RlogAbsLip.lean`).

Same constructive-order-free technique: the directed `RexpReal_sub_le` (`RrpowBounds.lean`) needs no
ordering of `u, v`, so both directions

    exp u − exp v ≤ 4·max(u−v,0)·exp u ≤ 4·M·|u−v|
    exp v − exp u ≤ 4·max(v−u,0)·exp v ≤ 4·M·|u−v|

hold whenever `M` bounds `exp` on the relevant inputs, and `Rabs_le_of_both` assembles the symmetric
bound. The constant `4·M` is real (the segment bound `M`); for a concrete bounded exponent domain it is
bounded by a rational, the bridge the integral layer needs. `RmaxZero z ≤ |z|` (`RmaxZero_le_abs`) is the
shared symmetrizing step.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RrpowBounds
import Core.F1.Analysis.RabsLemmas

namespace UOR.Bridge.F1Square.Analysis

/-- `max(z, 0) ≤ |z|` — the symmetrizing step shared by the directed→absolute conversions. -/
theorem RmaxZero_le_abs (z : Real) : Rle (RmaxZero z) (Rabs z) :=
  RmaxZero_le_of_le_of_nonneg (Rle_Rabs_self z) (Rnonneg_Rabs z)

/-- **Symmetric exp-Lipschitz** `|exp u − exp v| ≤ 4·M·|u − v|` whenever `M ≥ 0` bounds `exp u` and
    `exp v`. Both directions from the unordered `RexpReal_sub_le`, joined by `Rabs_le_of_both`. -/
theorem RexpReal_abs_lipschitz {u v M : Real} (hMnn : Rnonneg M)
    (hMu : Rle (RexpReal u) M) (hMv : Rle (RexpReal v) M) :
    Rle (Rabs (Rsub (RexpReal u) (RexpReal v)))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rsub u v))) M) := by
  -- leg 1:  exp u − exp v ≤ 4·max(u−v,0)·exp u ≤ 4·|u−v|·M
  have leg1 : Rle (Rsub (RexpReal u) (RexpReal v))
      (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rsub u v))) M) :=
    Rle_trans (RexpReal_sub_le u v)
      (Rmul_le_Rmul_both
        (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_RmaxZero _)) hMnn
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (RmaxZero_le_abs (Rsub u v))) hMu)
  -- leg 2:  exp v − exp u ≤ 4·max(v−u,0)·exp v ≤ 4·|v−u|·M = 4·|u−v|·M
  have habs_swap : Req (Rabs (Rsub v u)) (Rabs (Rsub u v)) :=
    Req_trans (Rabs_congr (Req_symm (Rneg_Rsub u v))) (Rabs_Rneg (Rsub u v))
  have leg2 : Rle (Rsub (RexpReal v) (RexpReal u))
      (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rsub u v))) M) :=
    Rle_trans (RexpReal_sub_le v u)
      (Rmul_le_Rmul_both
        (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_RmaxZero _)) hMnn
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
          (Rle_trans (RmaxZero_le_abs (Rsub v u)) (Rle_of_Req habs_swap))) hMv)
  exact Rabs_le_of_both leg1
    (Rle_trans (Rle_of_Req (Rneg_Rsub (RexpReal u) (RexpReal v))) leg2)

end UOR.Bridge.F1Square.Analysis
