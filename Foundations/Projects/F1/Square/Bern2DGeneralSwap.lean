/-
F1 square — **the general Fubini swap** (`Bern2DGeneralSwap.lean`), the transform bridge, Wall 3
(Move 3, the capstone of the 2D-Bernstein route). For a jointly-Lipschitz `F` on the unit square, the
two iterated double integrals are EQUAL:

    `∫₀¹ ∫₀¹ F(x,y) dy dx  =  ∫₀¹ ∫₀¹ F(x,y) dx dy`   (`bern2D_general_swap`).

The statement has NO `δ` and NO `n` — the Bernstein schedule (`δ = k+1`, `n = (k+1)²`) lives ONLY inside
the proof. Per schedule `k`: `bern2D_outer_close` at `F` bounds `2δn·|∫ₓ∫ᵧF − ∫ₓ Sₙ(F)|` by
`(Lx+Ly)·(δ²+n/4)`; the same at the transpose `G a b := F b a` bounds `2δn·|∫ᵧ∫ₓF − ∫ₓ Sₙ(G)|`;
`bern2D_finrank_symm` gives `Sₙ(F) = Sₙ(G)`, so the two Bernstein anchors coincide. A triangle through
that common anchor, scaled by `2δn ≥ 0` and divided out (`Rle_of_Rmul_ofQ_le`), yields
`|∫ₓ∫ᵧF − ∫ᵧ∫ₓF| ≤ (5/4)(Lx+Ly)/(k+1)`, and the real Archimedean squeeze (`Req_of_Rle_ofQ_all`)
closes the equality.

WHY (the transform bridge, Wall 3). The swap is performed HONESTLY via uniform Bernstein
approximation: the finite-rank Bernstein value enters ONLY as the intermediate anchor `Sₙ(F)/Sₙ(G)`
that both genuine iterated integrals are bounded against; the schedule kills the gap. The equality is
between the two GENUINE iterated integrals of `F`, NOT Bernstein values. NO closeness/limit/swap
hypothesis is assumed — only `F` joint-continuity + joint-Lipschitz + bound. NO positivity, NO crux.

HONEST SCOPE. The general Fubini swap `∫ₓ∫ᵧF = ∫ᵧ∫ₓF` for a jointly-Lipschitz `F` on the unit square,
proved via uniform 2D Bernstein approximation and the schedule limit — an analysis theorem. No
positivity, no determinacy, no crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Bern2DOuterClose
import Foundations.F1.Square.Bern2DFinrankSymm
import Foundations.F1.Square.MomentDeterminacy
import Foundations.F1.Analysis.ComplexZeta
import Foundations.F1.Analysis.Pi

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The abstract per-schedule triangle** (Move 3 core, axis-free). Given a common scale `q2 ≥ 0`, a
    common Bernstein anchor `M`, and the two anchored deviations `q2·|A−M| ≤ Cq`, `q2·|B−M| ≤ Cq`, the
    scaled deviation of `A` from `B` is bounded by `2·Cq`. Triangle `A−B` through `M`, scale by `q2`,
    distribute, and add the two halves. No positivity, no crux. -/
private theorem swap_perk_bound (q2 Cq : Q) (hq2d : 0 < q2.den) (hq2n : 0 ≤ q2.num)
    (hCqd : 0 < Cq.den) {A B M : Real}
    (hP : Rle (Rmul (ofQ q2 hq2d) (Rabs (Rsub A M))) (ofQ Cq hCqd))
    (hQ : Rle (Rmul (ofQ q2 hq2d) (Rabs (Rsub B M))) (ofQ Cq hCqd)) :
    Rle (Rmul (ofQ q2 hq2d) (Rabs (Rsub A B))) (ofQ (add Cq Cq) (add_den_pos hCqd hCqd)) := by
  have tri : Rle (Rabs (Rsub A B)) (Radd (Rabs (Rsub A M)) (Rabs (Rsub M B))) :=
    Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rsub_telescope A M B))))
      (Rabs_Radd (Rsub A M) (Rsub M B))
  have scaled : Rle (Rmul (ofQ q2 hq2d) (Rabs (Rsub A B)))
      (Rmul (ofQ q2 hq2d) (Radd (Rabs (Rsub A M)) (Rabs (Rsub M B)))) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ hq2d hq2n) tri
  have distr : Req (Rmul (ofQ q2 hq2d) (Radd (Rabs (Rsub A M)) (Rabs (Rsub M B))))
      (Radd (Rmul (ofQ q2 hq2d) (Rabs (Rsub A M))) (Rmul (ofQ q2 hq2d) (Rabs (Rsub M B)))) :=
    Rmul_distrib (ofQ q2 hq2d) (Rabs (Rsub A M)) (Rabs (Rsub M B))
  have hQ' : Rle (Rmul (ofQ q2 hq2d) (Rabs (Rsub M B))) (ofQ Cq hCqd) :=
    Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_symm M B))) hQ
  have addbnd : Rle (Radd (Rmul (ofQ q2 hq2d) (Rabs (Rsub A M)))
        (Rmul (ofQ q2 hq2d) (Rabs (Rsub M B)))) (Radd (ofQ Cq hCqd) (ofQ Cq hCqd)) :=
    Radd_le_add hP hQ'
  exact Rle_trans scaled (Rle_trans (Rle_of_Req distr)
    (Rle_trans addbnd (Rle_of_Req (Radd_ofQ_ofQ hCqd hCqd))))

/-- **The divided rational bound** (Move 3 arithmetic). With the schedule `δ = k+1`, `n = (k+1)²`, the
    doubled constant `add Cq Cq` divided by the weight `2(k+1)³` is at most `5·(Lx+Ly numerator)/(k+1)`;
    the surviving denominator factor `4·Lx.den·Ly.den ≥ 1` only shrinks the bound. Pure `Q`
    cross-multiplication. -/
private theorem final_q_bound (Lx Ly : Q) (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num)
    (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num) (k : Nat) :
    Qle (mul (⟨(1 : Int), 2 * (k + 1) * ((k + 1) * (k + 1))⟩ : Q)
          (add
            (mul (add Lx Ly)
              (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
                (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)))
            (mul (add Lx Ly)
              (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
                (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)))))
        (⟨((5 * (Lx.num * (Ly.den : Int) + Ly.num * (Lx.den : Int))).toNat : Int), k + 1⟩ : Q) := by
  have hN : (0 : Int) ≤ Lx.num * (Ly.den : Int) + Ly.num * (Lx.den : Int) :=
    Int.add_nonneg (Int.mul_nonneg hLxn (Int.ofNat_nonneg _))
      (Int.mul_nonneg hLyn (Int.ofNat_nonneg _))
  have hC : ((5 * (Lx.num * (Ly.den : Int) + Ly.num * (Lx.den : Int))).toNat : Int)
      = 5 * (Lx.num * (Ly.den : Int) + Ly.num * (Lx.den : Int)) :=
    Int.toNat_of_nonneg (by omega)
  simp only [Qle, mul, add]
  rw [hC]; push_cast
  have ha : (0 : Int) ≤ (↑k + 1 : Int) := by omega
  have hD1 : (1 : Int) ≤ (↑Lx.den : Int) * (↑Ly.den : Int) := by
    have h1 : 1 ≤ Lx.den * Ly.den := Nat.mul_le_mul hLxd hLyd
    exact_mod_cast h1
  have hpoly : ∀ (A B C E a : Int),
      5 * (A * E + B * C) * (2 * a * (a * a) * (C * E * 4 * (C * E * 4)))
        - 1 * ((A * E + B * C) * (a * a * 4 + a * a * 1) * (C * E * 4) +
              (A * E + B * C) * (a * a * 4 + a * a * 1) * (C * E * 4)) * a
        = 40 * (A * E + B * C) * (a * (a * a)) * (C * E) * (4 * (C * E) - 1) :=
    fun A B C E a => by ring_uor
  have hfac := hpoly Lx.num Ly.num (↑Lx.den) (↑Ly.den) (↑k + 1)
  have hnn : (0 : Int) ≤ 40 * (Lx.num * ↑Ly.den + Ly.num * ↑Lx.den) *
      ((↑k + 1) * ((↑k + 1) * (↑k + 1))) * (↑Lx.den * ↑Ly.den) *
      (4 * (↑Lx.den * ↑Ly.den) - 1) :=
    Int.mul_nonneg
      (Int.mul_nonneg
        (Int.mul_nonneg (Int.mul_nonneg (by decide) hN)
          (Int.mul_nonneg ha (Int.mul_nonneg ha ha)))
        (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)))
      (by omega)
  omega

/-- **THE GENERAL FUBINI SWAP** (Move 3, capstone of the 2D-Bernstein route). For a jointly-Lipschitz
    `F` on the unit square `[0,1]²` (moduli `Lx, Ly`, parametric-integral continuity data, bound `BF`),
    the two iterated double integrals are equal:

        `∫₀¹ ∫₀¹ F(x,y) dy dx  =  ∫₀¹ ∫₀¹ F(x,y) dx dy`.

    The left side is `∫ₓ (paramIntegralTest F …).f` (whose value at `x` is `∫ᵧ F(x,·)`); the right side
    is `∫ᵧ (paramIntegralTest Fᵀ …).f` (value at `y` is `∫ₓ F(·,y)`). Per schedule `k`
    (`δ = k+1`, `n = (k+1)²`), `bern2D_outer_close` at `F` and at the transpose `Fᵀ`, plus the
    finite-rank symmetry `bern2D_finrank_symm` (`Sₙ(F) = Sₙ(Fᵀ)`) that identifies the two Bernstein
    anchors; the anchored triangle scaled by `2δn ≥ 0`, divided out, and the real Archimedean squeeze
    close the equality. The Bernstein value is only the vanishing intermediate anchor — the equality is
    between the two GENUINE iterated integrals, with NO swap/limit hypothesis assumed. No positivity;
    the crux fields stay `none`. -/
theorem bern2D_general_swap (F : Real → Real → Real) (Lx Ly BF : Q)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num) (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (hLip : ∀ a a' b b', Rle (Rabs (Rsub (F a b) (F a' b')))
      (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub a a'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub b b')))))
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd)) :
    Req
      (riemannIntegralI
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hLd
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hLn
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hlip
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hfc
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (riemannIntegralI
        (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hLd
        (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hLn
        (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hlip
        (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
          (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hfc
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) := by
  -- Per-schedule witnesses for the transpose `G a b := F b a`.
  have main : ∀ k : Nat, Rle
      (Rabs (Rsub
        (riemannIntegralI
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hLd
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hLn
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hlip
          (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd x (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u))).hfc
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
        (riemannIntegralI
          (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
            (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
            (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hLd
          (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
            (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
            (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hLn
          (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
            (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
            (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hlip
          (paramIntegralTest (fun a b => F b a) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
            (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
            (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
            (fun x u _ _ => hFbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u) x)).hfc
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))))
      (ofQ (⟨((5 * (Lx.num * (Ly.den : Int) + Ly.num * (Lx.den : Int))).toNat : Int), k + 1⟩ : Q)
        (Nat.succ_pos k)) := by
    intro k
    -- schedule data
    have hn : 0 < (k + 1) * (k + 1) := Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)
    have hδd : 0 < (⟨((k + 1 : Nat) : Int), 1⟩ : Q).den := Nat.one_pos
    have hδn : 0 ≤ (⟨((k + 1 : Nat) : Int), 1⟩ : Q).num := Int.ofNat_nonneg _
    -- the transpose hypotheses
    have hLip_G : ∀ a a' b b', Rle (Rabs (Rsub (F b a) (F b' a')))
        (Radd (Rmul (ofQ Ly hLyd) (Rabs (Rsub a a'))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub b b')))) :=
      fun a a' b b' => Rle_trans (hLip b b' a a')
        (Rle_of_Req (Radd_comm (Rmul (ofQ Lx hLxd) (Rabs (Rsub b b')))
          (Rmul (ofQ Ly hLyd) (Rabs (Rsub a a')))))
    -- P k : outer close at F ; Q k : outer close at G ; R k : finite-rank symmetry
    have Pk := bern2D_outer_close F Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
      hlipY hfcY hlipX hfcX hLip hFbd ((k + 1) * (k + 1)) hn (⟨((k + 1 : Nat) : Int), 1⟩ : Q) hδd hδn
    have Qk := bern2D_outer_close (fun a b => F b a) Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn
      (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
      (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h) hLip_G (fun a b => hFbd b a)
      ((k + 1) * (k + 1)) hn (⟨((k + 1 : Nat) : Int), 1⟩ : Q) hδd hδn
    have Rk := bern2D_finrank_symm F BF hBFd hBFn hFbd ((k + 1) * (k + 1)) hn
      (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    -- the common constants
    have hδsqd : 0 < (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q)).den :=
      Qmul_den_pos hδd hδd
    have hCδd : 0 < (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
        (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)).den :=
      add_den_pos hδsqd (by show (0 : Nat) < 4; decide)
    have hCqd : 0 < (mul (add Lx Ly)
        (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
          (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q))).den :=
      Qmul_den_pos (add_den_pos hLxd hLyd) hCδd
    -- reduce the F-side RHS to a single `ofQ Cq`
    have rhsF : Req
        (Rmul (Radd (ofQ Lx hLxd) (ofQ Ly hLyd))
          (ofQ (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)) hCδd))
        (ofQ (mul (add Lx Ly)
          (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q))) hCqd) :=
      Req_trans (Rmul_congr (Radd_ofQ_ofQ hLxd hLyd) (Req_refl _))
        (Rmul_ofQ_ofQ (add_den_pos hLxd hLyd) hCδd)
    -- reduce the G-side RHS (order swapped) to the same `ofQ Cq`
    have hcomm : Qeq (mul (add Ly Lx)
          (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)))
        (mul (add Lx Ly)
          (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q))) := by
      simp only [Qeq, mul, add]; push_cast; ring_uor
    have rhsG : Req
        (Rmul (Radd (ofQ Ly hLyd) (ofQ Lx hLxd))
          (ofQ (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)) hCδd))
        (ofQ (mul (add Lx Ly)
          (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q))) hCqd) :=
      Req_trans (Req_trans (Rmul_congr (Radd_ofQ_ofQ hLyd hLxd) (Req_refl _))
        (Rmul_ofQ_ofQ (add_den_pos hLyd hLxd) hCδd))
        (ofQ_congr (Qmul_den_pos (add_den_pos hLyd hLxd) hCδd) hCqd hcomm)
    -- the anchored deviations `hP` (A vs M) and `hQ` (B vs M) at the common anchor `M = Sₙ(F)`
    have hP := Rle_trans Pk (Rle_of_Req rhsF)
    have hQ := Rle_trans
      (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr (Rsub_congr (Req_refl _) Rk))))
      (Rle_trans Qk (Rle_of_Req rhsG))
    -- the abstract triangle: `2δn·|A−B| ≤ add Cq Cq`
    have Tk := swap_perk_bound
      (mul (mul (⟨2, 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
        (⟨(((k + 1) * (k + 1) : Nat) : Int), 1⟩ : Q))
      (mul (add Lx Ly)
        (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
          (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)))
      (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos)
      (by
        show (0 : Int) ≤ (mul (mul (⟨2, 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
          (⟨(((k + 1) * (k + 1) : Nat) : Int), 1⟩ : Q)).num
        simp only [mul]
        exact Int.mul_nonneg (Int.mul_nonneg (by decide) hδn) (Int.ofNat_nonneg _))
      hCqd hP hQ
    -- divide by the Nat weight `2(k+1)³`
    have hR : 0 < 2 * (k + 1) * ((k + 1) * (k + 1)) :=
      Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos k)) hn
    have hcnum : (mul (mul (⟨2, 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
          (⟨(((k + 1) * (k + 1) : Nat) : Int), 1⟩ : Q)).num
        = ((2 * (k + 1) * ((k + 1) * (k + 1)) : Nat) : Int) := by
      simp only [mul]; push_cast; ring_uor
    have hBd : 0 < (add
        (mul (add Lx Ly)
          (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)))
        (mul (add Lx Ly)
          (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
            (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q)))).den :=
      add_den_pos hCqd hCqd
    have hkraw := Rle_of_Rmul_ofQ_le (2 * (k + 1) * ((k + 1) * (k + 1))) hR
      (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos) hcnum hBd Tk
    -- bound the divided rational by `5·(…)/(k+1)`
    exact Rle_trans hkraw (Rle_ofQ_ofQ (Qmul_den_pos hR hBd) (Nat.succ_pos k)
      (final_q_bound Lx Ly hLxd hLxn hLyd hLyn k))
  -- close the equality by the real Archimedean squeeze
  exact Req_of_Rle_ofQ_all
    (C := (5 * (Lx.num * (Ly.den : Int) + Ly.num * (Lx.den : Int))).toNat)
    (fun k => Rle_of_Rabs_le (main k))
    (fun k => Rle_trans (Rle_Rabs_self _)
      (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (main k)))

end Multiplicity.UOR.Bridge.F1Square.Square
