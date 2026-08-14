/-
F1 square — **the pre-Hilbert layer, brick 94** (`ContinuousMomentLinear.lean`): **the continuous
Mellin transform is linear in the test and L²-bounded** — the compact-side continuous moment
`compactMoment φ a s = ∫₀¹ φ·t^s` (brick 93) respects the test algebra and obeys Cauchy–Schwarz.

Because `compactMoment φ a s = innerI φ (compactPowTest …)` pairs `φ` against a FIXED test (the
compact power carries the exponent `s` and floor `a`, not `φ`), every linearity law is the
corresponding first-slot law of the certified `L²` pairing `innerI`:

- `compactMoment_add`  — `⟨φ + φ', t^s⟩ = ⟨φ, t^s⟩ + ⟨φ', t^s⟩`  (`innerI_add_left`),
- `compactMoment_neg`  — `⟨−φ, t^s⟩ = −⟨φ, t^s⟩`                  (`innerI_neg_left`),
- `compactMoment_sub`  — `⟨φ − φ', t^s⟩ = ⟨φ, t^s⟩ − ⟨φ', t^s⟩`  (`innerI_sub_left`),
- `compactMoment_cs`   — `(compactMoment φ a s)² ≤ ⟨φ,φ⟩·⟨t^s,t^s⟩` (`innerI_cauchy_schwarz`),

the continuous-exponent analog of the integer-moment `mellinMoment_cs` (`TestAlgebra.lean`). So
`compactMoment · a s` is a genuine `L²`-bounded linear functional on the bounded-Lipschitz test class,
at every continuous exponent `s ≥ 0`.

HONEST SCOPE. Linearity and the CS bound at a fixed floor `a` — the transform-as-linear-functional
structure, no continuity in `s`, no transform pair, no inversion, no positivity beyond `innerI`'s.
Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMoment
import Multiplicity.F1Square.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Additivity in the test**: `compactMoment (φ + φ') a s = compactMoment φ a s + compactMoment φ' a s`
    — the transform pairs against a fixed power, so this is `innerI_add_left`. -/
theorem compactMoment_add (φ φ' : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMoment (L2Test.add φ φ') a han had hs σ hσd hσn hsB)
        (Radd (compactMoment φ a han had hs σ hσd hσn hsB)
              (compactMoment φ' a han had hs σ hσd hσn hsB)) :=
  innerI_add_left φ φ' (compactPowTest a han had hs σ hσd hσn hsB)

/-- **Negation in the test**: `compactMoment (−φ) a s = −compactMoment φ a s` (`innerI_neg_left`). -/
theorem compactMoment_neg (φ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMoment (L2Test.neg φ) a han had hs σ hσd hσn hsB)
        (Rneg (compactMoment φ a han had hs σ hσd hσn hsB)) :=
  innerI_neg_left φ (compactPowTest a han had hs σ hσd hσn hsB)

/-- **Subtraction in the test**: `compactMoment (φ − φ') a s = compactMoment φ a s − compactMoment φ' a s`
    (`innerI_sub_left`). -/
theorem compactMoment_sub (φ φ' : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMoment (L2Test.sub φ φ') a han had hs σ hσd hσn hsB)
        (Rsub (compactMoment φ a han had hs σ hσd hσn hsB)
              (compactMoment φ' a han had hs σ hσd hσn hsB)) :=
  innerI_sub_left φ φ' (compactPowTest a han had hs σ hσd hσn hsB)

/-- **The continuous moment is L²-bounded** (Cauchy–Schwarz instance):
    `(compactMoment φ a s)² ≤ ⟨φ,φ⟩·⟨t^s, t^s⟩` — the continuous-exponent analog of `mellinMoment_cs`,
    a quantitative grip on the transform uniform in the exponent. -/
theorem compactMoment_cs (φ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Rle (Rmul (compactMoment φ a han had hs σ hσd hσn hsB)
              (compactMoment φ a han had hs σ hσd hσn hsB))
        (Rmul (innerI φ φ)
              (innerI (compactPowTest a han had hs σ hσd hσn hsB)
                      (compactPowTest a han had hs σ hσd hσn hsB))) :=
  innerI_cauchy_schwarz φ (compactPowTest a han had hs σ hσd hσn hsB)

end Multiplicity.UOR.Bridge.F1Square.Square
