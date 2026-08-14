/-
F1 square — **the pre-Hilbert layer, brick 116** (`ContinuousMomentClampValue.lean`): **the continuous
Mellin transform COMPUTES — the clamped identity's transform at integer `n` is exactly `1/(n+2)`**:

    `compactMomentGenLim clampTest n  ≈  1/(n+2)`
      (`compactMomentGenLim_clamp_eq`).

WHY (a concrete verification of the continuous-transform stack). The `a → 0` continuous Mellin transform
`compactMomentGenLim` (bricks 110–112) is an abstract Bishop limit; this brick evaluates it on a concrete
test to a closed-form rational, verifying end to end that the machinery produces the correct number. At
the integer exponent `n` the continuous transform is the integer Mellin moment (brick 115), and the
integer moment of the clamped identity obeys the Hausdorff law `mellinMoment clampTest n = 1/(n+2)`
(`mellinMoment_clamp_general`, brick 33) — so the two compose to `1/(n+2)`.

HONEST SCOPE. A concrete closed-form evaluation of the continuous transform on the clamped identity at
integer exponents. NOT the transform pair, NOT inversion. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentNatLimit
import Multiplicity.F1Square.Square.MomentLaw

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **★ THE CONTINUOUS TRANSFORM COMPUTES**: `compactMomentGenLim clampTest n ≈ 1/(n+2)` — the `a → 0`
    continuous Mellin transform of the clamped identity, at integer exponent `n`, is the exact rational
    `1/(n+2)`. Brick 115 identifies the continuous transform with the integer moment; the Hausdorff law
    (`mellinMoment_clamp_general`) evaluates the integer moment. -/
theorem compactMomentGenLim_clamp_eq (n : Nat) :
    Req (compactMomentGenLim clampTest (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q) Nat.one_pos
          (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n)))
        (ofQ (⟨1, n + 2⟩ : Q) (Nat.succ_pos (n + 1))) :=
  Req_trans (compactMomentGenLim_natExpR_eq_mellin clampTest n) (mellinMoment_clamp_general n)

end Multiplicity.UOR.Bridge.F1Square.Square
