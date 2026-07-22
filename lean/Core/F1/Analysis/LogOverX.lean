/-
F1 square — **the `∫ log/x` layer, part 5: the integrand family** (`LogOverX.lean`).
The totalized integrand of `∫₀¹ 2·log(c+t)/(c+t) dt`:

    `gLx c t := (gLog c t + gLog c t) · gRecipC c t`

— the product of the certified band-log (`LogIntegrand`) and the certified clamped
reciprocal (`HarmonicLogC`), with the full gateway data: uniform bounds
(`0 ≤ gLog c ≤ c` via `RlogPos_le_sub_one` — `log x ≤ x − 1` on the band `[1, c+1]`;
`|gRecipC| ≤ 1` via `Rinv_le_ofQ_inv`), congruence, and the product-Lipschitz
certificate (`Rmul_lipschitz`, constant `2c·1 + 1·2 = 2c + 2`). The gateway objects
`riemannIntegral (gLx c)` now construct for `1 ≤ c ≤ 3`.

HONEST SCOPE. A totalized integrand with certificates; no integral is evaluated and no
positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogSqStep
import Core.F1.Analysis.LogPointVal
import Core.F1.Analysis.HarmonicLogC
import Core.F1.Analysis.RmulLipschitz
import Core.F1.Analysis.RartanhBounds

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Real-level band bounds for `gLogArg`, and the `gLog` bounds.
-- ===========================================================================

/-- `1 ≤ gLogArg c t` at the `Real` level (from the per-index floor). -/
private theorem gLogArg_ge_one (c : Nat) (t : Real) : Rle one (gLogArg c t) := by
  intro n
  refine Qle_trans ((gLogArg c t).den_pos n) (gLogArg_ge1 c t n) ?_
  exact Qle_add_right_nonneg (show (0 : Int) ≤ (⟨2, n + 1⟩ : Q).num from
    (by decide : (0 : Int) ≤ 2))

/-- `gLogArg c t ≤ c + 1` at the `Real` level (from the per-index ceiling). -/
private theorem gLogArg_le_top (c : Nat) (t : Real) :
    Rle (gLogArg c t) (ofQ (⟨((c + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) := by
  intro n
  refine Qle_trans Nat.one_pos (gLogArg_hi c t n) ?_
  exact Qle_add_right_nonneg (show (0 : Int) ≤ (⟨2, n + 1⟩ : Q).num from
    (by decide : (0 : Int) ≤ 2))

/-- `1 ≤ c+1` at the band top (private copy). -/
private theorem lox_h1B (c : Nat) : Qle (⟨1, 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q) :=
  sample_ge_one (c + 1) 1 (Nat.le_add_left 1 c)

/-- **`gLog c ≥ 0`** — the band floor is `1`. -/
theorem gLog_nonneg (c : Nat) (t : Real) : Rnonneg (gLog c t) :=
  Rnonneg_RlogPos (gLogArg c t) _ (gLogArg_witness c t) (gLogArg_ge_one c t)

/-- **`gLog c ≤ c`** (`c ≤ 3`) — `log x ≤ x − 1` on the band, and the band tops at
    `c + 1`. -/
theorem gLog_le (c : Nat) (hc3 : c ≤ 3) (t : Real) :
    Rle (gLog c t) (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) := by
  refine Rle_trans (RlogPos_le_sub_one (gLogArg c t) _ (gLogArg_witness c t)
    (⟨((c + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos (lox_h1B c)
    (gLogArg_pos c t) (gLogArg_hi c t) (gLogArg_lo c t)
    (radius_half_proj (c + 1) 1 Nat.one_pos (Nat.le_add_left 1 c) (by omega))) ?_
  refine Rle_trans (Radd_le_add (gLogArg_le_top c t) (Rle_refl (Rneg one))) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Rsub_ofQ_ofQ Nat.one_pos (by decide)) ?_
  refine ofQ_congr (b := (⟨(c : Int), 1⟩ : Q))
    (add_den_pos Nat.one_pos (by decide)) Nat.one_pos ?_
  show Qeq (add (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (neg (⟨1, 1⟩ : Q))) (⟨(c : Int), 1⟩ : Q)
  simp only [Qeq, add, neg]; push_cast; ring_uor

-- ===========================================================================
-- The doubled log: bound and Lipschitz data (generic in the `1`-Lipschitz factor).
-- ===========================================================================

/-- `(d + d) ≈ 2·d`. -/
private theorem lox_two_smul (d : Real) :
    Req (Radd d d) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) d) :=
  Req_symm (Req_trans (Rmul_congr
      (Req_trans (ofQ_congr (by decide) (add_den_pos (by decide) (by decide))
        (by decide : Qeq (⟨2, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q))))
        (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) (Req_refl d))
    (Req_trans (Rmul_comm (Radd one one) d)
      (Req_trans (Rmul_distrib d one one)
        (Radd_congr (Rmul_one d) (Rmul_one d)))))

/-- The doubled log's uniform bound: `|2·gLog c| ≤ 2c` (`c ≤ 3`). -/
theorem twoGLog_abs (c : Nat) (hc3 : c ≤ 3) (t : Real) :
    Rle (Rabs (Radd (gLog c t) (gLog c t)))
      (ofQ (⟨((2 * c : Nat) : Int), 1⟩ : Q) Nat.one_pos) := by
  refine Rle_trans (Rle_of_Req (Rabs_of_nonneg
    (Rnonneg_Radd (gLog_nonneg c t) (gLog_nonneg c t)))) ?_
  refine Rle_trans (Radd_le_add (gLog_le c hc3 t) (gLog_le c hc3 t)) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
    (ofQ_congr (b := (⟨((2 * c : Nat) : Int), 1⟩ : Q))
      (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_))
  show Qeq (add (⟨(c : Int), 1⟩ : Q) (⟨(c : Int), 1⟩ : Q)) (⟨((2 * c : Nat) : Int), 1⟩ : Q)
  simp only [Qeq, add]; push_cast; ring_uor

/-- **The doubled integrand is `2`-Lipschitz**, generic in the `1`-Lipschitz factor. -/
theorem twoF_lip {f : Real → Real} {hd : 0 < ((⟨1, 1⟩ : Q)).den}
    (hf : ∀ x y, Rle (Rabs (Rsub (f x) (f y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) hd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Radd (f x) (f x)) (Radd (f y) (f y))))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_Radd_Radd (f x) (f x) (f y) (f y))
    (lox_two_smul (Rsub (f x) (f y)))))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
    (Rsub (f x) (f y)))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Rabs_of_nonneg (Rnonneg_ofQ (by decide)
    (by decide : (0 : Int) ≤ (⟨2, 1⟩ : Q).num))) (Req_refl _))) ?_
  exact Rmul_le_Rmul_left (Rnonneg_ofQ (by decide)
    (by decide : (0 : Int) ≤ (⟨2, 1⟩ : Q).num))
    (Rle_trans (hf x y) (Rle_of_Req (Rone_mul _)))

-- ===========================================================================
-- The reciprocal bound, and the integrand family.
-- ===========================================================================

/-- `|gRecipC c| ≤ 1` — the clamp floor is `1`, so the reciprocal caps at `1`. -/
theorem gRecipC_abs (c : Nat) (t : Real) :
    Rle (Rabs (gRecipC c t)) (ofQ (⟨1, 1⟩ : Q) Nat.one_pos) := by
  refine Rle_trans (Rle_of_Req (Rabs_of_nonneg
    (Rnonneg_clampedInv ⟨1, 1⟩ (by decide) (by decide) _))) ?_
  refine Rle_trans (Rinv_le_ofQ_inv (a := (⟨1, 1⟩ : Q)) (by decide) (by decide)
    (qClampQ_witness ⟨1, 1⟩ (by decide) (by decide)
      (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) t))
    (Rle_ofQ_qClampQ ⟨1, 1⟩ (by decide)
      (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) t))) ?_
  exact Rle_of_Req (ofQ_congr (Qinv_den_pos (by decide)) Nat.one_pos (by decide))

/-- **The `log/x` integrand**: `gLx c t = 2·log(band(c+t))·(1/max(c+t, 1))` — total,
    agreeing with `2·log(c+t)/(c+t)` on `[0, 1]`. -/
def gLx (c : Nat) : Real → Real :=
  fun t => Rmul (Radd (gLog c t) (gLog c t)) (gRecipC c t)

/-- `gLx` respects `≈`, given the `gLog` congruence. -/
theorem gLx_congr_of (c : Nat)
    (hgc : ∀ x y : Real, Req x y → Req (gLog c x) (gLog c y)) :
    ∀ x y : Real, Req x y → Req (gLx c x) (gLx c y) :=
  fun _ _ h => Rmul_congr (Radd_congr (hgc _ _ h) (hgc _ _ h)) (gRecipC_congr c _ _ h)

/-- **`gLx` is `(2c + 2)`-Lipschitz** (`c ≤ 3`), from the product rule
    `M_f·L_g + M_g·L_f = 2c·1 + 1·2`, given the `gLog` `1`-Lipschitz datum. -/
theorem gLx_lip_of (c : Nat) (hc3 : c ≤ 3)
    (hgl : ∀ x y : Real, Rle (Rabs (Rsub (gLog c x) (gLog c y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y)))) :
    ∀ x y : Real, Rle (Rabs (Rsub (gLx c x) (gLx c y)))
      (Rmul (ofQ (add (mul (⟨((2 * c : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
          (mul (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
        (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_den_pos Nat.one_pos Nat.one_pos)))
        (Rabs (Rsub x y))) :=
  fun x y => Rmul_lipschitz Nat.one_pos Nat.one_pos Nat.one_pos Nat.one_pos
    (by decide) (by decide)
    (show (0 : Int) ≤ (⟨((2 * c : Nat) : Int), 1⟩ : Q).num from Int.ofNat_nonneg _)
    (by decide)
    (twoF_lip hgl) (gRecipC_lip c)
    (twoGLog_abs c hc3) (gRecipC_abs c) x y

end UOR.Bridge.F1Square.Analysis
