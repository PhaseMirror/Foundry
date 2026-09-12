/-
F1 square — **the convolution's partial tail sum is a single `∫_t`** (`ConvPartialInterchange.lean`):
wiring the `Σ_m`/`∫_t` interchange (`riemannIntegralI_genSumTest`) to the convolution. The partial sum
of the convolution's twisted tail terms (at the minimal window-clearing clamps `m+2`) collapses to a
single `t`-integral of the summed swapped-outer test:

    `Σ_{m<N} twTerm (mulConvRTest f g (m+2)) n m  ≈  ∫_{lo}^{lo+w} (Σ_{m<N} coupOut_m)  dt`,

`coupOut_m = coupOuterTestSwap f g (powWinTest m n) (m+2) … [m+1,m+2]` the `m`-th swapped outer test.
Each term is `∫_t coupOut_m` (`mellinConv_fubini` through the `twTerm = mellinConv` bridge), so
`genSum_congr` lands the partial sum on `Σ_{m<N} ∫_t coupOut_m`, and `riemannIntegralI_genSumTest`
interchanges it to `∫_t Σ_{m<N} coupOut_m` (the summed test `genSumTest coupFam N`).

HONEST SCOPE. The finite partial-sum interchange, wired to the convolution. It takes NO `N→∞` limit
(the tail is `Rlim` of these partials — that commute is next), recognizes the summed integrand as `W·Σ
dilated tail` NOR applies the covariance, builds NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO
crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinConv
import Foundations.F1.Square.MellinHat
import Foundations.F1.Square.DilMellinFEval
import Foundations.F1.Square.IntervalAddTest
import Foundations.F1.Analysis.ComplexDigammaConj

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The swapped-outer-test family** `coupFam m = coupOuterTestSwap f g (powWinTest m n) (m+2) … [m+1,m+2]`
    — the `m`-th outer test whose `t`-integral is the convolution's `m`-th twisted tail term (at the
    minimal window-clearing clamp `m+2`). The family the tail interchange sums over. -/
def coupFam (f g : L2Test) (n : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Nat → L2Test :=
  fun m => coupOuterTestSwap f g (powWinTest m n) (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
    (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
    Nat.one_pos (by decide) (by decide)

/-- **The convolution's partial tail sum equals a single `∫_t` of the summed outer test.**
    `Σ_{m<N} twTerm (mulConvRTest f g (m+2)) n m = ∫_{lo}^{lo+w} (genSumTest coupFam N)`. Each term is
    `∫_t coupOut_m` (`mellinConv_fubini` via the `twTerm = mellinConv` defeq bridge); `genSum_congr` lands
    the sum on `Σ_{m<N} ∫_t coupOut_m`; `riemannIntegralI_genSumTest` interchanges to the single `∫_t`. -/
theorem convPartial_eq_intGenSum (f g : L2Test) (n : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (N : Nat) :
    Req (genSum (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
          (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m) N)
        (riemannIntegralI
          (genSumTest (coupFam f g n a han had lo w hlo hw hwn) N).hLd
          (genSumTest (coupFam f g n a han had lo w hlo hw hwn) N).hLn
          (genSumTest (coupFam f g n a han had lo w hlo hw hwn) N).hlip
          (genSumTest (coupFam f g n a han had lo w hlo hw hwn) N).hfc lo w hlo hw hwn) :=
  Req_trans
    (genSum_congr _ _
      (fun m => mellinConv_fubini f g (powWinTest m n) (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) N)
    (riemannIntegralI_genSumTest (coupFam f g n a han had lo w hlo hw hwn) lo w hlo hw hwn N)

end Multiplicity.UOR.Bridge.F1Square.Square
