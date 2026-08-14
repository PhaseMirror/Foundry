/-
F1 square — **the co-support filtration intersection is trivial** (`CoSupportTrivial.lean`), sub-brick
M₁. The co-support object `HatVanishes φ K` was shown proper, strict through depth 8, inhabited for
`K = 1..7`, thin at rate `1/(K+1)`. This brick pins its intersection:

  `(∀ K, φ ∈ HatVanishes·K)  ⟹  φ ≈ 0 on [0,1]`   (`hatVanishes_all_imp_zero`),

i.e. `⋂_K HatVanishes·K = {0}` — a unit-supported test orthogonal to *every* monomial `xⁿ` is zero on
`[0,1]`. Equivalently, the **monomial system is total** in the L² sense: the dual of L² density
(`bernOp_L2_converges` — polynomials dense) is that nothing nonzero is orthogonal to all of them.

The weld is immediate on the substrate: each level condition unfolds
(`hatVanishes_iff_orthogonal`) to `⟨φ,xⁿ⟩ ≈ 0` for `n < K`; taking `K = i+1` makes every moment
`mellinMoment φ i = ⟨φ, xⁱ⟩` vanish (definitionally `innerI φ (powTest i)`), and general moment
determinacy (`moment_determinacy_unit`, the completed Bernstein arc) closes.

WHY (the Sonine route, step 3, the co-support object). Density (approximation) and totality
(determinacy) are the two halves of the monomial system's completeness in `L²[0,1]`: the polynomials
are dense, and the filtration of orthogonal-complements collapses to `{0}`. Both are now theorems, on
the general bounded-Lipschitz class.

HONEST SCOPE. A determinacy corollary about the co-support filtration of a single unit-supported test.
NOT a completed L² space of functions, NOT surjectivity onto function space, NOT positivity beyond the
complement. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CoSupportWeld
import Multiplicity.F1Square.Square.MomentDeterminacy

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE CO-SUPPORT FILTRATION INTERSECTION IS TRIVIAL** (`⋂_K HatVanishes·K = {0}`): a unit-supported
    test lying in EVERY co-support level — orthogonal to every monomial `xⁿ` — is zero on `[0,1]`. The
    monomials are total (the dual of L² density). Each level unfolds via `hatVanishes_iff_orthogonal` to
    `⟨φ,xⁿ⟩ ≈ 0` for `n < K`; at `K = i+1` every moment vanishes, and `moment_determinacy_unit` closes. -/
theorem hatVanishes_all_imp_zero (φ : L2Test) (hsupp : UnitSupported φ)
    (hall : ∀ K : Nat, HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp φ hsupp))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req (φ.f x) zero := by
  refine moment_determinacy_unit φ (fun i => ?_) x h0 h1
  exact (hatVanishes_iff_orthogonal φ (i + 1) hsupp).mp (hall (i + 1)) i (Nat.lt_succ_self i)

end Multiplicity.UOR.Bridge.F1Square.Square
