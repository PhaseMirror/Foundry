/-
F1 square — **the pre-Hilbert layer, brick 80** (`L2Separation.lean`): **THE `L²` INNER PRODUCT
SEPARATES POINTS OF `[0,1]`** — two tests at `L²` distance zero agree at every point of the unit
interval:

    `dist2I φ ψ ≈ 0`,  `0 ≤ x ≤ 1`   ⟹   `φ(x) ≈ ψ(x)`   (`dist2I_zero_imp_pointwise_eq`).

This is the immediate payoff of brick 79's point-definiteness, applied to the difference test:
`dist2I φ ψ = ⟨φ−ψ, φ−ψ⟩` (`PairingLimitI`), so `dist2I φ ψ ≈ 0` forces `(φ−ψ)(x) ≈ 0` at every
point of `[0,1]` (brick 79), and `(φ−ψ)(x) = φ(x) − ψ(x)` (definitionally, `L2Test.sub` is
`add _ (neg _)`), so `φ(x) ≈ ψ(x)`. What it buys is that the `L²` seminorm is a genuine
*separating* form on `[0,1]`: two tests the pairing cannot tell apart are the same function there,
so the `L²` class injects into the values on `[0,1]`. This is the sense in which the completion
axis (`pairingLim`, `dist2I`, brick 62's `L²` completeness) is a *pre-Hilbert* structure and not
merely a semi-normed one — the null relation is pointwise equality on `[0,1]`, not a coarser
identification.

HONEST SCOPE. One direction only, and on `[0,1]` only. `dist2I φ ψ ≈ 0 ⟹ φ, ψ agree on `[0,1]``;
the converse (agree on `[0,1]` ⟹ `dist2I ≈ 0`) is the integral-of-a-vanishing-integrand direction,
which the certified integral's generic congruence lemmas state over *all* reals and which is in
fact false off `[0,1]` (the integral does not see values outside the interval) — so it needs a
`[0,1]`-restricted argument not performed here. This is separation, i.e. injectivity of the `L²`
class into functions on `[0,1]`, NOT a full isometry, and NOT the moment problem (a nonzero test
with every *moment* vanishing is a different, still-open question). Nothing here touches the Weil
form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DyadicDenseReal
import Foundations.F1.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `Req (Rsub a b) zero → Req a b` (local copy of `ZeroGeometry`'s additive helper). -/
private theorem Req_of_Rsub_zero {a b : Real} (h : Req (Rsub a b) zero) : Req a b := by
  have h1 : Req a (Radd (Rsub a b) b) := by
    show Req a (Radd (Radd a (Rneg b)) b)
    refine Req_trans (Req_symm (Radd_zero a)) ?_
    have hz : Req zero (Radd (Rneg b) b) :=
      Req_symm (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
    exact Req_trans (Radd_congr (Req_refl a) hz) (Req_symm (Radd_assoc a (Rneg b) b))
  refine Req_trans h1 ?_
  exact Req_trans (Radd_congr h (Req_refl b)) (Req_trans (Radd_comm zero b) (Radd_zero b))

/-- **THE `L²` INNER PRODUCT SEPARATES POINTS OF `[0,1]`**: two tests at `L²` distance zero agree
    at every point of `[0,1]`. Brick 79's point-definiteness on the difference test. -/
theorem dist2I_zero_imp_pointwise_eq (φ ψ : L2Test) (h : Req (dist2I φ ψ) zero)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req (φ.f x) (ψ.f x) :=
  Req_of_Rsub_zero (innerI_self_zero_imp_zero (L2Test.sub φ ψ) h x h0 h1)

/-- The same, written at the `innerI` level: `⟨φ−ψ, φ−ψ⟩ ≈ 0` forces pointwise agreement on
    `[0,1]`. -/
theorem innerI_sub_self_zero_imp_pointwise_eq (φ ψ : L2Test)
    (h : Req (innerI (L2Test.sub φ ψ) (L2Test.sub φ ψ)) zero)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req (φ.f x) (ψ.f x) :=
  dist2I_zero_imp_pointwise_eq φ ψ h x h0 h1

/-- **THE POLYNOMIAL CLASS, SEPARATED ON `[0,1]`**: two polynomial tests at `L²` distance zero
    are the same function on `[0,1]`. -/
theorem polyPN_dist2I_zero_imp_eq (a b a' b' : Nat → Nat) (d d' : Nat)
    (h : Req (dist2I (polyPN a b d) (polyPN a' b' d')) zero)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((polyPN a b d).f x) ((polyPN a' b' d').f x) :=
  dist2I_zero_imp_pointwise_eq (polyPN a b d) (polyPN a' b' d') h x h0 h1

end Multiplicity.UOR.Bridge.F1Square.Square
