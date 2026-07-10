/-
F1 square — v0.20.0 stage F: **the third Li coefficient `λ₃` in closed form**, the next rung of the
genuine λ-ladder, built on the constructive `γ₂` (`Rgamma2`).

The genuine Li sequence `λₙ = λₙ^{arith} + λₙ^{∞}` (`GenuineLi.lean`) is already general in `n`; its
arithmetic side is `λₙ^{arith} = −Σ_{j=1}^n C(n,j)·η_{j−1}` and the η-convention is anchored by
`η₀ = −γ`, `η₁ = γ² + 2γ₁` (the v0.15.3 / v0.18.0 slices). THIS FILE adds the next anchor —
deep-research-confirmed against Bombieri–Lagarias / Coffey / Keiper–Li:

    η₂  =  −γ³ − 3γγ₁ − (3/2)γ₂,

the FIRST anchor that needs the second Stieltjes constant `γ₂` (`Rgamma2`, the v0.20.0 dyadic-tail
construction). With it, `λ₃^{arith} = −(3η₀ + 3η₁ + η₂)` is a constructive object, and the closed
form meets the genuine ladder at `n = 3` (`genuineLam_three`) exactly as it did at `n = 1, 2`. The
archimedean side `λ₃^{∞} = genuineArchSeq 3` (needing `ζ(2), ζ(3)`) is already the general
construction — no new work.

WHAT THIS DOES AND DOES NOT DO. This completes the `λ₃` OBJECT (the closed-form constructive real)
and its consistency with the ladder. The `γ₂` numeric bracket that gates the `η₂` term (coefficient
`3/2`) is now CLOSED — `Rgamma2_ge_neg002 : γ₂ ≥ −0.02` (`GammaTwoBracket.lean`, the discrete
Euler–Maclaurin bracket). It does not YET prove `Pos λ₃`, but the difficulty was OVERSTATED here
once: the true value (computed from this very closed form) is `λ₃ ≈ 0.2076389` — the standard Li
coefficient — with `λ₃^{arith} ≈ +1.221` and `λ₃^{∞} ≈ −1.013`, an absolute MARGIN ≈ 0.208, not a
razor-thin `0.017`. The explicit closed form is
`λ₃ = 1 + (3/2)γ − 3γ² − 6γ₁ + γ³ + 3γγ₁ + (3/2)γ₂ − (3/2)log 4π + (9/4)ζ(2) − (7/8)ζ(3)`.

PRECISION ANALYSIS (term-by-term loss vs. the 0.208 margin — corrects an earlier note that named `γ`
as the sole binding constraint; it is NOT). The closed form has HEAVY CANCELLATION: the archimedean
block `−(3/2)log 4π + (9/4)ζ(2) − (7/8)ζ(3) ≈ −3.797 + 3.701 − 1.052` is three `Θ(3.8)` constants
collapsing to `Θ(1)`. So although the margin is `Θ(0.2)` in absolute terms, a positivity certificate
needs ALL SIX constants `γ, γ₁, γ₂, ζ(2), ζ(3), log 4π` sharpened to ~0.1–0.3% RELATIVE precision at
once. The DOMINANT loss is `γ₁`, not `γ`: the `−6γ₁` term is `+0.437` truly, but the only existing
bracket `γ₁ ≤ −0.0445` (`Rgamma1_le_neg445`, ±0.03-loose vs. the true `−0.0728`) yields only `+0.267`
— burning `0.17` of the `0.21` margin by itself. The remaining numeric work is therefore a SUBSTANTIAL
multi-constant bracketing project (a tight two-sided `γ₁` via deeper Euler–Maclaurin is the bottleneck;
`γ` to `~[0.577,0.578]`, `γ₂` to `~±0.005`, and `ζ(2),ζ(3),log 4π` to ~4 figures all needed too), NOT
a quick re-`decide`. CONNECTION TO THE CRUX: this is positive evidence that the per-`n` numeric route
is not merely finite (`UniformClosure`) but practically wall-bounded by cancellation that worsens with
`n` — reinforcing that the crux closes only as ONE uniform coherent fact (the prime–archimedean
coupling sign for all `n`, `genuine_crux_arch_coupling`), never by enumerating rungs. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.GenuineLi
import F1Square.Analysis.GammaTwo

namespace UOR.Bridge.F1Square.Analysis

/-- `η₀ = −γ` (the structure's first anchor value). -/
def Reta0 : Real := Rneg Rgamma_h

/-- `η₁ = γ² + 2γ₁` (the structure's second anchor value). -/
def Reta1 : Real := Radd (Rmul Rgamma_h Rgamma_h) (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)

/-- **`η₂ = −γ³ − 3γγ₁ − (3/2)γ₂`** — the third η-anchor, the first needing `γ₂` (`Rgamma2`).
    Deep-research-confirmed Bombieri–Lagarias / Keiper–Li convention. -/
def Reta2 : Real :=
  Rsub (Rsub (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
             (Rmul (ofQ ⟨3, 1⟩ (by decide)) (Rmul Rgamma_h Rgamma1)))
       (Rmul (ofQ ⟨3, 2⟩ (by decide)) Rgamma2)

/-- **η-data anchored through `η₂`** (extends `StieltjesEta` with the `γ₂`-bearing third anchor). -/
structure StieltjesEta3 extends StieltjesEta where
  /-- anchor: `η₂ = −γ³ − 3γγ₁ − (3/2)γ₂` (the built `γ`, `γ₁`, `γ₂`) -/
  eta_two : Req (eta 2) Reta2

/-- `n·(·)` respects `Req`. -/
theorem nsmulR_congr : ∀ (k : Nat) {x y : Real}, Req x y → Req (nsmulR k x) (nsmulR k y)
  | 0, _, _, _ => Req_refl _
  | 1, _, _, h => h
  | (k + 2), _, _, h => Radd_congr (nsmulR_congr (k + 1) h) h

/-- **`λ₃^{arith}` in closed form**: `−(3η₀ + 3η₁ + η₂)` with the canonical anchor values. -/
def Rlambda3_arith : Real :=
  Rneg (Radd (Radd (Radd zero (nsmulR (choose 3 1) Reta0)) (nsmulR (choose 3 2) Reta1))
             (nsmulR (choose 3 3) Reta2))

/-- **THE THIRD LI COEFFICIENT `λ₃` in closed form** — `λ₃^{arith} + λ₃^{∞}`, the next rung of the
    genuine ladder, the first to carry `γ₂`. -/
def Rlambda3 : Real := Radd Rlambda3_arith (genuineArchSeq 3)

/-- **Consistency at `n = 3`**: the genuine arithmetic side equals the closed form `λ₃^{arith}` for
    ANY η-data anchored through `η₂` (`−(3η₀ + 3η₁ + η₂)`). -/
theorem genuineArith_three (E : StieltjesEta3) :
    Req (genuineArithSeq E.eta 3) Rlambda3_arith := by
  unfold genuineArithSeq Rlambda3_arith
  simp only [arithTail]
  apply Rneg_congr
  exact Radd_congr (Radd_congr (Radd_congr (Req_refl zero)
    (nsmulR_congr (choose 3 1) E.eta_zero)) (nsmulR_congr (choose 3 2) E.eta_one))
    (nsmulR_congr (choose 3 3) E.eta_two)

/-- **The closed form meets the genuine ladder at `n = 3`**: `genuineLamSeq eta 3 ≈ Rlambda3` (the
    arithmetic sides reconcile by `genuineArith_three`; the archimedean side is `genuineArchSeq 3`
    on the nose). -/
theorem genuineLam_three (E : StieltjesEta3) :
    Req (genuineLamSeq E.eta 3) Rlambda3 := by
  unfold genuineLamSeq Rlambda3
  exact Radd_congr (genuineArith_three E) (Req_refl (genuineArchSeq 3))

/-- The inhabiting η₃-instance: the three built anchor values, `0` beyond (its `n ≥ 4` outputs are
    truncations — it exists to show the structure is real). -/
def etaThreeSlice : StieltjesEta3 where
  eta := fun n => match n with
    | 0 => Reta0
    | 1 => Reta1
    | 2 => Reta2
    | _ + 3 => zero
  eta_zero := Req_refl _
  eta_one := Req_refl _
  eta_two := Req_refl _

end UOR.Bridge.F1Square.Analysis
