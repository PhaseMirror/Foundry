/-
F1 square — v0.18.0 stage D, brick 2: the **Bombieri–Lagarias decomposition of `λ₂`**, and the
two-slice realization of the `Li.LiDecomposition` interface.

The Bombieri–Lagarias route (J. Number Theory 77 (1999), via the Guinand–Weil explicit formula)
splits every Li coefficient into an arithmetic (finite-place) and an archimedean part,
`λₙ = λₙ^{arith} + λₙ^{∞}`. The ARITHMETIC part has the verified finite binomial form

    λₙ^{arith} = −Σ_{j=1}^{n} C(n,j)·η_{j−1},

with `η_j` the Laurent coefficients of `−ζ′/ζ` at `s = 1` — constructible from `Λ` alone, with
the finite algebraic recursion `ηₙ = −(n+1)γₙ − Σ ηₖγ_{n−k−1}` tying them to the Stieltjes `γⱼ`
(Coffey, J. Comp. Appl. Math. 166 (2004); Maslanka, arXiv math/0406312). ⚠ CONVENTION (pinned):
this file uses the STANDARD Stieltjes convention, in which `η₀ = −γ` and `η₁ = γ² + 2γ₁` with
`γ₁ ≈ −0.0728` — Maslanka's raw-Laurent convention flips the `γ₁` sign (his `+2γ₁` = standard
`−2γ₁`); transcribing literature formulas without pinning the convention is the dominant error
mode here. The general-`n` closed form of the ARCHIMEDEAN part (a `ζ(j)`-binomial sum plus a
linear term) appears in Coffey (arXiv math-ph/0505052, Thm 1) but its exact general shape is
not independently verified — the instances used in this file are the `n = 1, 2` cases, each
independently verified (the `n = 2` total below reproduces the closed form
`λ₂ = 1 + γ − γ² − 2γ₁ − log 4π + ¾ζ(2) ≈ 0.0923457`, re-checked to 30 digits against
Keiper 1992 / Coffey 2005). At `n = 2`:

    λ₂^{arith} = −(2η₀ + η₁) = 2γ − (γ² + 2γ₁)        (the prime side, via the Stieltjes γ₁),
    λ₂^{∞}     = (1 − γ) − log 4π + ¾·ζ(2)            (the Γ-factor place),

and their sum is exactly the v0.16.0 `Rlambda2 = 1 + γ − γ² − 2γ₁ − log 4π + ¾·ζ(2)` —
proved below as a constructive-real identity (`Rlambda2_decomposition`), extending the v0.15.3
`n = 1` split (`λ₁ = γ + (1 − γ/2 − ½·log 4π)`, `Analysis/LiOne.lean`). The sequence-level
interface `Li.LiDecomposition` is then realized with BOTH genuine slices
(`li_decomposition_two_realized`), and both slices are certified positive
(`liTwo_evidence`) — the deepest genuine realization of the interface to date.

HONEST SCOPE: the `n = 1, 2` slices are genuine; for `n ≥ 3` the sequences fall back to the
trivial split (the higher `η_j` need the higher Stieltjes constants `γ₂, …`, not yet built).
Nothing here bears on `λₙ > 0 ∀ n` — that is RH and stays OPEN.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.LambdaTwo
import Multiplicity.F1.Analysis.LiOne

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The arithmetic (finite-place) part of `λ₂`**: `λ₂^{arith} = −(2η₀ + η₁) = 2γ − (γ² + 2γ₁)`
    (`η₀ = −γ`, `η₁ = γ² + 2γ₁` — the Laurent data of `−ζ′/ζ` at `s = 1`, carried by the
    Euler–Mascheroni `γ` and the first Stieltjes constant `γ₁`). -/
def Rlambda2_arith : Real :=
  Rsub (Radd Rgamma_h Rgamma_h)
    (Radd (Rmul Rgamma_h Rgamma_h) (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1))

/-- **The archimedean part of `λ₂`**: `λ₂^{∞} = (1 − γ) − log 4π + ¾·ζ(2)` (the Gamma-factor
    place; the BL `n = 2` instance `1 − (γ + log 4π) + (1 − 2⁻²)·ζ(2)·C(2,2)`). -/
def Rlambda2_arch : Real :=
  Radd (Radd (Rsub one Rgamma_h) (Rneg Rlog4pic))
    (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide)))

private theorem cancel_middle (T1 : Real) :
    Req (Radd (Rsub Rgamma_h T1) (Rsub one Rgamma_h)) (Rsub one T1) := by
  refine Req_trans (Req_symm (Rsub_Radd_Radd Rgamma_h one T1 Rgamma_h)) ?_
  show Req (Radd (Radd Rgamma_h one) (Rneg (Radd T1 Rgamma_h))) (Rsub one T1)
  refine Req_trans (Radd_congr (Req_refl (Radd Rgamma_h one)) (Rneg_Radd T1 Rgamma_h)) ?_
  refine Req_trans (Radd_congr (Req_refl (Radd Rgamma_h one))
    (Radd_comm (Rneg T1) (Rneg Rgamma_h))) ?_
  refine Req_trans (Radd_swap Rgamma_h one (Rneg Rgamma_h) (Rneg T1)) ?_
  refine Req_trans (Radd_congr (Radd_neg Rgamma_h) (Req_refl (Radd one (Rneg T1)))) ?_
  exact Req_trans (Radd_comm zero (Radd one (Rneg T1))) (Radd_zero (Radd one (Rneg T1)))

/-- **The Bombieri–Lagarias decomposition of `λ₂`**: `λ₂ = λ₂^{arith} + λ₂^{∞}` — the genuine
    two-place split of the second Li coefficient, as a constructive-real identity
    (the `n = 2` companion of `Rlambda1_decomposition`). -/
theorem Rlambda2_decomposition : Req Rlambda2 (Radd Rlambda2_arith Rlambda2_arch) := by
  refine Req_symm ?_
  -- abbreviations: A = γ − γ², T1 = 2γ₁, N2 = −log4π, Z = ¾ζ(2)
  show Req (Radd
      (Rsub (Radd Rgamma_h Rgamma_h)
        (Radd (Rmul Rgamma_h Rgamma_h) (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)))
      (Radd (Radd (Rsub one Rgamma_h) (Rneg Rlog4pic))
        (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide)))))
    Rlambda2
  -- Step 1: split the arithmetic part: (γ+γ) − (γ²+2γ₁) ≈ (γ−γ²) + (γ−2γ₁)
  refine Req_trans (Radd_congr
    (Rsub_Radd_Radd Rgamma_h Rgamma_h (Rmul Rgamma_h Rgamma_h)
      (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1))
    (Req_refl _)) ?_
  -- Step 2: pull ¾ζ(2) out: (A+B) + ((C+N2)+Z) ≈ ((A+B) + (C+N2)) + Z
  refine Req_trans (Req_symm (Radd_assoc
    (Radd (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h))
      (Rsub Rgamma_h (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)))
    (Radd (Rsub one Rgamma_h) (Rneg Rlog4pic))
    (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide))))) ?_
  refine Radd_congr ?_ (Req_refl (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide))))
  -- Step 3: reassociate (A+B) + (C+N2) ≈ A + ((B+C) + N2)
  refine Req_trans (Radd_assoc (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h))
    (Rsub Rgamma_h (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1))
    (Radd (Rsub one Rgamma_h) (Rneg Rlog4pic))) ?_
  refine Req_trans (Radd_congr (Req_refl (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)))
    (Req_symm (Radd_assoc (Rsub Rgamma_h (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1))
      (Rsub one Rgamma_h) (Rneg Rlog4pic)))) ?_
  -- Step 4: the cancellation (γ − 2γ₁) + (1 − γ) ≈ 1 − 2γ₁
  refine Req_trans (Radd_congr (Req_refl (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)))
    (Radd_congr (cancel_middle (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1))
      (Req_refl (Rneg Rlog4pic)))) ?_
  -- Step 5: A + ((1 − 2γ₁) + N2) ≈ ((1 + A) + (−2γ₁)) + N2 = λ₂'s first three terms
  refine Req_trans (Req_symm (Radd_assoc (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h))
    (Rsub one (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)) (Rneg Rlog4pic))) ?_
  refine Radd_congr ?_ (Req_refl (Rneg Rlog4pic))
  -- A + (1 + (−2γ₁)) ≈ (1 + A) + (−2γ₁)
  refine Req_trans (Req_symm (Radd_assoc (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)) one
    (Rneg (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)))) ?_
  exact Radd_congr (Radd_comm (Rsub Rgamma_h (Rmul Rgamma_h Rgamma_h)) one)
    (Req_refl (Rneg (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)))

-- ===========================================================================
-- The two-slice realization of `Li.LiDecomposition`.
-- ===========================================================================

/-- The arithmetic sequence with BOTH genuine slices: `λ₁^{arith} = γ` at `n = 1`,
    `λ₂^{arith} = 2γ − (γ² + 2γ₁)` at `n = 2`, `0` elsewhere (the higher slices need the
    higher Stieltjes constants `γ₂, …`). -/
def liArithSeqTwo : Nat → Real := fun n =>
  if n = 1 then Rlambda1_arith else if n = 2 then Rlambda2_arith else zero

/-- The archimedean sequence with both genuine slices. -/
def liArchSeqTwo : Nat → Real := fun n =>
  if n = 1 then Rlambda1_arch else if n = 2 then Rlambda2_arch else zero

/-- The Li sequence with both genuine values: `λ₁` at `n = 1`, `λ₂` at `n = 2`,
    `arith + arch` elsewhere. -/
def liLamSeqTwo : Nat → Real := fun n =>
  if n = 1 then Rlambda1 else if n = 2 then Rlambda2
  else Radd (liArithSeqTwo n) (liArchSeqTwo n)

/-- **`Li.LiDecomposition`, realized with TWO genuine slices**: the split
    `λₙ = λₙ^{arith} + λₙ^{∞}` holds for `liLamSeqTwo`, and at `n = 1` AND `n = 2` its pieces
    are the genuine Bombieri–Lagarias arithmetic/archimedean parts (`Rlambda1_decomposition`,
    `Rlambda2_decomposition`) — the deepest realization of the interface to date. -/
theorem li_decomposition_two_realized :
    Li.LiDecomposition liLamSeqTwo liArithSeqTwo liArchSeqTwo := by
  intro n
  by_cases h1 : n = 1
  · subst h1
    simp only [liLamSeqTwo, liArithSeqTwo, liArchSeqTwo, if_pos rfl]
    exact Rlambda1_decomposition
  · by_cases h2 : n = 2
    · subst h2
      simp only [liLamSeqTwo, liArithSeqTwo, liArchSeqTwo, if_neg h1, if_pos rfl]
      exact Rlambda2_decomposition
    · simp only [liLamSeqTwo, liArithSeqTwo, liArchSeqTwo, if_neg h1, if_neg h2]
      exact Req_refl _

/-- **The two-slice positivity evidence**: both genuine slices of the realized Li sequence are
    certified positive (certified lower bounds `λ₁ ≥ 0.0042`, `λ₂ ≥ 0.0043`; true values
    `λ₁ ≈ 0.0230957`, `λ₂ ≈ 0.0923457`) — evidence for Li's criterion at `n = 1, 2`, NOT the
    crux (`λₙ > 0 ∀ n` = RH stays open). -/
theorem liTwo_evidence : Pos (liLamSeqTwo 1) ∧ Pos (liLamSeqTwo 2) :=
  ⟨Rlambda1_pos, Rlambda2_pos⟩

end Multiplicity.UOR.Bridge.F1Square.Analysis
