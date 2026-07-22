/-
F1 square — v0.22.0 crux frontier: **`Pos Rlambda5`** (the `n = 5` prime–archimedean coupling
coefficient), the culmination of the `γ₄`/`decompForm4` effort — the first `Pos λₙ` to carry `γ₄`.

`Pos λ₅` needs the constant brackets tightened well beyond the `λ₄` inputs, because in
`λ₅^{arith} = −(5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄)` the large binomial coefficients (`×5`, `×10`)
amplify the looseness of `γ₃`, `γ₂`, `γ₁`.  This file first rebuilds five tightened brackets —
`γ₃ ≤ 1/40` (`Rgamma3_le_1_40`), `γ₂ ≤ −3/1000` (`Rgamma2_le_neg0003`), `γ₂ ≥ −14/1000`
(`Rgamma2_ge_neg0014`), `γ₁ ≤ −69/1000` (`Rgamma1_le_neg069`), `ζ(3) ≤ 1205/1000`
(`zeta3_le_1205`) — each a `(T,N,j)`-tightened MIRROR of its existing bracket theorem.

With those, together with `γ ∈ [0.577,0.578]`, `γ₁ ≥ −0.0762`, `γ₃ ≥ −1/20`, `γ₄ ≥ −1/5`,
`ζ(2) ≥ 1.644`, `ζ(4) ≥ 1.082`, `ζ(5) ≤ 1.052`, `log 4π ≤ 2.5316`:

  `λ₅^{arith} ≥ 1018326/10⁶ ≈ +1.0183`   and   `genuineArchSeq 5 ≥ −187/200 = −0.935`,

so `λ₅ ≥ 83326/10⁶ ≈ +0.0833 > 0` (true `λ₅ ≈ 0.518`).

`arch(5) = 1 − (5/2)(γ + log4π) + (15/2)ζ(2) − (35/4)ζ(3) + (75/16)ζ(4) − (31/32)ζ(5)`,
`η₄ = −γ⁵ − 5γ³γ₁ − 5γγ₁² − (5/2)γ²γ₂ − (5/2)γ₁γ₂ − (5/6)γγ₃ − (5/24)γ₄`.  This is `n = 5` ONLY —
NOT the crux (the uniform `∀ n` = RH); `liPositivityHolds` stays `none`, RH open.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaFourPos
import Core.F1.Analysis.GammaThreeLower
import Core.F1.Analysis.GammaFourLower
import Core.F1.Analysis.LambdaFive

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- STEP 1 — Five tightened constant brackets (mirrors, new `(T,N,j)` params).
-- ===========================================================================

/-! ### 1. `γ₃ ≤ 1/40` — mirror of `Rgamma3_le` at `N=650, j=500, T=21, D=10⁸`. -/

set_option exponentiation.threshold 4000 in
set_option maxRecDepth 500000 in
/-- **`corr ≤ 1/(j+1)` at `j = 500`** — `(2·500+15)³·501 ≤ 2(2^{1014}+1)` (poly ≤ exp). -/
theorem corr_weaken500 :
    Rle (ofQ (⟨(2 * (500 : Int) + 15) * (2 * (500 : Int) + 15) * (2 * (500 : Int) + 15),
          2 * (2 ^ (2 * 500 + 14) + 1)⟩ : Q) (Nat.mul_pos (by decide) (Nat.succ_pos _)))
        (ofQ (⟨1, 500 + 1⟩ : Q) (Nat.succ_pos 500)) :=
  Rle_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _)) (Nat.succ_pos 500) (by decide)

set_option maxRecDepth 500000 in
/-- The numeric heart: `gBound3 21 10⁸ 650 + 11/651 + 1/501 + 1/501 ≤ 1/40` — one big `decide`. -/
theorem gamma3_40_decide :
    Qle (add (add (add (gBound3 21 100000000 650) (⟨11, 650 + 1⟩ : Q)) (⟨1, 500 + 1⟩ : Q))
        (⟨1, 500 + 1⟩ : Q))
      (⟨1, 40⟩ : Q) := by decide

set_option maxRecDepth 500000 in
/-- **`γ₃ ≤ 1/40`** — tightened upper bracket on the third Stieltjes constant (mirror `Rgamma3_le`
    at `N=650, j=500`). -/
theorem Rgamma3_le_1_40 : Rle Rgamma3 (ofQ (⟨1, 40⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma3_le_hSeq3 650 500 (by decide)
    (Nat.le_trans (show (650 : Nat) ≤ 2 ^ 14 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide)))) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add
    (hSeq3_le_gBound3 21 100000000 650 (by decide) (by decide)) (Rle_refl _)) corr_weaken500)
    (Rle_refl _)) ?_
  refine Rle_trans (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (gBound3_den_pos 21 100000000 650 (by decide))
      (Nat.succ_pos 650)) (Nat.succ_pos 500)) (Nat.succ_pos 500)) (by decide) gamma3_40_decide

/-! ### 2. `γ₂ ≤ −3/1000` — mirror of `Rgamma2_le` at `N=600, j=400, T=12, D=10⁸`. -/

set_option exponentiation.threshold 4000 in
set_option maxRecDepth 500000 in
/-- **`corr ≤ 1/(j+1)²` at `j = 400`** — `(2·400+9)²·401² ≤ 2(2^{808}+1)`. -/
theorem corr2_weaken400 :
    Rle (ofQ (⟨(2 * (400 : Int) + 9) * (2 * (400 : Int) + 9), 2 * (2 ^ (2 * 400 + 8) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _)))
        (ofQ (⟨1, (400 + 1) * (400 + 1)⟩ : Q) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) :=
  Rle_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _))
    (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)) (by decide)

set_option maxRecDepth 500000 in
/-- The numeric heart: `gBound2up 12 10⁸ 600 + 2/601 + 1/401² + 1/401 ≤ −3/1000`. -/
theorem gamma2_up_neg0003_decide :
    Qle (add (add (add (gBound2up 12 100000000 600) (⟨2, 600 + 1⟩ : Q))
        (⟨1, (400 + 1) * (400 + 1)⟩ : Q)) (⟨1, 400 + 1⟩ : Q))
      (⟨-3, 1000⟩ : Q) := by decide

set_option maxRecDepth 500000 in
/-- **`γ₂ ≤ −3/1000`** — tightened upper bracket (mirror `Rgamma2_le` at `N=600, j=400`). -/
theorem Rgamma2_le_neg0003 : Rle Rgamma2 (ofQ (⟨-3, 1000⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma2_le_hSeq2_up 600 400 (by decide)
    (Nat.le_trans (show (600 : Nat) ≤ 2 ^ 10 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide)))) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add
    (hSeq2_le_gBound2up 12 100000000 600 (by decide) (by decide)) (Rle_refl _)) corr2_weaken400)
    (Rle_refl _)) ?_
  refine Rle_trans (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (gBound2up_den_pos 12 100000000 600 (by decide))
      (by decide)) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (Nat.succ_pos _)) (by decide)
    gamma2_up_neg0003_decide

/-! ### 3. `γ₂ ≥ −14/1000` — mirror of `Rgamma2_ge_neg002` at `N=256, T=12, D=10⁸`. -/

set_option maxRecDepth 500000 in
/-- The numeric heart: `−14/1000 ≤ gBound2 12 10⁸ 256 − 1/257` — one big `decide`. -/
theorem gamma2_ge_neg0014_decide :
    Qle (⟨-14, 1000⟩ : Q) (Qsub (gBound2 12 100000000 256) (⟨1, 256 + 1⟩ : Q)) := by decide

set_option maxRecDepth 500000 in
/-- **`γ₂ ≥ −14/1000`** — tightened lower bracket (mirror `Rgamma2_ge_neg002` at `N=256`). -/
theorem Rgamma2_ge_neg0014 : Rle (ofQ (⟨-14, 1000⟩ : Q) (by decide)) Rgamma2 := by
  have hD : 0 < 100000000 := by decide
  refine Rle_trans ?_ (Rgamma2_ge_hSeq (show 1 ≤ 256 by decide) (show 256 ≤ 256 by decide))
  refine Rle_trans ?_
    (Rsub_le_sub (hSeq_ge_gBound2 12 100000000 256 hD (by decide)) (Rle_of_Req (Req_refl _)))
  exact Rle_trans
    (Rle_ofQ_ofQ (by decide)
      (add_den_pos (gBound2_den_pos 12 100000000 256 hD) (Nat.succ_pos 256)) gamma2_ge_neg0014_decide)
    (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (gBound2_den_pos 12 100000000 256 hD) (Nat.succ_pos 256))))

/-! ### 4. `γ₁ ≤ −69/1000` — mirror of `Rgamma1_le_neg0677` at `N=600, j=400, T=12, D=10⁸`. -/

set_option exponentiation.threshold 4000 in
set_option maxRecDepth 500000 in
/-- **`corr ≤ 1/(j+1)²` at `j = 400`** — `(2·400+9)·401² ≤ 2(2^{808}+1)`. -/
theorem corr1_weaken400 :
    Rle (ofQ (⟨2 * (400 : Int) + 9, 2 * (2 ^ (2 * 400 + 8) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _)))
        (ofQ (⟨1, (400 + 1) * (400 + 1)⟩ : Q) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) :=
  Rle_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _))
    (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)) (by decide)

set_option maxRecDepth 500000 in
/-- The numeric heart: `gBound1up 12 10⁸ 600 + 1/1200 + 1/401² + 1/401 ≤ −69/1000`. -/
theorem gamma1_up_neg069_decide :
    Qle (add (add (add (gBound1up 12 100000000 600) (⟨1, 2 * 600⟩ : Q))
        (⟨1, (400 + 1) * (400 + 1)⟩ : Q)) (⟨1, 400 + 1⟩ : Q))
      (⟨-69, 1000⟩ : Q) := by decide

set_option maxRecDepth 500000 in
/-- **`γ₁ ≤ −69/1000`** — tightened upper bracket (mirror `Rgamma1_le_neg0677` at `N=600, j=400`). -/
theorem Rgamma1_le_neg069 : Rle Rgamma1 (ofQ (⟨-69, 1000⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma1_le_hSeq1_up 600 400 (by decide)
    (Nat.le_trans (show (600 : Nat) ≤ 2 ^ 10 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide)))) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add
    (hSeq1_le_gBound1up 12 100000000 600 (by decide) (by decide)) (Rle_refl _)) corr1_weaken400)
    (Rle_refl _)) ?_
  refine Rle_trans (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (gBound1up_den_pos 12 100000000 600 (by decide))
      (by decide)) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (Nat.succ_pos _)) (by decide)
    gamma1_up_neg069_decide

/-! ### 5. `ζ(3) ≤ 1205/1000` — mirror of `zeta3_upper` at `N=500`. -/

set_option maxRecDepth 500000 in
/-- `zetaU 3 500 ≤ 1205/1000` (one rational `decide`). -/
theorem zetaU_three_500_le : Qle (zetaU 3 500) (⟨1205, 1000⟩ : Q) := by decide

/-- **`ζ(3) ≤ 1205/1000`** — tightened upper bracket on Apéry's constant (mirror `zeta3_upper` at
    `N=500`). -/
theorem zeta3_le_1205 : Rle (zeta 3 (by decide)) (ofQ (⟨1205, 1000⟩ : Q) (by decide)) :=
  Rle_trans (zeta_le_partial 3 (by decide) 500)
    (Rle_ofQ_ofQ (zetaU_den_pos 3 500) (by decide) zetaU_three_500_le)

end UOR.Bridge.F1Square.Analysis
