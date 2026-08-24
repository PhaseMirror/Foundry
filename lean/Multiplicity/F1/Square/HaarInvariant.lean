/-
F1 square — **Haar invariance of the multiplicative-measure integral** (`HaarInvariant.lean`): the
capstone of transform-bridge Wall 1.

    `∫_{s·lo}^{s·(lo+w)} φ(y) dy/y  ≈  ∫_lo^{lo+w} φ(s·x) dx/x`     (rational scale `s > 0`)

— the defining property of the multiplicative Haar measure `dx/x`: dilating the test equals scaling
the window, with the integral VALUE preserved. In the repo's objects this reads
`haarIntegral φ [s·lo, s·w]  ≈  haarIntegral (dilateTest s φ) [lo, w]` (floors `a ≤ lo`, `a' ≤ s·lo`
so both clamped reciprocals are inert on their windows).

The proof composes the Wall-1 substrate: the linear change of variables `riemannIntegralI_dilate`
(substituting `y = s·x`, producing the Jacobian factor `s`), value-linearity `riemannIntegralI_smul`
(pulling `s` inside the integral), the window-congruence `riemannIntegralI_congr_unit`, and the
pointwise density cancellation `clampedInv_dilate_on` (`s·(1/(s·x)) = 1/x`, which absorbs the `s`).
The differing Lipschitz moduli are reconciled at a common weakened modulus through `lip_mono` and
`riemannIntegralI_certif_irrel`.

HONEST SCOPE. Haar invariance on bounded windows bounded away from `0`, for a bounded-Lipschitz test.
This is Wall 1 of the transform bridge — the invariance of the `dx/x` measure. It is NOT the
multiplicative convolution `⋆`, and NOT the Mellin convolution theorem; those (Walls 2–3) are what
would make `weilPrimeGram (vFrom g)` the genuine autocorrelation Gram, i.e. step 4 = RH. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.HaarInterval
import Multiplicity.F1.Analysis.DilateIntegral
import Multiplicity.F1.Analysis.IntervalCert
import Multiplicity.F1.Analysis.HaarDensity
import Multiplicity.F1.Square.MultShift
import Multiplicity.F1.Square.MellinLinear

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Value-scaling is Lipschitz**: `x ↦ s·f(x)` is `(s·L)`-Lipschitz when `f` is `L`-Lipschitz and
    `s ≥ 0` — `|s·f(x) − s·f(y)| = s·|f(x) − f(y)| ≤ (s·L)·|x−y|`. -/
private theorem Rmul_ofQ_lip {f : Real → Real} {L : Q} (hLd : 0 < L.den)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (s : Q) (hsd : 0 < s.den) (hsn : 0 ≤ s.num) : ∀ x y,
    Rle (Rabs (Rsub (Rmul (ofQ s hsd) (f x)) (Rmul (ofQ s hsd) (f y))))
        (Rmul (ofQ (mul s L) (Qmul_den_pos hsd hLd)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req
    (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ s hsd) (f x) (f y))))
      (Req_trans (Rabs_Rmul (ofQ s hsd) (Rsub (f x) (f y)))
        (Rmul_congr (Rabs_ofQ_nonneg hsd hsn) (Req_refl _))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hsd hsn) (hlip x y)) (Rle_of_Req ?_)
  exact Req_trans (Req_symm (Rmul_assoc (ofQ s hsd) (ofQ L hLd) (Rabs (Rsub x y))))
    (Rmul_congr (Rmul_ofQ_ofQ hsd hLd) (Req_refl _))

/-- **Haar invariance on the window**: `haarIntegral φ [s·lo, s·w] ≈ haarIntegral (dilateTest s φ)
    [lo, w]` — the multiplicative Haar measure `dx/x` is dilation-invariant. Floors `a ≤ lo` (base)
    and `a' ≤ s·lo` (scaled) keep both clamped reciprocals inert on their windows; the change of
    variables `y = s·x` carries the integral across, and the density cancellation `s·(1/(s·x)) = 1/x`
    (`clampedInv_dilate_on`) removes the Jacobian, leaving the value unchanged. -/
theorem haarIntegral_dilate (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    (a a' : Q) (an : 0 < a.num) (ad : 0 < a.den) (a'n : 0 < a'.num) (a'd : 0 < a'.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (haLo : Rle (ofQ a ad) (ofQ lo hlo))
    (ha'sLo : Rle (ofQ a' a'd) (ofQ (mul s lo) (Qmul_den_pos hsd hlo))) :
    Req (haarIntegral φ a' a'n a'd (mul s lo) (mul s w)
          (Qmul_den_pos hsd hlo) (Qmul_den_pos hsd hw) (Int.mul_nonneg (Int.le_of_lt hsn) hwn))
        (haarIntegral (dilateTest s hsn hsd φ) a an ad lo w hlo hw hwn) := by
  -- Natural moduli: D' (dilated φ·recipTest a') at Ld = (l2L φ ρ')·s; G ((dilateTest s φ)·recipTest a)
  -- at LG; s·D' at sLd = s·Ld; common Lc = Ld + (sLd + LG).
  have hD'ld := dilate_lip (l2L_den φ (recipTest a' a'n a'd)) (l2L_num φ (recipTest a' a'n a'd))
    (l2lip φ (recipTest a' a'n a'd)) s hsd (Int.le_of_lt hsn)
  have hD'fc := dilate_fc (l2fc φ (recipTest a' a'n a'd)) s hsd
  have hSDld := Rmul_ofQ_lip (Qmul_den_pos (l2L_den φ (recipTest a' a'n a'd)) hsd) hD'ld s hsd
    (Int.le_of_lt hsn)
  have hGlg := l2lip (dilateTest s hsn hsd φ) (recipTest a an ad)
  have hGfc := l2fc (dilateTest s hsn hsd φ) (recipTest a an ad)
  -- Num/den nonnegativity of the common modulus.
  have Ldn : (0 : Int) ≤ (mul (l2L φ (recipTest a' a'n a'd)) s).num :=
    Int.mul_nonneg (l2L_num φ (recipTest a' a'n a'd)) (Int.le_of_lt hsn)
  have sLdn : (0 : Int) ≤ (mul s (mul (l2L φ (recipTest a' a'n a'd)) s)).num :=
    Int.mul_nonneg (Int.le_of_lt hsn) Ldn
  have LGn := l2L_num (dilateTest s hsn hsd φ) (recipTest a an ad)
  have Ldd : 0 < (mul (l2L φ (recipTest a' a'n a'd)) s).den :=
    Qmul_den_pos (l2L_den φ (recipTest a' a'n a'd)) hsd
  have sLdd : 0 < (mul s (mul (l2L φ (recipTest a' a'n a'd)) s)).den := Qmul_den_pos hsd Ldd
  have LGd := l2L_den (dilateTest s hsn hsd φ) (recipTest a an ad)
  have Lcn : (0 : Int) ≤ (add (mul (l2L φ (recipTest a' a'n a'd)) s)
      (add (mul s (mul (l2L φ (recipTest a' a'n a'd)) s))
        (l2L (dilateTest s hsn hsd φ) (recipTest a an ad)))).num :=
    Qadd_num_nonneg_loc Ldn (Qadd_num_nonneg_loc sLdn LGn)
  have Lcd : 0 < (add (mul (l2L φ (recipTest a' a'n a'd)) s)
      (add (mul s (mul (l2L φ (recipTest a' a'n a'd)) s))
        (l2L (dilateTest s hsn hsd φ) (recipTest a an ad)))).den :=
    add_den_pos Ldd (add_den_pos sLdd LGd)
  -- Weaken the three integrands to the common modulus Lc.
  have hD'lc := fun x y => lip_mono Ldd Lcd (Qle_self_add (Qadd_num_nonneg_loc sLdn LGn))
    (Rnonneg_Rabs (Rsub x y)) (hD'ld x y)
  have hSDlc := fun x y => lip_mono sLdd Lcd
    (Qle_trans (add_den_pos sLdd LGd) (Qle_self_add LGn) (Qle_add_self Ldn))
    (Rnonneg_Rabs (Rsub x y)) (hSDld x y)
  have hGlc := fun x y => lip_mono LGd Lcd
    (Qle_trans (add_den_pos sLdd LGd) (Qle_add_self sLdn) (Qle_add_self Ldn))
    (Rnonneg_Rabs (Rsub x y)) (hGlg x y)
  have hSDfc := fun x y (h : Req x y) => Rmul_congr (Req_refl (ofQ s hsd)) (hD'fc x y h)
  -- The window pointwise identity: s·D'(y) ≈ G(y) on [lo, lo+w].
  have hfg : ∀ x, Rle zero x → Rle x one →
      Req (Rmul (ofQ s hsd) (Rmul (φ.f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))
            (clampedInv a' a'n a'd (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))))
          (Rmul (φ.f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))
            (clampedInv a an ad (affineMap lo w hlo hw x))) := by
    intro x h0 _h1
    have hy0 : Rnonneg (Rmul (ofQ w hw) x) :=
      Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0)
    have hlo_le_y : Rle (ofQ lo hlo) (affineMap lo w hlo hw x) := Rle_self_Radd_right hy0
    have hay : Rle (ofQ a ad) (affineMap lo w hlo hw x) := Rle_trans haLo hlo_le_y
    have ha'sy : Rle (ofQ a' a'd) (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)) :=
      Rle_trans ha'sLo (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hsd hlo)))
        (Rmul_le_Rmul_left (Rnonneg_ofQ hsd (Int.le_of_lt hsn)) hlo_le_y))
    refine Req_trans
      (Req_trans (Req_symm (Rmul_assoc (ofQ s hsd)
          (φ.f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))
          (clampedInv a' a'n a'd (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))))
        (Req_trans (Rmul_congr (Rmul_comm (ofQ s hsd)
            (φ.f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x)))) (Req_refl _))
          (Rmul_assoc (φ.f (Rmul (ofQ s hsd) (affineMap lo w hlo hw x))) (ofQ s hsd)
            (clampedInv a' a'n a'd (Rmul (ofQ s hsd) (affineMap lo w hlo hw x))))))
      (Rmul_congr (Req_refl _) (clampedInv_dilate_on s a a' hsd an ad a'n a'd hay ha'sy))
  -- Assemble: dilate (y = s·x) → align D' to Lc → pull s inside (smul) → window-congr with the
  -- density identity → align G back to its native modulus.
  refine Req_trans (riemannIntegralI_dilate (l2L_den φ (recipTest a' a'n a'd))
    (l2L_num φ (recipTest a' a'n a'd)) (l2lip φ (recipTest a' a'n a'd))
    (l2fc φ (recipTest a' a'n a'd)) s lo w hsd (Int.le_of_lt hsn) hlo hw hwn) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ s hsd))
    (riemannIntegralI_certif_irrel Ldd Ldn hD'ld hD'fc Lcd Lcn hD'lc hD'fc lo w hlo hw hwn)) ?_
  refine Req_trans (Req_symm (riemannIntegralI_smul s hsd Lcd Lcn hD'lc hD'fc hSDlc hSDfc
    lo w hlo hw hwn)) ?_
  refine Req_trans (riemannIntegralI_congr_unit Lcd Lcn hSDlc hSDfc hGlc hGfc lo w hlo hw hwn hfg) ?_
  exact riemannIntegralI_certif_irrel Lcd Lcn hGlc hGfc LGd LGn hGlg hGfc lo w hlo hw hwn

end Multiplicity.UOR.Bridge.F1Square.Square
