/-
F1 square — **the distance between two interval integrals is bounded by window × sup-distance**
(`IntegralDist.lean`): the reusable heart of "the integral of a uniform limit of tests is the limit of
the integrals". For two `L2Test`s `φ, ψ` over a window `[lo, lo+w]`, if `|φ(x) − ψ(x)| ≤ B` at every
window point, then `|∫_lo^{lo+w} φ − ∫_lo^{lo+w} ψ| ≤ w·B`.

This is the estimate that, composed with `Rlim_eval_real_rate`, commutes an `N→∞` limit with the outer
`∫_t` in the `∫_t` reconstruction of `M[f⋆g]=M[f]·M[g]`: the partial-sum tests `genSumTest coupFam N`
converge to the limit tail-integrand test uniformly in `t` (by `dilTailIntegrand_window_bound`), so their
integrals converge to the integral of the limit at a rate `w·(tail remainder) → 0`.

HONEST SCOPE. Two general interval-integral lemmas only: `riemannIntegralI_negTest` (`∫(−φ) = −∫φ` at the
test level) and `riemannIntegralI_dist_le_of_close` (the window×sup-distance bound). No convolution, no
tail assembly, no limit-inside-the-integral (that composes these with `Rlim_eval_real_rate`), no
covariance, no factorization, no positivity, no crux. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.IntervalAddTest
import Foundations.F1.Square.PairingLimitI
import Foundations.F1.Analysis.MellinDecay

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The negated test integrates to the negated integral**: `∫(−φ) = −∫φ`. The test-level packaging
    of `riemannIntegralI_neg` (`L2Test.neg φ` shares `φ`'s modulus/witnesses definitionally). -/
theorem riemannIntegralI_negTest (φ : L2Test) (lo w : Q)
    (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (L2Test.neg φ).hLd (L2Test.neg φ).hLn (L2Test.neg φ).hlip
            (L2Test.neg φ).hfc lo w hlo hw hwn)
        (Rneg (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc lo w hlo hw hwn)) :=
  riemannIntegralI_neg φ.hLd φ.hLn φ.hlip φ.hfc (L2Test.neg φ).hlip (L2Test.neg φ).hfc
    lo w hlo hw hwn

/-- **The distance between two interval integrals is bounded by window × sup-distance.** If
    `|φ(x) − ψ(x)| ≤ B` at every point of the window `[lo, lo+w]` (i.e. on the affine image of `[0,1]`),
    then `|∫_lo^{lo+w} φ − ∫_lo^{lo+w} ψ| ≤ w·B`. Composes: `∫φ − ∫ψ = ∫(φ − ψ)`
    (`riemannIntegralI_addTest` + `riemannIntegralI_negTest`) and `|∫(φ − ψ)| ≤ w·B`
    (`riemannIntegralI_abs_le_window`, since `(φ − ψ)(x) = φ(x) − ψ(x)` definitionally). -/
theorem riemannIntegralI_dist_le_of_close (φ ψ : L2Test) (lo w : Q)
    (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) {B : Q} (hBd : 0 < B.den)
    (hclose : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (Rsub (φ.f (affineMap lo w hlo hw x)) (ψ.f (affineMap lo w hlo hw x))))
        (ofQ B hBd)) :
    Rle (Rabs (Rsub (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc lo w hlo hw hwn)
                    (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc lo w hlo hw hwn)))
        (ofQ (mul w B) (Qmul_den_pos hw hBd)) := by
  -- ∫(φ − ψ) = ∫φ − ∫ψ
  have hsub : Req (riemannIntegralI (L2Test.sub φ ψ).hLd (L2Test.sub φ ψ).hLn
        (L2Test.sub φ ψ).hlip (L2Test.sub φ ψ).hfc lo w hlo hw hwn)
      (Rsub (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc lo w hlo hw hwn)
            (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc lo w hlo hw hwn)) :=
    Req_trans (riemannIntegralI_addTest φ (L2Test.neg ψ) lo w hlo hw hwn)
      (Radd_congr (Req_refl _) (riemannIntegralI_negTest ψ lo w hlo hw hwn))
  -- |∫(φ − ψ)| ≤ w·B, since (φ − ψ)(x) = φ(x) − ψ(x) is bounded by B on the window
  have hwin : Rle (Rabs (riemannIntegralI (L2Test.sub φ ψ).hLd (L2Test.sub φ ψ).hLn
        (L2Test.sub φ ψ).hlip (L2Test.sub φ ψ).hfc lo w hlo hw hwn))
      (ofQ (mul w B) (Qmul_den_pos hw hBd)) :=
    riemannIntegralI_abs_le_window (L2Test.sub φ ψ).hLd (L2Test.sub φ ψ).hLn
      (L2Test.sub φ ψ).hlip (L2Test.sub φ ψ).hfc lo w B hlo hw hwn hBd
      (fun x h0 h1 => hclose x h0 h1)
  exact Rle_trans (Rle_of_Req (Rabs_congr (Req_symm hsub))) hwin

end Multiplicity.UOR.Bridge.F1Square.Square
