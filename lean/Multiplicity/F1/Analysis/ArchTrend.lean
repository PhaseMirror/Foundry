/-
F1 square — v0.19.0 stage E, the closure push: **THE GENUINE ARCHIMEDEAN TREND, ALL `n`** —
the archimedean side of the crux as a single constructed object.

THE OBJECT. The Bombieri–Lagarias archimedean part has the exact general-`n` closed form
[CLASSICAL, deep-research-verified against the primary PDFs — Voros, *Math. Phys. Anal.
Geom.* 9 (2006), eqs. 20–21; Coffey, arXiv math-ph/0505052, Thm 1; Lagarias, *Ann. Inst.
Fourier* 57 (2007), eq. (4.11) with the pole term folded in]:

    `λₙ^{∞} = 1 − (n/2)(γ + log 4π) + Σ_{j=2}^n (−1)ʲ C(n,j) (1 − 2^{−j}) ζ(j)`.

EVERY ingredient is already built in this substrate: `γ` (`Rgamma_h`, v0.14.0), `log 4π`
(`Rlog4pic`, v0.14.0), `ζ(j)` for every `j ≥ 2` (`zeta`, v0.10.0), binomials (`choose`).
So the WHOLE archimedean side of the crux — for every `n` at once, one definition, no
enumeration — is constructible today, and here it is: `genuineArchSeq`.

THE CONSISTENCY THEOREMS (the guards): at the two independently-built slices the
construction agrees, as a theorem, with the v0.15.3/v0.18.0 archimedean parts —
`genuineArch_one : genuineArchSeq 1 ≈ Rlambda1_arch` and
`genuineArch_two : genuineArchSeq 2 ≈ Rlambda2_arch`. These are real reconciliations of
two distinct constructions (the closed-form instance vs the hand-assembled slices), not
restatements — exactly the §2.2 self-check discipline applied to the trend.

WHAT THIS CHANGES (and what it does not). With the trend constructed, the crux's open
content contracts to the ARITHMETIC side alone: through the trace and the dominance face
(`Square.crux_vs_constructed_trend`), the crux is now "the genuine arithmetic part admits
one bound strictly below THIS BUILT SEQUENCE". The identification of `genuineArchSeq` with
the archimedean side of the genuine ζ explicit formula is [CLASSICAL] (the closed form
above); its positivity/growth — `(n/2)log n + cn + O(1)`, `c = (γ−1−log 2π)/2`,
unconditional (Lagarias Thm 5.1) — is sourced, not mechanized. NOTHING here touches
positivity of the genuine `λₙ`: the crux stays open; the fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.LiTwo

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- The `j`-th archimedean summand, `j ≥ 2`: `(−1)ʲ · C(n,j) · (1 − 2^{−j}) · ζ(j)`,
    with the sign and the rational coefficient `C(n,j)·(2ʲ−1)/2ʲ` folded into one
    exact rational. -/
def genArchTerm (n j : Nat) (hj : 2 ≤ j) : Real :=
  Rmul
    (ofQ ⟨(if j % 2 = 0 then (1 : Int) else -1) * (choose n j) * (2 ^ j - 1), 2 ^ j⟩
      (Nat.pos_pow_of_pos j (by decide)))
    (zeta j hj)

/-- The archimedean tail `Σ_{i=2}^{j} (−1)ⁱ C(n,i)(1 − 2^{−i})ζ(i)` (empty for `j ≤ 1`). -/
def genArchTail (n : Nat) : Nat → Real
  | 0 => zero
  | 1 => zero
  | (j + 2) => Radd (genArchTail n (j + 1)) (genArchTerm n (j + 2) (by omega))

/-- `n`-fold real sum `n·x` (no scalar multiplication needed — pure `Radd`). -/
def nsmulR : Nat → Real → Real
  | 0, _ => zero
  | 1, x => x
  | (k + 2), x => Radd (nsmulR (k + 1) x) x

/-- **THE GENUINE ARCHIMEDEAN TREND, every `n`**:
    `λₙ^{∞} = 1 − (n/2)(γ + log 4π) + Σ_{j=2}^n (−1)ʲ C(n,j)(1 − 2^{−j})ζ(j)` as a single
    constructive object — the whole archimedean side of the crux, built (module
    docstring for provenance and for what stays open). -/
def genuineArchSeq (n : Nat) : Real :=
  Radd (Rsub one (Rhalf (nsmulR n (Radd Rgamma_h Rlog4pic)))) (genArchTail n n)

-- ===========================================================================
-- The consistency guards: the construction meets the independently-built slices.
-- ===========================================================================

/-- **Consistency at `n = 1`**: the closed-form instance equals the v0.15.3 hand-built
    `λ₁^{∞} = 1 − γ/2 − ½·log 4π` (`Rlambda1_arch`) — a genuine reconciliation of two
    distinct constructions. -/
theorem genuineArch_one : Req (genuineArchSeq 1) Rlambda1_arch := by
  show Req (Radd (Rsub one (Rhalf (Radd Rgamma_h Rlog4pic))) zero) Rlambda1_arch
  refine Req_trans (Radd_zero _) ?_
  -- `1 − ½(γ + L) ≈ (1 + (−½γ)) + (−½L)`
  refine Req_trans (Radd_congr (Req_refl one)
    (Req_trans (Rneg_congr (Rhalf_Radd Rgamma_h Rlog4pic))
      (Rneg_Radd (Rhalf Rgamma_h) (Rhalf Rlog4pic)))) ?_
  exact Req_symm (Radd_assoc one (Rneg (Rhalf Rgamma_h)) (Rneg (Rhalf Rlog4pic)))

/-- **Consistency at `n = 2`**: the closed-form instance equals the v0.18.0 hand-built
    `λ₂^{∞} = (1 − γ) − log 4π + ¾·ζ(2)` (`Rlambda2_arch`). -/
theorem genuineArch_two : Req (genuineArchSeq 2) Rlambda2_arch := by
  show Req
    (Radd (Rsub one (Rhalf (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))))
      (Radd zero (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide)))))
    Rlambda2_arch
  -- `1 − ½((γ+L) + (γ+L)) ≈ (1 − γ) + (−L)`
  have hmain : Req
      (Rsub one (Rhalf (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))))
      (Radd (Rsub one Rgamma_h) (Rneg Rlog4pic)) := by
    refine Req_trans (Radd_congr (Req_refl one) (Rneg_congr
      (Req_trans (Rhalf_Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (Rhalf_double (Radd Rgamma_h Rlog4pic))))) ?_
    refine Req_trans (Radd_congr (Req_refl one) (Rneg_Radd Rgamma_h Rlog4pic)) ?_
    exact Req_symm (Radd_assoc one (Rneg Rgamma_h) (Rneg Rlog4pic))
  have htail : Req (Radd zero (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide))))
      (Rmul (ofQ ⟨3, 4⟩ (by decide)) (zeta 2 (by decide))) :=
    Req_trans (Radd_comm zero _) (Radd_zero _)
  exact Radd_congr hmain htail

end Multiplicity.UOR.Bridge.F1Square.Analysis
