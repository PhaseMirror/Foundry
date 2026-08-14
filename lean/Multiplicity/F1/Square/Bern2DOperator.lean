/-
F1 square — **the 2D Bernstein operator as a finite-rank list + its Fubini swap**
(`Bern2DOperator.lean`), the transform bridge, Wall 3. The bivariate Bernstein approximant

    `B_n(F)(x, y) = Σ_{i,j=0}^n F(i/n, j/n)·b_{n,i}(x)·b_{n,j}(y)`

is a finite sum of SEPARABLE products `(F(i/n,j/n)·b_{n,i}(x))·b_{n,j}(y)`, hence a
`List (L2Test × L2Test)` (`bern2DList`): the `(i,j)` grid over `0..n × 0..n`, the real coefficient
`F(i/n, j/n)` carried on the `x`-factor as a `constTest` and multiplied into the `x`-basis by the test
algebra (`L2Test.mul`), the `y`-factor the bare `y`-basis. Being finite-rank separable, its iterated
integral swaps by `finrank_fubini_swap` — the swap the 2D Bernstein integrand satisfies, instantiated
here at this concrete list (`bern2D_fubini_swap`).

WHY (the transform bridge, Wall 3). A jointly-continuous `F(x, y)` is approximated uniformly on the
square by these `B_n(F)`; the general swap `∫_x∫_y F = ∫_y∫_x F` would then follow by passing the
uniform limit through the integral. This file supplies only the finite-rank rung's list representation
and its already-proven swap; it builds NO Bernstein convergence for `F`, NO uniform-limit interchange,
and NO swap for a genuinely-coupled `F`.

HONEST SCOPE. The 2D Bernstein approximant's `List (L2Test × L2Test)` representation and its Fubini
swap — a finite-rank instance of `finrank_fubini_swap`. No approximation, no convergence, no coupled
(non-separable) swap, no positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.FiniteRankFubini
import Multiplicity.F1Square.Square.BernsteinBasisZero
import Multiplicity.F1Square.Square.ConstScale
import Multiplicity.F1Square.Square.BernsteinDeviation

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The 2D Bernstein approximant as a finite-rank list** `B_n(F)`: the `(i,j)` grid over
    `0..n × 0..n`, each term the separable pair `(F(i/n,j/n)·b_{n,i}(x), b_{n,j}(y))` — the real
    coefficient `F(i/n, j/n)` carried on the `x`-factor as a `constTest` and multiplied into the
    `x`-basis by `L2Test.mul`, the `y`-factor the bare `y`-basis `bernBasisTest n j`. -/
def bern2DList (F : Real → Real → Real) (BF : Q) (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n) :
    List (L2Test × L2Test) :=
  (List.range (n + 1)).flatMap (fun i =>
    (List.range (n + 1)).map (fun j =>
      (L2Test.mul (constTest (F (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
          (hFbd (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i),
       bernBasisTest n j)))

/-- **The 2D Bernstein finite-rank Fubini swap**: the iterated integral of the 2D Bernstein approximant
    `B_n(F)` may be swapped in the order of integration, `∫_x∫_y B_n(F) ≈ ∫_y∫_x B_n(F)`. A direct
    instance of `finrank_fubini_swap` at the concrete separable-sum list `bern2DList F … n hn`. Builds
    no convergence and no coupled-integrand swap. -/
theorem bern2D_fubini_swap (F : Real → Real → Real) (BF : Q) (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n)
    (xlo xw ylo yw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (riemannIntegralI
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ylo yw hylo hyw hywn).hLd
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ylo yw hylo hyw hywn).hLn
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ylo yw hylo hyw hywn).hlip
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ylo yw hylo hyw hywn).hfc
          xlo xw hxlo hxw hxwn)
        (riemannIntegralI
          (sumProdTest ((bern2DList F BF hBFd hBFn hFbd n hn).map Prod.swap)
            xlo xw hxlo hxw hxwn).hLd
          (sumProdTest ((bern2DList F BF hBFd hBFn hFbd n hn).map Prod.swap)
            xlo xw hxlo hxw hxwn).hLn
          (sumProdTest ((bern2DList F BF hBFd hBFn hFbd n hn).map Prod.swap)
            xlo xw hxlo hxw hxwn).hlip
          (sumProdTest ((bern2DList F BF hBFd hBFn hFbd n hn).map Prod.swap)
            xlo xw hxlo hxw hxwn).hfc
          ylo yw hylo hyw hywn) :=
  finrank_fubini_swap (bern2DList F BF hBFd hBFn hFbd n hn) xlo xw ylo yw
    hxlo hxw hxwn hylo hyw hywn

end Multiplicity.UOR.Bridge.F1Square.Square
