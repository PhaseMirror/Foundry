/-
F1 square — **monotonicity of the real exponential** `RexpReal`: `x ≤ y ⟹ eˣ ≤ eʸ`.

The `RexpReal` substrate (`ExpReal.lean`) carries the value `e⁰ = 1`, additivity `e^{x+y} = eˣ·eʸ`
(`RexpReal_add`), non-negativity (`RexpReal_nonneg`), and the one-sided bound `e^X ≥ 1` for `X ≥ 0`
(`RexpReal_ge_one`), but not the order-preservation lemma itself. It follows cleanly from those:
`eʸ = eˣ·e^{y−x} ≥ eˣ·1 = eˣ`, since `y − x ≥ 0` makes `e^{y−x} ≥ 1` and `eˣ ≥ 0`.

This is a broadly reusable real-analysis primitive (every `RexpReal` estimate — dominated-convergence
tail bounds, the archimedean `e^{−d}` decays — wants it); it is the order half of the `RexpReal` API.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RealPow
import Core.F1.Analysis.ExpRealAdd

namespace UOR.Bridge.F1Square.Analysis

/-- **`RexpReal` is monotone**: `x ≤ y ⟹ eˣ ≤ eʸ`. Proof: `eʸ = eˣ·e^{y−x}` (`RexpReal_add` on
    `y ≈ x + (y−x)`), and `e^{y−x} ≥ 1` (`RexpReal_ge_one`, since `y − x ≥ 0`) with `eˣ ≥ 0`
    (`RexpReal_nonneg`) gives `eˣ = eˣ·1 ≤ eˣ·e^{y−x} = eʸ`. -/
theorem RexpReal_le_of_le {x y : Real} (h : Rle x y) :
    Rle (RexpReal x) (RexpReal y) := by
  -- `y − x ≥ 0`
  have hd : Rnonneg (Rsub y x) := Rnonneg_Rsub_of_Rle h
  -- `x + (y − x) ≈ y`
  have hxy : Req (Radd x (Rsub y x)) y :=
    Req_trans (Radd_congr (Req_refl x) (Radd_comm y (Rneg x)))
      (Req_trans (Req_symm (Radd_assoc x (Rneg x) y))
        (Req_trans (Radd_congr (Radd_neg x) (Req_refl y))
          (Req_trans (Radd_comm zero y) (Radd_zero y))))
  -- `eʸ ≈ eˣ · e^{y−x}`
  have hsplit : Req (RexpReal y) (Rmul (RexpReal x) (RexpReal (Rsub y x))) :=
    Req_trans (RexpReal_congr (Req_symm hxy)) (RexpReal_add x (Rsub y x))
  -- `eˣ = eˣ·1 ≤ eˣ·e^{y−x}`
  have hge : Rle (RexpReal x) (Rmul (RexpReal x) (RexpReal (Rsub y x))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_one (RexpReal x))))
      (Rmul_le_Rmul_left (RexpReal_nonneg x) (RexpReal_ge_one hd))
  exact Rle_trans hge (Rle_of_Req (Req_symm hsplit))

end UOR.Bridge.F1Square.Analysis
