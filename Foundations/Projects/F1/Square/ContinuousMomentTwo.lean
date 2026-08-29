/-
F1 square — **the pre-Hilbert layer, brick 103** (`ContinuousMomentTwo.lean`): **the compact power at
exponent `2` is the square at rational points** — `compactPow a 2 (q) ≈ q²` for every rational
`q ∈ (a,1]`, obtained by composing the power law (brick 99) with the `s = 1` value (brick 102):
`t² = t·t`.

`compactPow_exp_add` (brick 99) gives `compactPow a (1+1) (q) ≈ compactPow a 1 (q) · compactPow a 1 (q)`,
and `compactPow_ofQ_one` (brick 102) reads each factor as `q`, so the product is `q·q = q²`. This is the
integer-power evaluation obtained purely from the exponent-structure laws, with no new analysis — the
same route lifts to every integer exponent by iterating the power law.

HONEST SCOPE. The `s = 2` value at rational points of `(a,1]`, a worked instance of the integer-power
reader that the moment identification will iterate. No transform pair, no inversion, no positivity, no
`a → 0` limit, no general real `t`. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentOne
import Foundations.F1.Square.ContinuousMomentAdd

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`compactPow a 2 (q) ≈ q²`** at every rational `q ∈ (a,1]` — the `t² = t·t` value, via the power
    law `compactPow a (1+1) = compactPow a 1 · compactPow a 1` (brick 99) and `compactPow a 1 (q) ≈ q`
    (brick 102). -/
theorem compactPow_ofQ_two (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (q : Q) (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q) (hq1 : Qle q (⟨1, 1⟩ : Q)) :
    Req (compactPow a han had (Radd one one) (ofQ q hqd))
        (ofQ (mul q q) (Qmul_den_pos hqd hqd)) := by
  have hp1 := compactPow_ofQ_one a han had q hqd hqn haq hq1
  refine Req_trans (compactPow_exp_add a han had one one (ofQ q hqd)) ?_
  exact Req_trans (Rmul_congr hp1 hp1) (Rmul_ofQ_ofQ hqd hqd)

end Multiplicity.UOR.Bridge.F1Square.Square
