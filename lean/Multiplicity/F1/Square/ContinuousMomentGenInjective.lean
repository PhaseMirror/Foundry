/-
F1 square — **the pre-Hilbert layer, brick 123** (`ContinuousMomentGenInjective.lean`): **the
continuous Mellin transform SEPARATES polynomial tests** — the injectivity/uniqueness half of the
transform pair, now realized for the *continuous* transform object itself:

    two compactly-supported polynomial tests whose continuous transforms agree at every integer
    exponent below their degree are the same function on `[0,1]`
      (`compactMomentGenLim_poly_eq_imp_function_eq`).

WHY (the Sonine route, step 3, the transform PAIR). Injectivity/separation on the polynomial class was
proven for the integer *moment sequence* (bricks 87/88, through the `L²`-definiteness weld). The a→0
continuous transform (brick 112) agrees with the integer Mellin moment at every integer exponent (brick
115, `compactMomentGenLim_natExpR_eq_mellin`), so the moment-sequence separation transfers verbatim to
the continuous object: equal continuous transforms at integer exponents ⇒ equal moments ⇒ (brick 88)
equal functions on `[0,1]`. This lifts the *uniqueness direction of the transform pair* from the
moment sequence to the genuine continuous transform constructed in bricks 112–122 — the pair's
injectivity half, for the new object.

HONEST SCOPE. Injectivity/separation of the continuous transform on the **polynomial** class, over
`[0,1]`, at integer exponents. NOT general (bounded-Lipschitz) determinacy — that still needs Bernstein
approximation — NOT inversion, NOT any positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentNatLimit
import Multiplicity.F1Square.Square.MellinInjectivePair

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **★ THE CONTINUOUS TRANSFORM SEPARATES POLYNOMIAL TESTS**: if the continuous transforms of two
    compactly-supported polynomial tests agree at every integer exponent below `max d d'`, the tests
    agree on `[0,1]`. The integer-exponent bridge (brick 115) turns the hypothesis into moment equality,
    then brick 88's moment separation closes it — the injectivity half of the transform pair for the
    continuous object. -/
theorem compactMomentGenLim_poly_eq_imp_function_eq (a b a' b' : Nat → Nat) (d d' : Nat)
    (h : ∀ i : Nat, i < Nat.max d d' →
      Req (compactMomentGenLim (polyPN a b d) (natExpR_nonneg i) (⟨(i : Int), 1⟩ : Q)
            Nat.one_pos (Int.ofNat_nonneg i) (Rle_of_Req (natExpR_eq_ofQ i)))
          (compactMomentGenLim (polyPN a' b' d') (natExpR_nonneg i) (⟨(i : Int), 1⟩ : Q)
            Nat.one_pos (Int.ofNat_nonneg i) (Rle_of_Req (natExpR_eq_ofQ i))))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((polyPN a b d).f x) ((polyPN a' b' d').f x) := by
  refine polyPN_moment_eq_imp_function_eq a b a' b' d d' (fun i hi => ?_) x h0 h1
  exact Req_trans (Req_symm (compactMomentGenLim_natExpR_eq_mellin (polyPN a b d) i))
    (Req_trans (h i hi) (compactMomentGenLim_natExpR_eq_mellin (polyPN a' b' d') i))

end Multiplicity.UOR.Bridge.F1Square.Square
