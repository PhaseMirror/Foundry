/-
F1 square — **the finite-rank symmetry of the 2D Bernstein test** (`Bern2DFinrankSymm.lean`), the
transform bridge, Wall 3 (Move 2 of the general Fubini swap). On the unit square `[0,1]²`, the outer
`x`-integral of the finite-rank 2D Bernstein inner test for a jointly-bounded `F` equals that for the
TRANSPOSED `F` (`G a b := F b a`):

    `∫_x ∫_y B_n(F) dy dx  ≈  ∫_x ∫_y B_n(Fᵀ) dy dx`   (`bern2D_finrank_symm`).

This is a DISCRETE FUBINI: `finrank_fubini` turns each side into a fold over the separable list of
products `(∫_x φₖ)·(∫_y ψₖ)`; each fold becomes an iterated finite `RsumN` double sum over the
`(n+1)×(n+1)` Bernstein grid (mirroring `bern2DList_eval_eq`, with `riemannIntegralI_constTestMul`
factoring the constant coefficient `F(i/n,j/n)` out of the inner integral); the two grids are then
reconciled by the finite-sum swap `RsumN_swap` (the discrete-Fubini substrate from `Square/SelfAdjoint.lean`,
mirroring the rational `Fsum_swap`) plus commutativity of `Rmul` on each `(∫bᵢ)·(∫bⱼ)` pair.

WHY (the transform bridge, Wall 3). The general swap `∫_x∫_y F = ∫_y∫_x F` is reached through the
finite-rank Bernstein rung, whose swap is `finrank_fubini_swap`; this file supplies the companion
`Sₙ(F) = Sₙ(Fᵀ)` grid symmetry needed to relate the two orders once the axes are transposed. NO
continuous Fubini swap is performed — the outer `x`-integral is taken once on each side; the equality
is between two finite-rank objects. NO limit, NO convergence, NO positivity.

HONEST SCOPE. The finite-rank symmetry `Sₙ(F) = Sₙ(Fᵀ)` as a discrete Fubini on the `(n+1)×(n+1)`
Bernstein grid: a finite-sum combinatorial identity (`RsumN` swap + `Rmul` commutativity). No
continuous Fubini swap, no limit, no convergence, no positivity, no determinacy, no crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Bern2DOperator
import Foundations.F1.Square.Bern2DInnerClose
import Foundations.F1.Square.SelfAdjoint
import Foundations.F1.Square.WeilPSD

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

attribute [local irreducible] ratPt

-- ===========================================================================
-- Local fold ↔ `RsumL` bridge (private copies re-derived from `Bern2DValue`).
-- `RsumN_add` (from `Square/WeilPSD.lean`) and `RsumN_swap` (from `Square/SelfAdjoint.lean`) — the
-- reusable discrete-Fubini substrate — already exist in this namespace and are reused directly.
-- ===========================================================================

/-- `Eq → Req`, so a definitional list rewrite can be spliced into a `Req` chain. -/
private theorem Req_of_eq {a b : Real} (h : a = b) : Req a b := h ▸ Req_refl a

/-- The additive fold is `RsumL` of the mapped list. -/
private theorem foldr_to_RsumL {α : Type} (g : α → Real) (l : List α) :
    List.foldr (fun a acc => Radd (g a) acc) zero l = RsumL (List.map g l) := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    rw [List.map_cons, RsumL_cons, List.foldr_cons, ih]

/-- Pull `Rmul` associativity + commutativity through the middle factor:
    `(c·X)·Y ≈ (c·Y)·X`. -/
private theorem Rmul_pair_swap (c X Y : Real) :
    Req (Rmul (Rmul c X) Y) (Rmul (Rmul c Y) X) :=
  Req_trans (Rmul_assoc c X Y)
    (Req_trans (Rmul_congr (Req_refl c) (Rmul_comm X Y)) (Req_symm (Rmul_assoc c Y X)))

-- ===========================================================================
-- The finite-rank Fubini fold as an iterated `RsumN` over the Bernstein grid.
-- ===========================================================================

/-- **The finite-rank Fubini fold as a double sum** (on `[0,1]²`): the fold of the separable products
    `(∫_x φₖ)·(∫_y ψₖ)` over `bern2DList Fn … n hn` equals the iterated `RsumN` double sum whose
    `(i,j)` term is `Fn(i/n,j/n)·(∫_x bᵢ)·(∫_y bⱼ)`. Mirrors `bern2DList_eval_eq`: routes the fold
    through `RsumL`, converts the `flatMap`-of-`range`s to the iterated `RsumN`, then factors each
    constant coefficient out of the inner integral by `riemannIntegralI_constTestMul`. -/
private theorem foldFubini_eval (Fn : Real → Real → Real) (BF : Q) (hBFd : 0 < BF.den)
    (hBFn : 0 ≤ BF.num) (hFn : ∀ a b, Rle (Rabs (Fn a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n)
    (hx0 : 0 < (⟨0, 1⟩ : Q).den) (hx1 : 0 < (⟨1, 1⟩ : Q).den) (hx2 : 0 ≤ (⟨1, 1⟩ : Q).num)
    (hy0 : 0 < (⟨0, 1⟩ : Q).den) (hy1 : 0 < (⟨1, 1⟩ : Q).den) (hy2 : 0 ≤ (⟨1, 1⟩ : Q).num) :
    Req (List.foldr (fun p acc => Radd
          (Rmul (riemannIntegralI p.1.hLd p.1.hLn p.1.hlip p.1.hfc ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
                (riemannIntegralI p.2.hLd p.2.hLn p.2.hlip p.2.hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2)) acc)
          zero (bern2DList Fn BF hBFd hBFn hFn n hn))
        (RsumN (fun i => RsumN (fun j =>
          Rmul (Rmul (Fn (ratPt i n hn) (ratPt j n hn))
                     (riemannIntegralI (bernBasisTest n i).hLd (bernBasisTest n i).hLn
                       (bernBasisTest n i).hlip (bernBasisTest n i).hfc ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2))
                (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
                  (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))
          (n + 1)) (n + 1)) := by
  -- The fold is `RsumL` of the mapped list.
  refine Req_trans (Req_of_eq (foldr_to_RsumL
    (fun p => Rmul (riemannIntegralI p.1.hLd p.1.hLn p.1.hlip p.1.hfc ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
                   (riemannIntegralI p.2.hLd p.2.hLn p.2.hlip p.2.hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))
    (bern2DList Fn BF hBFd hBFn hFn n hn))) ?_
  -- Reduce `map _ bern2DList` to the grid of scalar products (map/flatMap fusion + defeq).
  have hlist : List.map
        (fun p => Rmul (riemannIntegralI p.1.hLd p.1.hLn p.1.hlip p.1.hfc ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
                       (riemannIntegralI p.2.hLd p.2.hLn p.2.hlip p.2.hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))
        (bern2DList Fn BF hBFd hBFn hFn n hn)
      = (List.range (n + 1)).flatMap (fun i =>
          (List.range (n + 1)).map (fun j =>
            Rmul (riemannIntegralI
                    (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                        (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hLd
                    (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                        (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hLn
                    (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                        (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hlip
                    (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                        (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hfc
                    ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
                 (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
                    (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))) := by
    unfold bern2DList
    rw [List.map_flatMap]
    simp only [List.map_map]
    rfl
  rw [hlist]
  -- `RsumL` of the `flatMap` is the outer `RsumN`.
  refine Req_trans (RsumL_flatMap_range (fun i =>
    (List.range (n + 1)).map (fun j =>
      Rmul (riemannIntegralI
              (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                  (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hLd
              (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                  (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hLn
              (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                  (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hlip
              (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                  (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hfc
              ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
           (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
              (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))) (n + 1)) ?_
  refine RsumN_congr (n + 1) (fun i _ => ?_)
  -- `RsumL` of the inner mapped `range` is the inner `RsumN`.
  refine Req_trans (RsumL_map_range (fun j =>
    Rmul (riemannIntegralI
            (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hLd
            (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hLn
            (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hlip
            (L2Test.mul (constTest (Fn (ratPt i n hn) (ratPt j n hn)) BF hBFd hBFn
                (hFn (ratPt i n hn) (ratPt j n hn))) (bernBasisTest n i)).hfc
            ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
         (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
            (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2)) (n + 1)) ?_
  refine RsumN_congr (n + 1) (fun j _ => ?_)
  -- Factor the constant coefficient out of the inner `x`-integral.
  exact Rmul_congr
    (riemannIntegralI_constTestMul (Fn (ratPt i n hn) (ratPt j n hn)) hBFd hBFn
      (hFn (ratPt i n hn) (ratPt j n hn)) (bernBasisTest n i) ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
    (Req_refl (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
      (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))

-- ===========================================================================
-- The finite-rank symmetry: `Sₙ(F) = Sₙ(Fᵀ)`.
-- ===========================================================================

/-- **The finite-rank Bernstein symmetry** (discrete Fubini, Move 2 of the general swap): on the unit
    square `[0,1]²`, the outer `x`-integral of the finite-rank 2D Bernstein inner test for `F` equals
    that for the transposed `F` (`G a b := F b a`). `finrank_fubini` on both sides turns each into a
    fold over the separable list; `foldFubini_eval` rewrites each fold as the iterated `RsumN` double
    sum with the coefficient factored out; `RsumN_swap` (discrete Fubini) plus `Rmul_pair_swap`
    (commutativity of the two basis-integrals) reconcile the two grids. No continuous swap, no limit,
    no positivity; the crux fields stay `none`. -/
theorem bern2D_finrank_symm (F : Real → Real → Real) (BF : Q) (hBFd : 0 < BF.den)
    (hBFn : 0 ≤ BF.num) (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n)
    (hx0 : 0 < (⟨0, 1⟩ : Q).den) (hx1 : 0 < (⟨1, 1⟩ : Q).den) (hx2 : 0 ≤ (⟨1, 1⟩ : Q).num)
    (hy0 : 0 < (⟨0, 1⟩ : Q).den) (hy1 : 0 < (⟨1, 1⟩ : Q).den) (hy2 : 0 ≤ (⟨1, 1⟩ : Q).num) :
    Req (riemannIntegralI
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hLd
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hLn
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hlip
          (sumProdTest (bern2DList F BF hBFd hBFn hFbd n hn) ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hfc
          ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
        (riemannIntegralI
          (sumProdTest (bern2DList (fun a b => F b a) BF hBFd hBFn (fun a b => hFbd b a) n hn)
            ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hLd
          (sumProdTest (bern2DList (fun a b => F b a) BF hBFd hBFn (fun a b => hFbd b a) n hn)
            ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hLn
          (sumProdTest (bern2DList (fun a b => F b a) BF hBFd hBFn (fun a b => hFbd b a) n hn)
            ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hlip
          (sumProdTest (bern2DList (fun a b => F b a) BF hBFd hBFn (fun a b => hFbd b a) n hn)
            ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2).hfc
          ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2) := by
  -- STEP 1: turn each side into the finite-rank Fubini fold of separable products.
  refine Req_trans
    (finrank_fubini (bern2DList F BF hBFd hBFn hFbd n hn) ⟨0, 1⟩ ⟨1, 1⟩ ⟨0, 1⟩ ⟨1, 1⟩
      hx0 hx1 hx2 hy0 hy1 hy2)
    (Req_trans ?_
      (Req_symm (finrank_fubini
        (bern2DList (fun a b => F b a) BF hBFd hBFn (fun a b => hFbd b a) n hn)
        ⟨0, 1⟩ ⟨1, 1⟩ ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2 hy0 hy1 hy2)))
  -- STEP 2: both folds become iterated `RsumN` double sums over the grid.
  refine Req_trans (foldFubini_eval F BF hBFd hBFn hFbd n hn hx0 hx1 hx2 hy0 hy1 hy2)
    (Req_trans ?_
      (Req_symm (foldFubini_eval (fun a b => F b a) BF hBFd hBFn (fun a b => hFbd b a) n hn
        hx0 hx1 hx2 hy0 hy1 hy2)))
  -- STEP 3: discrete Fubini + `Rmul` commutativity reconcile the two grids.
  refine Req_trans ?_
    (RsumN_swap (fun i j =>
      Rmul (Rmul (F (ratPt i n hn) (ratPt j n hn))
              (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
                (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2))
           (riemannIntegralI (bernBasisTest n i).hLd (bernBasisTest n i).hLn
             (bernBasisTest n i).hlip (bernBasisTest n i).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2))
      (n + 1) (n + 1))
  refine RsumN_congr (n + 1) (fun i _ => ?_)
  refine RsumN_congr (n + 1) (fun j _ => ?_)
  exact Rmul_pair_swap (F (ratPt i n hn) (ratPt j n hn))
    (riemannIntegralI (bernBasisTest n i).hLd (bernBasisTest n i).hLn
      (bernBasisTest n i).hlip (bernBasisTest n i).hfc ⟨0, 1⟩ ⟨1, 1⟩ hx0 hx1 hx2)
    (riemannIntegralI (bernBasisTest n j).hLd (bernBasisTest n j).hLn
      (bernBasisTest n j).hlip (bernBasisTest n j).hfc ⟨0, 1⟩ ⟨1, 1⟩ hy0 hy1 hy2)

end Multiplicity.UOR.Bridge.F1Square.Square
