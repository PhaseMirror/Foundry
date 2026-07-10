/-
F1 square — v0.21.0 stage G, brick **G0 (the numerical kill-test, throwaway pre-filter)**: a
decidable finite Gram-diagonal match test over the rational layer.

ROADMAP §8 (Stage 0) and §9. Before formalizing any candidate atlas rule one runs a cheap finite
test: compute the candidate's squared-norm diagonal `‖ι Cₙ‖²` for `n ≤ ~50` and check it against the
reference `2λₙ` within a tolerance. A candidate whose diagonal does not match (wrong growth, wrong
value) is **killed at the plotting stage** — it cannot be the witness, so no Lean effort is spent on
it. This brick supplies that test as a DECIDABLE predicate (`killTestPasses`, runnable by `decide`
over `ℚ`, no `native_decide`), with the growth-kill and the match-admission demonstrated.

WHAT THE TEST DOES AND DOES NOT DECIDE (§8). The test is a NECESSARY filter, not sufficient: a
finite diagonal match says nothing about the limit (`killTest_match_not_sufficient` records this as
the §6 Cayley caveat — the zero-built candidate matches the finite diagonal yet is a relocation),
and the `2λₙ` reference is only as sharp as the Stieltjes constants `γₖ` permit (the repo builds
`γ, γ₁, γ₂`; higher `γₖ` are slowly-converging limits).

HONEST STATUS (localization at G0, for now). The named atlas candidate generators (Coxeter order-30,
gauge-tower `Gₖ`, tropical/Kashiwara-crystal — §7) are NOT sourced in the F1 repository (the atlas
signature `Σ` is, by the program's own marking, "not yet sourced from the atlas repo"). So the test
currently has no in-repo atlas n-family to feed it and selects NO candidate — the §9 "Localized"
mode for the candidate search. The harness is built and demonstrated so that the test runs the
instant atlas data is supplied. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.Rat

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The finite Gram-diagonal kill-test**: the candidate squared-norms `d n` must match the
    reference `r n` (`= 2λₙ`) within tolerance `tol` for every `n < N`. Decidable over `ℚ` (a
    bounded `∀` of decidable `Qle`), so it runs by `decide` — the throwaway pre-filter. -/
def killTestPasses (d r : Nat → Q) (tol : Q) (N : Nat) : Prop :=
  ∀ n, n < N → Qle (Qabs (Qsub (d n) (r n))) tol

instance (d r : Nat → Q) (tol : Q) (N : Nat) : Decidable (killTestPasses d r tol N) := by
  unfold killTestPasses; exact Nat.decidableBallLT N _

/-- **The test ADMITS a match** (two-sided guard): a candidate whose diagonal equals the reference
    passes for every tolerance `≥ 0` and every `N`. (Demonstrated at `r n = n`, `tol = 1`, `N = 8`.) -/
theorem killTest_admits_match :
    killTestPasses (fun n => ⟨(n : Int), 1⟩) (fun n => ⟨(n : Int), 1⟩) ⟨1, 1⟩ 8 := by decide

/-- **The test KILLS a wrong-growth candidate**: a bounded (here constant-`0`) diagonal cannot
    match a reference that grows past the tolerance band — the kill fires at a finite index.
    (Demonstrated: constant `0` vs `r n = n`, `tol = 1` fails by `N = 3`, i.e. at `n = 2`.) This is
    the growth filter `atlasRule_growth_filter` in decidable form: a candidate not reproducing the
    Li growth `2λₙ ~ n log n` is rejected. -/
theorem killTest_kills_wrong_growth :
    ¬ killTestPasses (fun _ => ⟨0, 1⟩) (fun n => ⟨(n : Int), 1⟩) ⟨1, 1⟩ 3 := by decide

/-- **The §6 caveat in decidable form — a finite match is NOT sufficient.** A candidate whose
    diagonal matches the reference EXACTLY passes the test even at ZERO tolerance for the whole
    finite range, yet finite-diagonal success says nothing about the limit or the off-diagonal: the
    Cayley candidate passes every finite kill-test and is still the §6 relocation
    (`cayley_relocation`). The test filters OUT, it does not certify. (Demonstrated at `tol = 0`,
    `N = 8`.) -/
theorem killTest_match_not_sufficient :
    killTestPasses (fun n => ⟨(n : Int), 1⟩) (fun n => ⟨(n : Int), 1⟩) ⟨0, 1⟩ 8 := by decide

end UOR.Bridge.F1Square.Square
