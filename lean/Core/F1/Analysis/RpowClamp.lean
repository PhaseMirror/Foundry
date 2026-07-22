/-
F1 square — Track 1, item 6 substrate: **the total clamped real power** `rpowClamp` (`RpowClamp.lean`).

The Mellin integral layer needs a *total* `f : Real → Real`, but `RrpowPos x k hk e` requires a per-point
positivity witness `hk : Qlt (Qbound k) (x.seq k)`. The fix: precompose with `clampOne t = max(t, 1)`
(`ClampOne.lean`, `≥ 1` everywhere), which carries a **uniform** witness at index `1`:

    (clampOne t).seq 1 = ⟨1,1⟩ + (RmaxZero (t−1)).seq 3 ≥ 1 − Qbound 3 = 3/4 > 1/2 = Qbound 1,

from `Rnonneg_RmaxZero` alone — independent of `t`. So `rpowClamp e t := (clampOne t)^e` is a total
`Real → Real`, agreeing with `t^e` on `[1, ∞)` (where `clampOne` is inert). The remaining integrand work
(global Lipschitz on `[1,∞)` via the theta decay, and a `B`-free `RlogPos` congruence for `hfc`) is the
open assembly above this primitive.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ClampOne
import Core.F1.Analysis.Gamma

namespace UOR.Bridge.F1Square.Analysis

/-- **Uniform positivity witness for `clampOne`** at index `1`: `clampOne t > Qbound 1` everywhere,
    independent of `t`. The gateway to total power/log functions of an unconstrained real. -/
theorem clampOne_witness (t : Real) : Qlt (Qbound 1) ((clampOne t).seq 1) := by
  have hnn := Rnonneg_RmaxZero (Rsub t one) 3
  have hdp := (RmaxZero (Rsub t one)).den_pos 3
  show Qlt (Qbound 1) (add (one.seq 3) ((RmaxZero (Rsub t one)).seq 3))
  rw [one_seq]
  simp only [Qlt, Qle, Qbound, neg, add] at hnn ⊢
  push_cast at hnn ⊢
  omega

/-- **The total clamped real power** `rpowClamp e t = (max(t,1))^e` — a total `Real → Real` (uniform
    witness, `clampOne_witness`), equal to `t^e` on `[1, ∞)`. -/
def rpowClamp (e : Real) (t : Real) : Real :=
  RrpowPos (clampOne t) 1 (clampOne_witness t) e

end UOR.Bridge.F1Square.Analysis
