/-
F1 square — **certified integration, brick 69** (`IntegralPiece.lean`): **POSITIVE ON A PIECE ⟹
POSITIVE OVERALL** — the first consequence of brick 68's splitting law, and the shape every
downstream use wants:

    `f ≥ 0` on `[0,1]`  ⟹  `∫₀^{1/2} f ≤ ∫₀¹ f`  and  `∫_{1/2}^1 f ≤ ∫₀¹ f`
      (`riemannIntegral_ge_left_half`, `riemannIntegral_ge_right_half`)
    hence  `Pos (∫ over a half)  ⟹  Pos (∫₀¹ f)`
      (`riemannIntegral_pos_of_left_half`, `riemannIntegral_pos_of_right_half`).

Before brick 68 there was no way to say this at all: every law the gateway carried acted on a
fixed interval, so a lower bound established on part of the domain could not be transported to
the whole. Now it is three lines — the split, then the other half is non-negative
(`riemannIntegralI_nonneg`), so it can only help.

This is the coarsest scale of the statement (halves, not arbitrary sub-intervals). The general
form needs the split at an arbitrary interval `[a, a+w]`, which is brick 68 composed under the
affine pullback and is not done here.

HONEST SCOPE. Monotonicity of the certified integral against its two halves, for a non-negative
Lipschitz integrand on `[0,1]`.
NOTE ON "the Lipschitz class on `[0,1]`". The hypothesis `hlip` quantifies over ALL reals, not
just `[0,1]`, so the class is the GLOBALLY Lipschitz functions — `x(1−x)` as a bare function is
not in it, and callers supply a clamped representative (`clampTest`). This is the standing
convention of the `riemannIntegral` gateway and of `L2Test`, inherited rather than introduced
here, but the shorter phrase reads as a weaker requirement than the statement imposes.
 Integration substrate — nothing here touches the Weil form, and
nothing here is yet an `L²` definiteness statement (that needs the arbitrary-interval split and a
constructive way to locate a point of non-vanishing). The crux fields stay `none`.

SUPERSEDED. Brick 71 (`IntervalPiece.lean`) proves these for an ARBITRARY interval `[a, a+w]`,
of which the four results here are the `a = 0, w = 1` case. They are kept because they are the
first, most readable instance of the pattern and are cited by the CHANGELOG, but new work should
use `riemannIntegralI_ge_left_half` / `_ge_right_half` instead.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.IntegralSplit

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- **The left half is a lower bound** for a non-negative integrand. -/
theorem riemannIntegral_ge_left_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x)) :
    Rle (riemannIntegralI hLd hLn hlip hfc (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
          (by decide) (by decide) (by decide))
        (riemannIntegral hLd hLn hlip hfc) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (riemannIntegral_split_half hLd hLn hlip hfc)))
  exact Rle_self_Radd_right (riemannIntegralI_nonneg hLd hLn hlip hfc hfnn
    (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))

set_option maxHeartbeats 1000000 in
/-- **The right half is a lower bound** for a non-negative integrand. -/
theorem riemannIntegral_ge_right_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x)) :
    Rle (riemannIntegralI hLd hLn hlip hfc (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
          (by decide) (by decide) (by decide))
        (riemannIntegral hLd hLn hlip hfc) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (riemannIntegral_split_half hLd hLn hlip hfc)))
  exact Rle_self_Radd_left (riemannIntegralI_nonneg hLd hLn hlip hfc hfnn
    (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))

set_option maxHeartbeats 1000000 in
/-- **POSITIVE ON THE LEFT HALF ⟹ POSITIVE OVERALL.** -/
theorem riemannIntegral_pos_of_left_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x))
    (h : Pos (riemannIntegralI hLd hLn hlip hfc (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
          (by decide) (by decide) (by decide))) :
    Pos (riemannIntegral hLd hLn hlip hfc) :=
  Pos_mono (riemannIntegral_ge_left_half hLd hLn hlip hfc hfnn) h

set_option maxHeartbeats 1000000 in
/-- **POSITIVE ON THE RIGHT HALF ⟹ POSITIVE OVERALL.** -/
theorem riemannIntegral_pos_of_right_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x))
    (h : Pos (riemannIntegralI hLd hLn hlip hfc (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
          (by decide) (by decide) (by decide))) :
    Pos (riemannIntegral hLd hLn hlip hfc) :=
  Pos_mono (riemannIntegral_ge_right_half hLd hLn hlip hfc hfnn) h

end Multiplicity.UOR.Bridge.F1Square.Square
