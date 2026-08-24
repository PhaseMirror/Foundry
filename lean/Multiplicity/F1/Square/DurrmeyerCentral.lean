/-
F1 square — **the Durrmeyer second central-moment bound** (`DurrmeyerCentral.lean`), the
Mellin-inversion arc, sub-brick J₅ (analytic core). Assembling the three Bernstein–Durrmeyer moments
(`DurrmeyerMomentSum.lean`) into the second central moment `T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²` gives the
exact cleared identity

    `T_{p+3}(x) · (p+5)(p+6) = 2p·x(1−x) + 2`

(writing `n = p+3` to kill the Nat subtractions `n−1`, `n−3`), from which the `x(1−x) ≤ 1/4` clamp
(`quarter_bound`) yields the vanishing bound

    `T_{p+3}(x) ≤ 1/(p+5) = 1/(n+2)`   on `[0,1]`   (`durrOp_central2_le`).

This is the single analytic quantity `T_n(x) → 0` that (with a kernel-as-test AM–GM squeeze) would drive
the Durrmeyer strong-inversion convergence `durrOp φ n x → φ(x)`.

WHY (the Sonine route, step 3, the Mellin FRONT). The Bernstein–Durrmeyer operator is a genuine
positive averaging operator whose approximation is governed by the second central moment; a `1/(n+2)`
decay is exactly the Voronovskaja-type control the strong (pointwise) inversion needs beyond the weak
pairing inversion already in hand.

HONEST SCOPE. The second central moment `T_n` assembled and bounded by `1/(n+2)` on `[0,1]` (an exact
cleared identity plus one `1/4` clamp). NOT the convergence `durrOp φ n x → φ(x)`, NOT strong inversion,
NOT positivity. Step 4 (the band-coupling positivity) is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DurrmeyerMomentSum
import Multiplicity.F1.Square.BernsteinDevBound
import Multiplicity.F1.Square.MomentDeterminacy

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Positivity of the double denominator `(p+5)(p+6)`. -/
private theorem hden2 (p : Nat) : 0 < (p + 5) * (p + 6) :=
  Nat.mul_pos (Nat.succ_pos (p + 4)) (Nat.succ_pos (p + 5))

/-- **The reciprocal `1/((p+5)(p+6))` times the weight `(p+5)(p+6)` is `1`.** -/
private theorem recip2 (p : Nat) :
    Req (Rmul (ofQ (⟨1, (p + 5) * (p + 6)⟩ : Q) (hden2 p)) (RofNat ((p + 5) * (p + 6)))) one := by
  refine Req_trans (Rmul_ofQ_ofQ (hden2 p) Nat.one_pos) ?_
  refine ofQ_congr (Qmul_den_pos (hden2 p) Nat.one_pos) (by decide) ?_
  show Qeq (mul (⟨1, (p + 5) * (p + 6)⟩ : Q) (⟨((((p + 5) * (p + 6)) : Nat) : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **The reciprocal `1/(p+5)` times the weight `(p+5)(p+6)` is `(p+6)`.** -/
private theorem recip1 (p : Nat) :
    Req (Rmul (ofQ (⟨1, p + 5⟩ : Q) (Nat.succ_pos (p + 4))) (RofNat ((p + 5) * (p + 6))))
        (RofNat (p + 6)) := by
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos (p + 4)) Nat.one_pos) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos (p + 4)) Nat.one_pos) Nat.one_pos ?_
  show Qeq (mul (⟨1, p + 5⟩ : Q) (⟨((((p + 5) * (p + 6)) : Nat) : Int), 1⟩ : Q))
      (⟨(((p + 6) : Nat) : Int), 1⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **Clearing the `M⁽²⁾` denominator**: `M_{p+3}⁽²⁾ · (p+5)(p+6) = (p+3)(p+2)x² + 4(p+3)x + 2`. -/
private theorem clear2 (p : Nat) (x : Real) :
    Req (Rmul (durrOp (powTest 2) (p + 3) x) (RofNat ((p + 5) * (p + 6))))
        (Radd (Radd (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                    (Rmul (RofNat 4) (Rmul (RofNat (p + 3)) x))) (RofNat 2)) := by
  refine Req_trans (Rmul_congr (durrOp_powTest_two (p + 3) x) (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc _ _ (RofNat ((p + 5) * (p + 6)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (recip2 p)) ?_
  exact Rmul_one _

/-- **Clearing the `M⁽¹⁾` denominator**: `M_{p+3}⁽¹⁾ · (p+5)(p+6) = ((p+3)x + 1)·(p+6)`. -/
private theorem clear1 (p : Nat) (x : Real) :
    Req (Rmul (durrOp (powTest 1) (p + 3) x) (RofNat ((p + 5) * (p + 6))))
        (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6))) := by
  refine Req_trans (Rmul_congr (durrOp_powTest_one (p + 3) x) (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc _ _ (RofNat ((p + 5) * (p + 6)))) ?_
  exact Rmul_congr (Req_refl _) (recip1 p)

/-- Coefficient collapse `2·((p+3)·(p+6)) = 2·((p+3)·(p+6))` as reals. -/
private theorem coefB1_eq (p : Nat) :
    Req (RofNat (2 * ((p + 3) * (p + 6))))
        (Rmul (RofNat 2) (Rmul (RofNat (p + 3)) (RofNat (p + 6)))) :=
  Req_trans (RofNat_mul 2 ((p + 3) * (p + 6)))
    (Rmul_congr (Req_refl _) (RofNat_mul (p + 3) (p + 6)))

/-- Normalize `4·((p+3)·x)` to `(4(p+3))·x`. -/
private theorem norm_m2 (p : Nat) (x : Real) :
    Req (Rmul (RofNat 4) (Rmul (RofNat (p + 3)) x)) (Rmul (RofNat (4 * (p + 3))) x) :=
  Req_trans (Req_symm (Rmul_assoc (RofNat 4) (RofNat (p + 3)) x))
    (Rmul_congr (Req_symm (RofNat_mul 4 (p + 3))) (Req_refl x))

/-- Normalize `(2·x)·(p+6)` to `(2(p+6))·x`. -/
private theorem norm_b2 (p : Nat) (x : Real) :
    Req (Rmul (Rmul (RofNat 2) x) (RofNat (p + 6))) (Rmul (RofNat (2 * (p + 6))) x) := by
  refine Req_trans (Rmul_assoc (RofNat 2) x (RofNat (p + 6))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_comm x (RofNat (p + 6)))) ?_
  refine Req_trans (Req_symm (Rmul_assoc (RofNat 2) (RofNat (p + 6)) x)) ?_
  exact Rmul_congr (Req_symm (RofNat_mul 2 (p + 6))) (Req_refl x)

/-- Normalize `(2·x)·((p+3)·x·(p+6))` to `(2(p+3)(p+6))·x²`. -/
private theorem norm_b1 (p : Nat) (x : Real) :
    Req (Rmul (Rmul (RofNat 2) x) (Rmul (Rmul (RofNat (p + 3)) x) (RofNat (p + 6))))
        (Rmul (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x)) := by
  have hinner : Req (Rmul (Rmul (RofNat (p + 3)) x) (RofNat (p + 6)))
      (Rmul (Rmul (RofNat (p + 3)) (RofNat (p + 6))) x) :=
    Req_trans (Rmul_assoc (RofNat (p + 3)) x (RofNat (p + 6)))
      (Req_trans (Rmul_congr (Req_refl _) (Rmul_comm x (RofNat (p + 6))))
        (Req_symm (Rmul_assoc (RofNat (p + 3)) (RofNat (p + 6)) x)))
  refine Req_trans (Rmul_congr (Req_refl _) hinner) ?_
  refine Req_trans (Rmul_mul_mul (RofNat 2) x (Rmul (RofNat (p + 3)) (RofNat (p + 6))) x) ?_
  exact Rmul_congr (Req_symm (coefB1_eq p)) (Req_refl _)

/-- The `x`-coefficient collapse `4(p+3) − 2(p+6) = 2p` as reals. -/
private theorem coefU_eq (p : Nat) :
    Req (Rsub (RofNat (4 * (p + 3))) (RofNat (2 * (p + 6)))) (RofNat (2 * p)) := by
  refine Req_trans (Rsub_ofQ_ofQ Nat.one_pos Nat.one_pos) ?_
  refine ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_
  simp only [Qeq, add, neg, mul]; push_cast; ring_uor

/-- The `x²`-coefficient collapse `(p+3)(p+2) − 2(p+3)(p+6) + (p+5)(p+6) = −2p` as reals. -/
private theorem coefV_eq (p : Nat) :
    Req (Radd (Rsub (RofNat ((p + 3) * (p + 2))) (RofNat (2 * ((p + 3) * (p + 6)))))
              (RofNat ((p + 5) * (p + 6))))
        (Rneg (RofNat (2 * p))) := by
  refine Req_trans (Radd_congr (Rsub_ofQ_ofQ Nat.one_pos Nat.one_pos) (Req_refl _)) ?_
  refine Req_trans (Radd_ofQ_ofQ (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos) ?_
  refine Req_trans ?_ (Req_symm (Rneg_ofQ _ Nat.one_pos))
  refine ofQ_congr (add_den_pos (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos) Nat.one_pos ?_
  simp only [Qeq, add, neg, mul]; push_cast; ring_uor

/-- **The additive regrouping**: collect the `x²`-monomials `(m1, −b1, cc)` and the `x`-monomials
    `(m2, −b2)`, keeping the constant `two`. -/
private theorem combine6 (m1 m2 two b1 b2 cc : Real) :
    Req (Radd (Rsub (Radd (Radd m1 m2) two) (Radd b1 b2)) cc)
        (Radd (Radd (Radd (Rsub m1 b1) cc) (Rsub m2 b2)) two) := by
  have hstep3 : Req (Rsub (Radd m2 two) b2) (Radd (Rsub m2 b2) two) :=
    Req_trans (Radd_assoc m2 two (Rneg b2))
      (Req_trans (Radd_congr (Req_refl _) (Radd_comm two (Rneg b2)))
        (Req_symm (Radd_assoc m2 (Rneg b2) two)))
  have hsub : Req (Rsub (Radd (Radd m1 m2) two) (Radd b1 b2))
      (Radd (Rsub m1 b1) (Radd (Rsub m2 b2) two)) :=
    Req_trans (Rsub_congr (Radd_assoc m1 m2 two) (Req_refl _))
      (Req_trans (Rsub_Radd_Radd m1 (Radd m2 two) b1 b2)
        (Radd_congr (Req_refl _) hstep3))
  -- `Radd (Rsub A2 B) cc ≈ Radd (Radd V1 (Radd UU two)) cc`, then regroup.
  refine Req_trans (Radd_congr hsub (Req_refl cc)) ?_
  refine Req_trans (Radd_congr
    (Req_symm (Radd_assoc (Rsub m1 b1) (Rsub m2 b2) two)) (Req_refl cc)) ?_
  refine Req_trans (Radd_assoc (Radd (Rsub m1 b1) (Rsub m2 b2)) two cc) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_comm two cc)) ?_
  refine Req_trans (Radd_swap (Rsub m1 b1) (Rsub m2 b2) cc two) ?_
  exact Req_symm (Radd_assoc (Radd (Rsub m1 b1) cc) (Rsub m2 b2) two)

/-- **THE CLEARED SECOND-CENTRAL-MOMENT IDENTITY (polynomial core)**: with `M⁽²⁾`, `M⁽¹⁾` already
    denominator-cleared, the assembled polynomial reduces to `2p·x(1−x) + 2`. -/
private theorem poly_identity (p : Nat) (x : Real) :
    Req (Radd (Rsub
                (Radd (Radd (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                            (Rmul (RofNat 4) (Rmul (RofNat (p + 3)) x))) (RofNat 2))
                (Rmul (Rmul (RofNat 2) x)
                      (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6)))))
              (Rmul (Rmul x x) (RofNat ((p + 5) * (p + 6)))))
        (Radd (Rmul (RofNat (2 * p)) (Rmul x (Rsub one x))) (RofNat 2)) := by
  -- normal-form pieces
  have hA2 : Req
      (Radd (Radd (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                  (Rmul (RofNat 4) (Rmul (RofNat (p + 3)) x))) (RofNat 2))
      (Radd (Radd (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                  (Rmul (RofNat (4 * (p + 3))) x)) (RofNat 2)) :=
    Radd_congr (Radd_congr (Req_refl _) (norm_m2 p x)) (Req_refl _)
  have hInnerB : Req (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6)))
      (Radd (Rmul (Rmul (RofNat (p + 3)) x) (RofNat (p + 6))) (RofNat (p + 6))) :=
    Req_trans (Rmul_distrib_right (Rmul (RofNat (p + 3)) x) one (RofNat (p + 6)))
      (Radd_congr (Req_refl _) (Rone_mul (RofNat (p + 6))))
  have hBexpand : Req
      (Rmul (Rmul (RofNat 2) x) (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6))))
      (Radd (Rmul (Rmul (RofNat 2) x) (Rmul (Rmul (RofNat (p + 3)) x) (RofNat (p + 6))))
            (Rmul (Rmul (RofNat 2) x) (RofNat (p + 6)))) :=
    Req_trans (Rmul_congr (Req_refl _) hInnerB)
      (Rmul_distrib (Rmul (RofNat 2) x) (Rmul (Rmul (RofNat (p + 3)) x) (RofNat (p + 6)))
        (RofNat (p + 6)))
  have hB : Req
      (Rmul (Rmul (RofNat 2) x) (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6))))
      (Radd (Rmul (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x)) (Rmul (RofNat (2 * (p + 6))) x)) :=
    Req_trans hBexpand (Radd_congr (norm_b1 p x) (norm_b2 p x))
  -- rewrite LHS into the shape `combine6` consumes
  have hLHS1 : Req
      (Radd (Rsub
              (Radd (Radd (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                          (Rmul (RofNat 4) (Rmul (RofNat (p + 3)) x))) (RofNat 2))
              (Rmul (Rmul (RofNat 2) x)
                    (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6)))))
            (Rmul (Rmul x x) (RofNat ((p + 5) * (p + 6)))))
      (Radd (Rsub
              (Radd (Radd (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                          (Rmul (RofNat (4 * (p + 3))) x)) (RofNat 2))
              (Radd (Rmul (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x))
                    (Rmul (RofNat (2 * (p + 6))) x)))
            (Rmul (RofNat ((p + 5) * (p + 6))) (Rmul x x))) :=
    Radd_congr (Rsub_congr hA2 hB) (Rmul_comm (Rmul x x) (RofNat ((p + 5) * (p + 6))))
  -- the `x²`- and `x`-coefficient collapses
  have hVgroup : Req
      (Radd (Rsub (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                  (Rmul (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x)))
            (Rmul (RofNat ((p + 5) * (p + 6))) (Rmul x x)))
      (Rmul (Rneg (RofNat (2 * p))) (Rmul x x)) := by
    refine Req_trans (Radd_congr
      (Req_symm (Rmul_sub_distrib_right (RofNat ((p + 3) * (p + 2)))
        (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x))) (Req_refl _)) ?_
    refine Req_trans (Req_symm (Rmul_distrib_right
      (Rsub (RofNat ((p + 3) * (p + 2))) (RofNat (2 * ((p + 3) * (p + 6)))))
      (RofNat ((p + 5) * (p + 6))) (Rmul x x))) ?_
    exact Rmul_congr (coefV_eq p) (Req_refl _)
  have hUgroup : Req
      (Rsub (Rmul (RofNat (4 * (p + 3))) x) (Rmul (RofNat (2 * (p + 6))) x))
      (Rmul (RofNat (2 * p)) x) :=
    Req_trans (Req_symm (Rmul_sub_distrib_right (RofNat (4 * (p + 3))) (RofNat (2 * (p + 6))) x))
      (Rmul_congr (coefU_eq p) (Req_refl _))
  have hNF : Req
      (Radd (Radd (Radd (Rsub (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
                              (Rmul (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x)))
                        (Rmul (RofNat ((p + 5) * (p + 6))) (Rmul x x)))
                  (Rsub (Rmul (RofNat (4 * (p + 3))) x) (Rmul (RofNat (2 * (p + 6))) x))) (RofNat 2))
      (Radd (Radd (Rmul (Rneg (RofNat (2 * p))) (Rmul x x)) (Rmul (RofNat (2 * p)) x)) (RofNat 2)) :=
    Radd_congr (Radd_congr hVgroup hUgroup) (Req_refl _)
  -- reduce the RHS target to the same common form
  have hRHS : Req (Radd (Rmul (RofNat (2 * p)) (Rmul x (Rsub one x))) (RofNat 2))
      (Radd (Radd (Rmul (Rneg (RofNat (2 * p))) (Rmul x x)) (Rmul (RofNat (2 * p)) x)) (RofNat 2)) := by
    have hR1 : Req (Rmul (RofNat (2 * p)) (Rmul x (Rsub one x)))
        (Rsub (Rmul (RofNat (2 * p)) x) (Rmul (RofNat (2 * p)) (Rmul x x))) :=
      Req_trans (Rmul_congr (Req_refl _)
          (Req_trans (Rmul_sub_distrib x one x) (Rsub_congr (Rmul_one x) (Req_refl _))))
        (Rmul_sub_distrib (RofNat (2 * p)) x (Rmul x x))
    have hR2 : Req (Rsub (Rmul (RofNat (2 * p)) x) (Rmul (RofNat (2 * p)) (Rmul x x)))
        (Radd (Rmul (Rneg (RofNat (2 * p))) (Rmul x x)) (Rmul (RofNat (2 * p)) x)) :=
      Req_trans (Radd_congr (Req_refl _)
          (Req_symm (Rmul_neg_left (RofNat (2 * p)) (Rmul x x))))
        (Radd_comm (Rmul (RofNat (2 * p)) x) (Rmul (Rneg (RofNat (2 * p))) (Rmul x x)))
    exact Radd_congr (Req_trans hR1 hR2) (Req_refl _)
  exact Req_trans hLHS1
    (Req_trans (combine6 (Rmul (RofNat ((p + 3) * (p + 2))) (Rmul x x))
        (Rmul (RofNat (4 * (p + 3))) x) (RofNat 2)
        (Rmul (RofNat (2 * ((p + 3) * (p + 6)))) (Rmul x x)) (Rmul (RofNat (2 * (p + 6))) x)
        (Rmul (RofNat ((p + 5) * (p + 6))) (Rmul x x)))
      (Req_trans hNF (Req_symm hRHS)))

/-- **THE EXACT CLEARED IDENTITY** `T_{p+3}(x) · (p+5)(p+6) = 2p·x(1−x) + 2`: distribute the weight
    `(p+5)(p+6)` over `T = M⁽²⁾ − 2x·M⁽¹⁾ + x²`, clear both moment denominators (`clear2`, `clear1`),
    and collapse via `poly_identity`. -/
private theorem TW_identity (p : Nat) (x : Real) :
    Req (Rmul (Radd (Rsub (durrOp (powTest 2) (p + 3) x)
                          (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x)))
                    (Rmul x x))
              (RofNat ((p + 5) * (p + 6))))
        (Radd (Rmul (RofNat (2 * p)) (Rmul x (Rsub one x))) (RofNat 2)) := by
  refine Req_trans (Rmul_distrib_right
    (Rsub (durrOp (powTest 2) (p + 3) x)
      (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x)))
    (Rmul x x) (RofNat ((p + 5) * (p + 6)))) ?_
  refine Req_trans (Radd_congr (Rmul_sub_distrib_right (durrOp (powTest 2) (p + 3) x)
    (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x)) (RofNat ((p + 5) * (p + 6))))
    (Req_refl _)) ?_
  have hPW : Req (Rmul (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x))
        (RofNat ((p + 5) * (p + 6))))
      (Rmul (Rmul (RofNat 2) x) (Rmul (Radd (Rmul (RofNat (p + 3)) x) one) (RofNat (p + 6)))) :=
    Req_trans (Rmul_assoc (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x)
        (RofNat ((p + 5) * (p + 6))))
      (Rmul_congr (Req_refl _) (clear1 p x))
  refine Req_trans (Radd_congr (Rsub_congr (clear2 p x) hPW) (Req_refl _)) ?_
  exact poly_identity p x

/-- **★ THE DURRMEYER SECOND CENTRAL MOMENT IS `≤ 1/(n+2)` ON `[0,1]`** (`n = p+3`): the assembled
    second central moment `T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²` satisfies `T_n(x) ≤ 1/(p+5) = 1/(n+2)`.
    From the exact cleared identity `T_n·(p+5)(p+6) = 2p·x(1−x) + 2`, the clamp `x(1−x) ≤ 1/4`
    (`quarter_bound`) gives `2p·x(1−x)+2 ≤ p/2+2 ≤ p+6`, and dividing by the positive weight
    `(p+5)(p+6)` yields the bound. -/
theorem durrOp_central2_le (p : Nat) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Rle (Radd (Rsub (durrOp (powTest 2) (p + 3) x)
                    (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x)))
              (Rmul x x))
        (ofQ (⟨1, p + 5⟩ : Q) (Nat.succ_pos (p + 4))) := by
  -- `2p·x(1−x) ≤ 2p/4`
  have hquarter : Rle (Rmul (RofNat (2 * p)) (Rmul x (Rsub one x)))
      (ofQ (mul (⟨((2 * p : Nat) : Int), 1⟩ : Q) (⟨1, 4⟩ : Q))
        (Qmul_den_pos Nat.one_pos (by decide))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_RofNat (2 * p)) (quarter_bound x))
      (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos (by decide)))
  -- `2p·x(1−x) + 2 ≤ p+6`
  have hbound : Rle (Radd (Rmul (RofNat (2 * p)) (Rmul x (Rsub one x))) (RofNat 2))
      (RofNat (p + 6)) := by
    refine Rle_trans (Radd_le_add hquarter (Rle_refl (RofNat 2))) ?_
    refine Rle_trans (Rle_of_Req
      (Radd_ofQ_ofQ (Qmul_den_pos Nat.one_pos (by decide)) Nat.one_pos)) ?_
    refine Rle_ofQ_ofQ (add_den_pos (Qmul_den_pos Nat.one_pos (by decide)) Nat.one_pos)
      Nat.one_pos ?_
    simp only [Qle, add, mul]; push_cast; omega
  -- `T·(p+5)(p+6) ≤ p+6`
  have hTW : Rle (Rmul (Radd (Rsub (durrOp (powTest 2) (p + 3) x)
                (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x))) (Rmul x x))
              (RofNat ((p + 5) * (p + 6)))) (RofNat (p + 6)) :=
    Rle_trans (Rle_of_Req (TW_identity p x)) hbound
  -- swap the weight to the left, then divide by it
  have hWT : Rle (Rmul (RofNat ((p + 5) * (p + 6)))
              (Radd (Rsub (durrOp (powTest 2) (p + 3) x)
                (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x))) (Rmul x x)))
            (RofNat (p + 6)) :=
    Rle_trans (Rle_of_Req (Rmul_comm (RofNat ((p + 5) * (p + 6)))
      (Radd (Rsub (durrOp (powTest 2) (p + 3) x)
        (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) (p + 3) x))) (Rmul x x)))) hTW
  refine Rle_trans
    (Rle_of_Rmul_ofQ_le ((p + 5) * (p + 6)) (hden2 p) Nat.one_pos rfl Nat.one_pos hWT)
    (Rle_of_Req (ofQ_congr (Qmul_den_pos (hden2 p) Nat.one_pos) (Nat.succ_pos (p + 4)) ?_))
  simp only [Qeq, mul]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
