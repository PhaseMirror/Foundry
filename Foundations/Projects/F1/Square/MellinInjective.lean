/-
F1 square — **the pre-Hilbert layer, brick 87** (`MellinInjective.lean`): **THE MELLIN TRANSFORM IS
INJECTIVE ON THE COMPACT POLYNOMIAL CLASS** — the uniqueness/injectivity direction of the transform
pair, realized on polynomials by welding the co-support/transform condition to the now-complete `L²`
definiteness:

    `polyPN a b d` compactly supported, `f̂(n) = 0` for `n < d`  (`HatVanishes … d`, i.e. the
    Mellin transform vanishes below the degree)  ⟹  `polyPN a b d` is the **zero function** on
    `[0,1]`   (`polyPN_hatVanishes_zero_function`).

This is a one-line weld of two earlier results: co-support level `d` forces `L²`-nullity for a
`d`-coefficient polynomial (`polyPN_level_null`, brick 64 — through the orthogonality characterization
`hatVanishes_iff_orthogonal`), and `L²`-nullity forces pointwise vanishing on `[0,1]`
(`innerI_self_zero_imp_zero`, brick 79). Since for a compactly supported test the transform is the
moment sequence (`mellinHat_compact`), the co-support condition `HatVanishes … d` is exactly
"the Mellin transform vanishes below `d`". So a polynomial the transform cannot distinguish from the
zero test — one whose transform vanishes as far as its coefficient count reaches — is genuinely the
zero function, not merely moment-null. This is the injectivity half of the transform pair, for the
polynomial class.

HONEST SCOPE. Injectivity on the **polynomial** class, and against the zero function (equivalently:
two polynomial tests whose transforms agree far enough agree as functions on `[0,1]`, applied through
their difference). This is NOT the general transform pair (an inversion formula reconstructing an
arbitrary `f` from `f̂`), NOT the continuous parameter, and NOT injectivity beyond polynomials (that
would need Bernstein, which the layer does not have — a *non*-polynomial test with vanishing
transform is the open general-determinacy question). Nothing here touches the Weil form. Step 4 is
RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DyadicDenseReal

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE MELLIN TRANSFORM IS INJECTIVE ON THE COMPACT POLYNOMIAL CLASS**: a compactly supported
    polynomial test whose transform vanishes below its coefficient count (`HatVanishes … d`) is the
    zero function on `[0,1]`. Brick 64's `polyPN_level_null` (co-support ⟹ `L²`-null) welded to
    brick 79's definiteness (`L²`-null ⟹ pointwise zero). -/
theorem polyPN_hatVanishes_zero_function (a b : Nat → Nat) (d : Nat)
    (hsupp : UnitSupported (polyPN a b d))
    (hK : HatVanishes (polyPN a b d) d (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp (polyPN a b d) hsupp))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((polyPN a b d).f x) zero :=
  innerI_self_zero_imp_zero (polyPN a b d) (polyPN_level_null a b d hsupp hK) x h0 h1

end Multiplicity.UOR.Bridge.F1Square.Square
