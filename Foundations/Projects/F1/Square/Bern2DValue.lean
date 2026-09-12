/-
F1 square — **the 2D Bernstein list-fold ↔ pointwise-value agreement** (`Bern2DValue.lean`), the
transform bridge, Wall 3. This file connects the FINITE-RANK LIST representation `bern2DList` (the
`List (L2Test × L2Test)` of separable Bernstein terms, `Bern2DOperator.lean`) to the pointwise
double-sum value `bern2DVal` (`Bern2DDeviation.lean`), on the unit square `[0,1]²`.

Two pieces of purely combinatorial infrastructure:
  • a `flatMap`-of-`range`s fold ↔ iterated-`RsumN` correspondence, routed through `RsumL`
    (`foldr_to_RsumL`, `RsumL_map_range`, `RsumL_flatMap_range`): the fold of any grid-shaped list
    equals the iterated finite `RsumN` double sum;
  • the on-`[0,1]²` VALUE AGREEMENT (`bern2DList_eval_eq`): the fold of the pointwise products
    `Σ (φ.f x)·(ψ.f y)` over `bern2DList F … n hn` equals `bern2DVal F n hn x y`, because each
    clamped basis test agrees with the honest `bernR` on the unit interval
    (`bernBasisTest n k .f x ≈ bernR x n k`, via `natScale` scaling + `bernR_eq_scaled_clampProd`)
    and the real coefficient `F(i/n, j/n)` carried on the `constTest` factors out.

WHY (the transform bridge, Wall 3). To pass the general swap `∫_x∫_y F = ∫_y∫_x F` through the
uniform Bernstein limit one must know the finite-rank LIST integrand and the pointwise VALUE
`bern2DVal` are literally the same function on the square. This file is exactly that reconciliation:
it lets the list-side `finrank_fubini_swap` and the value-side `bern2DVal_deviation` be talked about
as one object. It builds NO integral, NO Fubini swap, NO convergence, and NO positivity.

HONEST SCOPE. The `flatMap`-double-sum correspondence and the on-`[0,1]²` integrand/value equality
connecting `bern2DList` to `bern2DVal`: general combinatorial/approximation infrastructure. No
integral, no swap, no positivity, no determinacy, no crux. Step 4 (band-coupling positivity) is RH;
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Bern2DOperator
import Foundations.F1.Square.Bern2DDeviation
import Foundations.F1.Square.BernsteinClampMatch
import Foundations.F1.Analysis.RAddNF

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

attribute [local irreducible] ratPt bernR

-- ===========================================================================
-- STEP A–C: the `flatMap`-of-`range`s fold ↔ iterated-`RsumN` correspondence.
-- ===========================================================================

/-- `Eq → Req`, so a definitional list rewrite can be spliced into a `Req` chain. -/
private theorem Req_of_eq {a b : Real} (h : a = b) : Req a b := h ▸ Req_refl a

/-- **STEP A — the additive fold is `RsumL` of the mapped list**: folding `Radd (g a) ·` over a list
    is exactly the `RsumL` of its image under `g`. -/
private theorem foldr_to_RsumL {α : Type} (g : α → Real) (l : List α) :
    List.foldr (fun a acc => Radd (g a) acc) zero l = RsumL (List.map g l) := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    rw [List.map_cons, RsumL_cons, List.foldr_cons, ih]

/-- **STEP B — `RsumL` of a mapped `range` is `RsumN`**: the last-element append of `List.range`
    matches the `RsumN` recursion exactly. -/
theorem RsumL_map_range (h : Nat → Real) (N : Nat) :
    Req (RsumL (List.map h (List.range N))) (RsumN h N) := by
  induction N with
  | zero => exact Req_refl _
  | succ N ih =>
    rw [List.range_succ, List.map_append]
    refine Req_trans (RsumL_append (List.map h (List.range N)) (List.map h [N])) ?_
    have hlast : Req (RsumL (List.map h [N])) (h N) := Radd_zero (h N)
    exact Radd_congr ih hlast

/-- **STEP C — `RsumL` of a `flatMap` over a `range` is the iterated `RsumN`**: the same clean
    last-element pattern, one dimension up. -/
theorem RsumL_flatMap_range (F : Nat → List Real) (N : Nat) :
    Req (RsumL ((List.range N).flatMap F)) (RsumN (fun i => RsumL (F i)) N) := by
  induction N with
  | zero => exact Req_refl _
  | succ N ih =>
    rw [List.range_succ, List.flatMap_append]
    refine Req_trans (RsumL_append ((List.range N).flatMap F) ([N].flatMap F)) ?_
    have hlast : Req (RsumL ([N].flatMap F)) (RsumL (F N)) :=
      Req_trans (RsumL_append (F N) []) (Radd_zero (RsumL (F N)))
    exact Radd_congr ih hlast

-- ===========================================================================
-- The `natScale` pointwise value: `(natScale k φ).f x ≈ k·(φ.f x)`.
-- ===========================================================================

-- `natScale` is `@[irreducible]`; re-derive its two defining equations as propositional `rfl`s so the
-- pointwise-value recursion can proceed without forcing the seal.
unseal natScale in
private theorem natScale_zero_e (φ : L2Test) : natScale 0 φ = zeroL2 := rfl

unseal natScale in
private theorem natScale_succ_e (k : Nat) (φ : L2Test) :
    natScale (k + 1) φ = L2Test.add φ (natScale k φ) := rfl

/-- Pointwise value of the integer-scaled test: `(natScale k φ).f x ≈ (RofNat k)·(φ.f x)`. -/
private theorem natScale_f (φ : L2Test) (x : Real) (k : Nat) :
    Req ((natScale k φ).f x) (Rmul (RofNat k) (φ.f x)) := by
  induction k with
  | zero =>
    rw [natScale_zero_e]
    show Req zero (Rmul (RofNat 0) (φ.f x))
    have h0 : Req (RofNat 0) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
    refine Req_symm ?_
    refine Req_trans (Rmul_congr h0 (Req_refl _)) ?_
    exact Req_trans (Rmul_comm zero (φ.f x)) (Rmul_zero (φ.f x))
  | succ k ih =>
    have hz1 : Req (RofNat 1) one := Req_of_seq_Qeq (fun _ => Qeq_refl _)
    rw [natScale_succ_e]
    show Req (Radd (φ.f x) ((natScale k φ).f x)) (Rmul (RofNat (k + 1)) (φ.f x))
    refine Req_trans (Radd_congr (Req_refl _) ih) ?_
    refine Req_symm ?_
    refine Req_trans (Rmul_congr (RofNat_add k 1) (Req_refl _)) ?_
    refine Req_trans (Rmul_congr (Radd_congr (Req_refl _) hz1) (Req_refl _)) ?_
    refine Req_trans (Rmul_distrib_right (RofNat k) one (φ.f x)) ?_
    refine Req_trans (Radd_congr (Req_refl _) (Rone_mul (φ.f x))) ?_
    exact Radd_comm (Rmul (RofNat k) (φ.f x)) (φ.f x)

/-- The clamped Bernstein basis test agrees with the honest `bernR` on `[0,1]`:
    `(bernBasisTest n k).f x ≈ bernR x n k`. Combine the `natScale` value law with
    `bernR_eq_scaled_clampProd`. -/
theorem bernBasisTest_f_eq_bernR (n k : Nat) {x : Real} (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((bernBasisTest n k).f x) (bernR x n k) :=
  Req_trans (natScale_f (clampProdTest k (n - k)) x (choose n k))
    (Req_symm (bernR_eq_scaled_clampProd n k h0 h1))

-- ===========================================================================
-- STEP D: the on-[0,1]² value agreement.
-- ===========================================================================

/-- **THE INTEGRAND / VALUE AGREEMENT on `[0,1]²`**: the additive fold of the pointwise separable
    products `(φ.f x)·(ψ.f y)` over `bern2DList F … n hn` equals the pointwise Bernstein value
    `bern2DVal F n hn x y`. Routes the fold through `RsumL`, converts the `flatMap`-of-`range`s to the
    iterated `RsumN` (Steps A–C), then matches each grid term: the `constTest` coefficient factors
    out and each clamped basis test agrees with `bernR` on the unit interval. -/
theorem bern2DList_eval_eq (F : Real → Real → Real) (BF : Q) (hBFd : 0 < BF.den)
    (hBFn : 0 ≤ BF.num) (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) (n : Nat) (hn : 0 < n)
    (x y : Real) (hx0 : Rle zero x) (hx1 : Rle x one) (hy0 : Rle zero y) (hy1 : Rle y one) :
    Req (List.foldr (fun p acc => Radd (Rmul ((p.1).f x) ((p.2).f y)) acc) zero
          (bern2DList F BF hBFd hBFn hFbd n hn))
        (bern2DVal F n hn x y) := by
  -- STEP A: the fold is `RsumL` of the mapped list.
  refine Req_trans (Req_of_eq (foldr_to_RsumL (fun p => Rmul ((p.1).f x) ((p.2).f y))
    (bern2DList F BF hBFd hBFn hFbd n hn))) ?_
  -- Reduce `map _ bern2DList` to the grid of scalar terms (map/flatMap fusion + defeq).
  have hlist : List.map (fun p => Rmul ((p.1).f x) ((p.2).f y))
        (bern2DList F BF hBFd hBFn hFbd n hn)
      = (List.range (n + 1)).flatMap (fun i =>
          (List.range (n + 1)).map (fun j =>
            Rmul (Rmul (F (ratPt i n hn) (ratPt j n hn)) ((bernBasisTest n i).f x))
                 ((bernBasisTest n j).f y))) := by
    unfold bern2DList
    rw [List.map_flatMap]
    simp only [List.map_map]
    rfl
  rw [hlist]
  -- STEP C: `RsumL` of the `flatMap` is the outer `RsumN`.
  refine Req_trans (RsumL_flatMap_range (fun i =>
    (List.range (n + 1)).map (fun j =>
      Rmul (Rmul (F (ratPt i n hn) (ratPt j n hn)) ((bernBasisTest n i).f x))
           ((bernBasisTest n j).f y))) (n + 1)) ?_
  rw [bern2DVal_unfold]
  refine RsumN_congr (n + 1) (fun i _ => ?_)
  -- STEP B: `RsumL` of the inner mapped `range` is the inner `RsumN`.
  refine Req_trans (RsumL_map_range (fun j =>
    Rmul (Rmul (F (ratPt i n hn) (ratPt j n hn)) ((bernBasisTest n i).f x))
         ((bernBasisTest n j).f y)) (n + 1)) ?_
  refine RsumN_congr (n + 1) (fun j _ => ?_)
  -- Per grid term: factor out the coefficient and match each basis test with `bernR`.
  have hbx : Req ((bernBasisTest n i).f x) (bernR x n i) :=
    bernBasisTest_f_eq_bernR n i hx0 hx1
  have hby : Req ((bernBasisTest n j).f y) (bernR y n j) :=
    bernBasisTest_f_eq_bernR n j hy0 hy1
  refine Req_trans (Rmul_congr (Rmul_congr (Req_refl _) hbx) hby) ?_
  exact Rmul_assoc (F (ratPt i n hn) (ratPt j n hn)) (bernR x n i) (bernR y n j)

end Multiplicity.UOR.Bridge.F1Square.Square
