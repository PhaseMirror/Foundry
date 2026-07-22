/-
F1 square — constant precision: **`λ₂ ≤ 0.1016`** (the THIRD two-sided Li coefficient) and the
**tightened `λ₃ ≥ 0.1436`** (the old certified lower was `0.0584`).

WHY. The order-2 CONTRACTION kill on the Gate-A finite list (`Square/GateAFiniteList.lean`)
refutes `2λ₃ ≈ a₀·2λ₁ + a₁·2λ₂` for all coefficients `≤ 1` by the strict inequality
`λ₁ + λ₂ < λ₃` — which needs `λ₂` from ABOVE (the `log 4π` LOWER consumer, like `λ₁ ≤ 0.02381`)
and `λ₃` from BELOW at better than the `Rlambda3_pos` margin. Ledger:

- `Rlambda2_le` : `λ₂ = 1 + γ − γ² − 2γ₁ − log4π + (3/4)ζ(2)
    ≤ 1 + 0.578 − 0.332929 + 0.1524 − 2.53038 + 0.75·1.646 = 0.101591 ≤ 1016/10⁴`
  (true value `0.0923457`). With `Rlambda2_pos`/`Rlambda2_ge`, `λ₂` is two-sided.
- `Rlambda3_ge` : arithmetic side tightened to `λ₃^{arith} ≥ 1.173914` (the stock
  `Rlambda3_arith_ge_r` gives `1.088713`) using `η₀ ≤ −0.577`, `η₁ ≤ 0.198685` (`reta1_le4`),
  and `η₂ ≤ −γ³ − 3γγ₁ − (3/2)γ₂ ≤ −0.192100033 + 0.1321308 + 0.021 = −0.038969`
  (`Rgamma_cube_ge`, `Rgamma_gamma1_ge`, `Rgamma2_ge_neg0014`); archimedean side reused
  (`archLoR_le : arch(3) ≥ −1.030276`). Total `λ₃ ≥ 0.143638 ≥ 1436/10⁴`
  (true value `0.207639`; the kill budget is `0.02381 + 0.1016 = 0.12541 < 0.1436`).

HONEST SCOPE. Finite certified brackets; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaThreeUpper
import Core.F1.Analysis.LambdaFourPos
import Core.F1.Analysis.LambdaGap

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- λ₂ from above (the third two-sided Li coefficient).
-- ===========================================================================

/-- **`λ₂ ≤ 1016/10⁴ = 0.1016`** (true value `0.0923457`) — with `Rlambda2_ge`, the third
    two-sided Li coefficient. Consumes the `log 4π` LOWER bracket. -/
theorem Rlambda2_le : Rle Rlambda2 (ofQ (⟨1016, 10000⟩ : Q) (by decide)) := by
  -- γ − γ² ≤ 0.578 − 0.577²
  have hsq : Rle (Rneg (Rmul Rgamma_h Rgamma_h))
      (ofQ (neg (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le Rgamma_sq_ge)
      (Rle_of_Req (Rneg_ofQ (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (by decide)))
  have hgg : Rle (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h))
      (ofQ (add (⟨578, 1000⟩ : Q) (neg (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add Rgamma_h_le_578 hsq) (Radd_Rle_ofQ_add (by decide) (by decide))
  have hone : Rle one (ofQ (⟨1, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl one)
  have h1 : Rle (Radd one (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)))
      (ofQ (add (⟨1, 1⟩ : Q) (add (⟨578, 1000⟩ : Q)
        (neg (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q))))) (by decide)) :=
    Rle_trans (Radd_le_add hone hgg) (Radd_Rle_ofQ_add (by decide) (by decide))
  -- −2γ₁ ≤ 0.1524
  have h2g1 : Rle (ofQ (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_ge_neg0762)
  have hng1 : Rle (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1))
      (ofQ (neg (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le h2g1)
      (Rle_of_Req (Rneg_ofQ (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)) (by decide)))
  have h2 : Rle (Radd (Radd one (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)))
      (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)))
      (ofQ (add (add (⟨1, 1⟩ : Q) (add (⟨578, 1000⟩ : Q)
          (neg (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)))))
        (neg (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add h1 hng1) (Radd_Rle_ofQ_add (by decide) (by decide))
  -- −log4π ≤ −2.53038 (the log-lower consumer)
  have hnl : Rle (Rneg Rlog4pic) (ofQ (neg (⟨253038, 100000⟩ : Q)) (by decide)) :=
    Rle_trans (Rneg_le Rlog4pic_ge)
      (Rle_of_Req (Rneg_ofQ (⟨253038, 100000⟩ : Q) (by decide)))
  have h3 : Rle (Radd (Radd (Radd one (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)))
      (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1))) (Rneg Rlog4pic))
      (ofQ (add (add (add (⟨1, 1⟩ : Q) (add (⟨578, 1000⟩ : Q)
          (neg (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)))))
        (neg (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)))) (neg (⟨253038, 100000⟩ : Q)))
        (by decide)) :=
    Rle_trans (Radd_le_add h2 hnl) (Radd_Rle_ofQ_add (by decide) (by decide))
  -- (3/4)ζ(2) ≤ 0.75·1.646
  have hz : Rle (Rmul (ofQ (⟨3, 4⟩ : Q) (by decide)) (zeta 2 (by decide)))
      (ofQ (mul (⟨3, 4⟩ : Q) (⟨1646, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_upper)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have h4 : Rle Rlambda2
      (ofQ (add (add (add (add (⟨1, 1⟩ : Q) (add (⟨578, 1000⟩ : Q)
          (neg (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)))))
        (neg (mul (⟨2, 1⟩ : Q) (⟨-762, 10000⟩ : Q)))) (neg (⟨253038, 100000⟩ : Q)))
        (mul (⟨3, 4⟩ : Q) (⟨1646, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Radd_le_add h3 hz) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans h4 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

-- ===========================================================================
-- λ₃ from below, tightened (arithmetic side sharp; archimedean side reused).
-- ===========================================================================

/-- `η₀ = −γ ≤ −0.577`. -/
private theorem eta0_le : Rle Reta0 (ofQ (neg (⟨577, 1000⟩ : Q)) (by decide)) :=
  Rle_trans (Rneg_le Rgamma_h_ge_577) (Rle_of_Req (Rneg_ofQ (⟨577, 1000⟩ : Q) (by decide)))

/-- `3η₀ ≤ −1.731`. -/
private theorem eta0_triple_le :
    Rle (nsmulR 3 Reta0) (ofQ (⟨-1731, 1000⟩ : Q) (by decide)) := by
  have hd : Rle (Radd Reta0 Reta0)
      (ofQ (add (neg (⟨577, 1000⟩ : Q)) (neg (⟨577, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Radd_le_add eta0_le eta0_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have ht : Rle (Radd (Radd Reta0 Reta0) Reta0)
      (ofQ (add (add (neg (⟨577, 1000⟩ : Q)) (neg (⟨577, 1000⟩ : Q)))
        (neg (⟨577, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Radd_le_add hd eta0_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans ht (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- `3η₁ ≤ 3·0.198685 = 0.596055` (`reta1_le4`, the `γ₁ ≤ −0.0677`-tight η₁ upper). -/
private theorem eta1_triple_le :
    Rle (nsmulR 3 Reta1) (ofQ (⟨596055, 1000000⟩ : Q) (by decide)) := by
  have hd : Rle (Radd Reta1 Reta1)
      (ofQ (add (⟨198685, 1000000⟩ : Q) (⟨198685, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add reta1_le4 reta1_le4) (Radd_Rle_ofQ_add (by decide) (by decide))
  have ht : Rle (Radd (Radd Reta1 Reta1) Reta1)
      (ofQ (add (add (⟨198685, 1000000⟩ : Q) (⟨198685, 1000000⟩ : Q))
        (⟨198685, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add hd reta1_le4) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans ht (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- **`η₂ ≤ −0.038969`** — the upper companion of `eta2_ge`, from the SHARP lower mixed
    product (`γγ₁ ≥ 0.578·(−0.0762)`, `Rgamma_gamma1_ge`) and `γ₂ ≥ −0.014`. -/
private theorem eta2_le : Rle (nsmulR 1 Reta2) (ofQ (⟨-38969, 1000000⟩ : Q) (by decide)) := by
  have hA : Rle (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
      (ofQ (neg (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)))
        (by decide)) :=
    Rle_trans (Rneg_le Rgamma_cube_ge)
      (Rle_of_Req (Rneg_ofQ (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (by decide)))
  have hBlo : Rle (ofQ (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))
        (by decide)) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma1_ge)
  have hnegB : Rle (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)))
      (ofQ (neg (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))) (by decide)) :=
    Rle_trans (Rneg_le hBlo)
      (Rle_of_Req (Rneg_ofQ (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))
        (by decide)))
  have hClo : Rle (ofQ (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma2_ge_neg0014)
  have hnegC : Rle (Rneg (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2))
      (ofQ (neg (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le hClo)
      (Rle_of_Req (Rneg_ofQ (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)) (by decide)))
  have hAB : Rle (Radd (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
      (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1))))
      (ofQ (add (neg (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q))))) (by decide)) :=
    Rle_trans (Radd_le_add hA hnegB) (Radd_Rle_ofQ_add (by decide) (by decide))
  have hsum : Rle Reta2
      (ofQ (add (add (neg (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))))
        (neg (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add hAB hnegC) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

set_option maxRecDepth 8192 in
/-- **`λ₃^{arith} ≥ 1173914/10⁶ = 1.173914`** (the stock `Rlambda3_arith_ge_r` gives
    `1.088713`; true value `1.22068`). -/
theorem Rlambda3_arith_ge_t :
    Rle (ofQ (⟨1173914, 1000000⟩ : Q) (by decide)) Rlambda3_arith := by
  have hzero : Rle zero (ofQ (⟨0, 1⟩ : Q) (by decide)) := Rle_of_Req (Req_refl zero)
  have h1 : Rle (Radd zero (nsmulR 3 Reta0))
      (ofQ (add (⟨0, 1⟩ : Q) (⟨-1731, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add hzero eta0_triple_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have h2 : Rle (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1))
      (ofQ (add (add (⟨0, 1⟩ : Q) (⟨-1731, 1000⟩ : Q)) (⟨596055, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add h1 eta1_triple_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have h3 : Rle (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2))
      (ofQ (add (add (add (⟨0, 1⟩ : Q) (⟨-1731, 1000⟩ : Q)) (⟨596055, 1000000⟩ : Q))
        (⟨-38969, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add h2 eta2_le) (Radd_Rle_ofQ_add (by decide) (by decide))
  have hT : Rle (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2))
      (ofQ (⟨-1173914, 1000000⟩ : Q) (by decide)) :=
    Rle_trans h3 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  exact Rneg_ofQ_le (by decide) hT

/-- **`λ₃ ≥ 1436/10⁴ = 0.1436`** (true value `0.207639`; the stock positivity lower was
    `0.0584`) — with `Rlambda3_le`, the second two-sided coefficient is now tight enough for
    the order-2 contraction kill: `λ₁ + λ₂ ≤ 0.12541 < 0.1436 ≤ λ₃`. -/
theorem Rlambda3_ge : Rle (ofQ (⟨1436, 10000⟩ : Q) (by decide)) Rlambda3 := by
  have hsum : Rle (ofQ (add (⟨1173914, 1000000⟩ : Q) (⟨-1030276, 1000000⟩ : Q)) (by decide))
      Rlambda3 :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
      (Radd_le_add Rlambda3_arith_ge_t archLoR_le)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum

-- ===========================================================================
-- The certified STRICT MONOTONICITY of the Li head.
-- ===========================================================================

/-- **`λ₁ < λ₂`** with the certified gap `λ₂ − λ₁ ≥ 0.05589` — from the disjoint brackets
    `λ₁ ≤ 0.02381 < 0.0797 ≤ λ₂`. (A sharper form of `Rlambda1_ne_Rlambda2`: not merely
    distinct, but ORDERED.) -/
theorem Rlambda1_lt_Rlambda2 : Pos (Rsub Rlambda2 Rlambda1) := by
  have hn : Rle (ofQ (neg (⟨2381, 100000⟩ : Q)) (by decide)) (Rneg Rlambda1) :=
    Rneg_ofQ_le (by decide) Rlambda1_le
  have hsum : Rle (ofQ (add (⟨797, 10000⟩ : Q) (neg (⟨2381, 100000⟩ : Q))) (by decide))
      (Rsub Rlambda2 Rlambda1) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add Rlambda2_ge hn)
  exact Pos_of_Rle_ofQ (c := add (⟨797, 10000⟩ : Q) (neg (⟨2381, 100000⟩ : Q)))
    (by decide) (by decide) hsum

/-- **`λ₂ < λ₃`** with the certified gap `λ₃ − λ₂ ≥ 0.042` — from `λ₂ ≤ 0.1016 < 0.1436 ≤ λ₃`. -/
theorem Rlambda2_lt_Rlambda3 : Pos (Rsub Rlambda3 Rlambda2) := by
  have hn : Rle (ofQ (neg (⟨1016, 10000⟩ : Q)) (by decide)) (Rneg Rlambda2) :=
    Rneg_ofQ_le (by decide) Rlambda2_le
  have hsum : Rle (ofQ (add (⟨1436, 10000⟩ : Q) (neg (⟨1016, 10000⟩ : Q))) (by decide))
      (Rsub Rlambda3 Rlambda2) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add Rlambda3_ge hn)
  exact Pos_of_Rle_ofQ (c := add (⟨1436, 10000⟩ : Q) (neg (⟨1016, 10000⟩ : Q)))
    (by decide) (by decide) hsum

/-- **The certified head of the Li sequence is STRICTLY INCREASING**: `λ₁ < λ₂ < λ₃`.

    This is the shape any future *convex-combination* prune consumes (`Σ aᵢ = 1`, `aᵢ ≥ 0`
    forces `λ_{K+1} ≤ max λᵢ = λ_K`, refuted by `λ_K < λ_{K+1}`) — a far cheaper lever than
    the contraction prune's `λ_{K+1} > λ₁ + … + λ_K`. Extending it to `λ₃ < λ₄` needs a `λ₄`
    LOWER above `0.2554` (true `λ₄ ≈ 0.3858`, so a ~34% margin — feasible, but blocked on the
    `γ₁` bracket, whose 12%-wide spread dominates the `η₁` slack at coefficient `6`). -/
theorem Rlambda_head_increasing :
    Pos (Rsub Rlambda2 Rlambda1) ∧ Pos (Rsub Rlambda3 Rlambda2) :=
  ⟨Rlambda1_lt_Rlambda2, Rlambda2_lt_Rlambda3⟩

end UOR.Bridge.F1Square.Analysis
