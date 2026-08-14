/-
F1 square — **certified integration, brick 71** (`IntervalPiece.lean`): **A HALF OF AN INTERVAL
LOWER-BOUNDS IT**, and interval integrals depend on their endpoints only through `Qeq`:

    `riemannIntegralI_congr_Q`   — `Qeq a a'`, `Qeq w w'` ⟹ the integrals agree
    `riemannIntegralI_ge_left_half` / `_ge_right_half`   — for `f ≥ 0`, each half is a lower bound.

Brick 69 said this for `[0,1]`; brick 70 supplied the general split; this is the general
consequence, and it is the induction *step* for descending to an arbitrary dyadic sub-interval.

The `Qeq` congruence is the piece that was quietly missing. Interval integrals are indexed by the
rational pair `(a, w)`, and a descent computes those endpoints — `a + 2q·w/2^{m+1}` on one route,
`a + q·w/2^m` on the other. Those are equal *rationals* but not equal *terms*, so without a `Qeq`
congruence an induction cannot connect its two sides at all. It follows from brick 70's
`riemannIntegral_congr_mod`: the pulled-back integrands agree pointwise because
`ofQ a + ofQ w·x ≈ ofQ a' + ofQ w'·x`, and the moduli `L·w`, `L·w'` are `Qeq`-equal.

HONEST SCOPE. The one-step bound and the endpoint congruence.
NOTE ON "the Lipschitz class on `[0,1]`". The hypothesis `hlip` quantifies over ALL reals, not
just `[0,1]`, so the class is the GLOBALLY Lipschitz functions — `x(1−x)` as a bare function is
not in it, and callers supply a clamped representative (`clampTest`). This is the standing
convention of the `riemannIntegral` gateway and of `L2Test`, inherited rather than introduced
here, but the shorter phrase reads as a weaker requirement than the statement imposes.
 The descent to a depth-`m` dyadic
sub-interval is the induction these support and is **not** performed here. Integration substrate;
nothing here touches the Weil form. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.IntervalSplit

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- **Interval integrals see their endpoints only through `Qeq`.** -/
theorem riemannIntegralI_congr_Q {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w a' w' : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (ha' : 0 < a'.den) (hw' : 0 < w'.den) (hwn' : 0 ≤ w'.num)
    (hqa : Qeq a a') (hqw : Qeq w w') :
    Req (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)
        (riemannIntegralI hLd hLn hlip hfc a' w' ha' hw' hwn') := by
  refine Rmul_congr (ofQ_congr hw hw' hqw) ?_
  refine riemannIntegral_congr_mod _ _ _ _ _ _ _ _
    (Qeq_le (Qmul_congr (Qeq_refl L) hqw)) (fun x => hfc _ _ ?_)
  show Req (Radd (ofQ a ha) (Rmul (ofQ w hw) x)) (Radd (ofQ a' ha') (Rmul (ofQ w' hw') x))
  exact Radd_congr (ofQ_congr ha ha' hqa) (Rmul_congr (ofQ_congr hw hw' hqw) (Req_refl x))

set_option maxHeartbeats 1000000 in
/-- **The left half of an interval lower-bounds it**, for a non-negative integrand. -/
theorem riemannIntegralI_ge_left_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Rle (riemannIntegralI hLd hLn hlip hfc a (halfQ w) ha (halfQ_den hw) (halfQ_num hwn))
        (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm
    (riemannIntegralI_split_half hLd hLn hlip hfc a w ha hw hwn)))
  exact Rle_self_Radd_right (riemannIntegralI_nonneg hLd hLn hlip hfc hfnn
    (add a (halfQ w)) (halfQ w) (add_den_pos ha (halfQ_den hw)) (halfQ_den hw) (halfQ_num hwn))

set_option maxHeartbeats 1000000 in
/-- **The right half of an interval lower-bounds it**, for a non-negative integrand. -/
theorem riemannIntegralI_ge_right_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Rle (riemannIntegralI hLd hLn hlip hfc (add a (halfQ w)) (halfQ w)
          (add_den_pos ha (halfQ_den hw)) (halfQ_den hw) (halfQ_num hwn))
        (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm
    (riemannIntegralI_split_half hLd hLn hlip hfc a w ha hw hwn)))
  exact Rle_self_Radd_left (riemannIntegralI_nonneg hLd hLn hlip hfc hfnn
    a (halfQ w) ha (halfQ_den hw) (halfQ_num hwn))

end Multiplicity.UOR.Bridge.F1Square.Square
