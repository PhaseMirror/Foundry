/-
F1 square — **the summed outer test's integrand is the partial dilated tail** (`ConvSummedIntegrand.lean`):
recognizing the integrand of the interchange's single `∫_t`. The value of the summed swapped-outer test
`genSumTest coupFam N` at `t` is exactly the partial sum of the `g`-weighted dilated tail terms:

    `(genSumTest coupFam N).f t  ≈  Σ_{m<N} dilTailIntegrand f g n m a t`,
    `dilTailIntegrand … = (g(t)·(1/max(t,a)))·twTerm (dilateTestR (1/max(t,a)) f) n m`.

A clean induction on `N`: base is `0 = 0` (`sumZeroTest.f ≡ 0`, empty `genSum`); the step is
`L2Test.add`'s pointwise `Radd` composed with `dilTail_ptw` (the `m`-th outer test's value IS the `m`-th
dilated-tail integrand). So the interchange's `∫_t (genSumTest coupFam N)` is `∫_t Σ_{m<N} (g·(1/max(t,a)))·
twTerm(dilateTestR c_t f) n m` — the finite `t`-integral of the `g`-weighted partial dilated tail.

HONEST SCOPE. The integrand recognition (pointwise, per `t`). It takes NO `N→∞` limit, applies NO
covariance, builds NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ConvPartialInterchange
import Foundations.F1.Square.TwTermMulConvDilated

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The summed outer test's value is the partial dilated tail.** `(genSumTest coupFam N).f t =
    Σ_{m<N} dilTailIntegrand f g n m a t`. Induction on `N`: base `sumZeroTest.f ≡ 0 = genSum … 0`; step
    `L2Test.add`'s `Radd` with `dilTail_ptw` (`coupOut_m.f t ≈ dilTailIntegrand_m t`, at the clamp `m+2`,
    inert on `[m+1,m+2]`). -/
theorem genSumTest_coupFam_eq (f g : L2Test) (n : Nat) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (t : Real) :
    ∀ N, Req ((genSumTest (coupFam f g n a han had lo w hlo hw hwn) N).f t)
             (genSum (fun m => dilTailIntegrand f g n m a han had t) N)
  | 0 => Req_refl _
  | (N + 1) =>
      Radd_congr (genSumTest_coupFam_eq f g n a han had lo w hlo hw hwn t N)
        (dilTail_ptw f g n N (⟨(N : Int) + 2, 1⟩ : Q) Nat.one_pos
          (by show (0 : Int) ≤ (N : Int) + 2; omega) a han had lo w hlo hw hwn
          (by show Qle (add (⟨(N : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨(N : Int) + 2, 1⟩ : Q);
              simp only [Qle, add]; push_cast; omega) t)

end Multiplicity.UOR.Bridge.F1Square.Square
