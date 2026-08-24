/-
F1 square — **the 2D pointwise Bernstein deviation bound** (`Bern2DDeviation.lean`), the Bernstein arc
extended to two variables. On a jointly-Lipschitz `F : Real → Real → Real` (moduli `Lx`, `Ly`), the
pointwise 2D Bernstein approximant `B_n(F)(x,y) = Σ_{i,j} F(i/n, j/n)·b_{n,i}(x)·b_{n,j}(y)`
(`bern2DVal`, `n ≥ 1`) is within the sum of the two first absolute central moments of `F`:

    `|B_n(F)(x,y) − F(x,y)| ≤ Lx·Σ_i |i/n − x|·b_{n,i}(x) + Ly·Σ_j |j/n − y|·b_{n,j}(y)`
    (`bern2DVal_deviation`, on `[0,1]²`).

WHY. Pure double-sum bookkeeping mirroring the 1D `bernOp_deviation`: `F(x,y) = F(x,y)·(Σ_i b_i(x))·
(Σ_j b_j(y))` (double partition of unity), so `B_n(F) − F(x,y) = Σ_{i,j}(F(i/n,j/n) − F(x,y))·
b_i(x)·b_j(y)`; the finite triangle inequality (`RsumN_Rabs_le`, basis `≥ 0`) and the joint Lipschitz
modulus `|F(i/n,j/n) − F(x,y)| ≤ Lx|i/n − x| + Ly|j/n − y|` bound the double sum, which then factors
(the transverse partition of unity summing to `1` in each slot).

HONEST SCOPE. The pure pointwise 2D Bernstein deviation for a jointly-Lipschitz `F`: general
approximation theory only. NO positivity, NO moment-integral, NO determinacy, NO inversion, NO crux.
Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.Bernstein
import Multiplicity.F1.Square.BernsteinConverge
import Multiplicity.F1.Square.BernsteinDeviation

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

attribute [local irreducible] ratPt bernR

/-- The **pointwise 2D Bernstein approximant**
    `B_n(F)(x,y) = Σ_{i,j} F(i/n, j/n)·b_{n,i}(x)·b_{n,j}(y)` (for `n ≥ 1`). -/
def bern2DVal (F : Real → Real → Real) (n : Nat) (hn : 0 < n) (x y : Real) : Real :=
  RsumN (fun i => RsumN (fun j =>
    Rmul (F (ratPt i n hn) (ratPt j n hn)) (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1)

/-- Unfolding equation for `bern2DVal` — rewrite before matching so the sealed `ratPt`/`bernR` are
    never re-exposed to unification. -/
theorem bern2DVal_unfold (F : Real → Real → Real) (n : Nat) (hn : 0 < n) (x y : Real) :
    bern2DVal F n hn x y =
      RsumN (fun i => RsumN (fun j =>
        Rmul (F (ratPt i n hn) (ratPt j n hn)) (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1) :=
  rfl

set_option maxHeartbeats 1600000 in
theorem bern2DVal_deviation (F : Real → Real → Real) (Lx Ly : Q)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num) (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hLip : ∀ a a' b b', Rle (Rabs (Rsub (F a b) (F a' b')))
      (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub a a'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub b b')))))
    (n : Nat) (hn : 0 < n) (x y : Real)
    (hx0 : Rle zero x) (hx1 : Rle x one) (hy0 : Rle zero y) (hy1 : Rle y one) :
    Rle (Rabs (Rsub (bern2DVal F n hn x y) (F x y)))
        (Radd (Rmul (ofQ Lx hLxd)
                    (RsumN (fun i => Rmul (Rabs (Rsub (ratPt i n hn) x)) (bernR x n i)) (n + 1)))
              (Rmul (ofQ Ly hLyd)
                    (RsumN (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1)))) := by
  have hx : Rnonneg x := Rnonneg_of_Rle_zero hx0
  have h1x : Rnonneg (Rsub one x) := Rnonneg_Rsub_of_Rle hx1
  have hy : Rnonneg y := Rnonneg_of_Rle_zero hy0
  have h1y : Rnonneg (Rsub one y) := Rnonneg_Rsub_of_Rle hy1
  -- STEP 1: `F x y` as the constant double sum.
  have hfxy : Req (F x y)
      (RsumN (fun i => RsumN (fun j =>
        Rmul (F x y) (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1)) := by
    refine Req_trans (Req_symm (Rmul_one (F x y))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (Req_symm (bernR_partition x n))) ?_
    refine Req_trans (Req_symm (RsumN_Rmul_const (F x y) (bernR x n) (n + 1))) ?_
    refine RsumN_congr (n + 1) (fun i _ => ?_)
    refine Req_trans (Rmul_congr (Req_refl _) (Req_symm (Rmul_one (bernR x n i)))) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_congr (Req_refl _) (Req_symm (bernR_partition y n)))) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Req_symm (RsumN_Rmul_const (bernR x n i) (bernR y n) (n + 1)))) ?_
    exact Req_symm (RsumN_Rmul_const (F x y) (fun j => Rmul (bernR x n i) (bernR y n j)) (n + 1))
  -- STEP 2: the difference is the double sum of the deviations.
  have hdiff : Req (Rsub (bern2DVal F n hn x y) (F x y))
      (RsumN (fun i => RsumN (fun j =>
        Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1)) := by
    rw [bern2DVal_unfold]
    refine Req_trans (Rsub_congr (Req_refl _) hfxy) ?_
    refine Req_trans (Req_symm (RsumN_Rsub
      (fun i => RsumN (fun j =>
        Rmul (F (ratPt i n hn) (ratPt j n hn)) (Rmul (bernR x n i) (bernR y n j))) (n + 1))
      (fun i => RsumN (fun j =>
        Rmul (F x y) (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))) ?_
    refine RsumN_congr (n + 1) (fun i _ => ?_)
    refine Req_trans (Req_symm (RsumN_Rsub
      (fun j => Rmul (F (ratPt i n hn) (ratPt j n hn)) (Rmul (bernR x n i) (bernR y n j)))
      (fun j => Rmul (F x y) (Rmul (bernR x n i) (bernR y n j))) (n + 1))) ?_
    refine RsumN_congr (n + 1) (fun j _ => ?_)
    exact Req_symm (Rmul_sub_distrib_right (F (ratPt i n hn) (ratPt j n hn)) (F x y)
      (Rmul (bernR x n i) (bernR y n j)))
  -- STEP 3: triangle inequality, outer then inner.
  have s1 : Rle (Rabs (Rsub (bern2DVal F n hn x y) (F x y)))
      (RsumN (fun i => Rabs (RsumN (fun j =>
        Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1))) (n + 1)) :=
    Rle_trans (Rle_of_Req (Rabs_congr hdiff))
      (RsumN_Rabs_le (fun i => RsumN (fun j =>
        Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))
  have s2 : Rle
      (RsumN (fun i => Rabs (RsumN (fun j =>
        Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1))) (n + 1))
      (RsumN (fun i => RsumN (fun j =>
        Rabs (Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
                   (Rmul (bernR x n i) (bernR y n j)))) (n + 1)) (n + 1)) :=
    RsumN_le (n + 1) (fun i _ => RsumN_Rabs_le
      (fun j => Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
                     (Rmul (bernR x n i) (bernR y n j))) (n + 1))
  -- STEP 4: per-term joint-Lipschitz bound.
  have per_term : ∀ i, i < n + 1 → ∀ j, j < n + 1 →
      Rle (Rabs (Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
                      (Rmul (bernR x n i) (bernR y n j))))
          (Rmul (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                      (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))))
                (Rmul (bernR x n i) (bernR y n j))) := by
    intro i _ j _
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
      (Rabs_of_nonneg (Rnonneg_Rmul (bernR_nonneg x hx h1x n i) (bernR_nonneg y hy h1y n j))))) ?_
    exact Rmul_le_Rmul_right
      (Rnonneg_Rmul (bernR_nonneg x hx h1x n i) (bernR_nonneg y hy h1y n j))
      (hLip (ratPt i n hn) x (ratPt j n hn) y)
  have s3 : Rle
      (RsumN (fun i => RsumN (fun j =>
        Rabs (Rmul (Rsub (F (ratPt i n hn) (ratPt j n hn)) (F x y))
                   (Rmul (bernR x n i) (bernR y n j)))) (n + 1)) (n + 1))
      (RsumN (fun i => RsumN (fun j =>
        Rmul (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                   (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1)) :=
    RsumN_le (n + 1) (fun i hi => RsumN_le (n + 1) (fun j hj => per_term i hi j hj))
  -- STEP 5: split the bounding double sum into the `Lx`-part and the `Ly`-part.
  have eqSplit : Req
      (RsumN (fun i => RsumN (fun j =>
        Rmul (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                   (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))
      (Radd
        (RsumN (fun i => RsumN (fun j =>
          Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
               (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))
        (RsumN (fun i => RsumN (fun j =>
          Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
               (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))) := by
    have inner : ∀ i, Req
        (RsumN (fun j =>
          Rmul (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                     (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))))
               (Rmul (bernR x n i) (bernR y n j))) (n + 1))
        (Radd
          (RsumN (fun j => Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                                (Rmul (bernR x n i) (bernR y n j))) (n + 1))
          (RsumN (fun j => Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
                                (Rmul (bernR x n i) (bernR y n j))) (n + 1))) := by
      intro i
      refine Req_trans (RsumN_congr (n + 1) (fun j _ => Rmul_distrib_right
        (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
        (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
        (Rmul (bernR x n i) (bernR y n j)))) ?_
      exact RsumN_Radd
        (fun j => Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                       (Rmul (bernR x n i) (bernR y n j)))
        (fun j => Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
                       (Rmul (bernR x n i) (bernR y n j))) (n + 1)
    refine Req_trans (RsumN_congr (n + 1) (fun i _ => inner i)) ?_
    exact RsumN_Radd
      (fun i => RsumN (fun j =>
        Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1))
      (fun i => RsumN (fun j =>
        Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1)
  -- The `Lx`-part factors as `Lx·Σ_i |i/n − x|·b_i(x)` (the transverse `Σ_j b_j(y) = 1`).
  have eqTermX : Req
      (RsumN (fun i => RsumN (fun j =>
        Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))
      (Rmul (ofQ Lx hLxd)
        (RsumN (fun i => Rmul (Rabs (Rsub (ratPt i n hn) x)) (bernR x n i)) (n + 1))) := by
    have inner : ∀ i, Req
        (RsumN (fun j =>
          Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
               (Rmul (bernR x n i) (bernR y n j))) (n + 1))
        (Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x))) (bernR x n i)) := by
      intro i
      refine Req_trans (RsumN_congr (n + 1) (fun j _ => Req_symm
        (Rmul_assoc (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
          (bernR x n i) (bernR y n j)))) ?_
      refine Req_trans (RsumN_Rmul_const
        (Rmul (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x))) (bernR x n i))
        (bernR y n) (n + 1)) ?_
      refine Req_trans (Rmul_congr (Req_refl _) (bernR_partition y n)) ?_
      exact Rmul_one _
    refine Req_trans (RsumN_congr (n + 1) (fun i _ => inner i)) ?_
    refine Req_trans (RsumN_congr (n + 1) (fun i _ =>
      Rmul_assoc (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)) (bernR x n i))) ?_
    exact RsumN_Rmul_const (ofQ Lx hLxd)
      (fun i => Rmul (Rabs (Rsub (ratPt i n hn) x)) (bernR x n i)) (n + 1)
  -- The `Ly`-part factors as `Ly·Σ_j |j/n − y|·b_j(y)` (the transverse `Σ_i b_i(x) = 1`).
  have eqTermY : Req
      (RsumN (fun i => RsumN (fun j =>
        Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))
      (Rmul (ofQ Ly hLyd)
        (RsumN (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1))) := by
    have inner : ∀ i, Req
        (RsumN (fun j =>
          Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
               (Rmul (bernR x n i) (bernR y n j))) (n + 1))
        (Rmul (bernR x n i)
          (Rmul (ofQ Ly hLyd)
            (RsumN (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1)))) := by
      intro i
      have innerj : ∀ j, Req
          (Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)))
                (Rmul (bernR x n i) (bernR y n j)))
          (Rmul (bernR x n i)
                (Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))) (bernR y n j))) := by
        intro j
        refine Req_trans (Req_symm (Rmul_assoc
          (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))) (bernR x n i) (bernR y n j))) ?_
        refine Req_trans (Rmul_congr
          (Rmul_comm (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))) (bernR x n i))
          (Req_refl _)) ?_
        exact Rmul_assoc (bernR x n i)
          (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))) (bernR y n j)
      refine Req_trans (RsumN_congr (n + 1) (fun j _ => innerj j)) ?_
      refine Req_trans (RsumN_Rmul_const (bernR x n i)
        (fun j => Rmul (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))) (bernR y n j))
        (n + 1)) ?_
      refine Rmul_congr (Req_refl _) ?_
      refine Req_trans (RsumN_congr (n + 1) (fun j _ =>
        Rmul_assoc (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j))) ?_
      exact RsumN_Rmul_const (ofQ Ly hLyd)
        (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1)
    refine Req_trans (RsumN_congr (n + 1) (fun i _ => inner i)) ?_
    refine Req_trans (RsumN_congr (n + 1) (fun i _ => Rmul_comm (bernR x n i)
      (Rmul (ofQ Ly hLyd)
        (RsumN (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1))))) ?_
    refine Req_trans (RsumN_Rmul_const
      (Rmul (ofQ Ly hLyd)
        (RsumN (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1)))
      (bernR x n) (n + 1)) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (bernR_partition x n)) ?_
    exact Rmul_one _
  -- Assemble.
  have eqBound : Req
      (RsumN (fun i => RsumN (fun j =>
        Rmul (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub (ratPt i n hn) x)))
                   (Rmul (ofQ Ly hLyd) (Rabs (Rsub (ratPt j n hn) y))))
             (Rmul (bernR x n i) (bernR y n j))) (n + 1)) (n + 1))
      (Radd (Rmul (ofQ Lx hLxd)
                  (RsumN (fun i => Rmul (Rabs (Rsub (ratPt i n hn) x)) (bernR x n i)) (n + 1)))
            (Rmul (ofQ Ly hLyd)
                  (RsumN (fun j => Rmul (Rabs (Rsub (ratPt j n hn) y)) (bernR y n j)) (n + 1)))) :=
    Req_trans eqSplit (Radd_congr eqTermX eqTermY)
  exact Rle_trans s1 (Rle_trans s2 (Rle_trans s3 (Rle_of_Req eqBound)))

end Multiplicity.UOR.Bridge.F1Square.Square
