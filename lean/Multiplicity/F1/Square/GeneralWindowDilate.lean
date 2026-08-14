/-
F1 square — **the general-window rational-scale Mellin dilation at the twist weight**
(`GeneralWindowDilate.lean`): the committed per-window rational-scale Mellin dilation
(`mellinWindowDilate`) INSTANTIATED at the twist weight `powBandGen`, on an ARBITRARY rational window
`[lo, lo+w]` (`lo, w` rationals, `0 ≤ lo`, `0 < w`), with the weight taken over a WIDE band
`[bandLo, bandHi]` that covers both the window and its `s`-scaling `[s·lo, s·(lo+w)]`.

This GENERALIZES the committed `window_dilate_powBandGen` (which fixed the integer window
`lo = m+1`, `w = 1`) to the arbitrary rational window that `dilMellinF` — the roadmap factorization
consumer (`MellinConvGPull.lean`) — integrates over. It is the rational base of the real-scale
factorization gate.

The only real content is DISCHARGING the `hHom` hypothesis of `mellinWindowDilate` — the degree-`n`
homogeneity of the weight on the window under the scale `s` — using the committed
`powBandGen_dilate_on`. Its four membership facts are supplied by the affine/scaling algebra: with
`y = affineMap lo w x = lo + w·x` for `0 ≤ x ≤ 1`, both `y ∈ [lo, lo+w] ⊆ [bandLo, bandHi]` and
`s·y ∈ [s·lo, s·(lo+w)] ⊆ [bandLo, bandHi]`, chained from the band-containment hypotheses
`hc1`–`hc4` through `Rle_ofQ_ofQ`, `Rmul_ofQ_ofQ`, the `Rmul`/`Radd` monotonicities,
`Rle_self_Radd_right`, and `Rmul_one`.

The resulting integral identity is exactly `mellinWindowDilate`'s conclusion at `P = powBandGen`
and the arbitrary window `[lo, lo+w]`:

    `∫_{s·lo}^{s·(lo+w)} (f · powBandGen) = s^(n+1) · ∫_lo^{lo+w} (dilate_s f · powBandGen)`.

HONEST SCOPE. The general-window rational-scale Mellin dilation covariance — for an arbitrary
rational window `[lo, lo+w]` and rational scale `s`,
`∫_{[s·lo, s·(lo+w)]}(f·powBandGen) = s^(n+1)·∫_{[lo, lo+w]}(dilate_s f·powBandGen)`, via the committed
`mellinWindowDilate` + `powBandGen_dilate_on` generalized from the fixed integer window `[m+1, m+2]`
to the arbitrary window `dilMellinF` integrates over. It builds NO real-scale extension, NO
factorization, NO half-line assembly, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.RationalWindowDilate
import Multiplicity.F1Square.Analysis.CosSinBound
import Multiplicity.F1Square.Analysis.Pi

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The general-window rational-scale Mellin dilation at the twist weight `powBandGen`.** On an
    arbitrary rational window `[lo, lo+w]`, with the weight `powBandGen bandLo bandHi … n` taken over a
    band `[bandLo, bandHi]` containing both the window (`hc1`, `hc2`) and its `s`-scaling (`hc3`,
    `hc4`),

      `∫_{s·lo}^{s·(lo+w)} (f · powBandGen) = s^(n+1) · ∫_lo^{lo+w} (dilate_s f · powBandGen)`.

    This is `mellinWindowDilate` applied at `P = powBandGen … n` and the arbitrary window `[lo, lo+w]`;
    the only new content is the `hHom` discharge via `powBandGen_dilate_on` together with the four
    membership facts of the affine window point `y = affineMap lo w x` and its scaling `s·y`. It
    generalizes the committed `window_dilate_powBandGen` from the fixed integer window `[m+1, m+2]`. -/
theorem general_window_dilate
    (f : L2Test) (n : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    (lo w : Q) (hlod : 0 < lo.den) (hwd : 0 < w.den) (hlon : 0 ≤ lo.num) (hwn : 0 ≤ w.num)
    (bandLo bandHi : Q) (hbLod : 0 < bandLo.den) (hbHid : 0 < bandHi.den)
    (hbLe : Qle bandLo bandHi) (hbLon : 0 ≤ bandLo.num)
    (hc1 : Qle bandLo lo)
    (hc2 : Qle (add lo w) bandHi)
    (hc3 : Qle bandLo (mul s lo))
    (hc4 : Qle (mul s (add lo w)) bandHi) :
    Req (riemannIntegralI
          (L2Test.mul f (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hLd
          (L2Test.mul f (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hLn
          (L2Test.mul f (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hlip
          (L2Test.mul f (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hfc
          (mul s lo) (mul s w)
          (Qmul_den_pos hsd hlod) (Qmul_den_pos hsd hwd)
          (Int.mul_nonneg (Int.le_of_lt hsn) hwn))
        (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
          (riemannIntegralI
            (L2Test.mul (dilateTest s hsn hsd f)
              (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hLd
            (L2Test.mul (dilateTest s hsn hsd f)
              (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hLn
            (L2Test.mul (dilateTest s hsn hsd f)
              (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hlip
            (L2Test.mul (dilateTest s hsn hsd f)
              (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n)).hfc
            lo w hlod hwd hwn)) := by
  have hsnn : Rnonneg (ofQ s hsd) := Rnonneg_ofQ hsd (Int.le_of_lt hsn)
  have hwnn : Rnonneg (ofQ w hwd) := Rnonneg_ofQ hwd hwn
  -- Apply the committed per-window dilation; the residual goal is exactly `hHom`.
  refine mellinWindowDilate f (powBandGen bandLo bandHi hbLod hbHid hbLe hbLon n) n s hsn hsd
    lo w hlod hwd hwn ?_
  intro x h0 h1
  -- The affine window point `y = lo + w·x` and its endpoints (in `Radd`/`Rmul` form, defeq to
  -- `affineMap lo w x`).
  -- lo ≤ y : the offset `w·x` is non-negative.
  have hy_base :
      Rle (ofQ lo hlod)
        (Radd (ofQ lo hlod) (Rmul (ofQ w hwd) x)) :=
    Rle_self_Radd_right (Rnonneg_Rmul hwnn (Rnonneg_of_Rle_zero h0))
  -- w·x ≤ w : from `x ≤ 1`.
  have hxle1 : Rle (Rmul (ofQ w hwd) x) (ofQ w hwd) :=
    Rle_trans (Rmul_le_Rmul_left hwnn h1)
      (Rle_of_Req (Rmul_one (ofQ w hwd)))
  -- y ≤ lo+w : add the offset bound to the base.
  have boundB :
      Rle (Radd (ofQ lo hlod) (Rmul (ofQ w hwd) x))
        (ofQ (add lo w) (add_den_pos hlod hwd)) :=
    Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle1)
      (Rle_of_Req (Radd_ofQ_ofQ hlod hwd))
  -- The four membership facts consumed by `powBandGen_dilate_on`.
  have hy_lo :
      Rle (ofQ bandLo hbLod)
        (Radd (ofQ lo hlod) (Rmul (ofQ w hwd) x)) :=
    Rle_trans (Rle_ofQ_ofQ hbLod hlod hc1) hy_base
  have hy_hi :
      Rle (Radd (ofQ lo hlod) (Rmul (ofQ w hwd) x))
        (ofQ bandHi hbHid) :=
    Rle_trans boundB (Rle_ofQ_ofQ (add_den_pos hlod hwd) hbHid hc2)
  have hsy_lo :
      Rle (ofQ bandLo hbLod)
        (Rmul (ofQ s hsd)
          (Radd (ofQ lo hlod) (Rmul (ofQ w hwd) x))) :=
    Rle_trans (Rle_ofQ_ofQ hbLod (Qmul_den_pos hsd hlod) hc3)
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hsd hlod)))
        (Rmul_le_Rmul_left hsnn hy_base))
  have hsy_hi :
      Rle (Rmul (ofQ s hsd)
            (Radd (ofQ lo hlod) (Rmul (ofQ w hwd) x)))
          (ofQ bandHi hbHid) :=
    Rle_trans (Rmul_le_Rmul_left hsnn boundB)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hsd (add_den_pos hlod hwd)))
        (Rle_ofQ_ofQ (Qmul_den_pos hsd (add_den_pos hlod hwd)) hbHid hc4))
  exact powBandGen_dilate_on bandLo bandHi hbLod hbHid hbLe hbLon n s hsd
    hy_lo hy_hi hsy_lo hsy_hi

end Multiplicity.UOR.Bridge.F1Square.Square
