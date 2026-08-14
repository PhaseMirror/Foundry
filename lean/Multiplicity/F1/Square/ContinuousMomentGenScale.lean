/-
F1 square — **the pre-Hilbert layer, brick 121** (`ContinuousMomentGenScale.lean`): **the continuous
Mellin transform is `ℤ⁺`-HOMOGENEOUS** — `compactMomentGenLim (k·φ) s ≈ k·compactMomentGenLim φ s`
(`compactMomentGenLim_natScale`), where `k·φ = natScale k φ` is the `k`-fold sum of a test and `k·(·)`
on the value side is `natScaleR`, the `k`-fold real sum. Together with additivity/negation/subtraction
(bricks 118–120) this completes the continuous transform as a genuinely `ℤ`-LINEAR map on the test
class: it commutes with `+`, `−`, and integer scaling.

WHY (the Sonine route, step 3, the transform PAIR). Homogeneity is the last algebraic law of the
transform. Its natural proof is induction on `k` from additivity: `natScale (k+1) φ = φ + natScale k φ`
(the defining step), so `transform(natScale (k+1) φ) ≈ transform φ + transform(natScale k φ) ≈
transform φ + k·transform φ = (k+1)·transform φ` by brick 118 and the inductive hypothesis; the base
`transform(natScale 0 φ) = transform 0 = 0` is `Rlim_zero` against `innerI_zeroL2`. The one obstacle was
mechanical, not mathematical: `natScale` is sealed (`@[irreducible]`, so its `k`-fold structure never
whnf-explodes when a moment reads `.M`), which also blocks unfolding it inside `compactMomentGenLim`.
The fix is to unfold it as a PROPOSITIONAL equation first (`natScale_succ`/`natScale_zero`, each `rfl`
under a local `unseal`), rewrite with it, and only THEN apply the additivity law — the seal is never
forced through `momRate`.

HONEST SCOPE. Integer homogeneity of the continuous transform in the test slot; with bricks 118–120 the
transform's linearity is complete. NOT the pairing/inversion. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentGenSub
import Multiplicity.F1Square.Square.DeepMemberThree

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The `k`-fold real sum — integer scaling on the value side, matching `natScale` on the test side. -/
def natScaleR : Nat → Real → Real
  | 0, _ => zero
  | k + 1, r => Radd r (natScaleR k r)

-- The two `natScale` unfolding equations as PROPOSITIONAL equalities. `natScale` is sealed
-- (`@[irreducible]`), so a local `unseal` is needed for the definitional `rfl`; rewriting with these
-- then never forces the seal through `momRate`/`.M` (the sole obstacle the earlier attempt hit).
unseal natScale in
private theorem natScale_zero (φ : L2Test) : natScale 0 φ = zeroL2 := rfl

unseal natScale in
private theorem natScale_succ (k : Nat) (φ : L2Test) :
    natScale (k + 1) φ = L2Test.add φ (natScale k φ) := rfl

/-- **The continuous transform of the zero test is zero**: every reindexed floor moment of `zeroL2`
    pairs to `0` (`innerI_zeroL2`), so the limit is `0` (`Rlim_zero`). The base of the homogeneity
    induction. -/
theorem compactMomentGenLim_zeroL2 {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMomentGenLim zeroL2 hs σ hσd hσn hsB) zero :=
  Rlim_zero (compactMomentGenSeq zeroL2 hs σ hσd hσn hsB)
    (compactMomentGenSeq_RReg zeroL2 hs σ hσd hσn hsB)
    (fun j => innerI_zeroL2 (compactPowTestF (momRate zeroL2 j) hs σ hσd hσn hsB))

/-- **★ THE CONTINUOUS TRANSFORM IS `ℤ⁺`-HOMOGENEOUS**: `compactMomentGenLim (k·φ) s ≈
    k·compactMomentGenLim φ s`. Induction on `k`: the base is `compactMomentGenLim_zeroL2`; the step
    rewrites `natScale (k+1) φ = φ + natScale k φ` (as a propositional equation, past the seal) and
    applies additivity (brick 118) with the inductive hypothesis. With bricks 118–120 this completes
    the transform as a `ℤ`-linear map. -/
theorem compactMomentGenLim_natScale (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q)
    (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    ∀ k, Req (compactMomentGenLim (natScale k φ) hs σ hσd hσn hsB)
             (natScaleR k (compactMomentGenLim φ hs σ hσd hσn hsB))
  | 0 => by
      rw [natScale_zero]; exact compactMomentGenLim_zeroL2 hs σ hσd hσn hsB
  | k + 1 => by
      rw [natScale_succ]
      refine Req_trans (compactMomentGenLim_add φ (natScale k φ) hs σ hσd hσn hsB) ?_
      exact Radd_congr (Req_refl _) (compactMomentGenLim_natScale φ hs σ hσd hσn hsB k)

end Multiplicity.UOR.Bridge.F1Square.Square
