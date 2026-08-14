/-
F1 square — **the pointwise product of two tests** (`ProductTest.lean`): `(φ·ψ)(x) = φ(x)·ψ(x)` as a
bundled `L2Test`, closing the class under multiplication.

The bounded-Lipschitz class is closed under products: `l2lip`/`l2fc` (`IntegralInner`) already give the
product's Lipschitz and congruence data, and `|φ(x)·ψ(x)| ≤ M_φ·M_ψ` its global bound. `productTest φ ψ`
packages these into a single `L2Test`, so a convolution integrand `t ↦ f(x/t)·g(t)` (a product of two
tests in `t`) is itself a test that `haarIntegral` can integrate — the structural prerequisite of the
multiplicative convolution `⋆` (transform-bridge Wall 2).

HONEST SCOPE. The product operation on the test class only. It is NOT the convolution `⋆` (which is
`haarIntegral` of a product), and NOT the Mellin theorem; those (Wall 2/3) are what would make
`weilPrimeGram (vFrom g)` the genuine autocorrelation Gram, i.e. step 4 = RH. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.IntegralInner

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The pointwise product of two tests** `(productTest φ ψ).f x = φ(x)·ψ(x)` — a genuine `L2Test`
    (Lipschitz modulus `l2L φ ψ = M_φ·L_ψ + M_ψ·L_φ`, bound `M_φ·M_ψ`), reusing the product
    certificates `l2lip`/`l2fc`. Closes the bounded-Lipschitz class under multiplication. -/
def productTest (φ ψ : L2Test) : L2Test where
  f := fun x => Rmul (φ.f x) (ψ.f x)
  L := l2L φ ψ
  M := mul φ.M ψ.M
  hLd := l2L_den φ ψ
  hLn := l2L_num φ ψ
  hMd := Qmul_den_pos φ.hMd ψ.hMd
  hMn := Int.mul_nonneg φ.hMn ψ.hMn
  hlip := l2lip φ ψ
  hfc := l2fc φ ψ
  hbd := fun x => Rle_trans (Rle_of_Req (Rabs_Rmul (φ.f x) (ψ.f x)))
    (Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ ψ.hMd ψ.hMn) (φ.hbd x) (ψ.hbd x))
      (Rle_of_Req (Rmul_ofQ_ofQ φ.hMd ψ.hMd)))

/-- The product test's value is the pointwise product — the defining computation, for downstream
    rewriting against `innerIonI`/`haarIntegral` integrands. -/
theorem productTest_f (φ ψ : L2Test) (x : Real) :
    (productTest φ ψ).f x = Rmul (φ.f x) (ψ.f x) := rfl

/-- **The product is commutative up to `≈`** `(productTest φ ψ).f x ≈ (productTest ψ φ).f x` — the
    integrand-level symmetry (pointwise `Rmul_comm`). -/
theorem productTest_comm (φ ψ : L2Test) (x : Real) :
    Req ((productTest φ ψ).f x) ((productTest ψ φ).f x) :=
  Rmul_comm (φ.f x) (ψ.f x)

end Multiplicity.UOR.Bridge.F1Square.Analysis
