/-
F1 square — **the pre-Hilbert layer, brick 83** (`CoSupportFunction.lean`): **THE CO-SUPPORT
MEMBERS ARE GENUINELY NONZERO FUNCTIONS ON `[0,1]`** — the function-level upgrade the definiteness
iff (brick 81) unlocks for the co-support filtration.

Until now the strictness of the co-support filtration lived at the *moment* level: `deep3` and the
`combo345` family were certified nonzero by an exact nonzero moment (third moment `−1/2520`,
`−a/2520`), turned into `Pos` moment-energy by brick 45. That is a statement about the moment
sequence, not about the test as a function. The definiteness iff closes the gap:

    `¬ Req (innerI φ φ) zero`   ⟹   `¬ (∀ x ∈ [0,1], φ(x) ≈ 0)`
      (`not_vanishing_of_innerI_self_not_zero`, the `.mpr` of `innerI_self_zero_iff_unit_zero`).

So a test with nonzero `L²` self-energy cannot vanish identically on `[0,1]`. Chaining the moment
side (`momentL2Sq_zero_of_innerI_self_zero` contrapositive against the certified `Pos` energy) gives
that `deep3` (`deep3_not_vanishing_on_unit`) and the whole `combo345 a b c` family with `a ≥ 1`
(`combo345_not_vanishing_on_unit`) are honestly nonzero **functions** on `[0,1]` — the filtration's
distinct levels are witnessed by tests that genuinely differ as functions there, not merely in their
moments.

HONEST SCOPE. `¬ (∀ x ∈ [0,1], φ(x) ≈ 0)` — "does not vanish identically on `[0,1]`". This is the
constructive negation of universal vanishing, NOT a constructed point of non-vanishing (exhibiting
such a point is a stronger, location-flavoured statement not made here). It is exactly the
function-level counterpart of the moment/energy non-vanishing already certified. Nothing here
touches the Weil form; the co-support skeleton's positivity is still diagonal-multiplier level only.
Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.L2DefiniteIff
import Multiplicity.F1Square.Square.L2MomentBridge
import Multiplicity.F1Square.Square.CoSupportFamily

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `0` is not strictly positive (local copy; the others are private per file). -/
private theorem zero_not_Pos' : ¬ Pos zero := by
  intro ⟨n, hn⟩
  simp only [Qlt, Qbound, zero_seq] at hn
  omega

/-- **A test with nonzero `L²` self-energy does not vanish identically on `[0,1]`** — the `.mpr`
    of the definiteness iff, contraposed. The bridge from energy non-vanishing to function-level
    non-vanishing. -/
theorem not_vanishing_of_innerI_self_not_zero (φ : L2Test)
    (h : ¬ Req (innerI φ φ) zero) :
    ¬ (∀ x, Rle zero x → Rle x one → Req (φ.f x) zero) :=
  fun hall => h ((innerI_self_zero_iff_unit_zero φ).mpr hall)

/-- **`deep3` IS A GENUINELY NONZERO FUNCTION ON `[0,1]`** — not merely nonzero in its moments. -/
theorem deep3_not_vanishing_on_unit :
    ¬ (∀ x, Rle zero x → Rle x one → Req (deep3.f x) zero) :=
  not_vanishing_of_innerI_self_not_zero deep3 innerI_deep3_self_not_zero

/-- **THE `combo345` FAMILY IS GENUINELY NONZERO ON `[0,1]` WHEREVER `a ≥ 1`** — the infinite
    level-3 family, each member a genuinely nonzero function on `[0,1]`. -/
theorem combo345_not_vanishing_on_unit (a b c : Nat) (ha : 1 ≤ a) :
    ¬ (∀ x, Rle zero x → Rle x one → Req ((combo345 a b c).f x) zero) :=
  not_vanishing_of_innerI_self_not_zero (combo345 a b c)
    (fun h => zero_not_Pos'
      (Pos_congr (momentL2Sq_zero_of_innerI_self_zero (combo345 a b c) h)
        (combo345_energy_pos a b c ha)))

end Multiplicity.UOR.Bridge.F1Square.Square
