/-
F1 square — **the pre-Hilbert layer, brick 105** (`ContinuousMomentGenTwo.lean`): **the compact power at
exponent `2` is the square for GENERAL real `t`** — `compactPow a 2 t ≈ t²` for every real `t ∈ [a,1]`,
composing the general-real `s = 1` identity (brick 104) with the power law (brick 99).

`compactPow_exp_add` (brick 99, all real `t`) gives `compactPow a (1+1) t ≈ compactPow a 1 t · compactPow
a 1 t`, and `compactPow_one_general` (brick 104) reads each factor as `t`, so the product is `t·t = t²`.
This is the general-real integer-power value obtained purely from the exponent-structure law and the
`s = 1` general-real identity — the same route lifts to every integer exponent by iterating the power
law, so the integer `t^n` identification holds for all real `t ∈ [a,1]`, not only rationals.

HONEST SCOPE. The general-real `s = 2` value on `[a,1]`; the general integer-`n` case iterates this, the
`a → 0` limit is still separate. No transform pair, no inversion, no positivity. Step 4 is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentGeneral
import Multiplicity.F1.Square.ContinuousMomentAdd

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`compactPow a 2 t ≈ t²`** for every real `t ∈ [a,1]` — the general-real `t² = t·t` value, via the
    power law (brick 99) and the general-real `s = 1` identity (brick 104). -/
theorem compactPow_two_general (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (t : Real) (hlo : Rle (ofQ a had) t) (hhi : Rle t one) :
    Req (compactPow a han had (Radd one one) t) (Rmul t t) := by
  have hg1 := compactPow_one_general a han had ha1 t hlo hhi
  exact Req_trans (compactPow_exp_add a han had one one t) (Rmul_congr hg1 hg1)

end Multiplicity.UOR.Bridge.F1Square.Square
