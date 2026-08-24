/-
F1 square — **the pre-Hilbert layer, brick 106** (`ContinuousMomentClamp.lean`): **the compact power at
`s = 1` agrees with the clamped-identity test on `[a,1]`** — `compactPow a 1 t ≈ clampTest.f t` for every
real `t ∈ [a,1]`, the integrand-agreement form of brick 104.

`clampTest.f = clamp01` is the clamped identity `qBandQ ⟨0,1⟩ ⟨1,1⟩`, inert on `[0,1]` (so `clamp01 t ≈
t`), and `compactPow a 1 t ≈ t` on `[a,1]` (brick 104). Composing, the two integrands `compactPow a 1`
and `clampTest.f = (powTest 1).f` coincide on `[a,1]` — they differ only on the sub-`a` region `[0,a)`.
Since the certified `L²` pairing `innerI φ ·` is an integral over `[0,1]`, this pins the entire
floor-dependence of `compactMoment φ a 1 = innerI φ (compactPowTest a 1)` (versus `mellinMoment φ 1 =
innerI φ (powTest 1)`) to `[0,a)` — the `O(M·a)` sub-`a` tail whose `a → 0` limit is the last step.

HONEST SCOPE. The integrand agreement on `[a,1]` at `s = 1`; the `a → 0` limit that converts it into
`compactMoment φ a 1 ≈ mellinMoment φ 1` is the remaining Mellin step. No transform pair, no inversion,
no positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentGeneral
import Multiplicity.F1.Square.TestAlgebra

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`compactPow a 1 t ≈ clampTest.f t` on `[a,1]`** — the compact power at `s = 1` and the
    clamped-identity integrand coincide off the sub-`a` region, via brick 104 (`compactPow a 1 t ≈ t`)
    and the inertness of `clamp01` on `[0,1]` (`clamp01 t ≈ t`). -/
theorem compactPow_one_eq_clamp (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (t : Real) (hlo : Rle (ofQ a had) t) (hhi : Rle t one) :
    Req (compactPow a han had one t) (clampTest.f t) := by
  have hg1 := compactPow_one_general a han had ha1 t hlo hhi
  have ht0 : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) t :=
    Rle_trans (Rle_ofQ_ofQ (by decide) had (by show (0 : Int) * (a.den : Int) ≤ a.num * 1; omega)) hlo
  have hclamp : Req (clampTest.f t) t := qBandQ_eq_of_band ht0 hhi
  exact Req_trans hg1 (Req_symm hclamp)

end Multiplicity.UOR.Bridge.F1Square.Square
