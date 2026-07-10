/-
F1 square — **the Burnol multiplier off-center: `α(2) < 0`** (the multiplier is indefinite).

Building on the completed kernel-value infrastructure (`ψ(1/4) ≤ −4`, `Σ cₙ(1) ≤ 4.22`, `log π ≥ 1`,
`h₊(2) < 0`), this supplies the last missing coefficient bound — `√2 ≤ 3/2` — via the exp∘log
inverse `Rexp_RlogNat`, and assembles the full pointwise statement.

THE √2 BOUND. `sqrt2 = exp(½·log 2)` (no sqrt primitive). `sqrt2² = exp(½·log2 + ½·log2) =
exp(log 2) = 2` (`RrpowPos_add` + `Rexp_RlogNat 2`, since `RlogNat 2 = RlogPos (ofQ 2) 0` is exactly
`sqrt2`'s logarithm up to proof-irrelevance). Then `√2 ≤ 3/2` from `2 ≤ 9/4` and `Rle_of_Rmul_self_le`.

THE INDEFINITENESS. Burnol's multiplier `α(τ) = 8√2·cos(τ log2)/(1+4τ²) + h₊(τ)`,
`h₊(τ) = Re ψ(1/4 + iτ/2) − log π`. At `τ = 2`: `|cos| ≤ 1`, `8√2 ≤ 12`, `1/(1+16) = 1/17`, so the
oscillating term is `≤ 12/17 ≈ 0.706`; and `h₊(2) ≤ 0.22 − 1 = −0.78`. Hence `α(2) ≤ 12/17 − 0.78 < 0`.

This mechanizes Burnol's observation that `α` is NOT pointwise non-negative (the "further idea seems
necessary"), and Connes–Consani's need for the Sonine-space projection — the obstruction to extending
the single-archimedean-place positivity, now a theorem. It is the barrier, NOT a route through it;
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.BurnolAlpha
import F1Square.Analysis.PsiLine
import F1Square.Analysis.EtaVariation

namespace UOR.Bridge.F1Square.Analysis

/-- **`√2 · √2 = 2`** — `sqrt2 = exp(½ log 2)`, so `sqrt2² = exp(log 2) = 2` via `RrpowPos_add`
    (`x^a·x^a = x^(a+a)`) and `Rexp_RlogNat 2` (`RlogNat 2 = RlogPos (ofQ 2) 0` is `sqrt2`'s log). -/
theorem sqrt2_mul_self : Req (Rmul sqrt2 sqrt2) (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
  refine Req_trans (Req_symm (RrpowPos_add (ofQ (⟨2, 1⟩ : Q) (by decide)) 0 two_seq_pos
    (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide)))) ?_
  show Req (RexpReal (Rmul (Radd (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide)))
      (RlogPos (ofQ (⟨2, 1⟩ : Q) (by decide)) 0 two_seq_pos))) (ofQ (⟨2, 1⟩ : Q) (by decide))
  refine Req_trans (RexpReal_congr ?_) (Rexp_RlogNat 2 (by omega))
  refine Req_trans (Rmul_congr ?_ (Req_refl _)) (Rone_mul _)
  exact Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))

/-- **`√2 ≤ 3/2`** — from `sqrt2² = 2 ≤ 9/4 = (3/2)²` and `Rle_of_Rmul_self_le` (`x ≥ 0`, `x² ≤ c² ⟹
    x ≤ c`). The upper companion of `one_le_sqrt2`; the multiplier-coefficient bound for `α(2)`. -/
theorem sqrt2_le_three_halves : Rle sqrt2 (ofQ (⟨3, 2⟩ : Q) (by decide)) := by
  refine Rle_of_Rmul_self_le (Rnonneg_ofQ (by decide) (by decide)) ?_
  refine Rle_trans (Rle_of_Req sqrt2_mul_self) ?_
  refine Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
    (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))

/-- `√2 ≥ 0` (from `1 ≤ √2`, avoiding any unfold of the exp/log term). -/
theorem sqrt2_nonneg : Rnonneg sqrt2 :=
  Rnonneg_of_Rle_zero (Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) one_le_sqrt2)

/-- **Burnol's window multiplier at `τ = 2`**: `α(2) = 8√2·cos(2 log2)/(1+16) + (Re ψ(1/4+i) − log π)`. -/
def burnolAlphaTwo : Real :=
  Radd (Rmul (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2)
             (Rmul (Rcos (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rlog2)) (ofQ (⟨1, 17⟩ : Q) (by decide))))
       (Rsub (psiLineReP 1 1 (by omega) (by omega)) Rlogπc)

/-- **`α(2) < 0` — Burnol's multiplier is indefinite.** With `|cos| ≤ 1`, `8√2 ≤ 12` (`√2 ≤ 3/2`),
    `1/(1+16) = 1/17`, the oscillating term is `≤ 12/17 ≈ 0.706`; and `h₊(2) = Re ψ(1/4+i) − log π ≤
    0.22 − 1 = −0.78`. So `α(2) ≤ 12/17 − 78/100 < 0`; equivalently `−α(2) ≥ 78/100 − 12/17 = 126/1700 >
    1/100 > 0` (the bound proven). The bare multiplier is NOT pointwise non-negative (Burnol "a further
    idea seems necessary"; CC need the Sonine projection): the obstruction to extending single-place
    positivity, mechanized. Crux `none`. -/
theorem burnolAlphaTwo_neg : Pos (Rneg burnolAlphaTwo) := by
  show Pos (Rneg (Radd (Rmul (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2)
             (Rmul (Rcos (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rlog2)) (ofQ (⟨1, 17⟩ : Q) (by decide))))
       (Rsub (psiLineReP 1 1 (by omega) (by omega)) Rlogπc)))
  have h8nn : Rnonneg (ofQ (⟨8, 1⟩ : Q) (by decide)) := Rnonneg_ofQ (by decide) (by decide)
  have h17nn : Rnonneg (ofQ (⟨1, 17⟩ : Q) (by decide)) := Rnonneg_ofQ (by decide) (by decide)
  have hAnn : Rnonneg (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2) :=
    Rnonneg_Rmul h8nn sqrt2_nonneg
  have hA_le : Rle (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2) (ofQ (⟨12, 1⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left h8nn sqrt2_le_three_halves)
      (Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
        (ofQ_congr (by decide) (by decide) (by decide))))
  have hB_le : Rle (Rmul (Rcos (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rlog2)) (ofQ (⟨1, 17⟩ : Q) (by decide)))
      (ofQ (⟨1, 17⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_right h17nn (Rcos_le_one _))
      (Rle_of_Req (Rone_mul _))
  have hcost_le : Rle (Rmul (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2)
        (Rmul (Rcos (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rlog2)) (ofQ (⟨1, 17⟩ : Q) (by decide))))
      (ofQ (⟨12, 17⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left hAnn hB_le)
      (Rle_trans (Rmul_le_Rmul_right h17nn hA_le)
        (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide))))
  have hhplus_le : Rle (Rsub (psiLineReP 1 1 (by omega) (by omega)) Rlogπc)
      (ofQ (⟨-78, 100⟩ : Q) (by decide)) :=
    Rle_trans (Rsub_le_sub psiLineReP_one_upper Rlogpi_ge_one)
      (Rle_of_Req (Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, 1⟩ : Q) (by decide)))
        (Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide)))))
  have hstart : Rle (ofQ (⟨1, 100⟩ : Q) (by decide))
      (Radd (Rneg (ofQ (⟨12, 17⟩ : Q) (by decide))) (Rneg (ofQ (⟨-78, 100⟩ : Q) (by decide)))) := by
    intro n
    show Qle (⟨1, 100⟩ : Q) (add (add (neg (⟨12, 17⟩ : Q)) (neg (⟨-78, 100⟩ : Q))) ⟨2, n + 1⟩)
    simp only [Qle, add, neg]; push_cast; omega
  exact Pos_of_Rle_ofQ (c := (⟨1, 100⟩ : Q)) (by decide) (by decide)
    (Rle_trans hstart
      (Rle_trans (Radd_le_add (Rneg_le hcost_le) (Rneg_le hhplus_le))
        (Rle_of_Req (Req_symm (Rneg_Radd _ _)))))

-- ===========================================================================
-- The indefiniteness capstone: the bare single-place multiplier takes BOTH signs, so pointwise
-- positivity is REFUTED — the Sonine-space projection (not pointwise α ≥ 0) is the resolution.
-- ===========================================================================

/-- `Rnonneg x ⟹ ¬ Pos (Rneg x)` — a non-negative real's negation is not positive. (Set `z = −x` in
    `not_Pos_of_Rnonneg_neg`, using `Rnonneg (−(−x)) = Rnonneg x` via `Rneg_neg`.) -/
private theorem not_Pos_neg_of_Rnonneg {x : Real} (h : Rnonneg x) : ¬ Pos (Rneg x) :=
  not_Pos_of_Rnonneg_neg (Rnonneg_congr (Req_symm (Rneg_neg x)) h)

/-- `Pos x ⟹ ¬ Rle x zero` — a positive real is not `≤ 0`. -/
private theorem not_Rle_zero_of_Pos {x : Real} (h : Pos x) : ¬ Rle x zero := fun hle =>
  not_Pos_of_Rnonneg_neg
    (Rnonneg_congr (Req_trans (Radd_comm zero (Rneg x)) (Radd_zero (Rneg x)))
      (Rnonneg_Rsub_of_Rle hle)) h

/-- The two computed samples of Burnol's archimedean multiplier `α`: the window center `α(0)` and the
    off-center point `α(2)`. -/
def burnolAlphaSample : Bool → Real
  | false => burnolAlphaZero
  | true  => burnolAlphaTwo

/-- **THE MULTIPLIER IS INDEFINITE — it takes both signs.** `α(0) > 0` (the window center,
    `burnolAlphaZero_pos`) and `α(2) < 0` (off-center, `burnolAlphaTwo_neg`). The single bare
    archimedean multiplier is genuinely sign-changing — the precise obstruction (Burnol: "a further
    idea seems necessary") to extending single-place Weil positivity. -/
theorem burnol_multiplier_indefinite :
    Pos burnolAlphaZero ∧ Pos (Rneg burnolAlphaTwo) :=
  ⟨burnolAlphaZero_pos, burnolAlphaTwo_neg⟩

/-- **POINTWISE SINGLE-PLACE POSITIVITY IS REFUTED**: the bare multiplier is NOT everywhere `≥ 0` on
    its computed samples — `α(2) < 0`. So no τ-uniform `α(τ) ≥ 0` holds; the Connes–Consani / Burnol
    **Sonine-space projection** (positivity recovered after projecting onto the prime-free window), not
    a pointwise `α ≥ 0`, is the genuine resolution. The crux stays `none`. -/
theorem burnolAlpha_not_pointwise_nonneg :
    ¬ (∀ b, Rnonneg (burnolAlphaSample b)) := fun h =>
  not_Pos_neg_of_Rnonneg (h true) burnolAlphaTwo_neg

/-- ...and the bare multiplier is not everywhere `≤ 0` either — `α(0) > 0` at the window center. With
    `burnolAlpha_not_pointwise_nonneg` this is genuine indefiniteness (both signs realized): single
    place positivity does NOT extend, exactly the gap the Sonine projection fills. Crux `none`. -/
theorem burnolAlpha_not_pointwise_nonpos :
    ¬ (∀ b, Rle (burnolAlphaSample b) zero) := fun h =>
  not_Rle_zero_of_Pos burnolAlphaZero_pos (h false)

end UOR.Bridge.F1Square.Analysis
