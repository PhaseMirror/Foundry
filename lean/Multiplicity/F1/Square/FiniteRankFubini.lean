/-
F1 square — **finite-rank Fubini** (`FiniteRankFubini.lean`): the iterated integral of a finite sum of
SEPARABLE products factors term by term:

    `∫_x ∫_y (Σₖ φₖ(x)·ψₖ(y)) dy dx  ≈  Σₖ (∫_x φₖ)·(∫_y ψₖ)`   (`finrank_fubini`)

A `List (L2Test × L2Test)` carries the pairs `(φₖ, ψₖ)`; `sumProdTest` folds their `prodParamTest`
inner-integral tests under `L2Test.add`. The proof inducts on the list: the outer integral is additive
over `L2Test.add` (`riemannIntegralI_L2add`, the interval counterpart of `innerI_add_left`), and each
term factors by `separable_fubini`. The empty case is the zero test integrating to `0`.

WHY (the transform bridge, Wall 3). This is the linearity extension of the separable factorization to
the class the general Fubini swap is reached THROUGH: a jointly-continuous `F(x, y)` is approximated
uniformly by 2D Bernstein polynomials `Σ_{i,j} F(i/n, j/n)·bᵢ(x)·bⱼ(y)` — finite sums of separable
products — for which the swap holds by THIS theorem; the general swap `∫_x∫_y F = ∫_y∫_x F` then follows
by passing the uniform limit through the integral. This file builds the finite-rank rung only; the 2D
Bernstein approximation and the uniform-limit interchange are unbuilt, so no swap for a
genuinely-coupled `F` is claimed here. The crux fields stay `none`.

HONEST SCOPE. Fubini for finite-rank (separable-sum) integrands, via list induction over
`separable_fubini` and interval additivity. No approximation, no general (coupled) swap, no positivity.
Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.SeparableFubini
import Multiplicity.F1.Square.ConstScale
import Multiplicity.F1.Analysis.IntegralBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Interval additivity of test integrals**: `∫_a^{a+w} (A + B) ≈ ∫_a^{a+w} A + ∫_a^{a+w} B` for
    `L2Test`s `A, B` (the pointwise sum `L2Test.add`). `riemannIntegralI_add` at the common modulus
    `A.L + B.L`, each summand realigned to its own modulus by certificate independence. -/
theorem riemannIntegralI_L2add (A B : L2Test) (xlo xw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) :
    Req (riemannIntegralI (L2Test.add A B).hLd (L2Test.add A B).hLn (L2Test.add A B).hlip
          (L2Test.add A B).hfc xlo xw hxlo hxw hxwn)
        (Radd (riemannIntegralI A.hLd A.hLn A.hlip A.hfc xlo xw hxlo hxw hxwn)
              (riemannIntegralI B.hLd B.hLn B.hlip B.hfc xlo xw hxlo hxw hxwn)) := by
  refine Req_trans (riemannIntegralI_add (L2Test.add A B).hLd (L2Test.add A B).hLn
    (lip_weaken A.hLd (L2Test.add A B).hLd (Qle_self_add B.hLn) A.hlip) A.hfc
    (lip_weaken B.hLd (L2Test.add A B).hLd (Qle_add_self A.hLn) B.hlip) B.hfc
    (L2Test.add A B).hlip (L2Test.add A B).hfc xlo xw hxlo hxw hxwn) ?_
  exact Radd_congr
    (riemannIntegralI_certif_irrel (L2Test.add A B).hLd (L2Test.add A B).hLn
      (lip_weaken A.hLd (L2Test.add A B).hLd (Qle_self_add B.hLn) A.hlip) A.hfc
      A.hLd A.hLn A.hlip A.hfc xlo xw hxlo hxw hxwn)
    (riemannIntegralI_certif_irrel (L2Test.add A B).hLd (L2Test.add A B).hLn
      (lip_weaken B.hLd (L2Test.add A B).hLd (Qle_add_self A.hLn) B.hlip) B.hfc
      B.hLd B.hLn B.hlip B.hfc xlo xw hxlo hxw hxwn)

/-- The additive-identity test: the constant `0`. -/
def zeroTest : L2Test := constTest zero (⟨0, 1⟩ : Q) (by decide) (by decide) (Rle_of_Req Rabs_zero)

/-- The zero test integrates to `0` on any interval. -/
theorem zeroTest_int (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) :
    Req (riemannIntegralI zeroTest.hLd zeroTest.hLn zeroTest.hlip zeroTest.hfc
          xlo xw hxlo hxw hxwn) zero := by
  refine Req_trans (riemannIntegralI_certif_irrel zeroTest.hLd zeroTest.hLn zeroTest.hlip
    zeroTest.hfc (by decide) (by decide) (const_lip0 zero) (fun _ _ _ => Req_refl zero)
    xlo xw hxlo hxw hxwn) ?_
  exact Req_trans (riemannIntegralI_const zero xlo xw hxlo hxw hxwn) (Rmul_zero (ofQ xw hxw))

/-- The finite sum of separable inner-integral tests `Σₖ prodParamTest φₖ ψₖ` (folded under
    `L2Test.add`), a genuine `L2Test` in `x` whose value at `x` is `∫_y (Σₖ φₖ(x)·ψₖ(y)) dy`. -/
def sumProdTest (l : List (L2Test × L2Test)) (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den)
    (hywn : 0 ≤ yw.num) : L2Test :=
  l.foldr (fun p acc => L2Test.add (prodParamTest p.1 p.2 ylo yw hylo hyw hywn) acc) zeroTest

/-- **Finite-rank Fubini**: `∫_x ∫_y (Σₖ φₖ(x)·ψₖ(y)) dy dx ≈ Σₖ (∫_x φₖ)·(∫_y ψₖ)` — the iterated
    integral of a finite sum of separable products factors term by term. Induction on the list:
    interval additivity peels each `L2Test.add`, `separable_fubini` factors each term, the empty case
    is `zeroTest_int`. -/
theorem finrank_fubini (l : List (L2Test × L2Test)) (xlo xw ylo yw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (riemannIntegralI (sumProdTest l ylo yw hylo hyw hywn).hLd
          (sumProdTest l ylo yw hylo hyw hywn).hLn (sumProdTest l ylo yw hylo hyw hywn).hlip
          (sumProdTest l ylo yw hylo hyw hywn).hfc xlo xw hxlo hxw hxwn)
        (l.foldr (fun p acc => Radd
          (Rmul (riemannIntegralI p.1.hLd p.1.hLn p.1.hlip p.1.hfc xlo xw hxlo hxw hxwn)
                (riemannIntegralI p.2.hLd p.2.hLn p.2.hlip p.2.hfc ylo yw hylo hyw hywn)) acc)
          zero) := by
  induction l with
  | nil => exact zeroTest_int xlo xw hxlo hxw hxwn
  | cons p rest ih =>
    refine Req_trans (riemannIntegralI_L2add (prodParamTest p.1 p.2 ylo yw hylo hyw hywn)
      (sumProdTest rest ylo yw hylo hyw hywn) xlo xw hxlo hxw hxwn) ?_
    exact Radd_congr (separable_fubini p.1 p.2 xlo xw ylo yw hxlo hxw hxwn hylo hyw hywn) ih

/-- The two product-sums of `finrank_fubini` in swapped order agree term by term (`Rmul` commutes on
    each `(∫φₖ)(∫ψₖ)`). The list of pairs is swapped by `Prod.swap`, matching the swapped-order
    `finrank_fubini`. -/
private theorem finrankProd_comm (l : List (L2Test × L2Test)) (xlo xw ylo yw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (l.foldr (fun p acc => Radd
          (Rmul (riemannIntegralI p.1.hLd p.1.hLn p.1.hlip p.1.hfc xlo xw hxlo hxw hxwn)
                (riemannIntegralI p.2.hLd p.2.hLn p.2.hlip p.2.hfc ylo yw hylo hyw hywn)) acc) zero)
        ((l.map Prod.swap).foldr (fun p acc => Radd
          (Rmul (riemannIntegralI p.1.hLd p.1.hLn p.1.hlip p.1.hfc ylo yw hylo hyw hywn)
                (riemannIntegralI p.2.hLd p.2.hLn p.2.hlip p.2.hfc xlo xw hxlo hxw hxwn)) acc) zero) := by
  induction l with
  | nil => exact Req_refl zero
  | cons p rest ih => exact Radd_congr (Rmul_comm _ _) ih

/-- **The finite-rank Fubini swap**: `∫_x ∫_y (Σₖ φₖ(x)·ψₖ(y)) dy dx ≈ ∫_y ∫_x (Σₖ ψₖ(y)·φₖ(x)) dx dy`
    — the order of integration may be swapped for a finite sum of separable products (the list of pairs
    swapped by `Prod.swap`). `finrank_fubini` in each order, reconciled by `finrankProd_comm`. This is
    the swap the 2D Bernstein approximant `B_n(F)` (a finite-rank integrand) satisfies. -/
theorem finrank_fubini_swap (l : List (L2Test × L2Test)) (xlo xw ylo yw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (riemannIntegralI (sumProdTest l ylo yw hylo hyw hywn).hLd
          (sumProdTest l ylo yw hylo hyw hywn).hLn (sumProdTest l ylo yw hylo hyw hywn).hlip
          (sumProdTest l ylo yw hylo hyw hywn).hfc xlo xw hxlo hxw hxwn)
        (riemannIntegralI (sumProdTest (l.map Prod.swap) xlo xw hxlo hxw hxwn).hLd
          (sumProdTest (l.map Prod.swap) xlo xw hxlo hxw hxwn).hLn
          (sumProdTest (l.map Prod.swap) xlo xw hxlo hxw hxwn).hlip
          (sumProdTest (l.map Prod.swap) xlo xw hxlo hxw hxwn).hfc ylo yw hylo hyw hywn) :=
  Req_trans (finrank_fubini l xlo xw ylo yw hxlo hxw hxwn hylo hyw hywn)
    (Req_trans (finrankProd_comm l xlo xw ylo yw hxlo hxw hxwn hylo hyw hywn)
      (Req_symm (finrank_fubini (l.map Prod.swap) ylo yw xlo xw hylo hyw hywn hxlo hxw hxwn)))

end Multiplicity.UOR.Bridge.F1Square.Square
