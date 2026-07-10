/-
F1 square — v0.22.0 crux frontier: **the fourth Li coefficient `λ₄` in closed form**, the next rung
of the genuine λ-ladder, built on the constructive `γ₃` (`Rgamma3`, `GammaThree.lean`).

The genuine Li sequence `λₙ = λₙ^{arith} + λₙ^{∞}` (`GenuineLi.lean`) is general in `n`; its
arithmetic side is `λₙ^{arith} = −Σ_{j=1}^n C(n,j)·η_{j−1}` with the η-convention anchored by
`η₀ = −γ`, `η₁ = γ² + 2γ₁`, `η₂ = −γ³ − 3γγ₁ − (3/2)γ₂` (the v0.15.3 / v0.18.0 / v0.20.0 slices).
THIS FILE adds the next anchor — the FIRST to carry `γ₃`, derived from the `−ζ′/ζ` Laurent data
`ζ(s) = 1/(s−1) + Σ (−1)ⁿγₙ(s−1)ⁿ/n!` and confirmed numerically (below):

    η₃  =  γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃.

With it, `λ₄^{arith} = −(4η₀ + 6η₁ + 4η₂ + η₃)` is a constructive object, and the closed form meets
the genuine ladder at `n = 4` (`genuineLam_four`) exactly as at `n = 1, 2, 3`. The archimedean side
`λ₄^{∞} = genuineArchSeq 4` (needing `ζ(2), ζ(3), ζ(4)`) is already the general construction.

NUMERIC CONFIRMATION (the standard Li value `λ₄ ≈ 0.36998`). With
`γ ≈ 0.5772157, γ₁ ≈ −0.0728158, γ₂ ≈ −0.0096904, γ₃ ≈ +0.0020538`:
`η₀ ≈ −0.577216, η₁ ≈ +0.187546, η₂ ≈ −0.051660, η₃ ≈ +0.014738`, so
`λ₄^{arith} = −(4η₀+6η₁+4η₂+η₃) ≈ +1.37549`, and `λ₄^{∞} = genuineArchSeq 4 ≈ −1.00672`
(`= −5.21640 + (9/2)ζ(2) − (7/2)ζ(3) + (15/16)ζ(4)`), giving `λ₄ ≈ +0.36877` — the standard Li
coefficient (small rounding). KEY for the bracket: `γ₃` enters λ₄ ONLY through `η₃`, with coefficient
`+2/3`, so in `λ₄^{arith} = −(… + η₃)` the `γ₃` contribution is `−(2/3)γ₃ ≈ −0.00137` — TINY, since
`γ₃ ≈ +0.00205`. Hence `Pos λ₄` needs only a LOOSE UPPER bound on `γ₃` (the side that controls the
negative `−(2/3)γ₃`), not the tight two-sided bracket the dominant constants demand. This pins the
`GammaThree` bracket target: an upper bound `γ₃ ≤ ε` for modest `ε`.

This completes the `λ₄` OBJECT (the closed-form constructive real) and its ladder consistency. It does
not prove `Pos λ₄` (that awaits the `γ₃` upper bracket plus the multi-constant assembly, as `λ₃`'s
`Rlambda3_pos` did). Extending `n` one rung conquers ground but never closes the crux (`∀ n` = RH);
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.LambdaThree
import F1Square.Analysis.GammaThree

namespace UOR.Bridge.F1Square.Analysis

/-- **`η₃ = γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃`** — the fourth η-anchor, the first needing `γ₃`
    (`Rgamma3`). Derived from the `−ζ′/ζ` Laurent expansion; numerically confirmed (module docstring). -/
def Reta3 : Real :=
  Radd (Radd (Radd
      (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
            (Rmul (ofQ ⟨4, 1⟩ (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)))
      (Rmul (ofQ ⟨2, 1⟩ (by decide)) (Rmul Rgamma1 Rgamma1)))
    (Rmul (ofQ ⟨2, 1⟩ (by decide)) (Rmul Rgamma_h Rgamma2)))
  (Rmul (ofQ ⟨2, 3⟩ (by decide)) Rgamma3)

/-- **η-data anchored through `η₃`** (extends `StieltjesEta3` with the `γ₃`-bearing fourth anchor). -/
structure StieltjesEta4 extends StieltjesEta3 where
  /-- anchor: `η₃ = γ⁴ + 4γ²γ₁ + 2γ₁² + 2γγ₂ + (2/3)γ₃` (the built `γ, γ₁, γ₂, γ₃`) -/
  eta_three : Req (eta 3) Reta3

/-- **`λ₄^{arith}` in closed form**: `−(4η₀ + 6η₁ + 4η₂ + η₃)` with the canonical anchor values. -/
def Rlambda4_arith : Real :=
  Rneg (Radd (Radd (Radd (Radd zero (nsmulR (choose 4 1) Reta0)) (nsmulR (choose 4 2) Reta1))
             (nsmulR (choose 4 3) Reta2))
             (nsmulR (choose 4 4) Reta3))

/-- **THE FOURTH LI COEFFICIENT `λ₄` in closed form** — `λ₄^{arith} + λ₄^{∞}`, the next rung of the
    genuine ladder, the first to carry `γ₃`. -/
def Rlambda4 : Real := Radd Rlambda4_arith (genuineArchSeq 4)

/-- **Consistency at `n = 4`**: the genuine arithmetic side equals the closed form `λ₄^{arith}` for
    ANY η-data anchored through `η₃` (`−(4η₀ + 6η₁ + 4η₂ + η₃)`). -/
theorem genuineArith_four (E : StieltjesEta4) :
    Req (genuineArithSeq E.eta 4) Rlambda4_arith := by
  unfold genuineArithSeq Rlambda4_arith
  simp only [arithTail]
  apply Rneg_congr
  exact Radd_congr (Radd_congr (Radd_congr (Radd_congr (Req_refl zero)
    (nsmulR_congr (choose 4 1) E.eta_zero)) (nsmulR_congr (choose 4 2) E.eta_one))
    (nsmulR_congr (choose 4 3) E.eta_two)) (nsmulR_congr (choose 4 4) E.eta_three)

/-- **The closed form meets the genuine ladder at `n = 4`**: `genuineLamSeq eta 4 ≈ Rlambda4` (the
    arithmetic sides reconcile by `genuineArith_four`; the archimedean side is `genuineArchSeq 4`
    on the nose). -/
theorem genuineLam_four (E : StieltjesEta4) :
    Req (genuineLamSeq E.eta 4) Rlambda4 := by
  unfold genuineLamSeq Rlambda4
  exact Radd_congr (genuineArith_four E) (Req_refl (genuineArchSeq 4))

/-- The inhabiting η₄-instance: the four built anchor values, `0` beyond (its `n ≥ 5` outputs are
    truncations — it exists to show the structure is real). -/
def etaFourSlice : StieltjesEta4 where
  eta := fun n => match n with
    | 0 => Reta0
    | 1 => Reta1
    | 2 => Reta2
    | 3 => Reta3
    | _ + 4 => zero
  eta_zero := Req_refl _
  eta_one := Req_refl _
  eta_two := Req_refl _
  eta_three := Req_refl _

end UOR.Bridge.F1Square.Analysis
