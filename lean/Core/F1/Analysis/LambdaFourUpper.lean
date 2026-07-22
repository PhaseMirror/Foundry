/-
F1 square — constant precision: **the `λ₄` UPPER bracket** (`λ₄ ≤ 0.563`; true value
`0.385812`), the FOURTH two-sided Li coefficient (joining `Rlambda4_pos`).

WHY. The surviving Gate-A candidate frontier after the four prunes is order-2 with a
coefficient `> 1`; its kill is the 3×3 Hankel determinant on `λ₁..λ₅`, which needs ALL FIVE
coefficients two-sided. `λ₄` is the last one whose upper is assemblable from current stock
(`λ₅`'s upper runs through the unbuilt `γ₄` upper). This brick completes it, adding the four
product LOWER bounds the `η₃` floor needs — each the `ge`-mirror of an existing upper:

- `Rgamma_pow4_ge`      : `γ⁴ ≥ 0.577⁴` (from `Rgamma_cube_ge`);
- `Rgamma_sq_gamma1_ge` : `γ²γ₁ ≥ 0.578²·(−0.0762)` (mixed sign — the floor needs the
  PRODUCT of the outer bounds, via the `Rmul_neg_right` route of `Rgamma_gamma1_le`);
- `Rgamma1_sq_ge`       : `γ₁² ≥ 0.0677²` (square of the certified magnitude, via the
  double-negation identity `γ₁² = (−γ₁)²`);
- `Rgamma_gamma2_ge`    : `γγ₂ ≥ 0.578·(−0.014)`.

THE LEDGER (exact rationals, rounded outward).
- `η₃ = γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃
     ≥ 0.110841719 − 0.101828803 + 0.00916658 − 0.016184 − 1/30 ≥ −0.0313379`;
- `λ₄^{arith} = −(4η₀ + 6η₁ + 4η₂ + η₃)`: with `4η₀ ≥ −2.312`, `6η₁ ≥ 1.083174`,
  `4η₂ ≥ −0.2856476` (the `LambdaThreeUpper` floors), `λ₄^{arith} ≤ 1.5458115`;
- `arch(4) = 1 − 2(γ + log4π) + (9/2)ζ(2) − (7/2)ζ(3) + (15/16)ζ(4)
     ≤ 1 − 6.21476 + 7.407 − 4.2035 + 1.0284375 = −0.9828225` (the `log 4π` LOWER consumer);
- **`Rlambda4_le : λ₄ ≤ 1.5458115 − 0.9828225 = 0.562989 ≤ 563/1000`.**

HONEST SCOPE. A finite bracket; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaFour
import Core.F1.Analysis.LambdaTwoThreePrecision

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The four product floors (ge-mirrors of the stock uppers).
-- ===========================================================================

/-- **`γ⁴ ≥ (577/1000)⁴`** — the quartic floor (left-comb shape, matching `Reta3`). -/
theorem Rgamma_pow4_ge :
    Rle (ofQ (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q)) (by decide))
      (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_ge_577) ?_
  exact Rmul_le_Rmul_right Rgamma_h_nonneg Rgamma_cube_ge

/-- **`γ²γ₁ ≥ (578/1000)²·(−762/10000)`** — the mixed-sign floor (`γ² ≥ 0`, `γ₁ < 0`:
    the floor is `(γ²)ᕼⁱ·(γ₁)ˡᵒ`). -/
theorem Rgamma_sq_gamma1_ge :
    Rle (ofQ (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨762, 10000⟩ : Q)))
        (by decide))
      (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1) := by
  have h1 : Rle (Rmul (Rmul Rgamma_h Rgamma_h) (ofQ (⟨-762, 10000⟩ : Q) (by decide)))
      (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1) :=
    Rmul_le_Rmul_left (Rnonneg_Rmul Rgamma_h_nonneg Rgamma_h_nonneg) Rgamma1_ge_neg0762
  have h2 : Req (Rmul (Rmul Rgamma_h Rgamma_h) (ofQ (⟨-762, 10000⟩ : Q) (by decide)))
      (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) (ofQ (⟨762, 10000⟩ : Q) (by decide)))) :=
    Req_trans (Rmul_congr (Req_refl (Rmul Rgamma_h Rgamma_h))
        (Req_symm (Rneg_ofQ (⟨762, 10000⟩ : Q) (by decide))))
      (Rmul_neg_right (Rmul Rgamma_h Rgamma_h) (ofQ (⟨762, 10000⟩ : Q) (by decide)))
  have h3 : Rle (Rneg (Rmul (Rmul (ofQ (⟨578, 1000⟩ : Q) (by decide))
        (ofQ (⟨578, 1000⟩ : Q) (by decide))) (ofQ (⟨762, 10000⟩ : Q) (by decide))))
      (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) (ofQ (⟨762, 10000⟩ : Q) (by decide)))) := by
    refine Rneg_le (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) ?_)
    refine Rle_trans (Rmul_le_Rmul_right Rgamma_h_nonneg Rgamma_h_le_578) ?_
    exact Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans h3 (Rle_trans (Rle_of_Req (Req_symm h2)) h1))
  refine Req_trans (Req_symm (Rneg_ofQ (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
    (⟨762, 10000⟩ : Q)) (by decide))) ?_
  exact Rneg_congr (Req_symm (Req_trans (Rmul_congr (Rmul_ofQ_ofQ (by decide) (by decide))
    (Req_refl (ofQ (⟨762, 10000⟩ : Q) (by decide)))) (Rmul_ofQ_ofQ (by decide) (by decide))))

/-- **`γ₁² ≥ (677/10000)²`** — the square of the certified magnitude (`γ₁ ≤ −0.0677`, so
    `−γ₁ ≥ 0.0677 ≥ 0` and `γ₁² = (−γ₁)²`). -/
theorem Rgamma1_sq_ge :
    Rle (ofQ (mul (⟨677, 10000⟩ : Q) (⟨677, 10000⟩ : Q)) (by decide))
      (Rmul Rgamma1 Rgamma1) := by
  have hn : Rle (ofQ (⟨677, 10000⟩ : Q) (by decide)) (Rneg Rgamma1) := by
    refine Rle_trans (Rle_of_Req ?_) (Rneg_le Rgamma1_le_neg0677)
    exact Req_symm (Rneg_ofQ (⟨-677, 10000⟩ : Q) (by decide))
  have hnn : Rnonneg (Rneg Rgamma1) :=
    Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg
      (Rnonneg_ofQ (by decide) (by decide))) hn)
  have hsq : Rle (ofQ (mul (⟨677, 10000⟩ : Q) (⟨677, 10000⟩ : Q)) (by decide))
      (Rmul (Rneg Rgamma1) (Rneg Rgamma1)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) hn)
        (Rmul_le_Rmul_left hnn hn))
  refine Rle_trans hsq (Rle_of_Req ?_)
  refine Req_trans (Rmul_neg_left Rgamma1 (Rneg Rgamma1)) ?_
  exact Req_trans (Rneg_congr (Rmul_neg_right Rgamma1 Rgamma1)) (Rneg_neg (Rmul Rgamma1 Rgamma1))

/-- **`γγ₂ ≥ (578/1000)·(−14/1000)`** — the mixed-sign floor for the `γ₂` product. -/
theorem Rgamma_gamma2_ge :
    Rle (ofQ (neg (mul (⟨578, 1000⟩ : Q) (⟨14, 1000⟩ : Q))) (by decide))
      (Rmul Rgamma_h Rgamma2) := by
  have h1 : Rle (Rmul Rgamma_h (ofQ (⟨-14, 1000⟩ : Q) (by decide))) (Rmul Rgamma_h Rgamma2) :=
    Rmul_le_Rmul_left Rgamma_h_nonneg Rgamma2_ge_neg0014
  have h2 : Req (Rmul Rgamma_h (ofQ (⟨-14, 1000⟩ : Q) (by decide)))
      (Rneg (Rmul Rgamma_h (ofQ (⟨14, 1000⟩ : Q) (by decide)))) :=
    Req_trans (Rmul_congr (Req_refl Rgamma_h)
        (Req_symm (Rneg_ofQ (⟨14, 1000⟩ : Q) (by decide))))
      (Rmul_neg_right Rgamma_h (ofQ (⟨14, 1000⟩ : Q) (by decide)))
  have h3 : Rle (Rneg (Rmul (ofQ (⟨578, 1000⟩ : Q) (by decide))
        (ofQ (⟨14, 1000⟩ : Q) (by decide))))
      (Rneg (Rmul Rgamma_h (ofQ (⟨14, 1000⟩ : Q) (by decide)))) :=
    Rneg_le (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578)
  refine Rle_trans (Rle_of_Req ?_) (Rle_trans h3 (Rle_trans (Rle_of_Req (Req_symm h2)) h1))
  refine Req_trans (Req_symm (Rneg_ofQ (mul (⟨578, 1000⟩ : Q) (⟨14, 1000⟩ : Q)) (by decide))) ?_
  exact Rneg_congr (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))

-- ===========================================================================
-- The η₃ floor and the arithmetic ceiling.
-- ===========================================================================

/-- **`η₃ ≥ −0.0313379`** — the five-term floor. -/
private theorem eta3_ge : Rle (ofQ (⟨-313379, 10000000⟩ : Q) (by decide)) Reta3 := by
  have hB : Rle (ofQ (mul (⟨4, 1⟩ : Q) (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨762, 10000⟩ : Q)))) (by decide))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_sq_gamma1_ge)
  have hC : Rle (ofQ (mul (⟨2, 1⟩ : Q) (mul (⟨677, 10000⟩ : Q) (⟨677, 10000⟩ : Q))) (by decide))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_sq_ge)
  have hD : Rle (ofQ (mul (⟨2, 1⟩ : Q) (neg (mul (⟨578, 1000⟩ : Q) (⟨14, 1000⟩ : Q))))
        (by decide))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma2)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma2_ge)
  have hE : Rle (ofQ (mul (⟨2, 3⟩ : Q) (⟨-1, 20⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨2, 3⟩ : Q) (by decide)) Rgamma3) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma3_ge_neg005)
  have h1 : Rle (ofQ (add (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q) (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨762, 10000⟩ : Q))))) (by decide))
      (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add Rgamma_pow4_ge hB)
  have h2 : Rle (ofQ (add (add (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q) (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨762, 10000⟩ : Q)))))
        (mul (⟨2, 1⟩ : Q) (mul (⟨677, 10000⟩ : Q) (⟨677, 10000⟩ : Q)))) (by decide))
      (Radd (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h1 hC)
  have h3 : Rle (ofQ (add (add (add (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q) (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨762, 10000⟩ : Q)))))
        (mul (⟨2, 1⟩ : Q) (mul (⟨677, 10000⟩ : Q) (⟨677, 10000⟩ : Q))))
        (mul (⟨2, 1⟩ : Q) (neg (mul (⟨578, 1000⟩ : Q) (⟨14, 1000⟩ : Q))))) (by decide))
      (Radd (Radd (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1)))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma2))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 hD)
  have h4 : Rle (ofQ (add (add (add (add (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q) (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨762, 10000⟩ : Q)))))
        (mul (⟨2, 1⟩ : Q) (mul (⟨677, 10000⟩ : Q) (⟨677, 10000⟩ : Q))))
        (mul (⟨2, 1⟩ : Q) (neg (mul (⟨578, 1000⟩ : Q) (⟨14, 1000⟩ : Q)))))
        (mul (⟨2, 3⟩ : Q) (⟨-1, 20⟩ : Q))) (by decide)) Reta3 :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h3 hE)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h4

/-- `η₀ = −γ ≥ −0.578`, quadrupled: `4η₀ ≥ −2.312`. -/
private theorem eta0_quad_ge :
    Rle (ofQ (⟨-2312, 1000⟩ : Q) (by decide)) (nsmulR 4 Reta0) := by
  have he : Rle (ofQ (⟨-578, 1000⟩ : Q) (by decide)) Reta0 :=
    Rneg_ofQ_le (by decide) Rgamma_h_le_578
  have h2 : Rle (ofQ (add (⟨-578, 1000⟩ : Q) (⟨-578, 1000⟩ : Q)) (by decide))
      (Radd Reta0 Reta0) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add he he)
  have h3 : Rle (ofQ (add (add (⟨-578, 1000⟩ : Q) (⟨-578, 1000⟩ : Q)) (⟨-578, 1000⟩ : Q))
        (by decide)) (Radd (Radd Reta0 Reta0) Reta0) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 he)
  have h4 : Rle (ofQ (add (add (add (⟨-578, 1000⟩ : Q) (⟨-578, 1000⟩ : Q)) (⟨-578, 1000⟩ : Q))
        (⟨-578, 1000⟩ : Q)) (by decide)) (Radd (Radd (Radd Reta0 Reta0) Reta0) Reta0) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h3 he)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h4

/-- `η₁ ≥ 0.180529`, six-folded: `6η₁ ≥ 1.083174`. -/
private theorem eta1_six_ge :
    Rle (ofQ (⟨1083174, 1000000⟩ : Q) (by decide)) (nsmulR 6 Reta1) := by
  have h2g1 : Rle (ofQ (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_ge_neg0762)
  have he : Rle (ofQ (⟨180529, 1000000⟩ : Q) (by decide)) Reta1 := by
    have hsum : Rle (ofQ (add (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))
          (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q))) (by decide)) Reta1 :=
      Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add Rgamma_sq_ge h2g1)
    exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum
  have h2 : Rle (ofQ (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q)) (by decide))
      (Radd Reta1 Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add he he)
  have h3 : Rle (ofQ (add (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q))
        (⟨180529, 1000000⟩ : Q)) (by decide)) (Radd (Radd Reta1 Reta1) Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 he)
  have h4 : Rle (ofQ (add (add (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q))
        (⟨180529, 1000000⟩ : Q)) (⟨180529, 1000000⟩ : Q)) (by decide))
      (Radd (Radd (Radd Reta1 Reta1) Reta1) Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h3 he)
  have h5 : Rle (ofQ (add (add (add (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q))
        (⟨180529, 1000000⟩ : Q)) (⟨180529, 1000000⟩ : Q)) (⟨180529, 1000000⟩ : Q)) (by decide))
      (Radd (Radd (Radd (Radd Reta1 Reta1) Reta1) Reta1) Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h4 he)
  have h6 : Rle (ofQ (add (add (add (add (add (⟨180529, 1000000⟩ : Q) (⟨180529, 1000000⟩ : Q))
        (⟨180529, 1000000⟩ : Q)) (⟨180529, 1000000⟩ : Q)) (⟨180529, 1000000⟩ : Q))
        (⟨180529, 1000000⟩ : Q)) (by decide))
      (Radd (Radd (Radd (Radd (Radd Reta1 Reta1) Reta1) Reta1) Reta1) Reta1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h5 he)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h6

/-- `η₂ ≥ −0.0714119`, quadrupled: `4η₂ ≥ −0.2856476`. -/
private theorem eta2_quad_ge :
    Rle (ofQ (⟨-2856476, 10000000⟩ : Q) (by decide)) (nsmulR 4 Reta2) := by
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
  have hAB : Rle (ofQ (add (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨578, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q)))))) (by decide))
      (Radd (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
        (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hA hnegB)
  have hsum : Rle (ofQ (add (add (neg (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
        (⟨578, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (neg (mul (⟨577, 1000⟩ : Q) (⟨677, 10000⟩ : Q))))))
        (neg (mul (⟨3, 2⟩ : Q) (⟨-3, 1000⟩ : Q)))) (by decide)) Reta2 :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hAB hnegC)
  have he : Rle (ofQ (⟨-714119, 10000000⟩ : Q) (by decide)) Reta2 :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum
  have h2 : Rle (ofQ (add (⟨-714119, 10000000⟩ : Q) (⟨-714119, 10000000⟩ : Q)) (by decide))
      (Radd Reta2 Reta2) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add he he)
  have h3 : Rle (ofQ (add (add (⟨-714119, 10000000⟩ : Q) (⟨-714119, 10000000⟩ : Q))
        (⟨-714119, 10000000⟩ : Q)) (by decide)) (Radd (Radd Reta2 Reta2) Reta2) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 he)
  have h4 : Rle (ofQ (add (add (add (⟨-714119, 10000000⟩ : Q) (⟨-714119, 10000000⟩ : Q))
        (⟨-714119, 10000000⟩ : Q)) (⟨-714119, 10000000⟩ : Q)) (by decide))
      (Radd (Radd (Radd Reta2 Reta2) Reta2) Reta2) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h3 he)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h4

-- ===========================================================================
-- The arithmetic ceiling: λ₄^{arith} ≤ 1.5458115.
-- ===========================================================================

set_option maxRecDepth 8192 in
/-- **`λ₄^{arith} ≤ 15458115/10⁷ = 1.5458115`** (true value `1.368`). -/
theorem Rlambda4_arith_le :
    Rle Rlambda4_arith (ofQ (⟨15458115, 10000000⟩ : Q) (by decide)) := by
  have hzero : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Rle_of_Req (Req_refl zero)
  have h1 : Rle (ofQ (add (⟨0, 1⟩ : Q) (⟨-2312, 1000⟩ : Q)) (by decide))
      (Radd zero (nsmulR 4 Reta0)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hzero eta0_quad_ge)
  have h2 : Rle (ofQ (add (add (⟨0, 1⟩ : Q) (⟨-2312, 1000⟩ : Q)) (⟨1083174, 1000000⟩ : Q))
        (by decide)) (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h1 eta1_six_ge)
  have h3 : Rle (ofQ (add (add (add (⟨0, 1⟩ : Q) (⟨-2312, 1000⟩ : Q)) (⟨1083174, 1000000⟩ : Q))
        (⟨-2856476, 10000000⟩ : Q)) (by decide))
      (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 eta2_quad_ge)
  have h4 : Rle (ofQ (add (add (add (add (⟨0, 1⟩ : Q) (⟨-2312, 1000⟩ : Q))
        (⟨1083174, 1000000⟩ : Q)) (⟨-2856476, 10000000⟩ : Q)) (⟨-313379, 10000000⟩ : Q))
        (by decide))
      (Radd (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2))
        (nsmulR 1 Reta3)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h3 eta3_ge)
  have hT : Rle (ofQ (⟨-15458115, 10000000⟩ : Q) (by decide))
      (Radd (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2))
        (nsmulR 1 Reta3)) :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h4
  refine Rle_trans (Rneg_le hT) ?_
  exact Rle_of_Req (Rneg_ofQ (⟨-15458115, 10000000⟩ : Q) (by decide))

-- ===========================================================================
-- The archimedean ceiling: arch(4) ≤ −0.9828225.
-- ===========================================================================

/-- `4(γ + log4π) ≥ 12.42952`. -/
private theorem gl_quad_ge : Rle (ofQ (⟨1242952, 100000⟩ : Q) (by decide))
    (nsmulR 4 (Radd Rgamma_h Rlog4pic)) := by
  have hg : Rle (ofQ (⟨310738, 100000⟩ : Q) (by decide)) (Radd Rgamma_h Rlog4pic) := by
    have h : Rle (ofQ (add (⟨577, 1000⟩ : Q) (⟨253038, 100000⟩ : Q)) (by decide))
        (Radd Rgamma_h Rlog4pic) :=
      Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
        (Radd_le_add Rgamma_h_ge_577 Rlog4pic_ge)
    exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h
  have h2 : Rle (ofQ (add (⟨310738, 100000⟩ : Q) (⟨310738, 100000⟩ : Q)) (by decide))
      (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hg hg)
  have h3 : Rle (ofQ (add (add (⟨310738, 100000⟩ : Q) (⟨310738, 100000⟩ : Q))
        (⟨310738, 100000⟩ : Q)) (by decide))
      (Radd (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (Radd Rgamma_h Rlog4pic)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h2 hg)
  have h4 : Rle (ofQ (add (add (add (⟨310738, 100000⟩ : Q) (⟨310738, 100000⟩ : Q))
        (⟨310738, 100000⟩ : Q)) (⟨310738, 100000⟩ : Q)) (by decide))
      (Radd (Radd (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (Radd Rgamma_h Rlog4pic)) (Radd Rgamma_h Rlog4pic)) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h3 hg)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h4

/-- `1 − 2(γ + log4π) ≤ −5.21476`. -/
private theorem arch4_head_le :
    Rle (Rsub one (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic))))
      (ofQ (⟨-521476, 100000⟩ : Q) (by decide)) := by
  have hH : Rle (ofQ (mul (⟨1, 2⟩ : Q) (⟨1242952, 100000⟩ : Q))
        (Qmul_den_pos (by decide) (by decide)))
      (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic))) := Rhalf_ge (by decide) gl_quad_ge
  have hneg : Rle (Rneg (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic))))
      (ofQ (neg (mul (⟨1, 2⟩ : Q) (⟨1242952, 100000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le hH)
      (Rle_of_Req (Rneg_ofQ (mul (⟨1, 2⟩ : Q) (⟨1242952, 100000⟩ : Q)) (by decide)))
  have hone : Rle one (ofQ (⟨1, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl one)
  have hsum : Rle (Rsub one (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic))))
      (ofQ (add (⟨1, 1⟩ : Q) (neg (mul (⟨1, 2⟩ : Q) (⟨1242952, 100000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add hone hneg) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- `(9/2)ζ(2) ≤ 4.5·1.646` (the `j = 2` term of `arch(4)`). -/
private theorem arch4_t2_le :
    Rle (genArchTerm 4 2 (by omega))
      (ofQ (mul (⟨18, 4⟩ : Q) (⟨1646, 1000⟩ : Q)) (by decide)) :=
  Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_upper)
    (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))

/-- `−(7/2)ζ(3) ≤ −3.5·1.201` (the `j = 3` term; `ζ(3) ≥ 1.201`). -/
private theorem arch4_t3_le :
    Rle (genArchTerm 4 3 (by omega))
      (ofQ (neg (mul (⟨28, 8⟩ : Q) (⟨1201, 1000⟩ : Q))) (by decide)) := by
  have hlo : Rle (ofQ (mul (⟨28, 8⟩ : Q) (⟨1201, 1000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta3_lower)
  have hneg : Rle (Rneg (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (ofQ (neg (mul (⟨28, 8⟩ : Q) (⟨1201, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le hlo)
      (Rle_of_Req (Rneg_ofQ (mul (⟨28, 8⟩ : Q) (⟨1201, 1000⟩ : Q)) (by decide)))
  have hconv : Req (genArchTerm 4 3 (by omega))
      (Rneg (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))) :=
    Req_trans (Rmul_congr (Req_symm (Rneg_ofQ (⟨28, 8⟩ : Q) (by decide)))
        (Req_refl (zeta 3 (by decide))))
      (Rmul_neg_left (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
  exact Rle_trans (Rle_of_Req hconv) hneg

/-- `(15/16)ζ(4) ≤ 0.9375·1.097` (the `j = 4` term). -/
private theorem arch4_t4_le :
    Rle (genArchTerm 4 4 (by omega))
      (ofQ (mul (⟨15, 16⟩ : Q) (⟨1097, 1000⟩ : Q)) (by decide)) :=
  Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta4_upper)
    (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))

/-- `genArchTail 4 4 ≤ 4.2319375`. -/
private theorem arch4_tail_le :
    Rle (genArchTail 4 4) (ofQ (⟨42319375, 10000000⟩ : Q) (by decide)) := by
  have hz : Rle zero (ofQ (⟨0, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl zero)
  have h1 : Rle (Radd zero (genArchTerm 4 2 (by omega)))
      (ofQ (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1646, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Radd_le_add hz arch4_t2_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have h2 : Rle (Radd (Radd zero (genArchTerm 4 2 (by omega))) (genArchTerm 4 3 (by omega)))
      (ofQ (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1646, 1000⟩ : Q)))
        (neg (mul (⟨28, 8⟩ : Q) (⟨1201, 1000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add h1 arch4_t3_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have h3 : Rle (Radd (Radd (Radd zero (genArchTerm 4 2 (by omega)))
        (genArchTerm 4 3 (by omega))) (genArchTerm 4 4 (by omega)))
      (ofQ (add (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1646, 1000⟩ : Q)))
        (neg (mul (⟨28, 8⟩ : Q) (⟨1201, 1000⟩ : Q))))
        (mul (⟨15, 16⟩ : Q) (⟨1097, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Radd_le_add h2 arch4_t4_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans h3 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- **`arch(4) ≤ −9828225/10⁷ = −0.9828225`** (true value `−0.982`). -/
theorem genuineArchSeq4_le :
    Rle (genuineArchSeq 4) (ofQ (⟨-9828225, 10000000⟩ : Q) (by decide)) := by
  have hsum : Rle (genuineArchSeq 4)
      (ofQ (add (⟨-521476, 100000⟩ : Q) (⟨42319375, 10000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add arch4_head_le arch4_tail_le)
      (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

-- ===========================================================================
-- The bracket.
-- ===========================================================================

/-- **`λ₄ ≤ 563/1000 = 0.563`** (true value `0.385812`) — with `Rlambda4_pos`, the FOURTH
    two-sided Li coefficient. The `λ₅` upper (the last Hankel-3 ingredient) runs through the
    unbuilt `γ₄` upper — the next numeric campaign. -/
theorem Rlambda4_le : Rle Rlambda4 (ofQ (⟨563, 1000⟩ : Q) (by decide)) := by
  have hsum : Rle Rlambda4
      (ofQ (add (⟨15458115, 10000000⟩ : Q) (⟨-9828225, 10000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add Rlambda4_arith_le genuineArchSeq4_le)
      (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

end UOR.Bridge.F1Square.Analysis
