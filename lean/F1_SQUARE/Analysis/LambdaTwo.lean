/-
F1 square — **`Pos λ₂`** (the second Li coefficient is positive), the capstone of the v0.16.0 stage-B
release. By the Bombieri–Lagarias / Coffey closed form,

    λ₂  =  1 + γ − γ²  −  2γ₁  −  log 4π  +  ¾·ζ(2),

with `γ` the Euler–Mascheroni constant, `γ₁` the first Stieltjes constant, `ζ(2)` the Basel constant.
Every constituent is now a constructive real with a *kernel-certified* bracket:

  • `1 + γ − γ² ≥ 1.2244`  — the **parabola** `(γ − 0.34)(0.66 − γ) ≥ 0` on `γ ∈ [0.54, 0.66]`
    (`Rgamma_h_lower`/`Rgamma_h_upper`), expanded to `γ − γ² ≥ 0.2244` (`parab_gen`),
  • `−2γ₁ ≥ 0.089`         — from `γ₁ ≤ −0.0445` (`Rgamma1_le_neg445`, the v0.16.0 γ₁ numeric),
  • `−log 4π ≥ −2.5316`    — from `log 2 ≤ 0.6931` (`Rlog2c_le`) and `log π ≤ 1.1453` (`Rlogπc_le`),
  • `¾·ζ(2) ≥ 1.2225`      — from `ζ(2) ≥ 1.63` (`zeta2_lower`).

Summing the rational brackets gives `λ₂ ≥ 0.0043 > 0` (exactly `43/10000`) — razor-thin but
kernel-decidable. This is the
`n = 2` slice of Li's criterion as **evidence**; it is NOT the crux (`λₙ > 0 ∀ n` = RH stays open, the
`liPositivityHolds` field remains `none`).

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.GammaOne
import F1Square.Analysis.GammaUpper
import F1Square.Analysis.ZetaTwo
import F1Square.Analysis.LambdaOne

namespace UOR.Bridge.F1Square.Analysis

/-- `−(−x) ≈ x`. -/
theorem Rneg_Rneg (x : Real) : Req (Rneg (Rneg x)) x :=
  Req_of_seq_Qeq (fun n => by simp only [Rneg, Qeq, neg]; push_cast; ring_uor)

/-- **The parabola lower bound** `a − a² ≥ 0.2244` for `a ∈ [0.34, 0.66]`: from `(a−0.34)(0.66−a) ≥ 0`
    (product of two non-negatives), expanded — using `0.34 + 0.66 = 1`, `0.34·0.66 = 0.2244` — to
    `a − a² − 0.2244 = (a−0.34)(0.66−a) ≥ 0`. The tight `1 + γ − γ²` bound `Pos λ₂` needs (the naive
    product-of-bounds `0.1836` is too weak). -/
theorem parab_gen (a : Real)
    (hc : Rle (ofQ (⟨34, 100⟩ : Q) (by decide)) a)
    (hd : Rle a (ofQ (⟨66, 100⟩ : Q) (by decide))) :
    Rle (ofQ (⟨2244, 10000⟩ : Q) (by decide)) (Rsub a (Rmul a a)) := by
  have hprod := Rnonneg_Rmul (Rnonneg_Rsub_of_Rle hc) (Rnonneg_Rsub_of_Rle hd)
  have hsum : Req (Radd (Rmul a (ofQ (⟨66, 100⟩ : Q) (by decide)))
      (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) a)) a := by
    refine Req_trans (Radd_congr (Req_refl _) (Rmul_comm _ a)) ?_
    refine Req_trans (Req_symm (Rmul_distrib a (ofQ (⟨66, 100⟩ : Q) (by decide))
      (ofQ (⟨34, 100⟩ : Q) (by decide)))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) ?_) (Rmul_one a)
    exact Req_trans (Radd_ofQ_ofQ (by decide) (by decide))
      (Req_of_seq_Qeq (fun n => by show Qeq (add (⟨66, 100⟩ : Q) ⟨34, 100⟩) ⟨1, 1⟩; decide))
  have hexpand : Req (Rmul (Rsub a (ofQ (⟨34, 100⟩ : Q) (by decide)))
        (Rsub (ofQ (⟨66, 100⟩ : Q) (by decide)) a))
      (Rsub (Rsub a (Rmul a a)) (ofQ (⟨2244, 10000⟩ : Q) (by decide))) := by
    refine Req_trans (Rmul_sub_distrib (Rsub a (ofQ (⟨34, 100⟩ : Q) (by decide)))
      (ofQ (⟨66, 100⟩ : Q) (by decide)) a) ?_
    refine Req_trans (Rsub_congr
      (Rmul_sub_distrib_right a (ofQ (⟨34, 100⟩ : Q) (by decide)) (ofQ (⟨66, 100⟩ : Q) (by decide)))
      (Rmul_sub_distrib_right a (ofQ (⟨34, 100⟩ : Q) (by decide)) a)) ?_
    refine Req_trans (Rsub_Radd_Radd (Rmul a (ofQ (⟨66, 100⟩ : Q) (by decide)))
      (Rneg (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) (ofQ (⟨66, 100⟩ : Q) (by decide))))
      (Rmul a a) (Rneg (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) a))) ?_
    refine Req_trans (Radd_congr (Req_refl _)
      (Req_trans (Radd_congr (Req_refl _) (Rneg_Rneg (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) a)))
        (Radd_comm _ _))) ?_
    refine Req_trans (Radd_swap (Rmul a (ofQ (⟨66, 100⟩ : Q) (by decide)))
      (Rneg (Rmul a a)) (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) a)
      (Rneg (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) (ofQ (⟨66, 100⟩ : Q) (by decide))))) ?_
    refine Req_trans (Radd_congr hsum (Req_refl _)) ?_
    refine Req_trans (Req_symm (Radd_assoc a (Rneg (Rmul a a))
      (Rneg (Rmul (ofQ (⟨34, 100⟩ : Q) (by decide)) (ofQ (⟨66, 100⟩ : Q) (by decide)))))) ?_
    exact Rsub_congr (Req_refl _) (Rmul_ofQ_ofQ (by decide) (by decide))
  exact Rle_of_Rnonneg_Rsub (Rnonneg_congr hexpand hprod)

-- ===========================================================================
-- `λ₂` and its positivity.
-- ===========================================================================

/-- The rational upper bound for `log 4π = 2·log 2 + log π` (`≈ 2.5310`, certified `≤ 2.5316 =
    25316/10000` in the `λ₂` proof), from `Rlog2c_le`/`Rlogπc_le`. -/
private def log4pib : Q :=
  add (add (mul ⟨2, 1⟩ (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩))
           (mul ⟨2, 1⟩ (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩)))
      (mul ⟨2, 1⟩ (add (artSum ⟨15, 29⟩ 6) ⟨npow 15 15, npow 29 13 * 616⟩))

/-- **The second Li coefficient** `λ₂ = 1 + γ − γ² − 2γ₁ − log 4π + ¾·ζ(2)` as a constructive real. -/
def Rlambda2 : Real :=
  Radd (Radd (Radd
    (Radd one (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)))
    (Rneg (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)))
    (Rneg Rlog4pic))
    (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide)))

/-- **`Pos λ₂`** — the second Li coefficient is positive (certified lower bound
    `λ₂ ≥ 0.0043`; the true value is `λ₂ ≈ 0.0923457`, Keiper 1992), kernel-certified from the
    parabola `1 + γ − γ² ≥ 1.2244`, `γ₁ ≤ −0.0445`, `log 2 ≤ 0.6931`, `log π ≤ 1.1453`, `ζ(2) ≥ 1.63`.
    Evidence for Li's criterion at `n = 2`; NOT the crux (`liPositivityHolds` stays `none`, RH open). -/
theorem Rlambda2_pos : Pos Rlambda2 := by
  -- denominators of the two log upper bounds
  have h2d : 0 < (mul ⟨2, 1⟩ (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩)).den :=
    Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 8)
      (Nat.mul_pos (by decide) (npow_pos (by decide) _)))
  have hpd : 0 < (mul ⟨2, 1⟩ (add (artSum ⟨15, 29⟩ 6) ⟨npow 15 15, npow 29 13 * 616⟩)).den :=
    Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 6) (by decide))
  have hlog4d : 0 < log4pib.den := add_den_pos (add_den_pos h2d h2d) hpd
  -- term 1: `1 + (γ − γ²) ≥ 12244/10000`
  have hgc : Rle (ofQ (⟨34, 100⟩ : Q) (by decide)) Rgamma_h :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) Rgamma_h_lower
  have hone : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) one :=
    Rle_of_Req (Req_of_seq_Qeq (fun n => by show Qeq (⟨1, 1⟩ : Q) ⟨1, 1⟩; decide))
  have hT1 : Rle (ofQ (add (⟨1, 1⟩ : Q) ⟨2244, 10000⟩) (by decide))
      (Radd one (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h))) :=
    Rle_trans (Rle_ofQ_add_Radd (p := (⟨1, 1⟩ : Q)) (q := ⟨2244, 10000⟩) (by decide) (by decide))
      (Radd_le_add hone (parab_gen Rgamma_h hgc Rgamma_h_upper))
  -- term 2: `−2γ₁ ≥ 890/10000`  (`= −(2·(−445/10000))`)
  have hT2 : Rle (ofQ (neg (mul (⟨2, 1⟩ : Q) ⟨-445, 10000⟩)) (by decide))
      (Rneg (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)) :=
    Rneg_ofQ_le _ (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg445)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))))
  -- term 3: `−log 4π ≥ −25316/10000`  (via `log 4π ≤ log4pib ≤ 2.5316`)
  have hB : Rle Rlog4pic (ofQ log4pib hlog4d) :=
    Rle_trans (Radd_le_add (Rle_trans (Radd_le_add Rlog2c_le Rlog2c_le) (Radd_Rle_ofQ_add h2d h2d))
      Rlogπc_le) (Radd_Rle_ofQ_add (add_den_pos h2d h2d) hpd)
  have hlog4_le : Qle log4pib (⟨25316, 10000⟩ : Q) := by decide
  have hT3 : Rle (ofQ (neg (⟨25316, 10000⟩ : Q)) (by decide)) (Rneg Rlog4pic) :=
    Rneg_ofQ_le _ (Rle_trans hB (Rle_ofQ_ofQ hlog4d (by decide) hlog4_le))
  -- term 4: `¾·ζ(2) ≥ 489/400`
  have hT4 : Rle (ofQ (mul (⟨3, 4⟩ : Q) ⟨163, 100⟩) (by decide))
      (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_lower)
  -- assemble: `λ₂ ≥ ofQ((1 + 2244/10000) − 2·(−445/10000) − 25316/10000 + ¾·163/100) = ofQ(43/10000) > 0`
  have hμ : Rle (ofQ (add (add (add (add (⟨1, 1⟩ : Q) ⟨2244, 10000⟩) (neg (mul ⟨2, 1⟩ ⟨-445, 10000⟩)))
        (neg ⟨25316, 10000⟩)) (mul ⟨3, 4⟩ ⟨163, 100⟩)) (by decide)) Rlambda2 := by
    refine Rle_trans ?_ (Radd_le_add (Radd_le_add (Radd_le_add hT1 hT2) hT3) hT4)
    refine Rle_trans (Rle_ofQ_add_Radd
      (p := add (add (add (⟨1, 1⟩ : Q) ⟨2244, 10000⟩) (neg (mul ⟨2, 1⟩ ⟨-445, 10000⟩)))
        (neg ⟨25316, 10000⟩))
      (q := mul ⟨3, 4⟩ ⟨163, 100⟩) (by decide) (by decide)) (Radd_le_add ?_ (Rle_refl _))
    refine Rle_trans (Rle_ofQ_add_Radd
      (p := add (add (⟨1, 1⟩ : Q) ⟨2244, 10000⟩) (neg (mul ⟨2, 1⟩ ⟨-445, 10000⟩)))
      (q := neg ⟨25316, 10000⟩) (by decide) (by decide)) (Radd_le_add ?_ (Rle_refl _))
    exact Rle_ofQ_add_Radd (p := add (⟨1, 1⟩ : Q) ⟨2244, 10000⟩) (q := neg (mul ⟨2, 1⟩ ⟨-445, 10000⟩))
      (by decide) (by decide)
  exact Pos_of_Rle_ofQ (by decide) (by decide) hμ

end UOR.Bridge.F1Square.Analysis
