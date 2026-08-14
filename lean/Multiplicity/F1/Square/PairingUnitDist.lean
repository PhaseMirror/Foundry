/-
F1 square — **the pre-Hilbert layer, brick 91** (`PairingUnitDist.lean`): **THE `L²` METRIC FACTORS
THROUGH `[0,1]`-RESTRICTION** — `dist2I` depends only on the restrictions to `[0,1]`:

    `φ ≈ φ'`, `ψ ≈ ψ'` on `[0,1]`   ⟹   `dist2I φ ψ ≈ dist2I φ' ψ'`   (`dist2I_congr_on_unit`).

Since `dist2I φ ψ = ⟨φ − ψ, φ − ψ⟩` and `φ − ψ` agrees with `φ' − ψ'` on `[0,1]` when the pairs do,
brick 90's two-argument congruence (`innerI_left_congr_on_unit`, `innerI_right_congr_on_unit`)
carries the equality through both slots. Together with brick 82 (`dist2I ≈ 0 ⟺` pointwise-`[0,1]`
agreement) and bricks 89–90, the `L²` inner product and its metric are a genuine *well-defined and
definite* structure on the `[0,1]`-equivalence classes of tests — the pre-Hilbert space is the space
of `[0,1]`-restrictions, cleanly.

HONEST SCOPE. Well-definedness of the metric on the `[0,1]`-restriction. A structural fact about
`dist2I`, NOT the `L²`-function-space limit member (still open) and NOT the moment problem. Nothing
here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.PairingUnitCongr
import Multiplicity.F1Square.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE `L²` METRIC FACTORS THROUGH `[0,1]`-RESTRICTION**: `dist2I` depends only on the
    restrictions of both tests to `[0,1]`. -/
theorem dist2I_congr_on_unit (φ φ' ψ ψ' : L2Test)
    (hφ : ∀ x, Rle zero x → Rle x one → Req (φ.f x) (φ'.f x))
    (hψ : ∀ x, Rle zero x → Rle x one → Req (ψ.f x) (ψ'.f x)) :
    Req (dist2I φ ψ) (dist2I φ' ψ') := by
  have hsub : ∀ x, Rle zero x → Rle x one →
      Req ((L2Test.sub φ ψ).f x) ((L2Test.sub φ' ψ').f x) :=
    fun x h0 h1 => Rsub_congr (hφ x h0 h1) (hψ x h0 h1)
  exact Req_trans
    (innerI_left_congr_on_unit (L2Test.sub φ ψ) (L2Test.sub φ' ψ') (L2Test.sub φ ψ) hsub)
    (innerI_right_congr_on_unit (L2Test.sub φ' ψ') (L2Test.sub φ ψ) (L2Test.sub φ' ψ') hsub)

end Multiplicity.UOR.Bridge.F1Square.Square
