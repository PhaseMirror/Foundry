/-
F1 square — **the real-scalar pulls out of a RIGHT constant factor** (`ConstMulRight.lean`): the mirror
of `riemannIntegralI_constTestMul` for `mul ψ (constTest c)` (the constant on the RIGHT). Needed because
the reconstruction's head test is `Whead = mul (mul g (powTest n)) (constTest M[f])` — the constant
`M[f]` is the outer-RIGHT factor:

    `∫_t (ψ(t)·c) dt  =  c · ∫_t ψ(t) dt`.

WHY (grounding `v = ĝ`). `convMellinHat = ∫_t Whead` (`convMellinHat_eq_intWhead`). Pulling the constant
`M[f]` out of that integral turns it into `M[f]·∫_t(g·tⁿ) = M[f]·(compact moment of g)` — the on-window
convolution theorem `M[f⋆g] = M[f]·M[g]`, the readoff that grounds `v = ĝ`.

Same structure as `riemannIntegralI_constTestMul`, plus one `Rmul_comm` congruence to move the integrand
`ψ(t)·c` into the `c·ψ(t)` form `riemannIntegralI_Rsmul` consumes, at a common weakened modulus.

HONEST SCOPE. A scalar-linearity lemma for the interval integral. It grounds NO `v = ĝ` on its own,
builds NO factorization in closed form, applies NO step-4 positivity (RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ConstScale
import Foundations.F1.Square.MellinLinear
import Foundations.F1.Analysis.IntervalRsmul

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The real scalar pulls out of a RIGHT constant factor.** `∫_t (ψ(t)·c) = c·∫_t ψ(t)` — the mirror
    of `riemannIntegralI_constTestMul` (constant on the right). Same route: reconcile the product modulus
    `l2L ψ (constTest c)` to the common `Lc = ψ.L + (l2L ψ (constTest c))` (`riemannIntegralI_certif_irrel`),
    commute the integrand `ψ·c → c·ψ` (`riemannIntegralI_congr` via `Rmul_comm`), pull `c` out
    (`riemannIntegralI_Rsmul`), and realign `ψ` to its own modulus. -/
theorem riemannIntegralI_mulConstTest_right (c : Real) {mB : Q} (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs c) (ofQ mB hMd)) (ψ : L2Test)
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (L2Test.mul ψ (constTest c mB hMd hMn hb)).hLd
          (L2Test.mul ψ (constTest c mB hMd hMn hb)).hLn
          (L2Test.mul ψ (constTest c mB hMd hMn hb)).hlip
          (L2Test.mul ψ (constTest c mB hMd hMn hb)).hfc a w ha hw hwn)
        (Rmul c (riemannIntegralI ψ.hLd ψ.hLn ψ.hlip ψ.hfc a w ha hw hwn)) := by
  let χ := L2Test.mul ψ (constTest c mB hMd hMn hb)
  -- common modulus `Lc = ψ.L + χ.L`
  have hLcd : 0 < (add ψ.L χ.L).den := add_den_pos ψ.hLd χ.hLd
  have hLcn : 0 ≤ (add ψ.L χ.L).num := Qadd_num_nonneg_loc ψ.hLn χ.hLn
  -- ψ and `c·ψ` certified at the common modulus
  have hlipψ' := lip_weaken ψ.hLd hLcd (Qle_self_add χ.hLn) ψ.hlip
  -- `c·ψ` is `Lc`-Lipschitz: |c·ψx − c·ψy| = |c|·|ψx−ψy| ≤ mB·ψ.L·|x−y| ≤ Lc·|x−y|.
  have hlipcψ : ∀ x y, Rle (Rabs (Rsub (Rmul c (ψ.f x)) (Rmul c (ψ.f y))))
      (Rmul (ofQ (add ψ.L χ.L) hLcd) (Rabs (Rsub x y))) := by
    intro x y
    refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib c (ψ.f x) (ψ.f y))))
        (Rabs_Rmul c (Rsub (ψ.f x) (ψ.f y))))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) hb) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hMd hMn) (ψ.hlip x y)) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc (ofQ mB hMd) (ofQ ψ.L ψ.hLd) (Rabs (Rsub x y))))) ?_
    refine Rmul_le_Rmul_right (Rnonneg_Rabs _) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hMd ψ.hLd)) ?_
    refine Rle_ofQ_ofQ (Qmul_den_pos hMd ψ.hLd) hLcd ?_
    -- mB·ψ.L ≤ ψ.L + χ.L, since χ.L = l2L ψ (constTest c) = ψ.M·0 + mB·ψ.L = mB·ψ.L (Qeq)
    have hχL : Qeq χ.L (mul mB ψ.L) := by
      show Qeq (add (mul ψ.M (⟨0, 1⟩ : Q)) (mul mB ψ.L)) (mul mB ψ.L)
      simp only [Qeq, add, mul]; push_cast; ring_uor
    exact Qle_trans χ.hLd (Qeq_le (Qeq_symm hχL)) (Qle_self_add_l ψ.hLn)
  have hfccψ : ∀ x y, Req x y → Req (Rmul c (ψ.f x)) (Rmul c (ψ.f y)) :=
    fun x y h => Rmul_congr (Req_refl c) (ψ.hfc x y h)
  -- χ at the common modulus, and χ.f y = ψ(y)·c (definitional).
  have hlipχ' := lip_weaken χ.hLd hLcd (Qle_self_add_l ψ.hLn) χ.hlip
  -- reconcile χ.L → Lc ; commute ψ·c → c·ψ ; pull c out ; realign ψ Lc → ψ.L.
  refine Req_trans (riemannIntegralI_certif_irrel χ.hLd χ.hLn χ.hlip χ.hfc
    hLcd hLcn hlipχ' χ.hfc a w ha hw hwn) ?_
  refine Req_trans (riemannIntegralI_congr hLcd hLcn hlipχ' χ.hfc hlipcψ hfccψ a w ha hw hwn
    (fun y => Rmul_comm (ψ.f y) c)) ?_
  refine Req_trans (riemannIntegralI_Rsmul c hLcd hLcn hlipψ' ψ.hfc hlipcψ hfccψ a w ha hw hwn) ?_
  exact Rmul_congr (Req_refl c)
    (riemannIntegralI_certif_irrel hLcd hLcn hlipψ' ψ.hfc ψ.hLd ψ.hLn ψ.hlip ψ.hfc a w ha hw hwn)

end Multiplicity.UOR.Bridge.F1Square.Square
