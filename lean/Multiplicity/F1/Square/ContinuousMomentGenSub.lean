/-
F1 square — **the pre-Hilbert layer, brick 120** (`ContinuousMomentGenSub.lean`): **the continuous
Mellin transform respects SUBTRACTION** — `compactMomentGenLim (φ − ψ) s ≈ compactMomentGenLim φ s −
compactMomentGenLim ψ s` (`compactMomentGenLim_sub`), completing the continuous transform as a LINEAR
MAP on the test class.

WHY (the Sonine route, step 3, the transform PAIR). `L2Test.sub φ ψ = L2Test.add φ (−ψ)`, so
subtraction is the immediate composite of additivity (brick 118) and negation (brick 119):
`transform(φ − ψ) ≈ transform φ + transform(−ψ) ≈ transform φ + (−transform ψ) = transform φ −
transform ψ`. With add/neg/sub the continuous transform is now a genuine linear map — the algebraic
half of the transform pair.

HONEST SCOPE. Subtraction-compatibility; the transform's linearity is complete. NOT the pairing/
inversion. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentGenNeg

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **★ THE CONTINUOUS TRANSFORM RESPECTS SUBTRACTION**: `compactMomentGenLim (φ − ψ) s ≈
    compactMomentGenLim φ s − compactMomentGenLim ψ s`. Immediate from additivity (brick 118) and
    negation (brick 119), since `L2Test.sub φ ψ = L2Test.add φ (−ψ)`. Completes the transform as a
    linear map. -/
theorem compactMomentGenLim_sub (φ ψ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMomentGenLim (L2Test.sub φ ψ) hs σ hσd hσn hsB)
        (Rsub (compactMomentGenLim φ hs σ hσd hσn hsB) (compactMomentGenLim ψ hs σ hσd hσn hsB)) :=
  Req_trans (compactMomentGenLim_add φ (L2Test.neg ψ) hs σ hσd hσn hsB)
    (Radd_congr (Req_refl _) (compactMomentGenLim_neg ψ hs σ hσd hσn hsB))

end Multiplicity.UOR.Bridge.F1Square.Square
