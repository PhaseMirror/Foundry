/-
F1 square — **the Haar density's dilation-covariance on the window** (`HaarDensity.lean`): the
per-point fact the integral-level Haar invariance consumes.

    `s · clampedInv_{a'}(s·y)  ≈  clampedInv_a(y)`     for `y ≥ a` and `s·y ≥ a'`

— on the window (where both clamped reciprocals are inert, `= 1/·`), the dilated density
`s·(1/(s·y))` collapses to `1/y` by the pointwise reciprocal cancellation `Rmul_ofQ_Rinv_Rmul`. The
positivity witnesses for `y` and `s·y` come from their rational lower bounds (`Pos_of_Rle_ofQ`), so no
witness data is threaded from the caller.

HONEST SCOPE. The pointwise density identity on the window only — the ingredient of Haar invariance
`∫ φ dx/x = ∫ φ(a·x) dx/x`, assembled next through the certified change of variables. Not the
convolution, not the Mellin theorem. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.RinvDilate
import Foundations.F1.Analysis.ClampedInv
import Foundations.F1.Analysis.Pi

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The Haar density's dilation-covariance on the window**: where `y ≥ a` and `s·y ≥ a'` (so both
    clamped reciprocals are inert), `s · clampedInv_{a'}(s·y) ≈ clampedInv_a(y)`. Both clamps drop to
    genuine reciprocals (`clampedInv_eq_of_ge`), the `s·(1/(s·y)) = 1/y` cancellation
    (`Rmul_ofQ_Rinv_Rmul`) closes it, and the inverse witnesses come from the lower bounds
    (`Pos_of_Rle_ofQ`). -/
theorem clampedInv_dilate_on (s a a' : Q) (hsd : 0 < s.den)
    (an : 0 < a.num) (ad : 0 < a.den) (a'n : 0 < a'.num) (a'd : 0 < a'.den)
    {y : Real} (hay : Rle (ofQ a ad) y) (ha'sy : Rle (ofQ a' a'd) (Rmul (ofQ s hsd) y)) :
    Req (Rmul (ofQ s hsd) (clampedInv a' a'n a'd (Rmul (ofQ s hsd) y)))
        (clampedInv a an ad y) := by
  obtain ⟨ky, hky⟩ := Pos_of_Rle_ofQ an ad hay
  obtain ⟨ksy, hksy⟩ := Pos_of_Rle_ofQ a'n a'd ha'sy
  refine Req_trans (Rmul_congr (Req_refl (ofQ s hsd)) (clampedInv_eq_of_ge hksy ha'sy)) ?_
  exact Req_trans (Rmul_ofQ_Rinv_Rmul hsd hky hksy) (Req_symm (clampedInv_eq_of_ge hky hay))

end Multiplicity.UOR.Bridge.F1Square.Analysis
