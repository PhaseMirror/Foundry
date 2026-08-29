/-
F1 square — **the constant test and the real-scalar pairing law** (`ConstScale.lean`), the Bernstein
arc, sub-brick H₃. The Bernstein operator `B_n(φ)(x) = Σ_k φ(k/n)·b_{n,k}(x)` has REAL coefficients
`φ(k/n)`; a real scalar cannot scale an `L2Test` (whose bound must be rational), so the coefficient is
carried as a **constant test** `constTest c` (a bounded-Lipschitz test with `f ≡ c`, bound the rational
`|c| ≤ mB`), multiplied into the basis by the test algebra. The pairing then obeys the real-scalar law

    `⟨φ, (constTest c)·ψ⟩ ≈ c·⟨φ, ψ⟩`   (`innerI_constMul`),

reducing `⟨φ, c·b_{n,k}⟩ = c·⟨φ, b_{n,k}⟩ = c·0 = 0` once the single-basis integral vanishes
(`innerI_bernBasis_zero`). The proof is the real-scalar mirror of `innerI_add_left`: certificate
weakening to a common modulus, `riemannIntegral_congr` to move `φ·(c·ψ)` to `c·(φ·ψ)`, then
`riemannIntegral_Rsmul` (the real-scalar integral law) to pull `c` out.

HONEST SCOPE. The constant test and the real-scalar case of pairing linearity. Infrastructure for the
operator integral; NOT yet the operator, NOT the deviation integral, NOT determinacy. Step 4 is RH;
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.TestAlgebra
import Foundations.F1.Analysis.IntegralRsmul

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The constant test** `f ≡ c` for a real `c` bounded by a rational `mB` — a genuine
    bounded-Lipschitz test (`0`-Lipschitz, bound `mB`), the carrier of a real coefficient in the
    test algebra. -/
def constTest (c : Real) (mB : Q) (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs c) (ofQ mB hMd)) : L2Test where
  f := fun _ => c
  L := ⟨0, 1⟩
  M := mB
  hLd := by decide
  hLn := by decide
  hMd := hMd
  hMn := hMn
  hlip := fun x y => by
    have hz : Req (Rabs (Rsub c c)) zero := Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero
    have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
    have hR : Req (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) zero :=
      Req_trans (Rmul_congr hz0 (Req_refl _)) (Req_trans (Rmul_comm zero _) (Rmul_zero _))
    exact Rle_trans (Rle_of_Req hz) (Rle_of_Req (Req_symm hR))
  hfc := fun _ _ _ => Req_refl c
  hbd := fun _ => hb

/-- **THE REAL-SCALAR PAIRING LAW**: `⟨φ, (constTest c)·ψ⟩ ≈ c·⟨φ, ψ⟩`. Mirror of `innerI_add_left`:
    the integrand `φ·(c·ψ)` is moved to `c·(φ·ψ)` (`riemannIntegral_congr`) at a common weakened
    modulus, then `riemannIntegral_Rsmul` pulls the real `c` through the integral; certificate
    independence realigns each end to its canonical certificate. -/
theorem innerI_constMul (φ ψ : L2Test) (c : Real) {mB : Q} (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs c) (ofQ mB hMd)) :
    Req (innerI φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) (Rmul c (innerI φ ψ)) := by
  -- `χ` = the constant test; `(χ·ψ)·`-integrand is `φ·(c·ψ)`, pointwise `c·(φ·ψ)`.
  have hLcd : 0 < (add (l2L φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) (l2L φ ψ)).den :=
    add_den_pos (l2L_den φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) (l2L_den φ ψ)
  have hLcn : 0 ≤ (add (l2L φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) (l2L φ ψ)).num :=
    Qadd_num_nonneg_loc (l2L_num φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) (l2L_num φ ψ)
  -- pointwise `φ·(c·ψ) ≈ c·(φ·ψ)`
  have hpt : ∀ x, Req (Rmul (φ.f x) (Rmul c (ψ.f x))) (Rmul c (Rmul (φ.f x) (ψ.f x))) := fun x =>
    Req_trans (Req_symm (Rmul_assoc (φ.f x) c (ψ.f x)))
      (Req_trans (Rmul_congr (Rmul_comm (φ.f x) c) (Req_refl (ψ.f x)))
        (Rmul_assoc c (φ.f x) (ψ.f x)))
  -- the `φ·(c·ψ)` integrand's certificates, weakened to the common modulus
  have hlipF := lip_weaken (l2L_den φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) hLcd
    (Qle_self_add (l2L_num φ ψ)) (l2lip φ (L2Test.mul (constTest c mB hMd hMn hb) ψ))
  have hfcF := l2fc φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)
  -- the `φ·ψ` integrand's certificates, weakened to the common modulus
  have hlipG := lip_weaken (l2L_den φ ψ) hLcd
    (Qle_self_add_l (l2L_num φ (L2Test.mul (constTest c mB hMd hMn hb) ψ))) (l2lip φ ψ)
  have hfcG := l2fc φ ψ
  -- the `c·(φ·ψ)` integrand's certificates (transport `hlipF` through `hpt`)
  have hlipCG : ∀ x y, Rle (Rabs (Rsub (Rmul c (Rmul (φ.f x) (ψ.f x)))
        (Rmul c (Rmul (φ.f y) (ψ.f y)))))
      (Rmul (ofQ (add (l2L φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) (l2L φ ψ)) hLcd)
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hpt x)) (Req_symm (hpt y)))))
      (hlipF x y)
  have hfcCG : ∀ x y, Req x y → Req (Rmul c (Rmul (φ.f x) (ψ.f x)))
      (Rmul c (Rmul (φ.f y) (ψ.f y))) := fun x y h => Rmul_congr (Req_refl c) (l2fc φ ψ x y h)
  -- assemble
  refine Req_trans (riemannIntegral_certif_irrel
    (l2L_den φ (L2Test.mul (constTest c mB hMd hMn hb) ψ))
    (l2L_num φ (L2Test.mul (constTest c mB hMd hMn hb) ψ))
    (l2lip φ (L2Test.mul (constTest c mB hMd hMn hb) ψ))
    (l2fc φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) hLcd hLcn hlipF hfcF) ?_
  refine Req_trans (riemannIntegral_congr hLcd hLcn hlipF hfcF hlipCG hfcCG hpt) ?_
  refine Req_trans (riemannIntegral_Rsmul c hLcd hLcn hlipG hfcG hlipCG hfcCG) ?_
  exact Rmul_congr (Req_refl c)
    (riemannIntegral_certif_irrel hLcd hLcn hlipG hfcG
      (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ))

/-- **THE CONSTANT-SCALED BASIS PAIRS TO ZERO**: if `⟨φ, ψ⟩ ≈ 0` then `⟨φ, (constTest c)·ψ⟩ ≈ 0` — the
    real coefficient multiplies a vanishing integral. -/
theorem innerI_constMul_zero (φ ψ : L2Test) (c : Real) {mB : Q} (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs c) (ofQ mB hMd)) (h : Req (innerI φ ψ) zero) :
    Req (innerI φ (L2Test.mul (constTest c mB hMd hMn hb) ψ)) zero :=
  Req_trans (innerI_constMul φ ψ c hMd hMn hb)
    (Req_trans (Rmul_congr (Req_refl c) h) (Rmul_zero c))

end Multiplicity.UOR.Bridge.F1Square.Square
