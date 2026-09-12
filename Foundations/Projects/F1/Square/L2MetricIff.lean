/-
F1 square — **the pre-Hilbert layer, brick 82** (`L2MetricIff.lean`): **THE `L²` DISTANCE IS A
GENUINE METRIC ON `[0,1]`** — the two-directional separation, closing brick 80 to an iff:

    `dist2I φ ψ ≈ 0`   ⟺   `∀ x ∈ [0,1], φ(x) ≈ ψ(x)`   (`dist2I_zero_iff_pointwise_eq`).

Brick 80 gave the forward direction (zero `L²` distance forces pointwise agreement on `[0,1]`); this
adds the converse via brick 81's reverse definiteness, applied to the difference test
`L2Test.sub φ ψ` (whose value at `x` is `φ(x) − ψ(x)`, definitionally): two tests that agree at
every point of `[0,1]` have `L²` distance zero. So the `L²` distance-squared `dist2I` vanishes
**exactly** on the pointwise-`[0,1]`-equality relation — it is a genuine metric there (`dist2I = 0`
iff the two functions coincide on `[0,1]`), the zero set is neither coarser nor finer than pointwise
agreement.

HONEST SCOPE. Both directions, on `[0,1]` only. This is the separation iff — the `L²` class is in
bijection with functions on `[0,1]` modulo nothing (on that domain) — NOT a full isometry to any
function space, and NOT the moment problem. Nothing here touches the Weil form. Step 4 is RH. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.L2Separation
import Foundations.F1.Square.L2DefiniteIff

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE `L²` DISTANCE IS A GENUINE METRIC ON `[0,1]`**: `dist2I φ ψ ≈ 0` iff `φ` and `ψ` agree at
    every point of `[0,1]`. Brick 80 forward (separation), brick 81 reverse (definiteness) applied
    to the difference test. -/
theorem dist2I_zero_iff_pointwise_eq (φ ψ : L2Test) :
    Req (dist2I φ ψ) zero ↔ ∀ x, Rle zero x → Rle x one → Req (φ.f x) (ψ.f x) :=
  ⟨fun h x h0 h1 => dist2I_zero_imp_pointwise_eq φ ψ h x h0 h1,
   fun h => innerI_self_zero_of_unit_zero (L2Test.sub φ ψ)
     (fun x h0 h1 => Req_trans (Rsub_congr (h x h0 h1) (Req_refl (ψ.f x))) (Radd_neg (ψ.f x)))⟩

end Multiplicity.UOR.Bridge.F1Square.Square
