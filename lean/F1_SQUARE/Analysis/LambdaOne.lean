/- ===========================================================================
   ADR-100: Conditional Proof Scaffold
   This is a research program. RH remains open. The F1-square with Hodge index
   is unconstructed. Numerical experiments and admitted bounds are exploratory
   and do not constitute proof or unconditional verification.
   ===========================================================================
   F1 square — the **first Li/Keiper coefficient** `λ₁` as a **positivity-certified** constructive real.

By the Bombieri–Lagarias formula, the first Li coefficient is the *closed-form constant*

  λ₁ = 1 + γ/2 − ½·log(4π)

(no zeros, no higher Stieltjes constants enter). The numerical value is `λ₁ ≈ 0.0231` — positive,
consistent with the Riemann hypothesis (Li's criterion: RH ⇔ λₙ > 0 ∀ n).

Here `λ₁` is assembled from the **convergence-accelerated** Euler–Mascheroni constant `Rgamma_h`
(harmonic-telescoped, with the kernel-certified lower bracket `γ ≥ 0.54`) and the clean
rational-argument logs `Rlog2c` (`log 2 ≤ 0.6931`) and `Rlogπc` (`log π ≤ 1.1453`, via the tight
Machin bracket `π ≤ 3.142`). With those bounds, `λ₁` is bracketed below by `c ≈ 0.0042 > 0`, so

  **`Rlambda1_pos : Pos Rlambda1`**

is a genuine, choice-free, kernel-checkable certificate that `λ₁ > 0` — built from first principles
(no Mathlib, no `()`/`native_decide`). This realizes the `n = 1` slice of Li's criterion as
**evidence**, NOT as the crux: it does not assert `λₙ > 0` for all `n` (that is RH, which stays open;
`liPositivityHolds` remains `none`).

We prove positivity through `2λ₁ = 2 + γ − log(4π)` (integer coefficients, so no halving is needed in
the bound), then halve once at the end (`Rhalf`, which preserves positivity).

Pure Lean 4, no Mathlib, no `()`/`native_decide`, choice-free.
-/

import F1Square.Analysis.GammaAccel

namespace UOR.Bridge.F1Square.Analysis

/-- **log 4π = 2·log 2 + log π**, as a constructive real (clean rational-argument logs). -/
def Rlog4pic : Real := Radd (Radd Rlog2c Rlog2c) Rlogπc

/-- **2·λ₁ = 2 + γ − log(4π)** — integer coefficients (no halving in the bound). -/
def Rtwolambda1 : Real := Radd (Radd (ofQ ⟨2, 1⟩ (by decide)) Rgamma_h) (Rneg Rlog4pic)

/-- **The first Li coefficient** `λ₁ = 1 + γ/2 − ½·log(4π) = ½·(2 + γ − log 4π)`, as a constructive
    real value (Bombieri–Lagarias). -/
def Rlambda1 : Real := Rhalf Rtwolambda1

/-- **`Pos λ₁`** — the first Li coefficient is positive (`λ₁ ≈ 0.0231 > 0`), kernel-certified from
    `γ ≥ 0.54`, `log 2 ≤ 0.6931`, `log π ≤ 1.1453`. This is the `n = 1` slice of Li's criterion as
    **evidence**; it is NOT the crux (`λₙ > 0 ∀ n` = RH stays open). -/
theorem Rlambda1_pos : Pos Rlambda1 := by
  -- denominators of the two log upper bounds
  have h2d : 0 < (mul ⟨2, 1⟩ (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩)).den :=
    Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 8)
      (Nat.mul_pos (by decide) (npow_pos (by decide) _)))
  have hpd : 0 < (mul ⟨2, 1⟩ (add (artSum ⟨15, 29⟩ 6) ⟨npow 15 15, npow 29 13 * 616⟩)).den :=
    Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 6) (by decide))
  -- 2 + γ  ≥  ofQ (2 + 54/100)
  have hA : Rle (ofQ (add ⟨2, 1⟩ ⟨54, 100⟩) (by decide)) (Radd (ofQ ⟨2, 1⟩ (by decide)) Rgamma_h) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
      (Radd_le_add (Rle_refl _) Rgamma_h_lower)
  -- log 4π  ≤  ofQ (2·log2_hi + logπ_hi)
  have hB := Rle_trans
    (Radd_le_add (Rle_trans (Radd_le_add Rlog2c_le Rlog2c_le) (Radd_Rle_ofQ_add h2d h2d)) Rlogπc_le)
    (Radd_Rle_ofQ_add (add_den_pos h2d h2d) hpd)
  -- −log 4π  ≥  ofQ (−(2·log2_hi + logπ_hi))
  have hnegB := Rneg_ofQ_le _ hB
  -- 2λ₁ = (2+γ) + (−log4π)  ≥  ofQ c   with c = (2 + 54/100) − (2·log2_hi + logπ_hi) ≈ 0.0084
  have hμ := Rle_trans
    (Rle_ofQ_add_Radd (by decide) (neg_den_pos (add_den_pos (add_den_pos h2d h2d) hpd)))
    (Radd_le_add hA hnegB)
  -- λ₁ = ½·(2λ₁)  ≥  ofQ (½c) > 0
  exact Pos_of_Rle_ofQ (by decide) (by decide) (Rhalf_ge _ hμ)

end UOR.Bridge.F1Square.Analysis
