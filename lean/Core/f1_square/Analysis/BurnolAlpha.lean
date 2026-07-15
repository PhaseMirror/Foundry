/-
F1 square — v0.19.0 (the genuine-pairing arc), brick W3b: **α(0) > 0 — Burnol's
window-center positivity certificate, computed.**

THE CERTIFICATE. Burnol's spectral multiplier for the prime-free window
(arXiv math/0101068; deep-research-verified) is
    `α(τ) = 8√2·cos(τ·log 2)/(1 + 4τ²) + h₊(τ)`,   `h₊(τ) = −log π + Re ψ(1/4 + iτ/2)`,
and `Z(g ⋆ g^τ) = ∫ α(τ)·|ĝ(s)|² dτ/2π ≥ 0`. The BARE `α` is NOT pointwise non-negative —
it is indefinite (`DigammaWindow`); windowed positivity is recovered on the RESTRICTED
test class via Burnol's `A_ε·cos(ετ)` correction (or the Connes–Consani Sonine-space
projection, *Selecta Math.* 27 (2021)), NOT by pointwise `α ≥ 0`. At the window CENTER
`τ = 0`:
    `α(0) = 8√2 − log π + ψ(1/4)`,
every term now built: `√2 = exp(½·log 2)` (`RrpowPos`, `≥ 1` since `log 2 ≥ 0`),
`log π` (`Rlogπc`, `≤ 115/100`), and `ψ(1/4)` (`psiQuarter`, `≥ −432/100`, brick W3a).

THE COMPUTED VALUE. `burnolAlphaZero_pos : Pos burnolAlphaZero` — `α(0) > 0` (true value
`≈ 5.94`), certified from the wide margin `8·1 − 1.15 − 4.32 = 2.53 > 0` (using only
`√2 ≥ 1`). This is the multiplier's value at the center of the prime-free window made an
axiom-clean theorem — the constructive footprint of the unconditional window positivity,
evaluated where it is computable.

THE HONEST BOUNDARY (the standing discipline). `α(0) > 0` is the multiplier at ONE point
— EVIDENCE for `α ≥ 0` (the windowed positivity), exactly as `weilPrime_demo` and the
certified `λ`-slices are evidence: it is not the universal `α(τ) ≥ 0 ∀τ` (which needs the
complex-digamma real part and its uniform-in-τ bound, beyond any finite check), still less
RH (the window excludes every prime). Nothing here asserts the universal; the crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `()`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.f1_square.Analysis.PsiQuarter
import Core.f1_square.Analysis.Gamma

namespace UOR.Bridge.F1Square.Analysis

/-- The base `2` as a constructive real with the positivity witness at index `0`
    (`2 > 1 = 1/(0+1)`). -/
theorem two_seq_pos : Qlt (Qbound 0) ((ofQ (⟨2, 1⟩ : Q) (by decide)).seq 0) := by
  show Qlt (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q); decide

/-- **`√2 = exp(½·log 2)`** — the constructive square root of `2` (no sqrt primitive). -/
def sqrt2 : Real := RrpowPos (ofQ (⟨2, 1⟩ : Q) (by decide)) 0 two_seq_pos (ofQ (⟨1, 2⟩ : Q) (by decide))

/-- **`√2 ≥ 1`**: `exp` of a non-negative real is `≥ 1` (the exponent `½·log 2 ≥ 0`, since
    `log 2 ≥ 0` for base `2 ≥ 1`). -/
theorem one_le_sqrt2 : Rle one sqrt2 := by
  refine RexpReal_ge_one ?_
  refine Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) ?_
  refine Rnonneg_RlogPos (ofQ (⟨2, 1⟩ : Q) (by decide)) 0 two_seq_pos ?_
  intro n
  show Qle (⟨1, 1⟩ : Q) (add (⟨2, 1⟩ : Q) ⟨2, n + 1⟩)
  show (1 : Int) * (((1 * (n + 1)) : Nat) : Int) ≤ ((2 : Int) * ((n + 1 : Nat) : Int) + 2 * 1) * 1
  push_cast; omega

/-- **Burnol's multiplier at the window center**: `α(0) = 8√2 − log π + ψ(1/4)`. -/
def burnolAlphaZero : Real :=
  Radd (Radd (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2) (Rneg Rlogπc)) psiQuarter

/-- **`8√2 ≥ 8`** (from `√2 ≥ 1`). -/
private theorem eight_le_eight_sqrt2 :
    Rle (ofQ (⟨8, 1⟩ : Q) (by decide)) (Rmul (ofQ (⟨8, 1⟩ : Q) (by decide)) sqrt2) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_one (ofQ (⟨8, 1⟩ : Q) (by decide))))) ?_
  exact Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) one_le_sqrt2

/-- **`−log π ≥ −115/100`** (from `log π ≤ 115/100`, tightening `Rlogπc_le`). -/
private theorem neg_logpi_lower :
    Rle (ofQ (neg (⟨115, 100⟩ : Q)) (by decide)) (Rneg Rlogπc) := by
  refine Rneg_ofQ_le (by decide) (Rle_trans Rlogπc_le ?_)
  exact Rle_ofQ_ofQ _ (by decide) (by decide)

/-- **THE WINDOW-CENTER POSITIVITY CERTIFICATE, computed**: `α(0) = 8√2 − log π + ψ(1/4) > 0`
    (true value `≈ 5.94`; certified from the wide margin `8 − 1.15 − 4.32 = 2.53 > 0`). The
    value of Burnol's window multiplier at the center of the prime-free window, made an
    axiom-clean theorem — EVIDENCE for the windowed Weil positivity, not the universal
    `α(τ) ≥ 0 ∀τ`, still less RH. -/
theorem burnolAlphaZero_pos : Pos burnolAlphaZero := by
  refine Pos_of_Rle_ofQ (c := ⟨253, 100⟩) (by decide) (by decide) ?_
  -- α(0) = (8√2 + (−logπ)) + ψ(1/4) ≥ (8 + (−115/100)) + (−432/100) = 253/100
  have hstep : Rle
      (Radd (Radd (ofQ (⟨8, 1⟩ : Q) (by decide)) (ofQ (neg (⟨115, 100⟩ : Q)) (by decide)))
        (ofQ (⟨-432, 100⟩ : Q) (by decide)))
      burnolAlphaZero :=
    Radd_le_add (Radd_le_add eight_le_eight_sqrt2 neg_logpi_lower) psiQuarter_lower
  refine Rle_trans ?_ hstep
  -- 253/100 ≤ (8 + (−115/100)) + (−432/100) as constructive reals
  have h1 : Qeq (⟨253, 100⟩ : Q)
      (add (add (⟨8, 1⟩ : Q) (neg (⟨115, 100⟩ : Q))) (⟨-432, 100⟩ : Q)) := by decide
  refine Rle_trans (Rle_of_Req (ofQ_congr (by decide)
    (add_den_pos (add_den_pos (by decide) (by decide)) (by decide)) h1)) ?_
  refine Rle_trans (Rle_ofQ_add_Radd (add_den_pos (by decide) (by decide)) (by decide)) ?_
  exact Radd_le_add (Rle_ofQ_add_Radd (by decide) (by decide)) (Rle_refl _)

end UOR.Bridge.F1Square.Analysis
