/-
F1 square — **real-scalar linearity of the interval integral** (`IntervalRsmul.lean`):

    `∫_a^{a+w} (c·f) = c·∫_a^{a+w} f`   for any `c : Real`   (`riemannIntegralI_Rsmul`),

the interval-integral counterpart of `riemannIntegral_Rsmul` (`IntegralRsmul.lean`, over `[0,1]`), and
the real-scalar mirror of the rational `riemannIntegralI_smul` (`IntervalIntegral.lean`). The proof is
the exact mirror: pull `c` through the affine-rescaled `[0,1]` integral with `riemannIntegral_Rsmul`,
then commute `c` past the width factor `w` (`w·(c·I) ≈ c·(w·I)`).

WHY. A separable (product) integrand `F(x, y) = φ(x)·ψ(y)` has inner integral
`∫_y φ(x)·ψ(y) dy = φ(x)·∫_y ψ(y) dy` — pulling the parameter-constant `φ(x)` (a REAL, not a rational)
out of the `y`-integral is exactly this law. It is the tool a *separable* Fubini step
`∫_x ∫_y φ(x)ψ(y) = (∫φ)·(∫ψ)` runs through — the final factorization the Mellin convolution theorem
`M[f⋆g]=M[f]·M[g]` reduces to once the change of variables has decoupled the integrand.

HONEST SCOPE. Real-scalar linearity of the certified interval integral; general integral
infrastructure. No swap, no product identity, no positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.IntervalIntegral
import Multiplicity.F1.Analysis.IntegralRsmul

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The interval integral respects a real constant scalar** `∫_a^{a+w} (c·f) = c·∫_a^{a+w} f` for
    `c : Real` — `riemannIntegral_Rsmul` on the affine-rescaled integrand, then left-commute the scalar
    `c` past the width factor `w` (`w·(c·I) ≈ c·(w·I)` via `Rmul_assoc`/`Rmul_comm`). The exact mirror
    of `riemannIntegralI_smul` with `ofQ q ↦ c`. -/
theorem riemannIntegralI_Rsmul {f : Real → Real} {L : Q} (c : Real) (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipcf : ∀ x y, Rle (Rabs (Rsub (Rmul c (f x)) (Rmul c (f y))))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfccf : ∀ x y, Req x y → Req (Rmul c (f x)) (Rmul c (f y)))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlipcf hfccf a w ha hw hwn)
        (Rmul c (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)) := by
  refine Req_trans (Rmul_congr (Req_refl (ofQ w hw))
    (riemannIntegral_Rsmul (f := fun x => f (affineMap a w ha hw x)) c
      (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlipf a w ha hw hwn)
      (fun x y h => hfcf _ _ (affineMap_congr a w ha hw h))
      (affine_lip hLd hLn hlipcf a w ha hw hwn)
      (fun x y h => hfccf _ _ (affineMap_congr a w ha hw h)))) ?_
  exact Req_trans (Req_symm (Rmul_assoc (ofQ w hw) c _))
    (Req_trans (Rmul_congr (Rmul_comm (ofQ w hw) c) (Req_refl _))
      (Rmul_assoc c (ofQ w hw) _))

end Multiplicity.UOR.Bridge.F1Square.Analysis
