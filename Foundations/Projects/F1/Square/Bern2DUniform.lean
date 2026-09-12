/-
F1 square — **the 2D uniform Bernstein convergence bound** (`Bern2DUniform.lean`), the transform
bridge (Wall 3). Combining the 2D pointwise deviation (`bern2DVal_deviation`) with the 1D
multiplied-form central-moment bound (`bernOp_devsum_bound`, applied in each variable) gives a
UNIFORM (in `x, y`) rational bound on the 2D Bernstein deviation:

    `2δn · |B_n(F)(x,y) − F(x,y)| ≤ (Lx + Ly)·(δ² + n/4)`   (`bern2DVal_devsum_bound`, on `[0,1]²`,
    any `δ > 0`).

In multiplied form, so the reciprocal `1/(2δn)` is formed only later at a concrete schedule. At the
schedule `δ = k+1`, `n = (k+1)²` the right side is `(Lx+Ly)·(5/4)(k+1)²` and `2δn = 2(k+1)³`, giving
`|B_n(F)(x,y) − F(x,y)| ≤ (Lx+Ly)·5/(8(k+1)) → 0` uniformly — the 2D Weierstrass rate, the analytic
input the general Fubini swap consumes (`‖F − B_n(F)‖∞ → 0`).

WHY (the transform bridge, Wall 3). The general swap `∫_x∫_y F = ∫_y∫_x F` for a jointly-Lipschitz `F`
follows from `|∫∫F − ∫∫B_n(F)| ≤ area·‖F−B_n(F)‖∞` (via `riemannIntegralI_dist_le_window`), the
finite-rank swap of `B_n(F)` (`bern2D_fubini_swap`), and this `→ 0` bound. This file supplies the
uniform bound only; the value-agreement to `bern2DList`'s integral and the limit passage stay unbuilt.

HONEST SCOPE. A uniform (in `x, y`) rational bound on the 2D Bernstein deviation for a
jointly-Lipschitz `F`; general approximation theory. NO positivity, NO integral, NO crux. Step 4 is
RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Bern2DDeviation
import Foundations.F1.Square.BernsteinDevBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `A·(u·P + v·Q) ≈ u·(A·P) + v·(A·Q)` — distribute then commute the leading scalar `A` past `u`, `v`
    in each summand. -/
private theorem reassoc4 (A u P v Q : Real) :
    Req (Rmul A (Radd (Rmul u P) (Rmul v Q)))
        (Radd (Rmul u (Rmul A P)) (Rmul v (Rmul A Q))) :=
  Req_trans (Rmul_distrib A (Rmul u P) (Rmul v Q))
    (Radd_congr
      (Req_trans (Req_symm (Rmul_assoc A u P))
        (Req_trans (Rmul_congr (Rmul_comm A u) (Req_refl P)) (Rmul_assoc u A P)))
      (Req_trans (Req_symm (Rmul_assoc A v Q))
        (Req_trans (Rmul_congr (Rmul_comm A v) (Req_refl Q)) (Rmul_assoc v A Q))))

/-- **The 2D uniform Bernstein convergence bound**, multiplied form:
    `2δn · |B_n(F)(x,y) − F(x,y)| ≤ (Lx + Ly)·(δ² + n/4)` on `[0,1]²`, for a jointly-Lipschitz `F`
    (moduli `Lx, Ly`) and any `δ > 0`. The 2D pointwise deviation `bern2DVal_deviation` bounds the
    deviation by `Lx·(x-central-moment) + Ly·(y-central-moment)`; scaling by `2δn ≥ 0` and applying
    `bernOp_devsum_bound` in each variable bounds each moment sum by `δ² + n/4`; the two `Lx`/`Ly`
    coefficients then factor out. -/
theorem bern2DVal_devsum_bound (F : Real → Real → Real) (Lx Ly : Q)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num) (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hLip : ∀ a a' b b', Rle (Rabs (Rsub (F a b) (F a' b')))
      (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub a a'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub b b')))))
    (n : Nat) (hn : 0 < n) (x y : Real)
    (hx0 : Rle zero x) (hx1 : Rle x one) (hy0 : Rle zero y) (hy1 : Rle y one)
    (δ : Q) (hδd : 0 < δ.den) (hδn : 0 ≤ δ.num) :
    Rle (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (Rabs (Rsub (bern2DVal F n hn x y) (F x y))))
        (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
              (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
                (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide)))) := by
  have hA : Rnonneg (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos)) :=
    Rnonneg_ofQ _ (by
      show (0 : Int) ≤ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q)).num
      simp only [mul]
      exact Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (by omega))
  have hLxnn : Rnonneg (ofQ Lx hLxd) := Rnonneg_ofQ hLxd hLxn
  have hLynn : Rnonneg (ofQ Ly hLyd) := Rnonneg_ofQ hLyd hLyn
  have bd := bern2DVal_deviation F Lx Ly hLxd hLxn hLyd hLyn hLip n hn x y hx0 hx1 hy0 hy1
  have dbx := bernOp_devsum_bound n hn hx0 hx1 δ hδd
  have dby := bernOp_devsum_bound n hn hy0 hy1 δ hδd
  -- A·|B_n−F| ≤ A·(Lx·Sx + Ly·Sy) = Lx·(A·Sx) + Ly·(A·Sy) ≤ Lx·B + Ly·B = (Lx+Ly)·B
  refine Rle_trans (Rmul_le_Rmul_left hA bd) ?_
  refine Rle_trans (Rle_of_Req (reassoc4 _ (ofQ Lx hLxd) _ (ofQ Ly hLyd) _)) ?_
  refine Rle_trans (Radd_le_add (Rmul_le_Rmul_left hLxnn dbx) (Rmul_le_Rmul_left hLynn dby)) ?_
  exact Rle_of_Req (Req_symm (Rmul_distrib_right (ofQ Lx hLxd) (ofQ Ly hLyd) _))

end Multiplicity.UOR.Bridge.F1Square.Square
