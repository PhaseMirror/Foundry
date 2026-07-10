/-
F1 square — v0.21.0 stage G, brick **the atlas generator (candidate)**: extrapolating from the
shift-length facet to formalize a uniform-rule candidate, and testing it against the growth filter.

Following the user's program — study the Atlas facets, then extrapolate to formalize the generator.
The Coxeter candidate was killed (periodic ⟹ bounded, `CoxeterCandidate`). The growth filter (§7)
requires the unbounded leading growth `2λₙ ~ n log n`. The **shift-length facet** supplies exactly
that growth class: the Frobenius orbit shift lengths `log p` (`Cohomology.orbitShift`,
`FrobForm.shiftLen`) accumulate as `Σ log ~ log n! ~ n log n` (Stirling).

So we INVENT the candidate diagonal from the shift lengths:
    `atlasShiftDiag n = Σ_{k<n} shiftLen k = Σ_{k<n} log(k+2)`,
zero-free and atlas-intrinsic (no `λ`, no zeros — built from the addressing/orbit log weights). We
then TEST it: unlike Coxeter it is **strictly monotone** (`atlasShiftDiag_mono`) with each step past
`n = 2` adding `≥ 1` (`atlasShiftDiag_step_ge_one`), hence UNBOUNDED — it **survives the growth
pre-filter** that killed the Coxeter candidate, and its leading order is `n log n` (Stirling, the
right class).

HONEST BOUNDARY. Surviving the growth filter is necessary, not sufficient (§8, Stage 0). The witness
must also satisfy Gate A — `gramOf ι D n n = 2λₙ` EXACTLY for all `n`, i.e. write `2λₙ` as a manifest
sum of squares emanating from the single Prime. That exact identity is §4.1 / RH; it is NOT supplied
by matching the growth class, and it is not asserted. This is a SURVIVING candidate, not a witness;
the crux fields stay `none`. The remaining work is whether the shift-length sum-of-squares can be
made to hit `2λₙ` on the nose — which is exactly the open content.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.FrobForm
import F1Square.Square.CoxeterCandidate

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The invented candidate diagonal**, from the shift-length facet: `Σ_{k<n} log(k+2)` — the
    accumulated Frobenius-orbit shift lengths. Atlas-intrinsic, zero-free, leading order `n log n`. -/
def atlasShiftDiag (n : Nat) : Real := RsumN shiftLen n

/-- **The candidate is strictly monotone** (each step adds a nonnegative shift length) — unlike the
    periodic Coxeter candidate, it never returns. -/
theorem atlasShiftDiag_mono (n : Nat) : Rle (atlasShiftDiag n) (atlasShiftDiag (n + 1)) := by
  show Rle (RsumN shiftLen n) (Radd (RsumN shiftLen n) (shiftLen n))
  exact Rle_self_Radd_right (Rnonneg_logN _ _)

/-- **Each step past `n = 2` adds `≥ 1`**: `atlasShiftDiag (n+1) ≥ atlasShiftDiag n + 1` for `n ≥ 2`
    (since `log(n+2) ≥ 1` for `n+2 ≥ 4`). So the candidate is UNBOUNDED — it SURVIVES the growth
    pre-filter that killed the bounded Coxeter candidate. -/
theorem atlasShiftDiag_step_ge_one (n : Nat) (h : 2 ≤ n) :
    Rle (Radd (atlasShiftDiag n) one) (atlasShiftDiag (n + 1)) := by
  show Rle (Radd (RsumN shiftLen n) one) (Radd (RsumN shiftLen n) (shiftLen n))
  refine Radd_le_add (Rle_refl _) ?_
  show Rle one (logN (n + 2) (by omega))
  exact logN_ge_one (by omega)

/-- **The candidate survives where Coxeter died**: it is strictly monotone with unbounded growth
    (`atlasShiftDiag_step_ge_one`), reproducing the `n log n` growth class — whereas the Coxeter
    candidate is periodic/bounded (`coxeter_candidate_periodic`) and is killed
    (`coxeter_candidate_killed`). Passing the growth filter is necessary, not sufficient: the exact
    Gate-A match `= 2λₙ` (a sum of squares) is RH, not asserted. -/
theorem atlasGenerator_survives_growth :
    (∀ n, 2 ≤ n → Rle (Radd (atlasShiftDiag n) one) (atlasShiftDiag (n + 1)))
    ∧ coxeterCandidate 30 = coxeterCandidate 0 :=
  ⟨atlasShiftDiag_step_ge_one, coxeter_candidate_periodic⟩

end UOR.Bridge.F1Square.Square
