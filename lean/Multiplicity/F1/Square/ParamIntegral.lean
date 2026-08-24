/-
F1 square — **the parametric interval integral as a test** (`ParamIntegral.lean`): for a jointly
bounded-Lipschitz two-variable integrand `F x y`, the map `x ↦ ∫_lo^{lo+w} F(x, y) dy` is itself a
genuine `L2Test` in the parameter `x`.

    `(paramIntegralTest F …).f x  =  ∫_{lo}^{lo+w} F(x, y) dy`

with Lipschitz modulus `w·Lx` (integrating the parameter-Lipschitz bound) and bound `w·B`
(integrating the window bound). This is the general shape the real-parameter convolution `mulConvRTest`
is one instance of (`F(x, t) = f(x/t)·g(t)·(1/max(t,a))`): the three `x`-continuity facts —
Lipschitz-in-`x` via `riemannIntegralI_dist_le_window`, bound via `riemannIntegralI_abs_le_window`,
congruence via `riemannIntegralI_congr` — are exactly the fields, now packaged once for any `F`.

WHY (the transform bridge, Wall 3). An iterated integral `∫_x ∫_y F(x,y)` is `∫_x` of *this* object
(with the outer variable in either slot, since the hypotheses are symmetric in the roles of `x` and
`y`), so a Fubini/iterated-integral swap `∫_x ∫_y F = ∫_y ∫_x F` — the deep two-variable step the
Mellin convolution theorem `M[f⋆g]=M[f]·M[g]` needs — is a statement *about* `paramIntegralTest`. This
file builds only the object (the inner integral as a valid parametric test); it proves NO swap. The
swap, and the theorem it feeds (identifying `mulConv` values at prime powers with
`weilPrimeGram (vFrom g)`, i.e. step 4 = RH), stay unbuilt. The crux fields stay `none`.

HONEST SCOPE. The parametric interval integral bundled as a bounded-Lipschitz test in its parameter;
non-negative on non-negative data. No product identity, no swap, no positivity beyond the sign of the
integrand. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MulConvRLip
import Multiplicity.F1.Analysis.MellinDecay
import Multiplicity.F1.Analysis.IntervalIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The parametric interval integral as a test**: for a two-variable integrand `F` that is
    `Ly`-Lipschitz and a congruence in the integration variable `y` (uniformly in the parameter `x`),
    `Lx`-Lipschitz and a congruence in the parameter `x`, and bounded by `B` on the integration window,
    the map `x ↦ ∫_{lo}^{lo+w} F(x, y) dy` is a genuine `L2Test` with modulus `w·Lx` and bound `w·B`.
    The general form the convolution-in-`x` `mulConvRTest` instantiates. -/
def paramIntegralTest
    (F : Real → Real → Real) (Ly Lx B : Q)
    (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num)
    (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hbdF : ∀ x u, Rle zero u → Rle u one →
      Rle (Rabs (F x (affineMap a w ha hw u))) (ofQ B hBd)) : L2Test where
  f := fun x => riemannIntegralI hLyd hLyn (hlipY x) (hfcY x) a w ha hw hwn
  L := mul w Lx
  M := mul w B
  hLd := Qmul_den_pos hw hLxd
  hLn := Int.mul_nonneg hwn hLxn
  hMd := Qmul_den_pos hw hBd
  hMn := Int.mul_nonneg hwn hBn
  hlip := fun x x' =>
    Rle_trans
      (riemannIntegralI_dist_le_window hLyd hLyn (hlipY x) (hfcY x) (hlipY x') (hfcY x')
        a w (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))) ha hw hwn
        (Rnonneg_Rmul (Rnonneg_ofQ hLxd hLxn) (Rnonneg_Rabs _))
        (fun u _ _ => hlipX x x' (affineMap a w ha hw u)))
      (Rle_of_Req
        (Req_trans (Req_symm (Rmul_assoc (ofQ w hw) (ofQ Lx hLxd) (Rabs (Rsub x x'))))
          (Rmul_congr (Rmul_ofQ_ofQ hw hLxd) (Req_refl _))))
  hfc := fun x x' hxx' =>
    riemannIntegralI_congr hLyd hLyn (hlipY x) (hfcY x) (hlipY x') (hfcY x')
      a w ha hw hwn (fun y => hfcX x x' y hxx')
  hbd := fun x =>
    riemannIntegralI_abs_le_window hLyd hLyn (hlipY x) (hfcY x) a w B ha hw hwn hBd (hbdF x)

/-- **The parametric interval integral of a non-negative integrand is non-negative** — the window
    integral of `F(x, ·) ≥ 0` is `≥ 0` at every parameter `x` (`riemannIntegralI_nonneg`). -/
theorem paramIntegralTest_nonneg
    (F : Real → Real → Real) (Ly Lx B : Q)
    (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num)
    (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hbdF : ∀ x u, Rle zero u → Rle u one →
      Rle (Rabs (F x (affineMap a w ha hw u))) (ofQ B hBd))
    (hFnn : ∀ x y, Rnonneg (F x y)) (x : Real) :
    Rnonneg ((paramIntegralTest F Ly Lx B hLyd hLyn hLxd hLxn hBd hBn
      hlipY hfcY hlipX hfcX a w ha hw hwn hbdF).f x) :=
  riemannIntegralI_nonneg hLyd hLyn (hlipY x) (hfcY x) (fun y => hFnn x y) a w ha hw hwn

end Multiplicity.UOR.Bridge.F1Square.Square
