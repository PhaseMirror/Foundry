/-
F1 square — **separable Fubini: the product of two interval integrals** (`SeparableFubini.lean`):

    `∫_{xlo}^{xlo+xw} ∫_{ylo}^{ylo+yw} φ(x)·ψ(y) dy dx  ≈  (∫_x φ)·(∫_y ψ)`   (`separable_fubini`)

the iterated integral of a SEPARABLE (product) integrand factors as the product of the two
single-variable integrals. The outer integrand is `prodParamTest φ ψ` (the inner integral as a test in
`x`); the inner factorization `prodParamTest_f_factor` rewrites its value as `φ(x)·(∫_y ψ)`, and a
second `riemannIntegralI_Rsmul` pulls the now-constant `∫_y ψ` out of the `x`-integral, leaving
`(∫_x φ)·(∫_y ψ)`. The Lipschitz moduli are reconciled by certificate independence (twice) and the one
`Q`-multiplication-associativity bridge `yw·(ψ.M·φ.L) = (yw·ψ.M)·φ.L`.

WHY (the transform bridge, Wall 3). This is the Fubini swap for the EASY, separable case: because the
integrand factors, no genuine two-variable interchange is needed — the swap reduces to the commutativity
of `Rmul` on the two constant integrals. It is the final factorization the Mellin convolution theorem
`M[f⋆g]=M[f]·M[g]` reduces to ONCE the change of variables has decoupled the integrand
(`∫_t ∫_u f(u)u^{s-1}·g(t)t^{s-1} = M[f]·M[g]`). The NON-separable middle — the change of variables /
genuine Fubini on the coupled integrand `f(x/t)g(t)x^{s-1}` — is unbuilt; this file provides NO swap for
a non-separable integrand. The crux fields stay `none`.

HONEST SCOPE. Fubini for a separable integrand only, via factorization; no genuine two-variable
interchange, no product identity for a coupled integrand, no positivity. Step 4 is RH; crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ProdParamTest
import Multiplicity.F1Square.Analysis.MellinDecay

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Separable Fubini**: `∫_x ∫_y φ(x)·ψ(y) dy dx ≈ (∫_x φ)·(∫_y ψ)`. The outer integrand is
    `prodParamTest φ ψ`; its inner factorization (`prodParamTest_f_factor`) makes the integrand
    `∫_y ψ`-times-`φ(x)`, and `riemannIntegralI_Rsmul` pulls the constant `∫_y ψ` out of the
    `x`-integral. Moduli reconciled by certificate independence + the `Q`-assoc bridge. -/
theorem separable_fubini (φ ψ : L2Test) (xlo xw ylo yw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (riemannIntegralI (prodParamTest φ ψ ylo yw hylo hyw hywn).hLd
          (prodParamTest φ ψ ylo yw hylo hyw hywn).hLn
          (prodParamTest φ ψ ylo yw hylo hyw hywn).hlip
          (prodParamTest φ ψ ylo yw hylo hyw hywn).hfc xlo xw hxlo hxw hxwn)
        (Rmul (riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc xlo xw hxlo hxw hxwn)
              (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn)) := by
  -- Kψ = ∫_y ψ, Kφ = ∫_x φ; the common outer modulus Lc = φ.L + (yw·ψ.M)·φ.L
  have hLcd : 0 < (add φ.L (mul (mul yw ψ.M) φ.L)).den :=
    add_den_pos φ.hLd (Qmul_den_pos (Qmul_den_pos hyw ψ.hMd) φ.hLd)
  have hLcn : 0 ≤ (add φ.L (mul (mul yw ψ.M) φ.L)).num :=
    Qadd_num_nonneg_loc φ.hLn (Int.mul_nonneg (Int.mul_nonneg hywn ψ.hMn) φ.hLn)
  -- |∫_y ψ| ≤ yw·ψ.M
  have hKψbd : Rle (Rabs (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn))
      (ofQ (mul yw ψ.M) (Qmul_den_pos hyw ψ.hMd)) :=
    riemannIntegralI_abs_le_window ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw ψ.M hylo hyw hywn ψ.hMd
      (fun u _ _ => ψ.hbd (affineMap ylo yw hylo hyw u))
  -- the `Kψ·φ` integrand's certificates at modulus Lc
  have hgLip : ∀ x x', Rle (Rabs (Rsub
        (Rmul (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn) (φ.f x))
        (Rmul (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn) (φ.f x'))))
      (Rmul (ofQ (add φ.L (mul (mul yw ψ.M) φ.L)) hLcd) (Rabs (Rsub x x'))) :=
    lip_weaken (Qmul_den_pos (Qmul_den_pos hyw ψ.hMd) φ.hLd) hLcd (Qle_add_self φ.hLn)
      (constMul_lip (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn)
        (Qmul_den_pos hyw ψ.hMd) hKψbd φ)
  have hgFc : ∀ x x', Req x x' →
      Req (Rmul (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn) (φ.f x))
          (Rmul (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn) (φ.f x')) :=
    fun _ _ h => Rmul_congr (Req_refl _) (φ.hfc _ _ h)
  -- φ's certificate weakened to Lc
  have hφLc : ∀ x x', Rle (Rabs (Rsub (φ.f x) (φ.f x')))
      (Rmul (ofQ (add φ.L (mul (mul yw ψ.M) φ.L)) hLcd) (Rabs (Rsub x x'))) :=
    lip_weaken φ.hLd hLcd
      (Qle_self_add (Int.mul_nonneg (Int.mul_nonneg hywn ψ.hMn) φ.hLn)) φ.hlip
  -- prodParamTest's certificate weakened to Lc (through the Q-assoc bridge on PT.L = yw·(ψ.M·φ.L))
  have hassoc : Qle (mul yw (mul ψ.M φ.L)) (add φ.L (mul (mul yw ψ.M) φ.L)) :=
    Qle_trans (Qmul_den_pos (Qmul_den_pos hyw ψ.hMd) φ.hLd)
      (Qeq_le (Qeq_symm (Qmul_assoc yw ψ.M φ.L))) (Qle_add_self φ.hLn)
  have hPTLc : ∀ x x', Rle (Rabs (Rsub ((prodParamTest φ ψ ylo yw hylo hyw hywn).f x)
        ((prodParamTest φ ψ ylo yw hylo hyw hywn).f x')))
      (Rmul (ofQ (add φ.L (mul (mul yw ψ.M) φ.L)) hLcd) (Rabs (Rsub x x'))) :=
    lip_weaken (prodParamTest φ ψ ylo yw hylo hyw hywn).hLd hLcd hassoc
      (prodParamTest φ ψ ylo yw hylo hyw hywn).hlip
  -- the pointwise rewrite of the outer integrand
  have hpt : ∀ x, Req ((prodParamTest φ ψ ylo yw hylo hyw hywn).f x)
      (Rmul (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn) (φ.f x)) :=
    fun x => Req_trans (prodParamTest_f_factor φ ψ ylo yw hylo hyw hywn x)
      (Rmul_comm (φ.f x) _)
  -- (a) certif_irrel: ∫_x PT (at PT.L) ≈ ∫_x PT (at Lc)
  refine Req_trans (riemannIntegralI_certif_irrel
    (prodParamTest φ ψ ylo yw hylo hyw hywn).hLd (prodParamTest φ ψ ylo yw hylo hyw hywn).hLn
    (prodParamTest φ ψ ylo yw hylo hyw hywn).hlip (prodParamTest φ ψ ylo yw hylo hyw hywn).hfc
    hLcd hLcn hPTLc (prodParamTest φ ψ ylo yw hylo hyw hywn).hfc xlo xw hxlo hxw hxwn) ?_
  -- (b) congr: ∫_x PT (at Lc) ≈ ∫_x (Kψ·φ) (at Lc)
  refine Req_trans (riemannIntegralI_congr hLcd hLcn hPTLc
    (prodParamTest φ ψ ylo yw hylo hyw hywn).hfc hgLip hgFc xlo xw hxlo hxw hxwn hpt) ?_
  -- (c) Rsmul: ∫_x (Kψ·φ) (at Lc) ≈ Kψ·(∫_x φ at Lc)
  refine Req_trans (riemannIntegralI_Rsmul
    (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc ylo yw hylo hyw hywn) hLcd hLcn hφLc φ.hfc
    hgLip hgFc xlo xw hxlo hxw hxwn) ?_
  -- (d) certif_irrel on the φ-side, then commute the product
  refine Req_trans (Rmul_congr (Req_refl _)
    (riemannIntegralI_certif_irrel hLcd hLcn hφLc φ.hfc φ.hLd φ.hLn φ.hlip φ.hfc
      xlo xw hxlo hxw hxwn)) ?_
  exact Rmul_comm _ _

/-- **The Fubini swap for a separable integrand**: `∫_x ∫_y φ(x)·ψ(y) dy dx ≈ ∫_y ∫_x ψ(y)·φ(x) dx dy`
    — the order of integration may be swapped. Both iterated integrals factor to the same product of
    single-variable integrals (`separable_fubini` in each order), reconciled by `Rmul` commutativity;
    because the integrand is separable, NO genuine two-variable interchange is invoked. The general
    (non-separable) swap is the unbuilt wall. -/
theorem separable_fubini_swap (φ ψ : L2Test) (xlo xw ylo yw : Q)
    (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hylo : 0 < ylo.den) (hyw : 0 < yw.den) (hywn : 0 ≤ yw.num) :
    Req (riemannIntegralI (prodParamTest φ ψ ylo yw hylo hyw hywn).hLd
          (prodParamTest φ ψ ylo yw hylo hyw hywn).hLn
          (prodParamTest φ ψ ylo yw hylo hyw hywn).hlip
          (prodParamTest φ ψ ylo yw hylo hyw hywn).hfc xlo xw hxlo hxw hxwn)
        (riemannIntegralI (prodParamTest ψ φ xlo xw hxlo hxw hxwn).hLd
          (prodParamTest ψ φ xlo xw hxlo hxw hxwn).hLn
          (prodParamTest ψ φ xlo xw hxlo hxw hxwn).hlip
          (prodParamTest ψ φ xlo xw hxlo hxw hxwn).hfc ylo yw hylo hyw hywn) :=
  Req_trans (separable_fubini φ ψ xlo xw ylo yw hxlo hxw hxwn hylo hyw hywn)
    (Req_trans (Rmul_comm _ _)
      (Req_symm (separable_fubini ψ φ ylo yw xlo xw hylo hyw hywn hxlo hxw hxwn)))

end Multiplicity.UOR.Bridge.F1Square.Square
