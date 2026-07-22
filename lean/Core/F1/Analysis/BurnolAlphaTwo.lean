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

import Core.F1.Analysis.BurnolAlpha
import Core.F1.Analysis.PsiLine
import Core.F1.Analysis.EtaVariation

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
theorem burnolAlphaTwo_neg : Pos (Rneg burnolAlphaTwo) := by decide