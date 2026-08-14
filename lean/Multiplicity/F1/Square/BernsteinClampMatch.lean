/-
F1 square — **the clamped Bernstein basis matches the honest basis on `[0,1]`**
(`BernsteinClampMatch.lean`), the Bernstein arc, sub-brick H₂. The clamped building blocks of
`BernsteinBasisZero.lean` (`powTest`, `powMinusTest`, `clampProdTest`) are genuine bounded-Lipschitz
tests, so they pair through the certified integral; the honest basis `bernR x n k =
C(n,k)·xᵏ·(1−x)ⁿ⁻ᵏ` (built from `Rpow`, unbounded off `[0,1]`) is what Bernstein's pointwise deviation
bound (sub-brick G) is stated over. This brick welds the two: on `[0,1]`, where `clamp01 x = x`,

    `bernR x n k ≈ C(n,k)·(clampProdTest k (n−k)).f x`   (`bernR_eq_scaled_clampProd`),

so every statement about `bernR` on the integration domain transfers to the clamped tests, and vice
versa. Since the certified integral only ever samples `[0,1]`, this is exactly the bridge the operator
integral and the deviation integral need.

WHY (the Sonine route, step 3, the Mellin FRONT). The determinacy arc runs the moment-integral over
the clamped tests (`innerI_bernBasis_zero`) but bounds the approximation error with the honest
deviation `|B_n(φ)(x) − φ(x)| ≤ L·Σ|k/n − x|·b_{n,k}(x)` (sub-brick G). The two live on the same domain
`[0,1]` and this brick certifies they agree there — the correspondences `(powTest k).f x = clamp01(x)ᵏ`
and `(powMinusTest m).f x = (1 − clamp01 x)ᵐ` are clean inductions, and `clamp01 x = x` on `[0,1]`
(`qBandQ_eq_of_band`) collapses both to the honest monomials.

HONEST SCOPE. The clamped-vs-honest basis identity on `[0,1]`, over `Real`. Infrastructure for the
determinacy arc; NOT yet the operator integral, NOT the deviation integral, NOT determinacy, NOT
inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinBasisZero
import Multiplicity.F1Square.Analysis.Bernstein

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`clamp01` is inert on `[0,1]`**: `clamp01 x ≈ x` for `0 ≤ x ≤ 1` — the band clamp is the
    identity on its own band (`qBandQ_eq_of_band`; `one = ofQ⟨1,1⟩` definitionally, `zero ≈ ofQ⟨0,1⟩`). -/
theorem clamp01_eq_self {x : Real} (h0 : Rle zero x) (h1 : Rle x one) : Req (clamp01 x) x := by
  have hz : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  show Req (qBandQ (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) x) x
  exact qBandQ_eq_of_band (Rle_trans (Rle_of_Req hz) h0) h1

/-- **`(powTest k).f x = clamp01(x)ᵏ`** — the clamped monomial test evaluates to the iterated clamp,
    by the `L2Test.mul` definition of `powTest`. -/
theorem powTest_f_eq (x : Real) : ∀ k, Req ((powTest k).f x) (Rpow (clamp01 x) k)
  | 0 => Req_refl one
  | k + 1 => by
    show Req (Rmul ((powTest k).f x) (clamp01 x)) (Rmul (clamp01 x) (Rpow (clamp01 x) k))
    exact Req_trans (Rmul_congr (powTest_f_eq x k) (Req_refl _))
      (Rmul_comm (Rpow (clamp01 x) k) (clamp01 x))

/-- **`(powMinusTest m).f x = (1 − clamp01 x)ᵐ`** — the `(1−x)` factor test evaluates to the iterated
    complementary clamp. -/
theorem powMinusTest_f_eq (x : Real) : ∀ m, Req ((powMinusTest m).f x) (Rpow (Rsub one (clamp01 x)) m)
  | 0 => Req_refl one
  | m + 1 => by
    show Req (Rmul (Rsub one (clamp01 x)) ((powMinusTest m).f x))
        (Rmul (Rsub one (clamp01 x)) (Rpow (Rsub one (clamp01 x)) m))
    exact Rmul_congr (Req_refl _) (powMinusTest_f_eq x m)

/-- **The basis factor equals the honest monomials on `[0,1]`**:
    `(clampProdTest k m).f x ≈ xᵏ·(1−x)ᵐ` for `0 ≤ x ≤ 1`. -/
theorem clampProdTest_eq_on_unit (k m : Nat) {x : Real} (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((clampProdTest k m).f x) (Rmul (Rpow x k) (Rpow (Rsub one x) m)) := by
  have hc := clamp01_eq_self h0 h1
  refine Req_trans (Rmul_congr (powTest_f_eq x k) (powMinusTest_f_eq x m)) ?_
  exact Rmul_congr (Rpow_congr hc k) (Rpow_congr (Rsub_congr (Req_refl one) hc) m)

/-- **★ THE CLAMPED BERNSTEIN BASIS MATCHES THE HONEST ONE ON `[0,1]`**:
    `bernR x n k ≈ C(n,k)·(clampProdTest k (n−k)).f x` for `0 ≤ x ≤ 1`. The `C(n,k)` factor is carried
    outside (as the real `RofNat (choose n k)`), so the deviation arc can absorb it into the operator's
    real coefficient without touching the sealed `natScale`. -/
theorem bernR_eq_scaled_clampProd (n k : Nat) {x : Real} (h0 : Rle zero x) (h1 : Rle x one) :
    Req (bernR x n k) (Rmul (RofNat (choose n k)) ((clampProdTest k (n - k)).f x)) := by
  show Req (Rmul (RofNat (choose n k)) (Rmul (Rpow x k) (Rpow (Rsub one x) (n - k))))
      (Rmul (RofNat (choose n k)) ((clampProdTest k (n - k)).f x))
  exact Rmul_congr (Req_refl _) (Req_symm (clampProdTest_eq_on_unit k (n - k) h0 h1))

end Multiplicity.UOR.Bridge.F1Square.Square
