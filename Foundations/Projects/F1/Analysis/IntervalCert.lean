/-
F1 square — **window-congruence for the interval integral** (`IntervalCert.lean`):
`∫_a^{a+w} f ≈ ∫_a^{a+w} g` from agreement of `f` and `g` on the affine image `[a, a+w]` ALONE (the
dyadic sums only sample there), a shared modulus assumed — the interval mirror of
`riemannIntegral_congr_unit` (`IntegralLocal`), via `riemannIntegralI_le_unit` in both directions.
This is the structural fact the Haar-invariance assembly consumes to equate two integrals whose
integrands differ off the window (the clamped reciprocals). (Certificate-independence at the interval
level is already provided by `Square.riemannIntegralI_certif_irrel` in `MellinLinear`.)

HONEST SCOPE. One general fact about the certified interval integral; no positivity, no crux claim.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.IntegralLocal

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Window-congruence of the interval integral**: `∫_a^{a+w} f ≈ ∫_a^{a+w} g` from agreement of `f`
    and `g` on the affine image of `[0,1]` (i.e. on `[a, a+w]`) alone, at a shared modulus `L` —
    antisymmetry of `riemannIntegralI_le_unit`. -/
theorem riemannIntegralI_congr_unit {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hfg : ∀ x, Rle zero x → Rle x one →
      Req (f (affineMap a w ha hw x)) (g (affineMap a w ha hw x))) :
    Req (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)
        (riemannIntegralI hLd hLn hlipg hfcg a w ha hw hwn) :=
  Rle_antisymm
    (riemannIntegralI_le_unit hLd hLn hlipf hfcf hlipg hfcg a w ha hw hwn
      (fun x h0 h1 => Rle_of_Req (hfg x h0 h1)))
    (riemannIntegralI_le_unit hLd hLn hlipg hfcg hlipf hfcf a w ha hw hwn
      (fun x h0 h1 => Rle_of_Req (Req_symm (hfg x h0 h1))))

end Multiplicity.UOR.Bridge.F1Square.Analysis
