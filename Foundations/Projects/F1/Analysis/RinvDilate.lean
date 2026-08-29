/-
F1 square — **the pointwise dilation-covariance of the reciprocal** (`RinvDilate.lean`):

    `s · (1 / (s·y))  ≈  1 / y`     (for `s·y` and `y` positive, via their inverse witnesses)

— the algebraic reason the multiplicative Haar measure `dx/x` is dilation-invariant. Under the
substitution `y = s·x`, the Jacobian factor `s` from `dy = s·dx` exactly cancels the `1/s` from
`1/(s·x)`, leaving the density `1/x` unchanged. This lemma is that cancellation at the point level,
proved from the inverse law `x·(1/x) = 1` (`Rmul_Rinv_self`) by uniqueness of the multiplicative
inverse: both `s·(1/(s·y))` and `1/y` are the inverse of `y`.

HONEST SCOPE. The pointwise density identity only. The integral-level Haar invariance
`∫ φ dx/x = ∫ φ(a·x) dx/x` that assembles this (through the certified change of variables
`riemannIntegralI_dilate` carried across the clamped reciprocal on the window) is the next brick;
it is not here. Not the convolution, not the Mellin theorem. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.RealDiv

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The pointwise dilation-covariance of the reciprocal** `s · (1/(s·y)) ≈ 1/y`. Both sides are the
    multiplicative inverse of `y`: `y · (s·(1/(s·y))) = (s·y)·(1/(s·y)) = 1 = y·(1/y)`, so they agree
    by uniqueness of the inverse. The inverse witnesses `hk` (for `s·y`) and `hky` (for `y`) carry the
    positivity; a witness for `s·y` can only exist when `s > 0`. -/
theorem Rmul_ofQ_Rinv_Rmul {s : Q} (hs : 0 < s.den) {y : Real} {ky : Nat}
    (hky : Qlt (Qbound ky) (y.seq ky)) {k : Nat}
    (hk : Qlt (Qbound k) ((Rmul (ofQ s hs) y).seq k)) :
    Req (Rmul (ofQ s hs) (Rinv (Rmul (ofQ s hs) y) k hk)) (Rinv y ky hky) := by
  -- y · (s·(1/(s·y))) = (s·y)·(1/(s·y)) = 1.
  have hprod : Req (Rmul y (Rmul (ofQ s hs) (Rinv (Rmul (ofQ s hs) y) k hk))) one := by
    refine Req_trans (Req_symm (Rmul_assoc y (ofQ s hs) (Rinv (Rmul (ofQ s hs) y) k hk))) ?_
    refine Req_trans (Rmul_congr (Rmul_comm y (ofQ s hs)) (Req_refl _)) ?_
    exact Rmul_Rinv_self hk
  -- 1/y = (1/y)·1 = (1/y)·(y·(s·(1/(s·y)))) = ((1/y)·y)·(s·(1/(s·y))) = 1·(…) = s·(1/(s·y)).
  refine Req_symm ?_
  refine Req_trans (Req_symm (Rmul_one (Rinv y ky hky))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Req_symm hprod)) ?_
  refine Req_trans (Req_symm (Rmul_assoc (Rinv y ky hky) y
    (Rmul (ofQ s hs) (Rinv (Rmul (ofQ s hs) y) k hk)))) ?_
  refine Req_trans (Rmul_congr
    (Req_trans (Rmul_comm (Rinv y ky hky) y) (Rmul_Rinv_self hky)) (Req_refl _)) ?_
  exact Req_trans (Rmul_comm one _) (Rmul_one _)

end Multiplicity.UOR.Bridge.F1Square.Analysis
