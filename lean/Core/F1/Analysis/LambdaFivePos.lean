/-
F1 square — n=5 closure STEP 2-4: `Pos Rlambda5` from the tightened brackets.

Builds ON `LambdaFivePrecision` (STEP 1, the tightened γ₁/γ₂/γ₃ + ζ(3) brackets, IMPORTED here so they
are opaque — matching how `LambdaFourPos` imports its brackets). λ₅^arith lower bound (η-anchor uppers) +
arch(5) lower bound + the `Pos Rlambda5` assembly, mirroring `LambdaFourPos`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import Core.F1.Analysis.LambdaFivePrecision
import Core.F1.Analysis.LambdaFourPos
import Core.F1.Analysis.GammaThreeLower
import Core.F1.Analysis.GammaFourLower
import Core.F1.Analysis.LambdaFive

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000
set_option maxRecDepth 8192

-- ===========================================================================
-- STEP 2 — `λ₅^{arith} ≥ arithLoQ5` (`≈ +1.0183`) from the η-anchor uppers
--          on the TIGHT brackets.  `λ₅^{arith} = −(5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄)`.
-- ===========================================================================

/-! ### 2a. Tight product bounds (mirrors of the `LambdaFourPos` ones, tight brackets). -/

/-- **`γ²·γ₁ ≤ (577/1000)²·(−69/1000)`** — sharp upper, using the TIGHT `γ₁ ≤ −69/1000`
    (`Rgamma1_le_neg069`).  (`γ² ≥ γ_lo²`, `γ₁ ≤ 0`, `γ₁ ≤ γ₁_hi`.) -/
theorem Rgamma_sq_gamma1_le_t :
    Rle (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)
      (ofQ (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨-69, 1000⟩ : Q)) (by decide)) := by
  have hg1nonpos : Rle Rgamma1 zero :=
    Rle_trans Rgamma1_le_neg069 (ofQ_nonpos (by decide) (by decide))
  refine Rle_trans (Rmul_le_Rmul_right_nonpos Rgamma_sq_ge hg1nonpos) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg069) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))

/-- **`γ·γ₂ ≤ (577/1000)·(−3/1000)`** — TIGHT: `γ₂ ≤ −3/1000` is negative, so `γ·γ₂ ≤ γ_lo·γ₂_hi`
    (`γ·γ₂ ≤ γ·γ₂_hi` by `γ ≥ 0`, then `γ·γ₂_hi ≤ γ_lo·γ₂_hi` by antitone in a nonpos factor). -/
theorem Rgamma_gamma2_le_t :
    Rle (Rmul Rgamma_h Rgamma2) (ofQ (mul (⟨577, 1000⟩ : Q) (⟨-3, 1000⟩ : Q)) (by decide)) := by
  have hg2hi_nonpos : Rle (ofQ (⟨-3, 1000⟩ : Q) (by decide)) zero := ofQ_nonpos (by decide) (by decide)
  refine Rle_trans (Rmul_le_Rmul_left Rgamma_h_nonneg Rgamma2_le_neg0003) ?_
  refine Rle_trans (Rmul_le_Rmul_right_nonpos Rgamma_h_ge_577 hg2hi_nonpos) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))

/-- **`γ⁵ ≥ (577/1000)⁵`** — five `≥ γ_lo` steps extending `Rgamma_cube_ge`.
    `γ⁵ = ((((γ·γ)·γ)·γ)·γ)` (the `Reta4` shape). -/
theorem Rgamma_pow5_ge :
    Rle (ofQ (mul (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)) (by decide))
      (Rmul (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h) Rgamma_h) := by
  -- γ⁴ ≥ γ_lo⁴
  have hpow4 : Rle (ofQ (mul (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (⟨577, 1000⟩ : Q)) (by decide))
      (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_cube_ge) ?_
    exact Rmul_le_Rmul_left (Rnonneg_Rmul (Rnonneg_Rmul Rgamma_h_nonneg Rgamma_h_nonneg) Rgamma_h_nonneg)
      Rgamma_h_ge_577
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) hpow4) ?_
  exact Rmul_le_Rmul_left
    (Rnonneg_Rmul (Rnonneg_Rmul (Rnonneg_Rmul Rgamma_h_nonneg Rgamma_h_nonneg) Rgamma_h_nonneg)
      Rgamma_h_nonneg) Rgamma_h_ge_577

/-- **`γ³·γ₁ ≥ (578/1000)³·(−762/10000)`** — lower bound (`γ₁ < 0`, so min at `γ³` max, `γ₁` min).
    `γ³·γ₁ = ((γ·γ)·γ)·γ₁`. -/
theorem Rgamma_cube_gamma1_ge :
    Rle (ofQ (mul (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)) (⟨-762, 10000⟩ : Q))
        (by decide))
      (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma1) := by
  -- γ³ ≤ γ_hi³
  have hcube_le : Rle (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h)
      (ofQ (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q)) (by decide)) := by
    refine Rle_trans (Rmul_le_Rmul_right Rgamma_h_nonneg Rgamma_sq_le) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_le_578) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))
  have hg1lo : Rle (ofQ (⟨-762, 10000⟩ : Q) (by decide)) Rgamma1 := Rgamma1_ge_neg0762
  have hg1nonpos : Rle Rgamma1 zero :=
    Rle_trans Rgamma1_le_neg069 (ofQ_nonpos (by decide) (by decide))
  have hcube_nonneg : Rnonneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) :=
    Rnonneg_Rmul (Rnonneg_Rmul Rgamma_h_nonneg Rgamma_h_nonneg) Rgamma_h_nonneg
  -- γ³·γ₁ ≥ γ³·γ₁_lo (γ³ ≥ 0)  ≥ γ_hi³·γ₁_lo (γ₁_lo ≤ 0, cube ≤ γ_hi³)
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right_nonpos hcube_le (ofQ_nonpos (by decide) (by decide))) ?_
  exact Rmul_le_Rmul_left hcube_nonneg hg1lo

/-- **`γ·γ₁² ≥ (577/1000)·(69/1000)²`** — lower bound: `γ ≥ 0`, `γ₁² ≥ γ₁_hi²` (`|γ₁| ≥ 69/1000`
    since `γ₁ ≤ −69/1000`).  `γ·γ₁² = γ·(γ₁·γ₁)`. -/
theorem Rgamma_gamma1sq_ge :
    Rle (ofQ (mul (⟨577, 1000⟩ : Q) (mul (⟨69, 1000⟩ : Q) (⟨69, 1000⟩ : Q))) (by decide))
      (Rmul Rgamma_h (Rmul Rgamma1 Rgamma1)) := by
  -- γ₁² ≥ (69/1000)² :  γ₁ ≤ −69/1000 ≤ 0, so (−γ₁) ≥ 69/1000 ≥ 0, square monotone.
  have hg1sq_ge : Rle (ofQ (mul (⟨69, 1000⟩ : Q) (⟨69, 1000⟩ : Q)) (by decide))
      (Rmul Rgamma1 Rgamma1) := by
    have hb : Rle (ofQ (⟨69, 1000⟩ : Q) (by decide)) (Rneg Rgamma1) :=
      Rle_trans (Rle_of_Req (Req_trans (ofQ_congr (by decide) (by decide) (by decide))
          (Req_symm (Rneg_ofQ (⟨-69, 1000⟩ : Q) (by decide)))))
        (Rle_Rneg Rgamma1_le_neg069)
    have hnn : Rnonneg (ofQ (⟨69, 1000⟩ : Q) (by decide)) := Rnonneg_ofQ (by decide) (by decide)
    have hng1_nonneg : Rnonneg (Rneg Rgamma1) :=
      Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg hnn) hb)
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
    refine Rle_trans (Rmul_le_Rmul_right hnn hb) ?_
    refine Rle_trans (Rmul_le_Rmul_left hng1_nonneg hb) ?_
    exact Rle_of_Req (Rneg_sq Rgamma1)
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) Rgamma_h_ge_577) ?_
  exact Rmul_le_Rmul_left Rgamma_h_nonneg hg1sq_ge

/-- **`γ²·γ₂ ≥ (578/1000)²·(−14/1000)`** — lower bound (`γ₂ < 0`: min at `γ²` max, `γ₂` min).
    `γ²·γ₂ = (γ·γ)·γ₂`. -/
theorem Rgamma_sq_gamma2_ge :
    Rle (ofQ (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨-14, 1000⟩ : Q)) (by decide))
      (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma2) := by
  have hsq_nonneg : Rnonneg (Rmul Rgamma_h Rgamma_h) := Rnonneg_Rmul Rgamma_h_nonneg Rgamma_h_nonneg
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right_nonpos Rgamma_sq_le (ofQ_nonpos (by decide) (by decide))) ?_
  exact Rmul_le_Rmul_left hsq_nonneg Rgamma2_ge_neg0014

/-- **`γ₁·γ₂ ≥ (−69/1000)·(−3/1000)`** — both negative (product `> 0`), min at the least magnitudes
    `γ₁ = γ₁_hi = −69/1000`, `γ₂ = γ₂_hi = −3/1000`. -/
theorem Rgamma1_gamma2_ge :
    Rle (ofQ (mul (⟨-69, 1000⟩ : Q) (⟨-3, 1000⟩ : Q)) (by decide)) (Rmul Rgamma1 Rgamma2) := by
  -- γ₁·γ₂ = (−(−γ₁))·(−(−γ₂)) = (−γ₁)(−γ₂), with (−γ₁) ≥ 69/1000, (−γ₂) ≥ 3/1000.
  have h1 : Rle (ofQ (⟨69, 1000⟩ : Q) (by decide)) (Rneg Rgamma1) :=
    Rle_trans (Rle_of_Req (Req_trans (ofQ_congr (by decide) (by decide) (by decide))
        (Req_symm (Rneg_ofQ (⟨-69, 1000⟩ : Q) (by decide)))))
      (Rle_Rneg Rgamma1_le_neg069)
  have h2 : Rle (ofQ (⟨3, 1000⟩ : Q) (by decide)) (Rneg Rgamma2) :=
    Rle_trans (Rle_of_Req (Req_trans (ofQ_congr (by decide) (by decide) (by decide))
        (Req_symm (Rneg_ofQ (⟨-3, 1000⟩ : Q) (by decide)))))
      (Rle_Rneg Rgamma2_le_neg0003)
  have hn1 : Rnonneg (ofQ (⟨69, 1000⟩ : Q) (by decide)) := Rnonneg_ofQ (by decide) (by decide)
  have hn2 : Rnonneg (Rneg Rgamma1) := Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg hn1) h1)
  have hprod : Rle (ofQ (mul (⟨69, 1000⟩ : Q) (⟨3, 1000⟩ : Q)) (by decide))
      (Rmul (Rneg Rgamma1) (Rneg Rgamma2)) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (by decide) (by decide)) h1) ?_
    exact Rmul_le_Rmul_left hn2 h2
  have hnegneg : Req (Rmul (Rneg Rgamma1) (Rneg Rgamma2)) (Rmul Rgamma1 Rgamma2) :=
    Req_trans (Rmul_neg_left Rgamma1 (Rneg Rgamma2))
      (Req_trans (Rneg_congr (Rmul_neg_right Rgamma1 Rgamma2)) (Rneg_neg (Rmul Rgamma1 Rgamma2)))
  refine Rle_trans ?_ (Rle_of_Req hnegneg)
  refine Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hprod

/-- **`γ·γ₃ ≥ (578/1000)·(−1/20)`** — `γ ≥ 0`, `γ₃ ≥ −1/20` (`Rgamma3_ge_neg005`); min at `γ` max,
    `γ₃` min. -/
theorem Rgamma_gamma3_ge :
    Rle (ofQ (mul (⟨578, 1000⟩ : Q) (⟨-1, 20⟩ : Q)) (by decide)) (Rmul Rgamma_h Rgamma3) := by
  -- γ·γ₃ ≥ γ·γ₃_lo (γ ≥ 0)  ≥ γ_hi·γ₃_lo (γ₃_lo ≤ 0)
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right_nonpos Rgamma_h_le_578 (ofQ_nonpos (by decide) (by decide))) ?_
  exact Rmul_le_Rmul_left Rgamma_h_nonneg Rgamma3_ge_neg005

/-! ### 2b. η-anchor uppers on the TIGHT brackets (rounded to `10⁶`). -/

set_option maxRecDepth 8192 in
/-- **`η₁ = γ² + 2γ₁ ≤ 196084/10⁶`** — tightened with `γ₁ ≤ −69/1000`. -/
theorem reta1_le5 : Rle Reta1 (ofQ (⟨196084, 1000000⟩ : Q) (by decide)) := by
  unfold Reta1
  have hlin : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨-69, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg069)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  refine Rle_trans (Radd_le_add Rgamma_sq_le hlin) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (by decide) (by decide))) ?_
  exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)

set_option maxRecDepth 8192 in
/-- **`η₂ = −γ³ − 3γγ₁ − (3/2)γ₂ ≤ −38968/10⁶`** — TIGHT (`γ₂ ≤ −3/1000` makes `−(3/2)γ₂` small
    and positive; `γγ₁ ≥ γ_hi·γ₁_lo` most negative → `−3γγ₁` largest). -/
theorem reta2_le5 : Rle Reta2 (ofQ (⟨-38968, 1000000⟩ : Q) (by decide)) := by
  unfold Reta2
  have hN : Rle (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
      (ofQ (⟨-192100, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rle_Rneg (Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) Rgamma_cube_ge))
      (Rle_of_Req (Req_trans (Rneg_ofQ (⟨192100, 1000000⟩ : Q) (by decide))
        (ofQ_congr (by decide) (by decide) (by decide))))
  -- −3γγ₁ ≤ −3·(γ_hi·γ₁_lo)  (γγ₁ ≥ γ_hi·γ₁_lo)
  have hC : Rle (ofQ (mul (⟨3, 1⟩ : Q) (⟨-44044, 1000000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)) := by
    have hgg : Rle (ofQ (⟨-44044, 1000000⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1) :=
      Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) Rgamma_gamma1_ge
    exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hgg)
  -- −(3/2)γ₂ ≤ −(3/2)·γ₂_lo = −(3/2)·(−14/1000) = 21/1000
  have hD : Rle (ofQ (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma2_ge_neg0014)
  refine Rle_trans (Rsub_le_sub (Rsub_le_sub hN hC) hD) ?_
  refine Rle_trans (Rle_of_Req (Rsub_congr
    (Rsub_ofQ_ofQ (by decide) (Qmul_den_pos (by decide) (by decide))) (Req_refl _))) ?_
  refine Rle_trans (Rle_of_Req (Rsub_ofQ_ofQ
    (Qsub_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide)))) ?_
  exact Rle_ofQ_ofQ (Qsub_den_pos (Qsub_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide))) (by decide) (by decide)

set_option maxRecDepth 8192 in
/-- **`η₃ ≤ 44543/10⁶`** — `η₃ = γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃` on the TIGHT brackets
    (`Rgamma_pow4_le`, `Rgamma_sq_gamma1_le_t`, `Rgamma1_sq_le`, `Rgamma_gamma2_le_t`,
    `Rgamma3_le_1_40`), each rounded to `10⁶`. -/
theorem reta3_le5 : Rle Reta3 (ofQ (⟨44543, 1000000⟩ : Q) (by decide)) := by
  unfold Reta3
  have hT1 : Rle (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
      (ofQ (⟨111613, 1000000⟩ : Q) (by decide)) :=
    Rle_trans Rgamma_pow4_le (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have hT2 : Rle (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1))
      (ofQ (⟨-91888, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_sq_gamma1_le_t)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have hT3 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1))
      (ofQ (⟨11613, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_sq_le)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have hT4 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma2))
      (ofQ (⟨-3462, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma2_le_t)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  have hT5 : Rle (Rmul (ofQ (⟨2, 3⟩ : Q) (by decide)) Rgamma3)
      (ofQ (⟨16667, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma3_le_1_40)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
        (Rle_ofQ_ofQ (by decide) (by decide) (by decide)))
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add hT1 hT2) hT3) hT4) hT5) ?_
  have hD : 0 < (1000000 : Nat) := by decide
  refine Rle_of_Req (Req_trans (Radd_congr (Radd_congr (Radd_congr
    (Radd_ofQ_same 111613 (-91888) 1000000 hD) (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_)
  refine Req_trans (Radd_congr (Radd_congr (Radd_ofQ_same 19725 11613 1000000 hD)
    (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_ofQ_same 31338 (-3462) 1000000 hD) (Req_refl _)) ?_
  exact Radd_ofQ_same 27876 16667 1000000 hD

set_option maxRecDepth 8192 in
set_option maxHeartbeats 8000000 in
/-- **`η₄ ≤ 72809/10⁶`** — seven product-lowers (a shared `hD` den proof) summed incrementally, negated. -/
theorem reta4_le5 : Rle Reta4 (ofQ (⟨72809, 1000000⟩ : Q) (by decide)) := by
  unfold Reta4
  have hD : 0 < (1000000 : Nat) := by decide
  have hB1 : Rle (ofQ (⟨63955, 1000000⟩ : Q) hD) (Rmul (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h) Rgamma_h) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide)) Rgamma_pow5_ge
  have hB2 : Rle (ofQ (⟨-73572, 1000000⟩ : Q) hD) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma1)) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide))
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_cube_gamma1_ge))
  have hB3 : Rle (ofQ (⟨13735, 1000000⟩ : Q) hD) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul Rgamma_h (Rmul Rgamma1 Rgamma1))) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide))
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma1sq_ge))
  have hB4 : Rle (ofQ (⟨-11693, 1000000⟩ : Q) hD) (Rmul (ofQ (⟨5, 2⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma2)) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide))
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_sq_gamma2_ge))
  have hB5 : Rle (ofQ (⟨517, 1000000⟩ : Q) hD) (Rmul (ofQ (⟨5, 2⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma2)) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide))
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_gamma2_ge))
  have hB6 : Rle (ofQ (⟨-24084, 1000000⟩ : Q) hD) (Rmul (ofQ (⟨5, 6⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma3)) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide))
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma3_ge))
  have hB7 : Rle (ofQ (⟨-41667, 1000000⟩ : Q) hD) (Rmul (ofQ (⟨5, 24⟩ : Q) (by decide)) Rgamma4) :=
    Rle_trans (Rle_ofQ_ofQ hD (by decide) (by decide))
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
        (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma4_ge_neg02))
  have hSum : Rle (ofQ (⟨-72809, 1000000⟩ : Q) hD)
      (Radd (Radd (Radd (Radd (Radd (Radd
        (Rmul (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h) Rgamma_h)
        (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma1)))
        (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul Rgamma_h (Rmul Rgamma1 Rgamma1))))
        (Rmul (ofQ (⟨5, 2⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma2)))
        (Rmul (ofQ (⟨5, 2⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma2)))
        (Rmul (ofQ (⟨5, 6⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma3)))
        (Rmul (ofQ (⟨5, 24⟩ : Q) (by decide)) Rgamma4)) := by
    refine Rle_trans (Rle_of_Req ?_)
      (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add
        hB1 hB2) hB3) hB4) hB5) hB6) hB7)
    have e1 : Req (Radd (ofQ (⟨63955,1000000⟩:Q) hD) (ofQ (⟨-73572,1000000⟩:Q) hD))
        (ofQ (⟨-9617,1000000⟩:Q) hD) := Radd_ofQ_same 63955 (-73572) 1000000 hD
    have e2 : Req _ (ofQ (⟨4118,1000000⟩:Q) hD) :=
      Req_trans (Radd_congr e1 (Req_refl (ofQ (⟨13735,1000000⟩:Q) hD))) (Radd_ofQ_same (-9617) 13735 1000000 hD)
    have e3 : Req _ (ofQ (⟨-7575,1000000⟩:Q) hD) :=
      Req_trans (Radd_congr e2 (Req_refl (ofQ (⟨-11693,1000000⟩:Q) hD))) (Radd_ofQ_same 4118 (-11693) 1000000 hD)
    have e4 : Req _ (ofQ (⟨-7058,1000000⟩:Q) hD) :=
      Req_trans (Radd_congr e3 (Req_refl (ofQ (⟨517,1000000⟩:Q) hD))) (Radd_ofQ_same (-7575) 517 1000000 hD)
    have e5 : Req _ (ofQ (⟨-31142,1000000⟩:Q) hD) :=
      Req_trans (Radd_congr e4 (Req_refl (ofQ (⟨-24084,1000000⟩:Q) hD))) (Radd_ofQ_same (-7058) (-24084) 1000000 hD)
    have e6 : Req _ (ofQ (⟨-72809,1000000⟩:Q) hD) :=
      Req_trans (Radd_congr e5 (Req_refl (ofQ (⟨-41667,1000000⟩:Q) hD))) (Radd_ofQ_same (-31142) (-41667) 1000000 hD)
    exact Req_symm e6
  refine Rle_trans (Rle_Rneg hSum) ?_
  exact Rle_of_Req (Req_trans (Rneg_ofQ (⟨-72809, 1000000⟩ : Q) hD)
    (ofQ_congr (by decide) (by decide) (by decide)))

/-! ### 2c. The `nsmulR` collapses (`5`, `10`) and the S-sum. -/

/-- `nsmulR 5 X ≤ 5·xu`. -/
theorem nsmulR5_le {X : Real} {xu : Q} (hxu : 0 < xu.den) (h : Rle X (ofQ xu hxu)) :
    Rle (nsmulR 5 X) (ofQ (mul (⟨5, 1⟩ : Q) xu) (Qmul_den_pos (by decide) hxu)) := by
  show Rle (Radd (Radd (Radd (Radd X X) X) X) X) _
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add h h) h) h) h)
    (Rle_of_Req ?_)
  refine Req_of_seq_Qeq (fun n => ?_)
  show Qeq (add (add (add (add xu xu) xu) xu) xu) (mul (⟨5, 1⟩ : Q) xu)
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- `nsmulR 10 X ≤ 10·xu`. -/
theorem nsmulR10_le {X : Real} {xu : Q} (hxu : 0 < xu.den) (h : Rle X (ofQ xu hxu)) :
    Rle (nsmulR 10 X) (ofQ (mul (⟨10, 1⟩ : Q) xu) (Qmul_den_pos (by decide) hxu)) := by
  show Rle (Radd (Radd (Radd (Radd (Radd (Radd (Radd (Radd (Radd X X) X) X) X) X) X) X) X) X) _
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add
    (Radd_le_add (Radd_le_add (Radd_le_add h h) h) h) h) h) h) h) h) h) (Rle_of_Req ?_)
  refine Req_of_seq_Qeq (fun n => ?_)
  show Qeq (add (add (add (add (add (add (add (add (add xu xu) xu) xu) xu) xu) xu) xu) xu) xu)
    (mul (⟨10, 1⟩ : Q) xu)
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- Collapse SIX same-denominator `ofQ` literals and compare in ONE `decide` (mirror of
    `Radd5_ofQ_le`, one more `Radd` layer — the intermediate sums stay SYMBOLIC `Int`). -/
theorem Radd6_ofQ_le (a b c d e f t : Int) (D : Nat) (hD : 0 < D)
    (h : Qle (⟨a + b + c + d + e + f, D⟩ : Q) (⟨t, D⟩ : Q)) :
    Rle (Radd (Radd (Radd (Radd (Radd (ofQ (⟨a, D⟩ : Q) hD) (ofQ (⟨b, D⟩ : Q) hD))
        (ofQ (⟨c, D⟩ : Q) hD)) (ofQ (⟨d, D⟩ : Q) hD)) (ofQ (⟨e, D⟩ : Q) hD))
        (ofQ (⟨f, D⟩ : Q) hD)) (ofQ (⟨t, D⟩ : Q) hD) := by
  refine Rle_trans (Rle_of_Req (Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_congr
      (Radd_ofQ_same a b D hD) (Req_refl _)) (Req_refl _)) (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_ofQ_same (a + b) c D hD)
        (Req_refl _)) (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr (Radd_congr (Radd_ofQ_same (a + b + c) d D hD)
        (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr (Radd_ofQ_same (a + b + c + d) e D hD) (Req_refl _))
      (Radd_ofQ_same (a + b + c + d + e) f D hD)))))) ?_
  exact Rle_ofQ_ofQ hD hD h

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- The inner sum `S = 5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄ ≤ −1018316/10⁶` (`Rlambda5_arith = −S`),
    with the η-anchors in explicit `nsmulR` form (the `choose 5 k` are `5,10,10,5,1`). -/
theorem Rlambda5_S_le :
    Rle (Radd (Radd (Radd (Radd (Radd zero (nsmulR 5 Reta0)) (nsmulR 10 Reta1)) (nsmulR 10 Reta2))
        (nsmulR 5 Reta3)) (nsmulR 1 Reta4)) (ofQ (⟨-1018316, 1000000⟩ : Q) (by decide)) := by
  have h0 : Rle (nsmulR 5 Reta0) (ofQ (⟨-2885000, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR5_le (by decide) reta0_le) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h1 : Rle (nsmulR 10 Reta1) (ofQ (⟨1960840, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR10_le (by decide) reta1_le5) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h2 : Rle (nsmulR 10 Reta2) (ofQ (⟨-389680, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR10_le (by decide) reta2_le5) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h3 : Rle (nsmulR 5 Reta3) (ofQ (⟨222715, 1000000⟩ : Q) (by decide)) :=
    Rle_trans (nsmulR5_le (by decide) reta3_le5) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h4 : Rle (nsmulR 1 Reta4) (ofQ (⟨72809, 1000000⟩ : Q) (by decide)) := by
    show Rle Reta4 _; exact reta4_le5
  have hz : Rle zero (ofQ (⟨0, 1000000⟩ : Q) (by decide)) :=
    Rle_zero_of_Rnonneg (Rnonneg_ofQ (by decide) (by decide))
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add hz h0) h1) h2)
    h3) h4) ?_
  exact Radd6_ofQ_le 0 (-2885000) 1960840 (-389680) 222715 72809 (-1018316) 1000000 (by decide)
    (by decide)

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- **`λ₅^{arith} ≥ 1018316/10⁶`** (`= −(5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄)`, true `≈ 1.459`), from the
    η-anchor uppers on the TIGHT brackets via `Rlambda5_S_le`.  `arithLoQ5 = 1018316/10⁶`. -/
theorem Rlambda5_arith_ge_r :
    Rle (ofQ (neg (⟨-1018316, 1000000⟩ : Q)) (by decide)) Rlambda5_arith := by
  unfold Rlambda5_arith
  refine Rle_trans (Rle_of_Req (Req_symm (Rneg_ofQ (⟨-1018316, 1000000⟩ : Q) (by decide))))
    (Rle_Rneg Rlambda5_S_le)

-- ===========================================================================
-- STEP 3 — The archimedean lower bound `genuineArchSeq 5 ≥ archLoQ5` (`= −187/200 = −0.935`).
--   arch(5) = 1 − (5/2)(γ+log4π) + (15/2)ζ(2) − (35/4)ζ(3) + (75/16)ζ(4) − (31/32)ζ(5).
-- ===========================================================================

theorem m5xu_den_pos : 0 < (mul (⟨5, 1⟩ : Q) xuQ).den := Qmul_den_pos (by decide) xuQ_den_pos
theorem half_m5xu_den_pos : 0 < (mul (⟨1, 2⟩ : Q) (mul (⟨5, 1⟩ : Q) xuQ)).den :=
  Qmul_den_pos (by decide) m5xu_den_pos
theorem ilq5_den_pos : 0 < (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨5, 1⟩ : Q) xuQ))).den :=
  Qsub_den_pos (by decide) half_m5xu_den_pos
theorem iilq5_den_pos : 0 < (add (add (add (add (⟨0, 1⟩ : Q) (mul (⟨30, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
    (mul (⟨-70, 8⟩ : Q) (⟨1205, 1000⟩ : Q))) (mul (⟨75, 16⟩ : Q) (⟨1082, 1000⟩ : Q)))
    (mul (⟨-31, 32⟩ : Q) (⟨1052, 1000⟩ : Q))).den :=
  add_den_pos (add_den_pos (add_den_pos (add_den_pos (by decide)
    (Qmul_den_pos (by decide) (by decide))) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (by decide) (by decide))) (Qmul_den_pos (by decide) (by decide))

/-- The certified rational lower bound on `genuineArchSeq 5` (`arch(5) ≈ −0.935`). -/
def archLoQ5 : Q :=
  add (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨5, 1⟩ : Q) xuQ)))
    (add (add (add (add (⟨0, 1⟩ : Q) (mul (⟨30, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
        (mul (⟨-70, 8⟩ : Q) (⟨1205, 1000⟩ : Q))) (mul (⟨75, 16⟩ : Q) (⟨1082, 1000⟩ : Q)))
        (mul (⟨-31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)))

theorem archLoQ5_den_pos : 0 < archLoQ5.den := add_den_pos ilq5_den_pos iilq5_den_pos

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- Archimedean part (I): `one − (5/2)(γ + log 4π) ≥ 1 − (5/2)·xuQ`. -/
theorem archI5_ge :
    Rle (ofQ (Qsub (⟨1, 1⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨5, 1⟩ : Q) xuQ))) ilq5_den_pos)
      (Rsub one (Rhalf (nsmulR 5 (Radd Rgamma_h Rlog4pic)))) := by
  have hX : Rle (Radd Rgamma_h Rlog4pic) (ofQ xuQ xuQ_den_pos) :=
    Rle_trans (Radd_le_add Rgamma_h_le_578 Rlog4pic_le)
      (Rle_of_Req (Radd_ofQ_ofQ (a := (⟨578, 1000⟩ : Q)) (b := (⟨25316, 10000⟩ : Q))
        (by decide) (by decide)))
  have hHalf : Rle (Rhalf (nsmulR 5 (Radd Rgamma_h Rlog4pic)))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (⟨5, 1⟩ : Q) xuQ)) half_m5xu_den_pos) :=
    Rle_trans (Rhalf_le_Rhalf (nsmulR5_le xuQ_den_pos hX))
      (Rle_of_Req (Rhalf_ofQ _ m5xu_den_pos))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (by decide) half_m5xu_den_pos))) ?_
  exact Rsub_le_sub (Rle_refl _) hHalf

set_option maxRecDepth 8192 in
/-- `(15/2)·ζ(2) ≤ genArchTerm 5 2`. -/
theorem archTerm5_2_ge :
    Rle (ofQ (mul (⟨30, 4⟩ : Q) (⟨1644, 1000⟩ : Q)) (by decide)) (genArchTerm 5 2 (by decide)) := by
  unfold genArchTerm
  exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_lower_tight)

set_option maxRecDepth 8192 in
/-- `(−35/4)·ζ(3) ≤ genArchTerm 5 3` (negative coeff, via `Rneg`; uses the TIGHT `ζ(3) ≤ 1205/1000`). -/
theorem archTerm5_3_ge :
    Rle (ofQ (mul (⟨-70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (by decide)) (genArchTerm 5 3 (by decide)) := by
  unfold genArchTerm
  have hup : Rle (Rmul (ofQ (⟨70, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
      (ofQ (mul (⟨70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta3_le_1205)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have heq2 : Req (Rneg (Rmul (ofQ (⟨70, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (Rmul (ofQ (⟨-70, 8⟩ : Q) (by decide)) (zeta 3 (by decide))) :=
    Req_trans (Req_symm (Rmul_neg_left (ofQ (⟨70, 8⟩ : Q) (by decide)) (zeta 3 (by decide))))
      (Rmul_congr (Rneg_ofQ (⟨70, 8⟩ : Q) (by decide)) (Req_refl _))
  have heq1 : Req (ofQ (mul (⟨-70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (by decide))
      (Rneg (ofQ (mul (⟨70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (by decide))) :=
    Req_trans (Req_of_seq_Qeq (fun n => by
        show Qeq (mul (⟨-70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (neg (mul (⟨70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)));
        decide))
      (Req_symm (Rneg_ofQ (mul (⟨70, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (by decide)))
  exact Rle_trans (Rle_of_Req heq1) (Rle_trans (Rle_Rneg hup) (Rle_of_Req heq2))

set_option maxRecDepth 8192 in
/-- `(75/16)·ζ(4) ≤ genArchTerm 5 4`. -/
theorem archTerm5_4_ge :
    Rle (ofQ (mul (⟨75, 16⟩ : Q) (⟨1082, 1000⟩ : Q)) (by decide)) (genArchTerm 5 4 (by decide)) := by
  unfold genArchTerm
  exact Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta4_lower)

set_option maxRecDepth 8192 in
/-- `(−31/32)·ζ(5) ≤ genArchTerm 5 5` (negative coeff, via `Rneg`; uses `ζ(5) ≤ 1052/1000`). -/
theorem archTerm5_5_ge :
    Rle (ofQ (mul (⟨-31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)) (by decide)) (genArchTerm 5 5 (by decide)) := by
  unfold genArchTerm
  have hup : Rle (Rmul (ofQ (⟨31, 32⟩ : Q) (by decide)) (zeta 5 (by decide)))
      (ofQ (mul (⟨31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta5_upper)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have heq2 : Req (Rneg (Rmul (ofQ (⟨31, 32⟩ : Q) (by decide)) (zeta 5 (by decide))))
      (Rmul (ofQ (⟨-31, 32⟩ : Q) (by decide)) (zeta 5 (by decide))) :=
    Req_trans (Req_symm (Rmul_neg_left (ofQ (⟨31, 32⟩ : Q) (by decide)) (zeta 5 (by decide))))
      (Rmul_congr (Rneg_ofQ (⟨31, 32⟩ : Q) (by decide)) (Req_refl _))
  have heq1 : Req (ofQ (mul (⟨-31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)) (by decide))
      (Rneg (ofQ (mul (⟨31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)) (by decide))) :=
    Req_trans (Req_of_seq_Qeq (fun n => by
        show Qeq (mul (⟨-31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)) (neg (mul (⟨31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)));
        decide))
      (Req_symm (Rneg_ofQ (mul (⟨31, 32⟩ : Q) (⟨1052, 1000⟩ : Q)) (by decide)))
  exact Rle_trans (Rle_of_Req heq1) (Rle_trans (Rle_Rneg hup) (Rle_of_Req heq2))

set_option maxRecDepth 8192 in
/-- Archimedean part (II): `genArchTail 5 5 ≥ (15/2)ζ(2) − (35/4)ζ(3) + (75/16)ζ(4) − (31/32)ζ(5)`. -/
theorem archII5_ge :
    Rle (ofQ (add (add (add (add (⟨0, 1⟩ : Q) (mul (⟨30, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
        (mul (⟨-70, 8⟩ : Q) (⟨1205, 1000⟩ : Q))) (mul (⟨75, 16⟩ : Q) (⟨1082, 1000⟩ : Q)))
        (mul (⟨-31, 32⟩ : Q) (⟨1052, 1000⟩ : Q))) iilq5_den_pos)
      (genArchTail 5 5) := by
  show Rle _ (Radd (Radd (Radd (Radd zero (genArchTerm 5 2 (by decide))) (genArchTerm 5 3 (by decide)))
    (genArchTerm 5 4 (by decide))) (genArchTerm 5 5 (by decide)))
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Radd_le_add ?_ archTerm5_5_ge
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Radd_le_add ?_ archTerm5_4_ge
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  refine Radd_le_add ?_ archTerm5_3_ge
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) ?_
  exact Radd_le_add (Rle_of_Req (Req_refl _)) archTerm5_2_ge

set_option maxRecDepth 8192 in
set_option maxHeartbeats 4000000 in
/-- **`genuineArchSeq 5 ≥ archLoQ5`** — lower bound on the archimedean side (`arch(5) ≈ −0.935`). -/
theorem genuineArchSeq5_ge : Rle (ofQ archLoQ5 archLoQ5_den_pos) (genuineArchSeq 5) := by
  unfold genuineArchSeq
  refine Rle_trans (Rle_of_Req ?_) (Radd_le_add archI5_ge archII5_ge)
  show Req (ofQ archLoQ5 _) _
  exact Req_symm (Radd_ofQ_ofQ ilq5_den_pos iilq5_den_pos)

set_option maxRecDepth 8192 in
/-- **`genuineArchSeq 5 ≥ −935000/10⁶`** — `archLoQ5` rounded to `10⁶` (`= −187/200 = −0.935`). -/
theorem archLoR5_le : Rle (ofQ (⟨-935000, 1000000⟩ : Q) (by decide)) (genuineArchSeq 5) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) archLoQ5_den_pos (by decide)) genuineArchSeq5_ge

-- ===========================================================================
-- STEP 4 — `Pos Rlambda5`.
-- ===========================================================================

set_option maxRecDepth 8192 in
/-- **`Pos Rlambda5`** — the fifth Li coefficient is positive, certified
    `λ₅ ≥ 83316/10⁶ ≈ +0.0833` (true `λ₅ ≈ 0.518`), assembled from `λ₅^{arith} ≥ 1018316/10⁶`
    and `genuineArchSeq 5 ≥ −935000/10⁶ = −0.935`, i.e. from the TIGHT brackets
    `γ₁ ≤ −0.069`, `γ₂ ∈ [−0.014, −0.003]`, `γ₃ ≤ 1/40` together with `γ ∈ [0.577,0.578]`,
    `γ₁ ≥ −0.0762`, `γ₃ ≥ −1/20`, `γ₄ ≥ −1/5`, `ζ(2) ≥ 1.644`, `ζ(3) ≤ 1.205`, `ζ(4) ≥ 1.082`,
    `ζ(5) ≤ 1.052`, `log 4π ≤ 2.5316`.

    The FIRST `Pos λₙ` to carry `γ₄` (the culmination of the `decompForm4` effort).  This is
    `n = 5` ONLY — NOT the crux (the uniform `∀ n` = RH); `liPositivityHolds` stays `none`,
    RH open. -/
theorem Rlambda5_pos : Pos Rlambda5 := by
  have hμ : Rle (ofQ (add (neg (⟨-1018316, 1000000⟩ : Q)) (⟨-935000, 1000000⟩ : Q)) (by decide))
      Rlambda5 :=
    Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide) (by decide))))
      (Radd_le_add Rlambda5_arith_ge_r archLoR5_le)
  exact Pos_of_Rle_ofQ (by decide) (by decide) hμ


end UOR.Bridge.F1Square.Analysis
