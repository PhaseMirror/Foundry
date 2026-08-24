/-
F1 square — **the separable (product) integrand as a parametric test** (`ProdParamTest.lean`): the
instance of `paramIntegralTest` at `F(x, y) = φ(x)·ψ(y)`, and the inner factorization its integral
enjoys.

    `prodParamTest φ ψ [ylo, yw] .f x  =  ∫_{ylo}^{ylo+yw} φ(x)·ψ(y) dy  ≈  φ(x)·(∫_{ylo}^{ylo+yw} ψ)`
                                                                          (`prodParamTest_f_factor`)

The three joint-continuity facts a product integrand needs — Lipschitz in each variable with the other
held constant, and the joint bound — are the one-sided `constMul_*` helpers (`|c·χ(y) − c·χ(y')| ≤
(M·Lχ)·|y−y'|` for `|c| ≤ M`, and its bound companion), fed to `paramIntegralTest`. The inner
factorization then pulls the parameter-constant `φ(x)` (a REAL) out of the `y`-integral by
`riemannIntegralI_Rsmul`, reconciling the common Lipschitz modulus with certificate independence.

WHY (the transform bridge, Wall 3). A separable double integral `∫_x ∫_y φ(x)ψ(y)` factors to
`(∫φ)·(∫ψ)`; this brick supplies the inner half of that factorization (the outer half — pulling `∫ψ`
out of the `x`-integral — is the same `riemannIntegralI_Rsmul` again). It is the shape the Mellin
convolution theorem `M[f⋆g]=M[f]·M[g]` reduces to ONCE the change of variables has decoupled the
integrand; that change of variables (the genuine two-variable/Fubini step) is unbuilt, and this file
provides no swap and no product identity for a NON-separable integrand. The crux fields stay `none`.

HONEST SCOPE. The product integrand as a valid parametric test, and the inner factorization of its
integral. No swap, no non-separable Fubini, no positivity beyond what the factors carry. Step 4 is RH;
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ParamIntegral
import Multiplicity.F1.Analysis.IntervalRsmul
import Multiplicity.F1.Square.MellinLinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **One-sided product Lipschitz**: with a constant `c`, `|c·χ(y) − c·χ(y')| ≤ (M·Lχ)·|y−y'|` when
    `|c| ≤ M` (`M` a rational bound on `c`). -/
theorem constMul_lip (c : Real) {M : Q} (hMd : 0 < M.den) (hcM : Rle (Rabs c) (ofQ M hMd))
    (χ : L2Test) (y y' : Real) :
    Rle (Rabs (Rsub (Rmul c (χ.f y)) (Rmul c (χ.f y'))))
        (Rmul (ofQ (mul M χ.L) (Qmul_den_pos hMd χ.hLd)) (Rabs (Rsub y y'))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rmul_sub_distrib c (χ.f y) (χ.f y'))))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul c (Rsub (χ.f y) (χ.f y')))) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs c)
    (Rnonneg_Rmul (Rnonneg_ofQ χ.hLd χ.hLn) (Rnonneg_Rabs _)) hcM (χ.hlip y y')) ?_
  exact Rle_of_Req (Req_trans
    (Req_symm (Rmul_assoc (ofQ M hMd) (ofQ χ.L χ.hLd) (Rabs (Rsub y y'))))
    (Rmul_congr (Rmul_ofQ_ofQ hMd χ.hLd) (Req_refl _)))

/-- **One-sided product bound**: `|c·χ(z)| ≤ M·Mχ` when `|c| ≤ M`. -/
private theorem constMul_bd (c : Real) {M : Q} (hMd : 0 < M.den) (hcM : Rle (Rabs c) (ofQ M hMd))
    (χ : L2Test) (z : Real) :
    Rle (Rabs (Rmul c (χ.f z))) (ofQ (mul M χ.M) (Qmul_den_pos hMd χ.hMd)) := by
  refine Rle_trans (Rle_of_Req (Rabs_Rmul c (χ.f z))) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs c) (Rnonneg_ofQ χ.hMd χ.hMn) hcM (χ.hbd z)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ hMd χ.hMd)

-- The product integrand `F(x, y) = φ(x)·ψ(y)` and its joint-continuity certificates.
-- Ly = ψ.L + φ.M·ψ.L (the common modulus that carries both ψ and φ(x)·ψ, for the Rsmul step);
-- Lx = ψ.M·φ.L; B = φ.M·ψ.M.

private theorem prodLipY (φ ψ : L2Test) : ∀ x y y',
    Rle (Rabs (Rsub (Rmul (φ.f x) (ψ.f y)) (Rmul (φ.f x) (ψ.f y'))))
        (Rmul (ofQ (add ψ.L (mul φ.M ψ.L)) (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd)))
          (Rabs (Rsub y y'))) :=
  fun x => lip_weaken (Qmul_den_pos φ.hMd ψ.hLd) (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd))
    (Qle_add_self ψ.hLn) (constMul_lip (φ.f x) φ.hMd (φ.hbd x) ψ)

private theorem prodFcY (φ ψ : L2Test) : ∀ x y y', Req y y' →
    Req (Rmul (φ.f x) (ψ.f y)) (Rmul (φ.f x) (ψ.f y')) :=
  fun x _ _ h => Rmul_congr (Req_refl (φ.f x)) (ψ.hfc _ _ h)

private theorem prodLipX (φ ψ : L2Test) : ∀ x x' y,
    Rle (Rabs (Rsub (Rmul (φ.f x) (ψ.f y)) (Rmul (φ.f x') (ψ.f y))))
        (Rmul (ofQ (mul ψ.M φ.L) (Qmul_den_pos ψ.hMd φ.hLd)) (Rabs (Rsub x x'))) :=
  fun x x' y => Rle_trans
    (Rle_of_Req (Rabs_congr (Rsub_congr (Rmul_comm (φ.f x) (ψ.f y)) (Rmul_comm (φ.f x') (ψ.f y)))))
    (constMul_lip (ψ.f y) ψ.hMd (ψ.hbd y) φ x x')

private theorem prodFcX (φ ψ : L2Test) : ∀ x x' y, Req x x' →
    Req (Rmul (φ.f x) (ψ.f y)) (Rmul (φ.f x') (ψ.f y)) :=
  fun _ _ y h => Rmul_congr (φ.hfc _ _ h) (Req_refl (ψ.f y))

private theorem prodBd (φ ψ : L2Test) (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den) :
    ∀ x u, Rle zero u → Rle u one →
      Rle (Rabs (Rmul (φ.f x) (ψ.f (affineMap ylo yw hylo hyw u))))
          (ofQ (mul φ.M ψ.M) (Qmul_den_pos φ.hMd ψ.hMd)) :=
  fun x u _ _ => constMul_bd (φ.f x) φ.hMd (φ.hbd x) ψ (affineMap ylo yw hylo hyw u)

/-- **The separable product integrand `φ(x)·ψ(y)` as a parametric test in `x`**: `paramIntegralTest`
    at `F(x, y) = φ(x)·ψ(y)`, so `.f x = ∫_{ylo}^{ylo+yw} φ(x)·ψ(y) dy`. -/
def prodParamTest (φ ψ : L2Test) (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den)
    (hywn : 0 ≤ yw.num) : L2Test :=
  paramIntegralTest (fun x y => Rmul (φ.f x) (ψ.f y))
    (add ψ.L (mul φ.M ψ.L)) (mul ψ.M φ.L) (mul φ.M ψ.M)
    (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd))
    (Qadd_num_nonneg_loc ψ.hLn (Int.mul_nonneg φ.hMn ψ.hLn))
    (Qmul_den_pos ψ.hMd φ.hLd) (Int.mul_nonneg ψ.hMn φ.hLn)
    (Qmul_den_pos φ.hMd ψ.hMd) (Int.mul_nonneg φ.hMn ψ.hMn)
    (prodLipY φ ψ) (prodFcY φ ψ) (prodLipX φ ψ) (prodFcX φ ψ)
    ylo yw hylo hyw hywn (prodBd φ ψ ylo yw hylo hyw)

/-- **The inner factorization**: `∫_{ylo}^{ylo+yw} φ(x)·ψ(y) dy ≈ φ(x)·(∫_{ylo}^{ylo+yw} ψ)` — the
    parameter-constant `φ(x)` (a REAL) pulls out of the `y`-integral (`riemannIntegralI_Rsmul` at the
    common modulus `ψ.L + φ.M·ψ.L`, the `ψ`-side reconciled to its own modulus by certificate
    independence). -/
theorem prodParamTest_f_factor (φ ψ : L2Test) (ylo yw : Q) (hylo : 0 < ylo.den) (hyw : 0 < yw.den)
    (hywn : 0 ≤ yw.num) (x : Real) :
    Req ((prodParamTest φ ψ ylo yw hylo hyw hywn).f x)
        (Rmul (φ.f x) (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn)) := by
  refine Req_trans
    (riemannIntegralI_Rsmul (φ.f x)
      (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd))
      (Qadd_num_nonneg_loc ψ.hLn (Int.mul_nonneg φ.hMn ψ.hLn))
      (lip_weaken ψ.hLd (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd))
        (Qle_self_add (Int.mul_nonneg φ.hMn ψ.hLn)) ψ.hlip)
      ψ.hfc (prodLipY φ ψ x) (prodFcY φ ψ x) ylo yw hylo hyw hywn) ?_
  exact Rmul_congr (Req_refl (φ.f x))
    (riemannIntegralI_certif_irrel
      (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd))
      (Qadd_num_nonneg_loc ψ.hLn (Int.mul_nonneg φ.hMn ψ.hLn))
      (lip_weaken ψ.hLd (add_den_pos ψ.hLd (Qmul_den_pos φ.hMd ψ.hLd))
        (Qle_self_add (Int.mul_nonneg φ.hMn ψ.hLn)) ψ.hlip)
      ψ.hfc ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn)

end Multiplicity.UOR.Bridge.F1Square.Square
