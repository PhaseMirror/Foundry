/-
F1 square — **the pre-Hilbert layer** (`RationalWindowDilate.lean`): **the degree-`n`
HOMOGENEITY of the rational-window power `powBandGen` on its band** — the `hHom` hypothesis
`mellinWindowDilate` needs, generalized from the `[0,1]`-clamped `powTest` (whose discharge is
`powTest_dilate_on`) to the wide-band `powBandGen`.

On a band `[lo, hi]` containing BOTH a window and its `s`-scaling, the weight is un-clamped
(`= tⁿ`), so homogeneity holds — unlike the narrow integer-window `powWinTest` whose clamp
breaks homogeneity on a rescaled window. The proof mirrors `powTest_dilate_on` exactly, with
the band-inertness `powBandGen_eq_Rpow_on` playing the role of clamp-inertness.

HONEST SCOPE. The degree-`n` homogeneity of the rational-window power `powBandGen` on its band
— on a band containing both a point and its `s`-scaling, `powBandGen(s·y) = sⁿ·powBandGen(y)`
(`powBandGen_dilate_on`), via the band-inertness `powBandGen_eq_Rpow_on` and `Rpow_dilate_ofQ`;
the `hHom` discharge `mellinWindowDilate` consumes, generalized from `powTest_dilate_on`. It
builds NO integral, NO dilation covariance, NO factorization, NO positivity, NO determinacy, NO
crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.RationalWindowPower
import Multiplicity.F1Square.Square.MellinWindowDilate

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The rational-window power is `Rpow` on its band**: for `lo ≤ x ≤ hi`,
    `(powBandGen … n) x ≈ xⁿ`. The band is un-clamped, so the iterated product IS the raw power.
    Proof by induction: base `≡ 1 = x⁰`; step chains `powBandGen_succ_inert` (`≈ (prev)·x`),
    the IH (`prev ≈ xⁿ`), and `Rmul_comm` to land on `Rpow x (n+1) = x·xⁿ`. -/
theorem powBandGen_eq_Rpow_on (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den)
    (hle : Qle lo hi) (hlon : 0 ≤ lo.num) (n : Nat) {x : Real}
    (hlo : Rle (ofQ lo hlod) x) (hhi : Rle x (ofQ hi hhid)) :
    Req ((powBandGen lo hi hlod hhid hle hlon n).f x) (Rpow x n) := by
  induction n with
  | zero => exact Req_refl one
  | succ n ih =>
    refine Req_trans (powBandGen_succ_inert lo hi hlod hhid hle hlon n hlo hhi) ?_
    refine Req_trans (Rmul_congr ih (Req_refl x)) ?_
    exact Rmul_comm (Rpow x n) x

/-- **The degree-`n` homogeneity of `powBandGen` on its band** — the `hHom` discharge for the
    rational window: with both a point `y` and its scaling `s·y` inside `[lo, hi]`,
    `(powBandGen … n)(s·y) = sⁿ·(powBandGen … n)(y)`. The band is inert at both points
    (`powBandGen_eq_Rpow_on`), so the window value is the raw `Rpow`, and `Rpow_dilate_ofQ`
    supplies the homogeneity. Mirrors `powTest_dilate_on`, generalized to the wide band. -/
theorem powBandGen_dilate_on (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den)
    (hle : Qle lo hi) (hlon : 0 ≤ lo.num) (n : Nat) (s : Q) (hsd : 0 < s.den) {y : Real}
    (hy_lo : Rle (ofQ lo hlod) y) (hy_hi : Rle y (ofQ hi hhid))
    (hsy_lo : Rle (ofQ lo hlod) (Rmul (ofQ s hsd) y))
    (hsy_hi : Rle (Rmul (ofQ s hsd) y) (ofQ hi hhid)) :
    Req ((powBandGen lo hi hlod hhid hle hlon n).f (Rmul (ofQ s hsd) y))
        (Rmul (ofQ (qpow s n) (qpow_den_pos hsd n))
          ((powBandGen lo hi hlod hhid hle hlon n).f y)) := by
  have hpow_y : Req (Rpow y n) ((powBandGen lo hi hlod hhid hle hlon n).f y) :=
    Req_symm (powBandGen_eq_Rpow_on lo hi hlod hhid hle hlon n hy_lo hy_hi)
  refine Req_trans
    (powBandGen_eq_Rpow_on lo hi hlod hhid hle hlon n hsy_lo hsy_hi) ?_
  refine Req_trans (Rpow_dilate_ofQ s hsd y n) ?_
  exact Rmul_congr (Req_refl (ofQ (qpow s n) (qpow_den_pos hsd n))) hpow_y

end Multiplicity.UOR.Bridge.F1Square.Square
