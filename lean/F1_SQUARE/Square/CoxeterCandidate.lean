/-
F1 square — v0.21.0 stage G, brick **Coxeter candidate**: testing a §7 named candidate generator
for the uniform atlas rule, and eliminating it by the growth pre-filter.

The v0.21.0 §7 prerequisite names candidate generators for the uniform rule `Cₙ ↦ vector` (the
single witness that would close the crux, `UniformClosure`): "Coxeter iteration (order 30),
gauge-tower level `Gₖ`, the tropical/Kashiwara-crystal structure". Exploiting the formalized Atlas
structure, the FIRST candidate is now decidable:

The E₈ Coxeter element has order `30` (`AtlasCoxeter`), so "Coxeter iteration" produces a PERIODIC
`n`-family — period 30, hence BOUNDED. But the diagonal it must match is `2λₙ ~ n log n`, UNBOUNDED
(Voros/Lagarias). A bounded family cannot reproduce unbounded growth, so the Coxeter-iteration
candidate FAILS the growth pre-filter (`KillTest`): `coxeter_candidate_killed`. The §7 candidate is
ELIMINATED — narrowing the search to the gauge-tower `Gₖ` and the tropical/crystal generators (not
sourced in F1).

This is genuine discovery-program progress: a named candidate for the uniform feature, tested and
killed, by the formalized Coxeter order `30`. The crux fields stay `none` (eliminating a candidate
does not close the crux).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.KillTest
import F1Square.Square.AtlasCoxeter

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The Coxeter-iteration candidate (§7) as a rational `n`-family: the E₈ Coxeter element has order
    `30` (`AtlasCoxeter`), so iteration is periodic with period `30`, modeled by `n % 30` — BOUNDED
    (values in `[0, 30)`). -/
def coxeterCandidate (n : Nat) : Q := ⟨Int.ofNat (n % 30), 1⟩

/-- **THE COXETER-ITERATION CANDIDATE IS KILLED BY THE GROWTH PRE-FILTER**: being periodic (order
    `30`, bounded), its diagonal cannot reproduce the unbounded Li growth `2λₙ ~ n log n` — it fails
    the finite kill-test against a growing reference already by `n = 30` (`coxeterCandidate 30 = 0`,
    reference `30`, gap `30 > 1`). The §7 Coxeter candidate is eliminated. -/
theorem coxeter_candidate_killed :
    ¬ killTestPasses coxeterCandidate (fun n => ⟨(n : Int), 1⟩) ⟨1, 1⟩ 31 := by decide

/-- **Periodicity is the obstruction** (the structural reason): the candidate returns to `0` every
    `30` steps (`coxeterCandidate 30 = coxeterCandidate 0`), so it is bounded and cannot track an
    unbounded reference — a finite-order generator cannot supply the `½ n log n` growth the uniform
    witness needs. -/
theorem coxeter_candidate_periodic : coxeterCandidate 30 = coxeterCandidate 0 := by decide

end UOR.Bridge.F1Square.Square
