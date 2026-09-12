/-
F1 square — **the determinacy reduction and the deviation transfer** (`BernsteinDeviationTransfer.lean`),
the Bernstein arc, sub-brick H₅. Two facts that turn the operator moment-integral (H₄) into a bound on
the L² energy `⟨φ,φ⟩` of a moment-null test:

- **reduction**: since `⟨φ, B_n(φ)⟩ ≈ 0` (H₄), `⟨φ,φ⟩ ≈ ⟨φ, φ − B_n(φ)⟩` (`innerI_self_eq_sub`) — the
  energy equals the pairing of `φ` with its Bernstein *residual*;
- **deviation transfer**: on `[0,1]` the residual is pointwise bounded by Bernstein's deviation,
  `|φ(x) − (bernOpCTest φ n hn).f x| ≤ L·Σ_k |k/n − x|·b_{n,k}(x)` (`bernOpCTest_pointwise_dev`), because
  the operator test agrees with the honest `bernOp` there (H₄) and `bernOp` obeys the pointwise bound
  (sub-brick G).

WHY (the Sonine route, step 3, the Mellin FRONT). `⟨φ,φ⟩ = ⟨φ, φ − B_nφ⟩` with the residual → 0
uniformly is the whole determinacy step: it forces `⟨φ,φ⟩ ≈ 0`, and (brick 79) `φ ≈ 0` on `[0,1]`. This
brick lands the two structural facts; the next converts the pointwise deviation into a vanishing
rational bound on the energy.

HONEST SCOPE. The reduction and the pointwise deviation bound for the residual, over `Real`.
Infrastructure for determinacy; NOT yet the energy bound, NOT `⟨φ,φ⟩ ≈ 0`, NOT determinacy, NOT
inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.BernsteinOperatorTest
import Foundations.F1.Square.ContinuousMomentTailBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE DETERMINACY REDUCTION**: for a moment-null `φ`, `⟨φ,φ⟩ ≈ ⟨φ, φ − B_n(φ)⟩` — the L² energy
    equals the pairing of `φ` with its Bernstein residual, since `⟨φ, B_n(φ)⟩ ≈ 0` (H₄). -/
theorem innerI_self_eq_sub (φ : L2Test) (hmom : ∀ i, Req (mellinMoment φ i) zero)
    (n : Nat) (hn : 0 < n) :
    Req (innerI φ φ) (innerI φ (L2Test.sub φ (bernOpCTest φ n hn))) :=
  Req_symm (Req_trans (innerI_sub_right φ φ (bernOpCTest φ n hn))
    (Req_trans (Rsub_congr (Req_refl _) (innerI_bernOpCTest_zero φ hmom n hn))
      (Rsub_zero (innerI φ φ))))

/-- **THE DEVIATION TRANSFER**: on `[0,1]`, the Bernstein residual of `φ` is bounded by Bernstein's
    pointwise deviation, `|φ(x) − (bernOpCTest φ n hn).f x| ≤ L·Σ_k |k/n − x|·b_{n,k}(x)`. The operator
    test agrees with the honest `bernOp` on `[0,1]` (`bernOpCTest_eq_on_unit`), so the deviation bound
    (`bernOp_deviation`, sub-brick G) transfers — the sign flip inside the absolute value is inert. -/
theorem bernOpCTest_pointwise_dev (φ : L2Test) (n : Nat) (hn : 0 < n) {x : Real}
    (h0 : Rle zero x) (h1 : Rle x one) :
    Rle (Rabs (Rsub (φ.f x) ((bernOpCTest φ n hn).f x)))
        (Rmul (ofQ φ.L φ.hLd)
          (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _)
    (bernOpCTest_eq_on_unit φ n hn h0 h1)))) ?_
  refine Rle_trans (Rle_of_Req (Req_trans
    (Rabs_congr (Req_symm (Rneg_Rsub_flip (bernOp φ n hn x) (φ.f x))))
    (Rabs_Rneg (Rsub (bernOp φ n hn x) (φ.f x))))) ?_
  exact bernOp_deviation φ n hn x (Rnonneg_of_Rle_zero h0) (Rnonneg_Rsub_of_Rle h1)

end Multiplicity.UOR.Bridge.F1Square.Square
