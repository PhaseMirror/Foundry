/-
F1 square — **the outer-integration deviation** (`Bern2DOuterClose.lean`), the transform bridge
(Wall 3, the 2D-swap route). This is Move 1 of the general Fubini swap: integrating the ALREADY-PROVEN
per-`x` inner deviation (`bern2D_inner_close`) over the outer parameter `x ∈ [0,1]`, the genuine iterated
double integral `∫_x ∫_y F` and the finite-rank `∫_x` of the 2D Bernstein inner test are uniformly close:

    `2δn · |∫₀¹ ∫₀¹ F  −  ∫₀¹ (sumProdTest (bern2DList F …) 0 1)| ≤ (Lx + Ly)·(δ² + n/4)`
    (`bern2D_outer_close`).

Both objects are genuine `L2Test`s in `x`: the left is `paramIntegralTest F …` (whose value at `x` is the
inner `y`-integral `∫₀¹ F(x, ·) dy`), the right is `sumProdTest (bern2DList F …) 0 1` (whose value at `x`
is the finite-rank Bernstein inner value). The outer integral is the `2δn`-scaled window comparison
`riemannIntegralI_dist_le_window` over the unit `x`-window, fed the uniform per-`x` bound
`bern2D_inner_close` (at `x := u`, the affine pullback trivial on `[0,1]` by `affineMap01`). Each scaled
integral is related back to `2δn·(true integral)` by `riemannIntegralI_ofQscale`; multiplied form (the
reciprocal `1/(2δn)` is never formed).

WHY (the transform bridge, Wall 3). The per-`x` inner deviation is uniform in `x`, so the outer integral
inherits the bound — this is exactly the outer half of the Fubini-swap limit passage. NO swap is performed
here (the finite-rank swap `finrank_fubini`/`bern2D_fubini_swap` is composed later), NO convergence limit
is taken, NO positivity.

HONEST SCOPE. The outer integration of the per-`x` inner-integral deviation for a jointly-Lipschitz `F`:
an analysis/approximation estimate. No Fubini swap, no limit interchange, no positivity, no determinacy,
no crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Bern2DInnerClose
import Foundations.F1.Square.FiniteRankFubini
import Foundations.F1.Square.ParamIntegral
import Foundations.F1.Square.MulConvRLip

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- On the unit window `[0,1]` the affine pullback is the identity: `affineMap 0 1 v ≈ v`. -/
private theorem affineMap01_outer (v : Real) :
    Req (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) v := by
  show Req (Radd (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) v)) v
  have h0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  have h1 : Req (ofQ (⟨1, 1⟩ : Q) (by decide)) one := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  refine Req_trans (Radd_congr h0 (Req_trans (Rmul_congr h1 (Req_refl v)) (Rone_mul v))) ?_
  exact Req_trans (Radd_comm zero v) (Radd_zero v)

/-- **THE OUTER-INTEGRATION DEVIATION** (Move 1 of the general Fubini swap, multiplied form). For a
    jointly-Lipschitz `F` (moduli `Lx, Ly`) with the parametric-integral continuity data and the
    `bern2DList` bound `BF`, for `n ≥ 1`, `δ > 0`, the genuine iterated double integral `∫₀¹ ∫₀¹ F` and
    the finite-rank `∫₀¹` of the 2D Bernstein inner test `sumProdTest (bern2DList …) 0 1` satisfy

        `2δn · |∫₀¹ ∫₀¹ F − ∫₀¹ (sumProdTest (bern2DList …) 0 1)| ≤ (Lx + Ly)·(δ² + n/4)`.

    The proof integrates the per-`x` deviation `bern2D_inner_close` over the unit `x`-window via the
    `2δn`-scaled window comparison `riemannIntegralI_dist_le_window`; each scaled integral is related to
    `2δn·(true integral)` by `riemannIntegralI_ofQscale`. Multiplied form: the reciprocal `1/(2δn)` is
    never formed. NO swap, NO limit, NO positivity; the crux fields stay `none`. -/
theorem bern2D_outer_close (F : Real → Real → Real) (Lx Ly BF : Q)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num) (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (hLip : ∀ a a' b b', Rle (Rabs (Rsub (F a b) (F a' b')))
      (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub a a'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub b b')))))
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n)
    (δ : Q) (hδd : 0 < δ.den) (hδn : 0 ≤ δ.num) :
    Rle (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (Rabs (Rsub
                (riemannIntegralI
                  (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
                    (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
                      (by decide) u))).hLd
                  (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
                    (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
                      (by decide) u))).hLn
                  (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
                    (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
                      (by decide) u))).hlip
                  (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
                    (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
                      (by decide) u))).hfc
                  (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
                (riemannIntegralI
                  (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
                  (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
                  (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip
                  (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
                    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
                  (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)))))
        (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
              (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
                (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) := by
  -- the rational scale `q2 = 2δn` and its positivity/nonnegativity
  have hq2d : 0 < (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).den :=
    Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos
  have hq2n : 0 ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num := by
    show (0 : Int) ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num
    simp only [mul]
    exact Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (by omega)
  -- the outer integrand pieces: `Aint` (the parametric inner integral) and `Bint` (the finite-rank test)
  have hbdF : ∀ x u, Rle zero u → Rle u one →
      Rle (Rabs (F x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u)))
          (ofQ BF hBFd) :=
    fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u)
  -- the pointwise `hdiff` for the OUTER `riemannIntegralI_dist_le_window`
  have hdiff : ∀ v, Rle zero v → Rle v one →
      Rle (Rabs (Rsub
            (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
              ((paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
                  (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).f
                (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v)))
            (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
              ((sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
                  (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).f
                (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v)))))
          (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
            (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
              (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) := by
    intro v hv0 hv1
    have hwvv : Req (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) v :=
      affineMap01_outer v
    -- rewrite `|2δn·A(am v) − 2δn·B(am v)|` to `2δn·|A v − B v|`, then invoke `bern2D_inner_close`
    refine Rle_trans (Rle_of_Req ?_)
      (bern2D_inner_close F Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn hlipY hfcY hlipX hfcX hLip hFbd
        n hn v hv0 hv1 δ hδd hδn)
    refine Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib
      (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
      ((paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).f
        (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v))
      ((sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).f
        (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v))))) ?_
    refine Req_trans (Rabs_Rmul_ofQ_nonneg hq2d hq2n _) ?_
    exact Rmul_congr (Req_refl _) (Rabs_congr (Rsub_congr
      ((paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc
        (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) v hwvv)
      ((sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
        (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) v) v hwvv)))
  -- assemble via the OUTER `riemannIntegralI_dist_le_window`
  -- common modulus `Lc = q2·Aint.L + q2·Bint.L`
  have hLcd : 0 < (add
      (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).L)
      (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).L)).den :=
    add_den_pos
      (Qmul_den_pos hq2d
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd)
      (Qmul_den_pos hq2d
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd)
  have hLcn : 0 ≤ (add
      (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).L)
      (mul (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).L)).num :=
    Qadd_num_nonneg_loc
      (Int.mul_nonneg hq2n
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn)
      (Int.mul_nonneg hq2n
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn)
  -- scaled certs at the common modulus
  have hlipF := lip_weaken
    (Qmul_den_pos hq2d
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd) hLcd
    (Qle_self_add (Int.mul_nonneg hq2n
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn))
    (scaled_lip (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hlip)
  have hlipG := lip_weaken
    (Qmul_den_pos hq2d
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd) hLcd
    (Qle_self_add_l (Int.mul_nonneg hq2n
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn))
    (scaled_lip (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip)
  have hCnn : Rnonneg (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
      (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
        (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) :=
    Rnonneg_Rmul (Rnonneg_Radd (Rnonneg_ofQ hLxd hLxn) (Rnonneg_ofQ hLyd hLyn))
      (Rnonneg_ofQ (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide))
        (Qadd_num_nonneg_loc (Int.mul_nonneg hδn hδn) (Int.ofNat_nonneg n)))
  have hdist := riemannIntegralI_dist_le_window hLcd hLcn hlipF
    (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc)
    hlipG
    (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc)
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
    (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
      (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
        (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide))))
    (by decide) (by decide) (by decide) hCnn hdiff
  -- relate the two scaled integrals to `2δn · Ixy` and `2δn · Sn`
  have hFint : Req (riemannIntegralI hLcd hLcn hlipF
        (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
        (riemannIntegralI
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hlip
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))) := by
    refine Req_trans (riemannIntegralI_certif_irrel hLcd hLcn hlipF
      (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc)
      (Qmul_den_pos hq2d
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd)
      (Int.mul_nonneg hq2n
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn)
      (scaled_lip (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hlip)
      (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc)
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) ?_
    exact riemannIntegralI_ofQscale (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLd
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hLn
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hlip
      (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hbdF).hfc
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
  have hGint : Req (riemannIntegralI hLcd hLcn hlipG
        (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
        (riemannIntegralI
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))) := by
    refine Req_trans (riemannIntegralI_certif_irrel hLcd hLcn hlipG
      (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc)
      (Qmul_den_pos hq2d
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd)
      (Int.mul_nonneg hq2n
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn)
      (scaled_lip (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip)
      (scaled_fc (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc)
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) ?_
    exact riemannIntegralI_ofQscale (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d hq2n
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip
      (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
  -- final inequality
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans hdist (Rle_of_Req ?_))
  · -- `2δn·|Ixy − Sn| ≈ |∫(2δn·Aint) − ∫(2δn·Bint)|`
    refine Req_trans ?_ (Rabs_congr (Rsub_congr (Req_symm hFint) (Req_symm hGint)))
    refine Req_symm (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib
      (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)) hq2d)
      (riemannIntegralI
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
            (by decide) u))).hLd
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
            (by decide) u))).hLn
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
            (by decide) u))).hlip
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide)
            (by decide) u))).hfc
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (riemannIntegralI
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip
        (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))))) ?_)
    exact Rabs_Rmul_ofQ_nonneg hq2d hq2n _
  · -- `1·C ≈ C`
    refine Req_trans (Rmul_congr (Req_of_seq_Qeq (fun _ => Qeq_refl _)) (Req_refl _)) ?_
    exact Rone_mul _

end Multiplicity.UOR.Bridge.F1Square.Square
