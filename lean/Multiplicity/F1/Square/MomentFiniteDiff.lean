/-
F1 square — **the reconstruction coefficients are finite differences of the moments**
(`MomentFiniteDiff.lean`), the Mellin-inversion arc, sub-brick I₁. The Hausdorff/Bernstein inversion
of the moment map reconstructs `φ` from its moment sequence `μ_n = ⟨φ, xⁿ⟩`; its coefficients are the
integrals `⟨φ, xᵏ(1−x)ᵐ⟩` of `φ` against the Bernstein basis factors, and this brick shows those are
**computable from the moments alone**, as forward finite differences:

    `⟨φ, xᵏ(1−x)ᵐ⟩ = (Δᵐμ)_k`   (`clampProd_integral_eq_momDiff`),

where `(Δᵐμ)_k` is the `m`-th forward difference of `μ` starting at `k` (`momDiff`, `Δ⁰_k = μ_k`,
`Δ^{m+1}_k = Δᵐ_k − Δᵐ_{k+1}`). The proof is the same Pascal recursion the determinacy arc used: the
basis factor obeys `xᵏ(1−x)ᵐ⁺¹ = xᵏ(1−x)ᵐ − xᵏ⁺¹(1−x)ᵐ` (`clampProd_step_pt`), which is exactly the
finite-difference recursion — so the two sides agree by induction on `m`, with the base
`⟨φ, xᵏ⟩ = μ_k`. No signed binomial coefficients are ever formed.

WHY (the Sonine route, step 3, the Mellin FRONT). Determinacy (the transform pair's injectivity half,
now proven on the general class) says the moments determine `φ`; inversion is the *constructive*
recovery. Its first ingredient is that the reconstruction coefficients live in the moment data, which
is this identity. The Bernstein reconstruction operator and its convergence to `φ` are the next steps.

HONEST SCOPE. The finite-difference identity for the reconstruction coefficients, over `Real`.
Infrastructure for inversion; NOT the reconstruction operator, NOT its convergence, NOT inversion, NOT
the transform pair's surjectivity, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinBasisZero
import Multiplicity.F1Square.Square.ContinuousMomentTailBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The forward finite differences of the moment sequence**: `Δ⁰_k = μ_k`,
    `Δ^{m+1}_k = Δᵐ_k − Δᵐ_{k+1}`. -/
def momDiff (φ : L2Test) (k : Nat) : Nat → Real
  | 0 => mellinMoment φ k
  | m + 1 => Rsub (momDiff φ k m) (momDiff φ (k + 1) m)

/-- **★ THE RECONSTRUCTION COEFFICIENT IS A FINITE DIFFERENCE OF MOMENTS**:
    `⟨φ, xᵏ(1−x)ᵐ⟩ = (Δᵐμ)_k`. Induction on `m`: the base is the `k`-th moment; the step is the Pascal
    recursion of the basis factor (`clampProd_step_pt`) split by `innerI_sub_right`, mirroring the
    finite-difference recursion of `momDiff`. -/
theorem clampProd_integral_eq_momDiff (φ : L2Test) :
    ∀ m k, Req (innerI φ (clampProdTest k m)) (momDiff φ k m)
  | 0, k => by
    refine innerI_right_congr_on_unit φ (clampProdTest k 0) (powTest k) (fun x _ _ => ?_)
    show Req (Rmul ((powTest k).f x) one) ((powTest k).f x)
    exact Rmul_one _
  | m + 1, k => by
    refine Req_trans (innerI_right_congr_on_unit φ (clampProdTest k (m + 1))
      (L2Test.sub (clampProdTest k m) (clampProdTest (k + 1) m))
      (fun x _ _ => clampProd_step_pt k m x)) ?_
    refine Req_trans (innerI_sub_right φ (clampProdTest k m) (clampProdTest (k + 1) m)) ?_
    exact Rsub_congr (clampProd_integral_eq_momDiff φ m k)
      (clampProd_integral_eq_momDiff φ m (k + 1))

end Multiplicity.UOR.Bridge.F1Square.Square
