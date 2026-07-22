/-
F1 square — constant precision: **the `λ₃` UPPER bracket** (`λ₃ ≤ 0.2554`; true value
`0.207639`), the second two-sided Li coefficient.

WHY. The Gate-A finite-list prune of the FULL order-1 class (`Square/GateAFiniteList.lean`)
runs through the product identity `(2λ₂)² ≈ (2λ₃)(2λ₁)` forced by any order-1 recurrence; its
refutation needs `4λ₂² > 4λ₃λ₁`, i.e. a `λ₃` UPPER — which in turn needs `log 4π` from BELOW
(`Rlog4pic_ge`, the previous brick: `log 4π` enters `arch(3)` with coefficient `−3/2`, so an
upper on `arch(3)` consumes the LOWER log bracket). A loose upper suffices
(`0.2554 < 0.2668` is the kill budget), but two SHARP ingredients are forced:

- `Rgamma_gamma1_le` — the mixed-sign product upper `γγ₁ ≤ 0.577·(−0.0677) = −0.0390629`:
  its NEGATIVITY is load-bearing (the two-sided `Rmul_le_mul_of_abs` bound `|γγ₁| ≤ 0.044`
  would blow the budget by `0.25`). Route: `γγ₁ ≤ γ·(−0.0677) = −(γ·0.0677) ≤ −(0.577·0.0677)`
  (`Rmul_neg_right` + `Rneg_le`).
- `γ₂ ≤ −3/1000` (`Rgamma2_le_neg0003`, the tight v0.22 bracket): the loose `γ₂ ≤ 1/40`
  costs `0.042` and overshoots the budget.

THE LEDGER (all exact rationals, rounded outward at the ends).
- arithmetic side `λ₃^{arith} = −(3η₀ + 3η₁ + η₂)`:
  `3η₀ ≥ −1.734`, `3η₁ ≥ 3·(0.577² − 0.1524) = 0.541587`,
  `η₂ = −γ³ − 3γγ₁ − (3/2)γ₂ ≥ −0.578³ + 0.1171887 + 0.0045 = −0.071411852 ≥ −0.0714119`,
  so `λ₃^{arith} ≤ 1.2638249` (true `1.22068`).
- archimedean side `arch(3) = 1 − (3/2)(γ + log4π) + (9/4)ζ(2) − (7/8)ζ(3)`:
  `γ + log4π ≥ 0.577 + 2.53038 = 3.10738` (`Rlog4pic_ge`), `ζ(2) ≤ 1.646`, `ζ(3) ≥ 1.201`,
  so `arch(3) ≤ 1 − 4.66107 + 3.7035 − 1.050875 = −1.008445` (true `−1.01308`).
- **`Rlambda3_le : λ₃ ≤ 1.2638249 − 1.008445 = 0.2553799 ≤ 2554/10⁴`.**

With `Rlambda3_pos`, the third Li coefficient is two-sided. HONEST SCOPE: a finite bracket;
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaThree
import Core.F1.Analysis.LambdaThreePos
import Core.F1.Analysis.LambdaFivePrecision
import Core.F1.Analysis.LogFourPiLower

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The two sharp product ingredients.
-- ===========================================================================

/-- **`γ³ ≤ (578/1000)³`** — upper bound on `γ³` (mirror of `Rgamma_cube_ge`). -/
theorem Rgamma_cube_le :
    Rle (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h)
      (ofQ (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)) (by decide)) := by
  refine Rle_trans (Rmul_le_Rmul_right Rgamma_h_nonneg Rgamma_sq_le) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))

/-- **THE SHARP MIXED-SIGN UPPER `γγ₁ ≤ (577/1000)·(−677/10000) = −0.0390629`** — the
    negativity of the bound is what the `λ₃` budget needs (`γ > 0`, `γ₁ < 0`, so the product
    is at most `γ_lo · γ₁_hi`). -/
theorem Rgamma_gamma1_le :
    Rle (Rmul Rgamma_h Rgamma1)
      (ofQ (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q))) (by decide)) := by
  have h1 : Rle (Rmul Rgamma_h Rgamma1)
      (Rmul Rgamma_h (ofQ (⟨-677, 10000⟩ : Q) (by decide))) :=
    Rmul_le_Rmul_left Rgamma_h_nonneg Rgamma1_le_neg0677
  have h2 : Req (Rmul Rgamma_h (ofQ (⟨-677, 10000⟩ : Q) (by decide)))
      (Rneg (Rmul Rgamma_h (ofQ (⟨677, 10000⟩ : Q) (by decide)))) :=
    Req_trans (Rmul_congr (Req_refl Rgamma_h)
        (Req_symm (Rneg_ofQ (⟨677, 10000⟩ : Q) (by decide))))
      (Rmul_neg_right Rgamma_h (ofQ (⟨677, 10000⟩ : Q) (by decide)))
  have h3 : Rle (Rneg (Rmul Rgamma_h (ofQ (⟨677, 10000⟩ : Q) (by decide))))
      (Rneg (Rmul (ofQ (⟨577, 1000⟩ : Q) (by decide)) (ofQ (⟨677, 10000⟩ : Q) (by decide)))) :=
    Rneg_le (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_ge_577)
  refine Rle_trans h1 (Rle_trans (Rle_of_Req h2) (Rle_trans h3 (Rle_of_Req ?_)))
  exact Req_trans (Rneg_congr (Rmul_ofQ_ofQ (by decide) (by decide)))
    (Rneg_ofQ (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q)) (by decide))

-- ===========================================================================
-- The arithmetic side: λ₃^{arith} ≤ 1.2638249.
-- ===========================================================================

/-- `η₀ = −γ ≥ −0.578`. -/
private theorem eta0_ge : Rle (ofQ (⟨-578, 1000⟩ : Q) (by decide)) Reta0 :=
  Rneg_ofQ_le (by decide) Rgamma_h_le_578

/-- `3η₀ ≥ −1.734`. -/
private theorem eta0_triple_ge :
    Rle (ofQ (⟨-1734, 1000⟩ : Q) (by decide)) (nsmulR 3 Reta0) := by
  have hd : Rle (ofQ (add (⟨-578, 1000⟩ : Q) (⟨-578, 1000⟩ : Q)) (by decide))
      (Radd Reta0 Reta0) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add eta0_ge eta0_ge)
  have ht : Rle (ofQ (add (add (⟨-578, 1000⟩ : Q) (⟨-578, 1000⟩ : Q)) (⟨-578, 1000⟩ : Q))
        (by decide)) (Radd (Radd Reta0 Reta0) Reta0) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hd eta0_ge)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) ht

/-- `η₁ = γ² + 2γ₁ ≥ 0.577² − 0.1524 = 0.180529`. -/
private theorem eta1_ge : Rle (ofQ (⟨180529, 1000000⟩ : Q) (by decide)) Reta1 := by
  have h2g1 : Rle (ofQ (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_ge_neg0762)
  have hsum : Rle (ofQ (add (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))
        (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q))) (by decide)) Reta1 :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add Rgamma_sq_ge h2g1)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum

/-- `3η₁ ≥ 0.541587`. -/
private theorem eta1_triple_ge :
    Rle (ofQ (⟨541587, 1000000⟩ : Q) (by decide)) (nsmulR 3 Reta1) := by
  have hd : Rle (ofQ (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q)) (by decide))
      (Radd Reta1 Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add eta1_ge eta1_ge)
  have ht : Rle (ofQ (add (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q))
        (⟨180529, 1000000⟩ : Q)) (by decide)) (Radd (Radd Reta1 Reta1) Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hd eta1_ge)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) ht

/-- **`η₂ = −γ³ − 3γγ₁ − (3/2)γ₂ ≥ −0.0714119`** — the sharp mixed product and the tight
    `γ₂ ≤ −3/1000` both load-bearing. -/
private theorem eta2_ge : Rle (ofQ (⟨-714119, 10000000⟩ : Q) (by decide)) (nsmulR 1 Reta2) := by
  have hA : Rle (ofQ (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)))
        (by decide)) (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h)) :=
    Rneg_ofQ_le (by decide) Rgamma_cube_le
  have hB : Rle (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1))
      (ofQ (mul (⟨3, 1⟩ : Q) (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q)))) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma1_le)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have hnegB : Rle (ofQ (neg (mul (⟨3, 1⟩ : Q)
        (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q))))) (by decide))
      (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1))) :=
    Rneg_ofQ_le (by decide) hB
  have hC : Rle (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2)
      (ofQ (mul (⟨3, 2⟩ : Q) (⟨-3, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma2_le_neg0003)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have hnegC : Rle (ofQ (neg (mul (⟨3, 2⟩ : Q) (⟨-3, 1000⟩ : Q))) (by decide))
      (Rneg (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2)) :=
    Rneg_ofQ_le (by decide) hC
  have hAB : Rle (ofQ (add (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q)))))) (by decide))
      (Radd (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
        (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hA hnegB)
  have hsum : Rle (ofQ (add (add (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
          (⟨578, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q))))))
        (neg (mul (⟨3, 2⟩ : Q) (⟨-3, 1000⟩ : Q)))) (by decide)) Reta2 :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hAB hnegC)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum

/-- **`λ₃^{arith} ≤ 12638249/10⁷ = 1.2638249`** (true value `1.22068`). -/
theorem Rlambda3_arith_le :
    Rle Rlambda3_arith (ofQ (⟨12638249, 10000000⟩ : Q) (by decide)) := by
  have hzero : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Rle_of_Req (Req_refl zero)
  have h1 : Rle (ofQ (add (⟨0, 1⟩ : Q) (⟨-1734, 1000⟩ : Q)) (by decide))
      (Radd zero (nsmulR 3 Reta0)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hzero eta0_triple_ge)
  have h2 : Rle (ofQ (add (add (⟨0, 1⟩ : Q) (⟨-1734, 1000⟩ : Q)) (⟨541587, 1000000⟩ : Q))
        (by decide)) (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h1 eta1_triple_ge)
  have h3 : Rle (ofQ (add (add (add (⟨0, 1⟩ : Q) (⟨-1734, 1000⟩ : Q)) (⟨541587, 1000000⟩ : Q))
        (⟨-714119, 10000000⟩ : Q)) (by decide))
      (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 eta2_ge)
  have hT : Rle (ofQ (⟨-12638249, 10000000⟩ : Q) (by decide))
      (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2)) :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h3
  refine Rle_trans (Rneg_le hT) ?_
  exact Rle_of_Req (Rneg_ofQ (⟨-12638249, 10000000⟩ : Q) (by decide))

-- ===========================================================================
-- The archimedean side: arch(3) ≤ −1.008445.
-- ===========================================================================

/-- `γ + log4π ≥ 3.10738` — the `Rlog4pic_ge` consumer. -/
private theorem gl_ge : Rle (ofQ (⟨310738, 100000⟩ : Q) (by decide))
    (Radd Rgamma_h Rlog4pic) := by
  have h : Rle (ofQ (add (⟨577, 1000⟩ : Q) (⟨253038, 100000⟩ : Q)) (by decide))
      (Radd Rgamma_h Rlog4pic) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
      (Radd_le_add Rgamma_h_ge_577 Rlog4pic_ge)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h

/-- `3(γ + log4π) ≥ 9.32214`. -/
private theorem gl_triple_ge : Rle (ofQ (⟨932214, 100000⟩ : Q) (by decide))
    (nsmulR 3 (Radd Rgamma_h Rlog4pic)) := by
  have hd : Rle (ofQ (add (⟨310738, 100000⟩ : Q) (⟨310738, 100000⟩ : Q)) (by decide))
      (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add gl_ge gl_ge)
  have ht : Rle (ofQ (add (add (⟨310738, 100000⟩ : Q) (⟨310738, 100000⟩ : Q))
        (⟨310738, 100000⟩ : Q)) (by decide))
      (Radd (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (Radd Rgamma_h Rlog4pic)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hd gl_ge)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) ht

/-- `1 − (3/2)(γ + log4π) ≤ −3.66107`. -/
private theorem arch3_head_le :
    Rle (Rsub one (Rhalf (nsmulR 3 (Radd Rgamma_h Rlog4pic))))
      (ofQ (⟨-366107, 100000⟩ : Q) (by decide)) := by
  have hH : Rle (ofQ (mul (⟨1, 2⟩ : Q) (⟨932214, 100000⟩ : Q))
        (Qmul_den_pos (by decide) (by decide)))
      (Rhalf (nsmulR 3 (Radd Rgamma_h Rlog4pic))) := Rhalf_ge (by decide) gl_triple_ge
  have hneg : Rle (Rneg (Rhalf (nsmulR 3 (Radd Rgamma_h Rlog4pic))))
      (ofQ (neg (mul (⟨1, 2⟩ : Q) (⟨932214, 100000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le hH)
      (Rle_of_Req (Rneg_ofQ (mul (⟨1, 2⟩ : Q) (⟨932214, 100000⟩ : Q)) (by decide)))
  have hone : Rle one (ofQ (⟨1, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl one)
  have hsum : Rle (Rsub one (Rhalf (nsmulR 3 (Radd Rgamma_h Rlog4pic))))
      (ofQ (add (⟨1, 1⟩ : Q) (neg (mul (⟨1, 2⟩ : Q) (⟨932214, 100000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add hone hneg) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- `(9/4)ζ(2) ≤ 2.25·1.646` (the `j = 2` archimedean term of `arch(3)`). -/
private theorem arch3_t2_le :
    Rle (genArchTerm 3 2 (by omega))
      (ofQ (mul (⟨9, 4⟩ : Q) (⟨1646, 1000⟩ : Q)) (by decide)) :=
  Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_upper)
    (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))

/-- `−(7/8)ζ(3) ≤ −0.875·1.201` (the `j = 3` archimedean term; `ζ(3) ≥ 1.201`). -/
private theorem arch3_t3_le :
    Rle (genArchTerm 3 3 (by omega))
      (ofQ (neg (mul (⟨7, 8⟩ : Q) (⟨1201, 1000⟩ : Q))) (by decide)) := by
  have hlo : Rle (ofQ (mul (⟨7, 8⟩ : Q) (⟨1201, 1000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta3_lower)
  have hneg : Rle (Rneg (Rmul (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (ofQ (neg (mul (⟨7, 8⟩ : Q) (⟨1201, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le hlo)
      (Rle_of_Req (Rneg_ofQ (mul (⟨7, 8⟩ : Q) (⟨1201, 1000⟩ : Q)) (by decide)))
  have hconv : Req (genArchTerm 3 3 (by omega))
      (Rneg (Rmul (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))) :=
    Req_trans (Rmul_congr (Req_symm (Rneg_ofQ (⟨7, 8⟩ : Q) (by decide)))
        (Req_refl (zeta 3 (by decide))))
      (Rmul_neg_left (ofQ (⟨7, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
  exact Rle_trans (Rle_of_Req hconv) hneg

/-- `genArchTail 3 3 ≤ 2.652625`. -/
private theorem arch3_tail_le :
    Rle (genArchTail 3 3) (ofQ (⟨2652625, 1000000⟩ : Q) (by decide)) := by
  have hz : Rle zero (ofQ (⟨0, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl zero)
  have h1 : Rle (Radd zero (genArchTerm 3 2 (by omega)))
      (ofQ (add (⟨0, 1⟩ : Q) (mul (⟨9, 4⟩ : Q) (⟨1646, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Radd_le_add hz arch3_t2_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have h2 : Rle (Radd (Radd zero (genArchTerm 3 2 (by omega))) (genArchTerm 3 3 (by omega)))
      (ofQ (add (add (⟨0, 1⟩ : Q) (mul (⟨9, 4⟩ : Q) (⟨1646, 1000⟩ : Q)))
        (neg (mul (⟨7, 8⟩ : Q) (⟨1201, 1000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add h1 arch3_t3_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans h2 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- **`arch(3) ≤ −1008445/10⁶ = −1.008445`** (true value `−1.01308`). -/
theorem genuineArchSeq3_le :
    Rle (genuineArchSeq 3) (ofQ (⟨-1008445, 1000000⟩ : Q) (by decide)) := by
  have hsum : Rle (genuineArchSeq 3)
      (ofQ (add (⟨-366107, 100000⟩ : Q) (⟨2652625, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add arch3_head_le arch3_tail_le)
      (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

-- ===========================================================================
-- The bracket.
-- ===========================================================================

/-- **`λ₃ ≤ 2554/10⁴ = 0.2554`** (true value `0.207639`) — with `Rlambda3_pos`, the SECOND
    two-sided Li coefficient. Consumed by the full order-1 Gate-A class kill. -/
theorem Rlambda3_le : Rle Rlambda3 (ofQ (⟨2554, 10000⟩ : Q) (by decide)) := by
  have hsum : Rle Rlambda3
      (ofQ (add (⟨12638249, 10000000⟩ : Q) (⟨-1008445, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add Rlambda3_arith_le genuineArchSeq3_le)
      (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

end UOR.Bridge.F1Square.Analysis
