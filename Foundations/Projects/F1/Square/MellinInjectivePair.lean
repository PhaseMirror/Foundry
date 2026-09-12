/-
F1 square — **the pre-Hilbert layer, brick 88** (`MellinInjectivePair.lean`): **THE MELLIN
TRANSFORM SEPARATES POLYNOMIAL TESTS** — the two-test / equal-transforms form of injectivity,
completing brick 87's against-zero version. Two compactly supported polynomial tests whose Mellin
transforms agree far enough are the same function on `[0,1]`:

    `⟨p, xⁱ⟩ = ⟨q, xⁱ⟩` for `i < max d d'`   ⟹   `p(x) ≈ q(x)` for `x ∈ [0,1]`
      (`polyPN_moment_eq_imp_function_eq`, with `p = polyPN a b d`, `q = polyPN a' b' d'`).

For compact support the transform *is* the moment sequence (`mellinHat_compact`), so agreeing
transforms means agreeing moments. The proof does not need to express the difference `p − q` as a
single `polyPN` (which would need coefficient addition through the sealed `natScale`): it decomposes
`⟨p − q, ψ⟩` through `innerI`-bilinearity (`innerI_sub_left`) into the `polyN` pieces, each killed by
brick 64's `innerI_polyPN_zero`, so `⟨p − q, p − q⟩ ≈ 0` when the difference's first `max d d'`
moments vanish (`innerI_polyPN_diff_self_zero`). Brick 79's definiteness then forces `p − q` to
vanish pointwise on `[0,1]`, i.e. `p ≈ q` there.

HONEST SCOPE. Injectivity/separation on the **polynomial** class, over `[0,1]`. This is the
uniqueness direction of the transform pair on that class — NOT the full transform pair (no inversion
formula reconstructing an arbitrary `f` from `f̂`), NOT the continuous parameter, and NOT separation
beyond polynomials (a nonzero *non*-polynomial test with vanishing transform is the open
general-determinacy question, needing Bernstein). Nothing here touches the Weil form. Step 4 is RH.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DyadicDenseReal

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `Req (Rsub a b) zero → Req a b` (local copy of `ZeroGeometry`'s helper). -/
private theorem Req_of_Rsub_zero {a b : Real} (h : Req (Rsub a b) zero) : Req a b := by
  have h1 : Req a (Radd (Rsub a b) b) := by
    show Req a (Radd (Radd a (Rneg b)) b)
    refine Req_trans (Req_symm (Radd_zero a)) ?_
    have hz : Req zero (Radd (Rneg b) b) :=
      Req_symm (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
    exact Req_trans (Radd_congr (Req_refl a) hz) (Req_symm (Radd_assoc a (Rneg b) b))
  refine Req_trans h1 ?_
  exact Req_trans (Radd_congr h (Req_refl b)) (Req_trans (Radd_comm zero b) (Radd_zero b))

/-- **The difference of two polynomial tests pairs to zero with anything the monomials below
    `max d d'` do** — decompose through `innerI_sub_left` into the two `polyPN` pieces, each killed
    by brick 64's `innerI_polyPN_zero`. -/
theorem innerI_polyPN_diff_zero (a b a' b' : Nat → Nat) (d d' : Nat) (ψ : L2Test)
    (h : ∀ i : Nat, i < Nat.max d d' → Req (innerI (powTest i) ψ) zero) :
    Req (innerI (L2Test.sub (polyPN a b d) (polyPN a' b' d')) ψ) zero := by
  refine Req_trans (innerI_sub_left (polyPN a b d) (polyPN a' b' d') ψ) ?_
  refine Req_trans (Rsub_congr
    (innerI_polyPN_zero a b d ψ (fun i hi => h i (Nat.lt_of_lt_of_le hi (Nat.le_max_left d d'))))
    (innerI_polyPN_zero a' b' d' ψ (fun i hi => h i (Nat.lt_of_lt_of_le hi (Nat.le_max_right d d'))))) ?_
  exact Radd_neg zero

/-- **`d = max d d'` vanishing moments of the difference force zero `L²` energy.** -/
theorem innerI_polyPN_diff_self_zero (a b a' b' : Nat → Nat) (d d' : Nat)
    (h : ∀ i : Nat, i < Nat.max d d' →
      Req (mellinMoment (L2Test.sub (polyPN a b d) (polyPN a' b' d')) i) zero) :
    Req (innerI (L2Test.sub (polyPN a b d) (polyPN a' b' d'))
          (L2Test.sub (polyPN a b d) (polyPN a' b' d'))) zero :=
  innerI_polyPN_diff_zero a b a' b' d d'
    (L2Test.sub (polyPN a b d) (polyPN a' b' d'))
    (fun i hi => Req_trans (innerI_symm (powTest i)
      (L2Test.sub (polyPN a b d) (polyPN a' b' d'))) (h i hi))

/-- **THE MELLIN TRANSFORM SEPARATES POLYNOMIAL TESTS**: two compactly supported polynomial tests
    whose transforms (= moments) agree below `max d d'` are the same function on `[0,1]`. -/
theorem polyPN_moment_eq_imp_function_eq (a b a' b' : Nat → Nat) (d d' : Nat)
    (h : ∀ i : Nat, i < Nat.max d d' →
      Req (mellinMoment (polyPN a b d) i) (mellinMoment (polyPN a' b' d') i))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((polyPN a b d).f x) ((polyPN a' b' d').f x) := by
  have hdiff : ∀ i : Nat, i < Nat.max d d' →
      Req (mellinMoment (L2Test.sub (polyPN a b d) (polyPN a' b' d')) i) zero := by
    intro i hi
    refine Req_trans (innerI_sub_left (polyPN a b d) (polyPN a' b' d') (powTest i)) ?_
    exact Req_trans (Rsub_congr (h i hi) (Req_refl _)) (Radd_neg _)
  exact Req_of_Rsub_zero
    (innerI_self_zero_imp_zero (L2Test.sub (polyPN a b d) (polyPN a' b' d'))
      (innerI_polyPN_diff_self_zero a b a' b' d d' hdiff) x h0 h1)

end Multiplicity.UOR.Bridge.F1Square.Square
