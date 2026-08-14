/-
F1 square — **the Bernstein basis pairs to zero against a moment-null test**
(`BernsteinBasisZero.lean`), the Bernstein arc, sub-brick H₁ — the FIRST integration step of the
determinacy arc. For a test `φ` whose EVERY integer moment vanishes:

    `⟨φ, C(n,k)·xᵏ·(1−x)ⁿ⁻ᵏ⟩ = ∫₀¹ φ(x)·b_{n,k}(x) dx ≈ 0`   (`innerI_bernBasis_zero`).

WHY (the Sonine route, step 3, the Mellin FRONT). Bernstein's theorem (sub-brick G) writes the
approximation as `B_n(φ)(x) = Σ_k φ(k/n)·b_{n,k}(x)`, so `∫₀¹ φ·B_n(φ) = Σ_k φ(k/n)·∫₀¹ φ·b_{n,k}`.
The real coefficients `φ(k/n)` are only outer factors — the whole operator integral collapses once
each single-basis integral `∫₀¹ φ·b_{n,k}` vanishes, and that is what this brick proves. It needs no
monomial bookkeeping and no signed-binomial `polyPN`: the basis factor `xᵏ·(1−x)ᵐ` satisfies the
Pascal recursion `xᵏ(1−x)ᵐ⁺¹ = xᵏ(1−x)ᵐ − xᵏ⁺¹(1−x)ᵐ`, so by induction on `m`, bilinearity
(`innerI_sub_right`) and unit-restriction congruence (`innerI_right_congr_on_unit`, brick 90) reduce
every `⟨φ, xᵏ(1−x)ᵐ⟩` to the base case `⟨φ, xᵏ⟩ = mellinMoment φ k ≈ 0`. The clamped building blocks
(`powTest`, `1 − clampTest`) keep everything a genuine bounded-Lipschitz test, and agree with the
honest `bernR` (which uses `Rpow`) on `[0,1]` — the only place the certified integral samples.

HONEST SCOPE. The single-basis moment-integral, over `Real`. Infrastructure for the determinacy arc;
NOT yet the operator integral `∫φ·B_nφ` (needs the `bernR`-matching and the finite sum), NOT the
deviation integral, NOT determinacy, NOT inversion, NOT positivity. Step 4 is RH; crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.PairingUnitCongr
import Multiplicity.F1Square.Square.ContinuousMomentTailBound
import Multiplicity.F1Square.Square.PolyDeterminacy

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The clamped Bernstein building blocks (genuine bounded-Lipschitz tests).
-- ===========================================================================

/-- `1 − clamp01` as a test — the `(1−x)` factor, clamped so it stays bounded-Lipschitz. -/
def oneMinusClampTest : L2Test := L2Test.sub oneTest clampTest

/-- `(1 − clamp01)ᵐ` as a test, by iterated product. -/
def powMinusTest : Nat → L2Test
  | 0 => oneTest
  | m + 1 => L2Test.mul oneMinusClampTest (powMinusTest m)

/-- The un-normalized Bernstein factor `clamp01ᵏ·(1 − clamp01)ᵐ` as a test — on `[0,1]` this is
    `xᵏ·(1−x)ᵐ`. -/
def clampProdTest (k m : Nat) : L2Test := L2Test.mul (powTest k) (powMinusTest m)

/-- The clamped **Bernstein basis test** `C(n,k)·clamp01ᵏ·(1 − clamp01)ⁿ⁻ᵏ` — on `[0,1]` it equals
    the honest basis `bernR x n k`. -/
def bernBasisTest (n k : Nat) : L2Test := natScale (choose n k) (clampProdTest k (n - k))

-- ===========================================================================
-- The Pascal step, pointwise.
-- ===========================================================================

/-- **The Pascal recursion of the basis factor**, pointwise (globally, hence on `[0,1]`):
    `clamp01ᵏ·(1−clamp01)ᵐ⁺¹ = clamp01ᵏ·(1−clamp01)ᵐ − clamp01ᵏ⁺¹·(1−clamp01)ᵐ`. Pure
    `Rmul`/`Rsub` algebra: distribute `(1−clamp01)` and reassociate `clamp01ᵏ·clamp01 = clamp01ᵏ⁺¹`. -/
theorem clampProd_step_pt (k m : Nat) (x : Real) :
    Req ((clampProdTest k (m + 1)).f x)
        ((L2Test.sub (clampProdTest k m) (clampProdTest (k + 1) m)).f x) := by
  show Req (Rmul ((powTest k).f x) (Rmul (Rsub one (clamp01 x)) ((powMinusTest m).f x)))
      (Rsub (Rmul ((powTest k).f x) ((powMinusTest m).f x))
            (Rmul (Rmul ((powTest k).f x) (clamp01 x)) ((powMinusTest m).f x)))
  have h1 : Req (Rmul (Rsub one (clamp01 x)) ((powMinusTest m).f x))
      (Rsub ((powMinusTest m).f x) (Rmul (clamp01 x) ((powMinusTest m).f x))) :=
    Req_trans (Rmul_sub_distrib_right one (clamp01 x) ((powMinusTest m).f x))
      (Rsub_congr (Rone_mul ((powMinusTest m).f x)) (Req_refl _))
  exact Req_trans (Rmul_congr (Req_refl ((powTest k).f x)) h1)
    (Req_trans (Rmul_sub_distrib ((powTest k).f x) ((powMinusTest m).f x)
        (Rmul (clamp01 x) ((powMinusTest m).f x)))
      (Rsub_congr (Req_refl _)
        (Req_symm (Rmul_assoc ((powTest k).f x) (clamp01 x) ((powMinusTest m).f x)))))

-- ===========================================================================
-- The single-basis moment-integral.
-- ===========================================================================

/-- **★ THE BASIS FACTOR PAIRS TO ZERO**: if every moment of `φ` vanishes, then
    `⟨φ, clamp01ᵏ·(1−clamp01)ᵐ⟩ ≈ 0` for every `k, m`. Induction on `m`: the base `m = 0` is the
    `k`-th moment; the step is the Pascal recursion, split by `innerI_sub_right` into two `m`-cases. -/
theorem innerI_clampProd_zero (φ : L2Test) (hmom : ∀ i, Req (mellinMoment φ i) zero) :
    ∀ m k, Req (innerI φ (clampProdTest k m)) zero
  | 0, k => by
    refine Req_trans (innerI_right_congr_on_unit φ (clampProdTest k 0) (powTest k) ?_) (hmom k)
    intro x _ _
    show Req (Rmul ((powTest k).f x) one) ((powTest k).f x)
    exact Rmul_one _
  | m + 1, k => by
    refine Req_trans (innerI_right_congr_on_unit φ (clampProdTest k (m + 1))
      (L2Test.sub (clampProdTest k m) (clampProdTest (k + 1) m))
      (fun x _ _ => clampProd_step_pt k m x)) ?_
    refine Req_trans (innerI_sub_right φ (clampProdTest k m) (clampProdTest (k + 1) m)) ?_
    exact Req_trans (Rsub_congr (innerI_clampProd_zero φ hmom m k)
      (innerI_clampProd_zero φ hmom m (k + 1))) (Radd_neg zero)

/-- **★ THE BERNSTEIN BASIS PAIRS TO ZERO**: if every moment of `φ` vanishes, then
    `⟨φ, C(n,k)·clamp01ᵏ·(1−clamp01)ⁿ⁻ᵏ⟩ ≈ 0` — the normalized basis, through the `ℕ`-scaling of
    the pairing (`innerI_natScale_zero`, in the first slot after `innerI_symm`). -/
theorem innerI_bernBasis_zero (φ : L2Test) (hmom : ∀ i, Req (mellinMoment φ i) zero) (n k : Nat) :
    Req (innerI φ (bernBasisTest n k)) zero :=
  Req_trans (innerI_symm φ (bernBasisTest n k))
    (innerI_natScale_zero (clampProdTest k (n - k)) φ
      (Req_trans (innerI_symm (clampProdTest k (n - k)) φ)
        (innerI_clampProd_zero φ hmom (n - k) k)) (choose n k))

end Multiplicity.UOR.Bridge.F1Square.Square
