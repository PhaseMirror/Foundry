/-
F1 square — **the per-window twisted dilation covariance** (`TwTermDilateWindow.lean`): the two
committed halves composed into a single per-window identity relating the scaled-window integral of
`φ` to the `mellinHat` tail term of the dilated test.

`window_dilate_powBandGen` gives the per-window rational-scale Mellin dilation at the wide-band twist
weight, and `twTerm_eq_window_powBandGen` swaps that wide-band weight for the integer-window
`powWinTest` used by `twTerm`. Composing them:

    `∫_{s·(m+1)}^{s·(m+2)} (φ · powBandGen)  =  s^(n+1) · twTerm (dilate_s φ) n m`.

This is the per-window twisted dilation covariance: the `m`-th window integral of the ORIGINAL `φ`
against the genuine power, over the `s`-scaled window `[s(m+1), s(m+2)]`, equals `s^(n+1)` times the
`m`-th `mellinHat` tail term of the dilated test `dilate_s φ`. Summing over `m` (a later reschedule
brick) is what turns the dilated Mellin tail into the original one.

HONEST SCOPE. The per-window twisted dilation covariance: the scaled-window integral of `φ` against
`powBandGen` equals `s^(n+1)` times the tail term `twTerm (dilate_s φ) n m`, composing the committed
`window_dilate_powBandGen` and `twTerm_eq_window_powBandGen`. It builds NO half-line assembly, NO
reschedule (the sum over windows), NO factorization, NO positivity, NO determinacy, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.WindowDilatePow
import Foundations.F1.Square.TwTermPowBand

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The per-window twisted dilation covariance.** On the `s`-scaling `[s(m+1), s(m+2)]` of the
    integer window `[m+1, m+2]`, with the weight `powBandGen lo hi … n` over a band `[lo, hi]`
    covering both windows (`hc1`–`hc4`),

      `∫_{s·(m+1)}^{s·(m+2)} (φ · powBandGen)  =  s^(n+1) · twTerm (dilate_s φ) n m`.

    Composes the committed `window_dilate_powBandGen` (the per-window dilation at the wide-band
    weight) with `twTerm_eq_window_powBandGen` (the weight-swap to the integer-window `powWinTest`
    of `twTerm`), instantiated at the dilated test `dilate_s φ`. -/
theorem twTerm_dilate_window
    (φ : L2Test) (n m : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi) (hlon : 0 ≤ lo.num)
    (hc1 : Qle lo (⟨(m : Int) + 1, 1⟩ : Q))
    (hc2 : Qle (⟨(m : Int) + 2, 1⟩ : Q) hi)
    (hc3 : Qle lo (mul s (⟨(m : Int) + 1, 1⟩ : Q)))
    (hc4 : Qle (mul s (⟨(m : Int) + 2, 1⟩ : Q)) hi) :
    Req (riemannIntegralI
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLd
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLn
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hlip
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hfc
          (mul s (⟨(m : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
          (twTerm (dilateTest s hsn hsd φ) n m)) := by
  refine Req_trans
    (window_dilate_powBandGen φ n m s hsn hsd lo hi hlod hhid hle hlon hc1 hc2 hc3 hc4) ?_
  refine Rmul_congr (Req_refl _) ?_
  exact twTerm_eq_window_powBandGen (dilateTest s hsn hsd φ) n m lo hi hlod hhid hle hlon hc1 hc2

end Multiplicity.UOR.Bridge.F1Square.Square
