/-
F1 square — Track 1, item 6: **the total power integrand `gPowClamp` and its `∀x,y` Lipschitz**
(`RpowClampLip.lean`) — the culmination of the Mellin-integrand base-Lipschitz arc.

`gPowClamp e t := (max(t,1))^e` is a *total* `Real → Real` (the per-index clamp `qClampOne` supplies a
uniform positivity witness at index 1 via `ge1_pos_witness`). For `e ≤ 0` it is globally `4·|e|`-Lipschitz
with a clean rational constant:

    |gPowClamp e x − gPowClamp e y| ≤ 4·|e|·|qClampOne x − qClampOne y| ≤ 4·|e|·|x − y|,

composing `RrpowPos_abs_lipschitz_natB` (at the common integer bound `N = max(xBound x, xBound y)`, where
both clamps land in `[1,N]` via `canon_bound_le`) with `qClampOne_lipschitz`. This is exactly the
`∀x,y, |f x − f y| ≤ ofQ L · |x−y|` shape the integral layer (`improperIntegral1`/`halfLineIntegral`)
consumes, with `L = 4·|e|` — `ofQ`-valued once `|e|` is a rational (concrete `σ`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RrpowAbsLipNat
import Core.F1.Analysis.RQmaxClamp
import Core.F1.Analysis.RlogMulPos

namespace UOR.Bridge.F1Square.Analysis

/-- **The total clamped power** `gPowClamp e t = max(t,1)^e` — a total `Real → Real` (uniform witness at
    index 1 from `qClampOne_ge1`), equal to `t^e` on `[1,∞)` (`qClampOne_eq_of_ge`). Marked `irreducible`
    so downstream `whnf`/unification does not unfold the `RrpowPos ∘ qClampOne ∘ Qmax` cascade (which
    blows up when the exponent is a concrete `ofQ q`); proofs that need the `RrpowPos` form `unfold` it. -/
@[irreducible] def gPowClamp (e : Real) (t : Real) : Real :=
  RrpowPos (qClampOne t) 1 (ge1_pos_witness (qClampOne t) (qClampOne_ge1 t 1)) e

set_option maxHeartbeats 2000000 in
/-- **`gPowClamp e` is globally `4·|e|`-Lipschitz** for `e ≤ 0`: `|gPowClamp e x − gPowClamp e y| ≤
    4·|e|·|x−y|`, all `x, y`. The total Mellin-integrand base-bound. -/
theorem gPowClamp_lipschitz (e : Real) (he : Rle e zero) (x y : Real) :
    Rle (Rabs (Rsub (gPowClamp e x) (gPowClamp e y)))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e)) (Rabs (Rsub x y))) := by
  unfold gPowClamp
  have hN1 : 1 ≤ max (xBound x) (xBound y) := Nat.le_trans (xBound_pos x) (Nat.le_max_left _ _)
  have hB1 : Qle (⟨1, 1⟩ : Q) (⟨((max (xBound x) (xBound y) : Nat) : Int), 1⟩ : Q) := by
    have h := hN1; simp only [Qle]; push_cast; omega
  have hxle : ∀ n, Qle ((qClampOne x).seq n) (⟨((max (xBound x) (xBound y) : Nat) : Int), 1⟩ : Q) :=
    qClampOne_le hB1 (fun m => Qle_trans (Qabs_den_pos (x.den_pos m)) (Qle_self_Qabs (x.seq m))
      (canon_bound_le (Nat.le_max_left _ _) m))
  have hyle : ∀ n, Qle ((qClampOne y).seq n) (⟨((max (xBound x) (xBound y) : Nat) : Int), 1⟩ : Q) :=
    qClampOne_le hB1 (fun m => Qle_trans (Qabs_den_pos (y.den_pos m)) (Qle_self_Qabs (y.seq m))
      (canon_bound_le (Nat.le_max_right _ _) m))
  refine Rle_trans
    (RrpowPos_abs_lipschitz_natB (qClampOne x) (qClampOne y) 1
      (ge1_pos_witness (qClampOne x) (qClampOne_ge1 x 1)) 1
      (ge1_pos_witness (qClampOne y) (qClampOne_ge1 y 1)) e he
      (max (xBound x) (xBound y)) hN1
      (qClampOne_pos x) hxle (qClampOne_ge1 x) (qClampOne_pos y) hyle (qClampOne_ge1 y)) ?_
  exact Rmul_le_Rmul_left
    (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_Rabs e))
    (qClampOne_lipschitz x y)

/-- **`gPowClamp e` respects `≈`** — the integral's `hfc` hypothesis. From the Lipschitz bound: `x ≈ y`
    ⟹ `|x−y| ≈ 0` ⟹ `|gPowClamp e x − gPowClamp e y| ≤ 0`, and `≥ 0` (`Rnonneg_Rabs`), so the difference
    is `≈ 0`. -/
theorem gPowClamp_congr (e : Real) (he : Rle e zero) {x y : Real} (hxy : Req x y) :
    Req (gPowClamp e x) (gPowClamp e y) := by
  have hRHS0 : Req (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e)) (Rabs (Rsub x y))) zero := by
    refine Req_trans (Rmul_congr (Req_refl _) ?_) (Rmul_zero _)
    refine Req_trans (Rabs_congr ?_) Rabs_zero
    exact Req_trans (Rsub_congr (Req_refl x) (Req_symm hxy)) (Radd_neg x)
  have habsle : Rle (Rabs (Rsub (gPowClamp e x) (gPowClamp e y))) zero :=
    Rle_trans (gPowClamp_lipschitz e he x y) (Rle_of_Req hRHS0)
  have hle : Rle (Rsub (gPowClamp e x) (gPowClamp e y)) zero := Rle_of_Rabs_le habsle
  have hge : Rle zero (Rsub (gPowClamp e x) (gPowClamp e y)) :=
    Rle_trans (Rle_of_Req (Req_symm Rneg_zero)) (Rneg_le_of_Rabs_le habsle)
  exact Req_of_Rsub_zero_loc (Rle_antisymm hle hge)

end UOR.Bridge.F1Square.Analysis
