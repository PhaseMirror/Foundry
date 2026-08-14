/-
F1 square — **the per-`x` inner-integral deviation** (`Bern2DInnerClose.lean`), the transform bridge
(Wall 3, the 2D-swap route). At a fixed parameter `x ∈ [0,1]`, the inner `y`-integral of a
jointly-Lipschitz `F` and the 2D Bernstein finite-rank test value are uniformly close:

    `2δn · |∫₀¹ F(x, y) dy − (Σₖ φₖ(x)·∫₀¹ ψₖ) | ≤ (Lx + Ly)·(δ² + n/4)`   (`bern2D_inner_close`).

The comparison object on the right is `(sumProdTest (bern2DList F … n hn) 0 1).f x`, the value at `x` of
the finite-rank inner-integral test; the key identity `sumProdTest_f_eq_gxInt` rewrites it as the
genuine interval integral `∫₀¹ gxSumTest` of a single `y`-test `gxSumTest` whose value on `[0,1]` is the
pointwise 2D Bernstein value `bern2DVal(x, ·)` (`bern2DList_eval_eq`). The uniform closeness is then the
`2δn`-scaled window comparison `riemannIntegralI_dist_le_window` fed by the uniform pointwise deviation
`bern2DVal_devsum_bound`, in multiplied form (the reciprocal `1/(2δn)` is never formed).

WHY (the transform bridge, Wall 3). This is the per-`x` core of the general Fubini swap limit passage:
`∫_x ∫_y F ≈ ∫_x ∫_y B_n(F)` reduces, at each `x`, to *this* inner deviation, uniformly in `x`; the
outer integral then inherits the bound. It builds only the inner passage — NO outer integral, NO swap
(the finite-rank swap `bern2D_fubini_swap` is proven elsewhere), NO convergence limit, NO positivity.

HONEST SCOPE. The per-`x` inner-integral deviation for a jointly-Lipschitz `F`: an
analysis/approximation estimate. No swap, no limit interchange, no positivity, no determinacy, no crux.
Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.Bern2DValue
import Multiplicity.F1Square.Square.Bern2DUniform
import Multiplicity.F1Square.Square.ProdParamTest
import Multiplicity.F1Square.Square.ParamIntegral
import Multiplicity.F1Square.Square.MulConvRLip
import Multiplicity.F1Square.Analysis.IntervalRsmul

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The single `y`-test that carries the parameter-constant coefficients.
-- ===========================================================================

/-- **The parameter-scaled inner test**: at a fixed parameter `x`, the finite sum
    `Σₖ (φₖ.f x)·ψₖ` folded under `L2Test.add`, each coefficient `φₖ.f x` (a REAL) carried on a
    `constTest` and multiplied into `ψₖ`. Its value at `y` is `Σₖ (φₖ.f x)·(ψₖ.f y)`; on `[0,1]²`,
    for the Bernstein list, this is `bern2DVal(x, y)`. -/
def gxSumTest (l : List (L2Test × L2Test)) (x : Real) : L2Test :=
  l.foldr (fun p acc =>
    L2Test.add (L2Test.mul (constTest (p.1.f x) p.1.M p.1.hMd p.1.hMn (p.1.hbd x)) p.2) acc)
    zeroTest

/-- The pointwise value of `gxSumTest`: `(gxSumTest l x).f y = Σₖ (φₖ.f x)·(ψₖ.f y)` (the additive
    fold of the pointwise separable products), literally the fold that `bern2DList_eval_eq` matches. -/
theorem gxSumTest_f (l : List (L2Test × L2Test)) (x y : Real) :
    (gxSumTest l x).f y =
      List.foldr (fun p acc => Radd (Rmul ((p.1).f x) ((p.2).f y)) acc) zero l := by
  induction l with
  | nil => rfl
  | cons p t ih =>
    rw [List.foldr_cons]
    show Radd (Rmul ((p.1).f x) ((p.2).f y)) ((gxSumTest t x).f y) = _
    rw [ih]

-- ===========================================================================
-- The interval integral of a `constTest`-scaled test.
-- ===========================================================================

/-- **The interval integral of a `constTest`-scaled test**: `∫ₐ^{a+w} ((constTest c)·ψ) ≈ c·∫ₐ^{a+w} ψ`
    — the real coefficient `c` pulls out of the interval integral (`riemannIntegralI_Rsmul` at a common
    modulus, each end realigned to its canonical certificate by certificate independence). -/
theorem riemannIntegralI_constTestMul (c : Real) {mB : Q} (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs c) (ofQ mB hMd)) (ψ : L2Test)
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLd
          (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLn
          (L2Test.mul (constTest c mB hMd hMn hb) ψ).hlip
          (L2Test.mul (constTest c mB hMd hMn hb) ψ).hfc a w ha hw hwn)
        (Rmul c (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc a w ha hw hwn)) := by
  -- `χ = (constTest c)·ψ`, integrand `fun y => c·(ψ.f y)`; common modulus `Lc = ψ.L + χ.L`.
  have hχLd : 0 < (L2Test.mul (constTest c mB hMd hMn hb) ψ).L.den :=
    (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLd
  have hLcd : 0 < (add ψ.L (L2Test.mul (constTest c mB hMd hMn hb) ψ).L).den :=
    add_den_pos ψ.hLd hχLd
  have hLcn : 0 ≤ (add ψ.L (L2Test.mul (constTest c mB hMd hMn hb) ψ).L).num :=
    Qadd_num_nonneg_loc ψ.hLn (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLn
  -- ψ certified at the common modulus
  have hlipψ' := lip_weaken ψ.hLd hLcd
    (Qle_self_add (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLn) ψ.hlip
  -- χ (= c·ψ) certified at the common modulus
  have hlipχ' := lip_weaken (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLd hLcd
    (Qle_self_add_l ψ.hLn) (L2Test.mul (constTest c mB hMd hMn hb) ψ).hlip
  refine Req_trans (riemannIntegralI_certif_irrel
    (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLd (L2Test.mul (constTest c mB hMd hMn hb) ψ).hLn
    (L2Test.mul (constTest c mB hMd hMn hb) ψ).hlip (L2Test.mul (constTest c mB hMd hMn hb) ψ).hfc
    hLcd hLcn hlipχ' (L2Test.mul (constTest c mB hMd hMn hb) ψ).hfc a w ha hw hwn) ?_
  refine Req_trans (riemannIntegralI_Rsmul c hLcd hLcn hlipψ' ψ.hfc hlipχ'
    (L2Test.mul (constTest c mB hMd hMn hb) ψ).hfc a w ha hw hwn) ?_
  exact Rmul_congr (Req_refl c)
    (riemannIntegralI_certif_irrel hLcd hLcn hlipψ' ψ.hfc ψ.hLd ψ.hLn ψ.hlip ψ.hfc a w ha hw hwn)

-- ===========================================================================
-- The key identity: the inner-integral test value is an interval integral.
-- ===========================================================================

/-- The common right-hand fold: `Σₖ (φₖ.f x)·(∫ ψₖ)` over the list. -/
private def innerFold (l : List (L2Test × L2Test)) (x : Real)
    (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) : Real :=
  l.foldr (fun p acc => Radd
    (Rmul ((p.1).f x) (riemannIntegralI (p.2).hLd (p.2).hLn (p.2).hlip (p.2).hfc
      ylo yw hylo hyw hywn)) acc) zero

/-- The `sumProdTest` value at `x` is the right-hand fold `Σₖ (φₖ.f x)·(∫ ψₖ)`
    (`prodParamTest_f_factor` term by term). -/
private theorem sumProdTest_f_eq_innerFold (l : List (L2Test × L2Test)) (x : Real)
    (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req ((sumProdTest l ylo yw hylo hyw hywn).f x) (innerFold l x ylo yw hylo hyw hywn) := by
  induction l with
  | nil => exact Req_refl zero
  | cons p t ih =>
    show Req (Radd ((prodParamTest p.1 p.2 ylo yw hylo hyw hywn).f x)
                   ((sumProdTest t ylo yw hylo hyw hywn).f x)) _
    exact Radd_congr (prodParamTest_f_factor p.1 p.2 ylo yw hylo hyw hywn x) ih

/-- The interval integral of `gxSumTest` is the same right-hand fold `Σₖ (φₖ.f x)·(∫ ψₖ)`
    (`riemannIntegralI_L2add` peels each `L2Test.add`, `riemannIntegralI_constTestMul` factors each
    coefficient out). -/
private theorem gxSumTest_int_eq_innerFold (l : List (L2Test × L2Test)) (x : Real)
    (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (riemannIntegralI (gxSumTest l x).hLd (gxSumTest l x).hLn (gxSumTest l x).hlip
          (gxSumTest l x).hfc ylo yw hylo hyw hywn) (innerFold l x ylo yw hylo hyw hywn) := by
  induction l with
  | nil => exact zeroTest_int ylo yw hylo hyw hywn
  | cons p t ih =>
    refine Req_trans (riemannIntegralI_L2add
      (L2Test.mul (constTest (p.1.f x) p.1.M p.1.hMd p.1.hMn (p.1.hbd x)) p.2)
      (gxSumTest t x) ylo yw hylo hyw hywn) ?_
    exact Radd_congr
      (riemannIntegralI_constTestMul (p.1.f x) p.1.hMd p.1.hMn (p.1.hbd x) p.2
        ylo yw hylo hyw hywn) ih

/-- **THE KEY IDENTITY**: the finite-rank inner-integral test value at `x` is the genuine interval
    integral of the single `y`-test `gxSumTest`: `(sumProdTest l 0 1).f x ≈ ∫₀¹ gxSumTest l x`. Both
    sides equal the right-hand fold `Σₖ (φₖ.f x)·(∫ ψₖ)`. -/
theorem sumProdTest_f_eq_gxInt (l : List (L2Test × L2Test)) (x : Real)
    (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req ((sumProdTest l ylo yw hylo hyw hywn).f x)
        (riemannIntegralI (gxSumTest l x).hLd (gxSumTest l x).hLn (gxSumTest l x).hlip
          (gxSumTest l x).hfc ylo yw hylo hyw hywn) :=
  Req_trans (sumProdTest_f_eq_innerFold l x ylo yw hylo hyw hywn)
    (Req_symm (gxSumTest_int_eq_innerFold l x ylo yw hylo hyw hywn))

-- ===========================================================================
-- Scaling an integrand by a nonnegative rational.
-- ===========================================================================

/-- **Scaled Lipschitz**: if `g` is `L`-Lipschitz then `q·g` is `(q·L)`-Lipschitz (`q ≥ 0` rational). -/
theorem scaled_lip {g : Real → Real} {L : Q} (q : Q) (hqd : 0 < q.den) (hqn : 0 ≤ q.num)
    (hLd : 0 < L.den) (_hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hqd) (g x)) (Rmul (ofQ q hqd) (g y))))
        (Rmul (ofQ (mul q L) (Qmul_den_pos hqd hLd)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ q hqd) (g x) (g y))))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg hqd hqn (Rsub (g x) (g y)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hqd hqn) (hlip x y)) ?_
  exact Rle_of_Req (Req_trans (Req_symm (Rmul_assoc (ofQ q hqd) (ofQ L hLd) (Rabs (Rsub x y))))
    (Rmul_congr (Rmul_ofQ_ofQ hqd hLd) (Req_refl _)))

/-- **Scaled congruence**: `q·g` respects `≈` when `g` does. -/
theorem scaled_fc {g : Real → Real} (q : Q) (hqd : 0 < q.den)
    (hfc : ∀ x y, Req x y → Req (g x) (g y)) :
    ∀ x y, Req x y → Req (Rmul (ofQ q hqd) (g x)) (Rmul (ofQ q hqd) (g y)) :=
  fun x y h => Rmul_congr (Req_refl _) (hfc x y h)

/-- **The interval integral scales by a nonnegative rational**: `∫ₐ^{a+w} (q·g) ≈ q·∫ₐ^{a+w} g`
    (`riemannIntegralI_Rsmul` at the real scalar `ofQ q`, a common modulus reconciling `g` at `L` and
    `q·g` at `q·L`). -/
theorem riemannIntegralI_ofQscale {g : Real → Real} {L : Q} (q : Q)
    (hqd : 0 < q.den) (hqn : 0 ≤ q.num) (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (g x) (g y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (Qmul_den_pos hqd hLd) (Int.mul_nonneg hqn hLn)
          (scaled_lip q hqd hqn hLd hLn hlip) (scaled_fc q hqd hfc) a w ha hw hwn)
        (Rmul (ofQ q hqd) (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)) := by
  have hSd : 0 < (add L (mul q L)).den := add_den_pos hLd (Qmul_den_pos hqd hLd)
  have hSn : 0 ≤ (add L (mul q L)).num := Qadd_num_nonneg_loc hLn (Int.mul_nonneg hqn hLn)
  have hlipg := lip_weaken hLd hSd (Qle_self_add (Int.mul_nonneg hqn hLn)) hlip
  have hlipqg := lip_weaken (Qmul_den_pos hqd hLd) hSd (Qle_self_add_l hLn)
    (scaled_lip q hqd hqn hLd hLn hlip)
  refine Req_trans (riemannIntegralI_certif_irrel (Qmul_den_pos hqd hLd) (Int.mul_nonneg hqn hLn)
    (scaled_lip q hqd hqn hLd hLn hlip) (scaled_fc q hqd hfc) hSd hSn hlipqg
    (scaled_fc q hqd hfc) a w ha hw hwn) ?_
  refine Req_trans (riemannIntegralI_Rsmul (ofQ q hqd) hSd hSn hlipg hfc hlipqg
    (scaled_fc q hqd hfc) a w ha hw hwn) ?_
  exact Rmul_congr (Req_refl _)
    (riemannIntegralI_certif_irrel hSd hSn hlipg hfc hLd hLn hlip hfc a w ha hw hwn)

-- ===========================================================================
-- The unit `y`-window and the per-`x` deviation.
-- ===========================================================================

/-- On the unit window `[0,1]` the affine pullback is the identity: `affineMap 0 1 v ≈ v`. -/
private theorem affineMap01 (v : Real) :
    Req (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) v := by
  show Req (Radd (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) v)) v
  have h0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  have h1 : Req (ofQ (⟨1, 1⟩ : Q) (by decide)) one := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  refine Req_trans (Radd_congr h0 (Req_trans (Rmul_congr h1 (Req_refl v)) (Rone_mul v))) ?_
  exact Req_trans (Radd_comm zero v) (Radd_zero v)

/-- **THE PER-`x` INNER-INTEGRAL DEVIATION** (multiplied form). For a jointly-Lipschitz `F` (moduli
    `Lx, Ly`) with the parametric-integral continuity data and the `bern2DList` bound `BF`, at a fixed
    `x ∈ [0,1]`, `n ≥ 1`, `δ > 0`, the inner `y`-integral of `F(x, ·)` and the finite-rank Bernstein
    inner test value `(sumProdTest (bern2DList …) 0 1).f x` satisfy

        `2δn · |∫₀¹ F(x, y) dy − (sumProdTest (bern2DList …) 0 1).f x| ≤ (Lx + Ly)·(δ² + n/4)`.

    The comparison object is rewritten to the interval integral of `gxSumTest` (`sumProdTest_f_eq_gxInt`,
    value `bern2DVal(x, ·)` on `[0,1]` by `bern2DList_eval_eq`); the `2δn`-scaled window comparison
    `riemannIntegralI_dist_le_window` is fed the uniform pointwise deviation `bern2DVal_devsum_bound`.
    Multiplied form: the reciprocal `1/(2δn)` is never formed. -/
theorem bern2D_inner_close (F : Real → Real → Real) (Lx Ly BF : Q)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num) (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (hLip : ∀ a a' b b', Rle (Rabs (Rsub (F a b) (F a' b')))
      (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub a a'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub b b')))))
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n)
    (x : Real) (hx0 : Rle zero x) (hx1 : Rle x one)
    (δ : Q) (hδd : 0 < δ.den) (hδn : 0 ≤ δ.num) :
    Rle (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (Rabs (Rsub
                ((paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
                    (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
                      (by decide) u))).f x)
                ((sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).f x))))
        (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
              (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
                (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) := by
  -- abbreviations
  have hq2d : 0 < (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).den :=
    Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos
  have hq2n : 0 ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num := by
    show (0 : Int) ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num
    simp only [mul]
    exact Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (by omega)
  -- the objects
  have hbdF : ∀ x u, Rle zero u → Rle u one →
      Rle (Rabs (F x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u)))
          (ofQ BF hBFd) :=
    fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u)
  -- the list, the parameter-scaled inner test, and the pieces
  have hgxVal : ∀ v, Rle zero v → Rle v one →
      Req ((gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).f v) (bern2DVal F n hn x v) := by
    intro v hv0 hv1
    rw [gxSumTest_f]
    exact bern2DList_eval_eq F BF hBFd hBFn hFbd n hn x v hx0 hx1 hv0 hv1
  -- the pointwise `hdiff` for `riemannIntegralI_dist_le_window`
  have hdiff : ∀ v, Rle zero v → Rle v one →
      Rle (Rabs (Rsub
            (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
              (F x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v)))
            (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
              ((gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).f
                (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v)))))
          (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
            (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
              (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) := by
    intro v hv0 hv1
    have hwvv : Req (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) v :=
      affineMap01 v
    have hw0 : Rle zero (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) :=
      Rle_trans hv0 (Rle_of_Req (Req_symm hwvv))
    have hw1 : Rle (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) one :=
      Rle_trans (Rle_of_Req hwvv) hv1
    have hgx := hgxVal (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) hw0 hw1
    refine Rle_trans (Rle_of_Req ?_)
      (bern2DVal_devsum_bound F Lx Ly hLxd hLxn hLyd hLyn hLip n hn x
        (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v)
        hx0 hx1 hw0 hw1 δ hδd hδn)
    -- rewrite `|2δn·F − 2δn·gx|` to `2δn·|bern2DVal − F|`
    refine Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib
      (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
      (F x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v))
      ((gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).f
        (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v))))) ?_
    refine Req_trans (Rabs_Rmul_ofQ_nonneg hq2d hq2n _) ?_
    refine Rmul_congr (Req_refl _) ?_
    refine Req_trans (Rabs_congr (Rsub_congr (Req_refl _) hgx)) ?_
    exact Rabs_Rsub_symm (F x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v))
      (bern2DVal F n hn x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v))
  -- assemble via `riemannIntegralI_dist_le_window`
  -- common modulus
  have hLcd : 0 < (add (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) Ly)
      (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
        (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).L)).den :=
    add_den_pos (Qmul_den_pos hq2d hLyd)
      (Qmul_den_pos hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLd)
  have hLcn : 0 ≤ (add (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) Ly)
      (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
        (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).L)).num :=
    Qadd_num_nonneg_loc (Int.mul_nonneg hq2n hLyn)
      (Int.mul_nonneg hq2n (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLn)
  -- scaled certs at the common modulus
  have hlipF := lip_weaken (Qmul_den_pos hq2d hLyd) hLcd
    (Qle_self_add (Int.mul_nonneg hq2n (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLn))
    (scaled_lip (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n hLyd hLyn (hlipY x))
  have hlipG := lip_weaken
    (Qmul_den_pos hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLd) hLcd
    (Qle_self_add_l (Int.mul_nonneg hq2n hLyn))
    (scaled_lip (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLd
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLn
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hlip)
  have hCnn : Rnonneg (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
      (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
        (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) :=
    Rnonneg_Rmul (Rnonneg_Radd (Rnonneg_ofQ hLxd hLxn) (Rnonneg_ofQ hLyd hLyn))
      (Rnonneg_ofQ (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide))
        (Qadd_num_nonneg_loc (Int.mul_nonneg hδn hδn) (Int.ofNat_nonneg n)))
  have hdist := riemannIntegralI_dist_le_window hLcd hLcn hlipF (scaled_fc _ hq2d (hfcY x))
    hlipG (scaled_fc _ hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hfc)
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
    (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
      (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
        (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide))))
    (by decide) (by decide) (by decide) hCnn hdiff
  -- relate the two scaled integrals to `2δn · A x` and `2δn · Bsum x`
  have hFint : Req (riemannIntegralI hLcd hLcn hlipF (scaled_fc _ hq2d (hfcY x))
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
        ((paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).f x)) := by
    refine Req_trans (riemannIntegralI_certif_irrel hLcd hLcn hlipF
      (scaled_fc _ hq2d (hfcY x)) (Qmul_den_pos hq2d hLyd) (Int.mul_nonneg hq2n hLyn)
      (scaled_lip _ hq2d hq2n hLyd hLyn (hlipY x)) (scaled_fc _ hq2d (hfcY x))
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) ?_
    exact riemannIntegralI_ofQscale (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      hLyd hLyn (hlipY x) (hfcY x) (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
  have hGint : Req (riemannIntegralI hLcd hLcn hlipG
        (scaled_fc _ hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hfc)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
        ((sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).f x)) := by
    refine Req_trans (riemannIntegralI_certif_irrel hLcd hLcn hlipG
      (scaled_fc _ hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hfc)
      (Qmul_den_pos hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLd)
      (Int.mul_nonneg hq2n (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLn)
      (scaled_lip _ hq2d hq2n (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLd
        (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLn
        (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hlip)
      (scaled_fc _ hq2d (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hfc)
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) ?_
    refine Req_trans (riemannIntegralI_ofQscale
      (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLd
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hLn
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hlip
      (gxSumTest (bern2DList F BF hBFd hBFn hFbd n hn) x).hfc
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) ?_
    exact Rmul_congr (Req_refl _) (Req_symm (sumProdTest_f_eq_gxInt
      (bern2DList F BF hBFd hBFn hFbd n hn) x (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
      (by decide) (by decide) (by decide)))
  -- final inequality
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans hdist (Rle_of_Req ?_))
  · -- `2δn·|A − B| ≈ |2δn·A − 2δn·B|`
    refine Req_trans ?_ (Rabs_congr (Rsub_congr (Req_symm hFint) (Req_symm hGint)))
    refine Req_symm (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib
      (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
      ((paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
            (by decide) u))).f x)
      ((sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).f x)))) ?_)
    exact Rabs_Rmul_ofQ_nonneg hq2d hq2n _
  · -- `1·C ≈ C`
    refine Req_trans (Rmul_congr (Req_of_seq_Qeq (fun _ => Qeq_refl _)) (Req_refl _)) ?_
    exact Rone_mul _

end Multiplicity.UOR.Bridge.F1Square.Square
