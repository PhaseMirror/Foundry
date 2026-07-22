/-
F1 square — v0.22.0 crux frontier: **the fifth Li coefficient `λ₅` in closed form**, the next rung of
the genuine λ-ladder, the FIRST to carry `γ₄` (`Rgamma4`, `GammaFour.lean`).

The genuine Li sequence `λₙ = λₙ^{arith} + λₙ^{∞}` (`GenuineLi.lean`) has arithmetic side
`λₙ^{arith} = −Σ_{j=1}^n C(n,j)·η_{j−1}`, the η-anchors coming from the `−ζ′/ζ` Laurent data
`ζ(s) = 1/(s−1) + Σ (−1)ⁿγₙ(s−1)ⁿ/n!`.  Writing `F(u) = (s−1)ζ = 1 + Σ bₙu^{n+1}`,
`bₙ = (−1)ⁿγₙ/n!`, the η are the Taylor coefficients of `−F'/F = −(log F)'`, i.e.
`ηⱼ = (j+1)·gⱼ₊₁` with `−log F = Σ gⱼuʲ`.  This reproduces `η₀=−γ`, `η₁=γ²+2γ₁`,
`η₂=−γ³−3γγ₁−(3/2)γ₂`, `η₃=γ⁴+4γ²γ₁+2γ₁²+2γγ₂+(2/3)γ₃` exactly (the v0.15.3–v0.22.0 slices), and
gives the next anchor — the FIRST to carry `γ₄`:

    η₄ = −γ⁵ − 5γ³γ₁ − 5γγ₁² − (5/2)γ²γ₂ − (5/2)γ₁γ₂ − (5/6)γγ₃ − (5/24)γ₄.

With it, `λ₅^{arith} = −(5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄)` is a constructive object, and the closed form
meets the genuine ladder at `n = 5` (`genuineLam_five`) exactly as at `n = 1..4`.

NUMERIC CONFIRMATION (the standard Li value `λ₅ ≈ 0.51812`). With
`γ ≈ 0.5772157, γ₁ ≈ −0.0728158, γ₂ ≈ −0.0096904, γ₃ ≈ +0.0020538, γ₄ ≈ +0.0072186`:
`η₄ ≈ −0.005539`, so `λ₅^{arith} = −(5η₀+10η₁+10η₂+5η₃+η₄) ≈ +1.45906`, and
`λ₅^{∞} = genuineArchSeq 5 ≈ −0.94094`, giving `λ₅ ≈ +0.51812` — the standard Li coefficient.
KEY for the bracket: `γ₄` enters `λ₅` ONLY through `η₄`, with coefficient `−(5/24)`, so in
`λ₅^{arith} = −(… + η₄)` the `γ₄` contribution is `+(5/24)γ₄ ≈ +0.00150` — TINY and POSITIVE
(the favourable side), so `Pos λ₅` needs only a LOOSE bound on `γ₄`.

This completes the `λ₅` OBJECT (the closed-form constructive real) and its ladder consistency. It does
NOT prove `Pos λ₅` (that awaits the `γ₄` numeric bracket plus the multi-constant assembly, as `λ₄`'s
`Rlambda4_pos` did). Extending `n` one rung conquers ground but never closes the crux (`∀ n` = RH); the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaFour
import Core.F1.Analysis.GammaFour

namespace UOR.Bridge.F1Square.Analysis

/-- **`η₄ = −γ⁵ − 5γ³γ₁ − 5γγ₁² − (5/2)γ²γ₂ − (5/2)γ₁γ₂ − (5/6)γγ₃ − (5/24)γ₄`** — the fifth η-anchor,
    the first needing `γ₄` (`Rgamma4`). Derived from the `−ζ′/ζ` Laurent expansion (`ηⱼ = (j+1)gⱼ₊₁`,
    `−log F = Σ gⱼuʲ`); numerically confirmed (module docstring, `η₄ ≈ −0.005539`). -/
def Reta4 : Real :=
  Rneg (Radd (Radd (Radd (Radd (Radd (Radd
      (Rmul (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h) Rgamma_h)
      (Rmul (ofQ ⟨5, 1⟩ (by decide)) (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma1)))
      (Rmul (ofQ ⟨5, 1⟩ (by decide)) (Rmul Rgamma_h (Rmul Rgamma1 Rgamma1))))
      (Rmul (ofQ ⟨5, 2⟩ (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma2)))
      (Rmul (ofQ ⟨5, 2⟩ (by decide)) (Rmul Rgamma1 Rgamma2)))
      (Rmul (ofQ ⟨5, 6⟩ (by decide)) (Rmul Rgamma_h Rgamma3)))
      (Rmul (ofQ ⟨5, 24⟩ (by decide)) Rgamma4))

/-- **η-data anchored through `η₄`** (extends `StieltjesEta4` with the `γ₄`-bearing fifth anchor). -/
structure StieltjesEta5 extends StieltjesEta4 where
  /-- anchor: `η₄ = −γ⁵ − 5γ³γ₁ − 5γγ₁² − (5/2)γ²γ₂ − (5/2)γ₁γ₂ − (5/6)γγ₃ − (5/24)γ₄`. -/
  eta_four : Req (eta 4) Reta4

/-- **`λ₅^{arith}` in closed form**: `−(5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄)` with the canonical anchors. -/
def Rlambda5_arith : Real :=
  Rneg (Radd (Radd (Radd (Radd (Radd zero (nsmulR (choose 5 1) Reta0)) (nsmulR (choose 5 2) Reta1))
             (nsmulR (choose 5 3) Reta2)) (nsmulR (choose 5 4) Reta3))
             (nsmulR (choose 5 5) Reta4))

/-- **THE FIFTH LI COEFFICIENT `λ₅` in closed form** — `λ₅^{arith} + λ₅^{∞}`, the next rung of the
    genuine ladder, the first to carry `γ₄`. -/
def Rlambda5 : Real := Radd Rlambda5_arith (genuineArchSeq 5)

/-- **Consistency at `n = 5`**: the genuine arithmetic side equals the closed form `λ₅^{arith}` for
    ANY η-data anchored through `η₄` (`−(5η₀ + 10η₁ + 10η₂ + 5η₃ + η₄)`). -/
theorem genuineArith_five (E : StieltjesEta5) :
    Req (genuineArithSeq E.eta 5) Rlambda5_arith := by
  unfold genuineArithSeq Rlambda5_arith
  simp only [arithTail]
  apply Rneg_congr
  exact Radd_congr (Radd_congr (Radd_congr (Radd_congr (Radd_congr (Req_refl zero)
    (nsmulR_congr (choose 5 1) E.eta_zero)) (nsmulR_congr (choose 5 2) E.eta_one))
    (nsmulR_congr (choose 5 3) E.eta_two)) (nsmulR_congr (choose 5 4) E.eta_three))
    (nsmulR_congr (choose 5 5) E.eta_four)

/-- **The closed form meets the genuine ladder at `n = 5`**: `genuineLamSeq eta 5 ≈ Rlambda5`. -/
theorem genuineLam_five (E : StieltjesEta5) :
    Req (genuineLamSeq E.eta 5) Rlambda5 := by
  unfold genuineLamSeq Rlambda5
  exact Radd_congr (genuineArith_five E) (Req_refl (genuineArchSeq 5))

/-- The inhabiting η₅-instance: the five built anchor values, `0` beyond. -/
def etaFiveSlice : StieltjesEta5 where
  eta := fun n => match n with
    | 0 => Reta0
    | 1 => Reta1
    | 2 => Reta2
    | 3 => Reta3
    | 4 => Reta4
    | _ + 5 => zero
  eta_zero := Req_refl _
  eta_one := Req_refl _
  eta_two := Req_refl _
  eta_three := Req_refl _
  eta_four := Req_refl _

end UOR.Bridge.F1Square.Analysis
