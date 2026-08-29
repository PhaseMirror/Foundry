/-
F1 square — **the compact Mellin moment is Lipschitz in the real dilation scale**
(`MellinMomentScaleLip.lean`): the map `c ↦ mellinMoment (dilateTestR c φ) n = ∫₀¹ φ(c·x)·clamp01(x)ⁿ`
is Lipschitz in the REAL scale `c`, with the rational constant `φ.L`.

WHY (rung 6, the real-scale gate of the transform bridge). The half-line dilation covariance
`s^(n+1)·mellinHat(dilate_s φ) = mellinHat φ` is already UNCONDITIONAL for a RATIONAL scale
(`mellinHat_dilate_covariance_uncond`). The factorization consumer `dilMellinF` carries a REAL scale
`clampedInv(a,t)`, so the covariance must be pushed from rational to real scale. Because the half-line
is scale-invariant (no real-window barrier), the extension goes by rational approximation `q_k → c`
plus CONTINUITY of `mellinHat (dilate_· φ)` in the scale. This file supplies the reusable engine of
that continuity on the compact `[0,1]` piece: the moment is `φ.L`-Lipschitz in `c`. The key algebra is
that `dilateTestR c φ` and `dilateTestR c' φ` share the SAME `L = φ.L·S` and `M = φ.M` (both
independent of the scale), so the two integrands sit at one common modulus and a `[0,1]`-window
distance estimate applies; the pointwise integrand difference is
`|φ(c·x) − φ(c'·x)|·|clamp01(x)ⁿ| ≤ φ.L·|c−c'|·|x|·1 ≤ φ.L·|c−c'|` on the unit window.

HONEST SCOPE. Lipschitz-in-scale of the compact `[0,1]` moment only, plus the auxiliary
`powTest`-bounded-by-`1` fact and a reusable `[0,1]`-window integral-distance estimate. It builds NO
tail continuity, NO half-line real-scale covariance, NO factorization, NO positivity, NO determinacy,
NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.DilateTestR
import Foundations.F1.Square.TestAlgebra
import Foundations.F1.Square.MulConvRLip
import Foundations.F1.Analysis.IntegralLocal

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The clamped monomial test is bounded by `1`**: `|clamp01(x)ⁿ| ≤ 1` for every `n` and `x`. By
    induction — `powTest 0 = oneTest` (value `1`), and `powTest (n+1) x = powTest n x · clamp01 x`
    with both factors in `[-1,1]` (`|clamp01 x| ≤ 1`). The unit weight bound the moment's
    scale-Lipschitz estimate multiplies against. -/
theorem powTest_abs_le_one : ∀ (n : Nat) (x : Real), Rle (Rabs ((powTest n).f x)) one
  | 0, _ => by
      show Rle (Rabs one) one
      exact Rle_of_Req (Rabs_of_nonneg Rnonneg_one)
  | n + 1, x => by
      show Rle (Rabs (Rmul ((powTest n).f x) (clamp01 x))) one
      refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
      refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (clamp01 x)) (powTest_abs_le_one n x)) ?_
      refine Rle_trans (Rmul_le_Rmul_left Rnonneg_one (clamp01_abs x)) ?_
      exact Rle_of_Req (Rone_mul one)

/-- **`[0,1]`-window integral-distance estimate**: two integrands `f, h` at a shared modulus `L`,
    differing by at most a real `K ≥ 0` on `[0,1]`, have `|∫₀¹ f − ∫₀¹ h| ≤ K`. The unit-window
    (`w = 1`) analog of `riemannIntegralI_dist_le_window`: two one-directional comparisons
    `∫p ≤ ∫(q+K) = ∫q + K` (`riemannIntegral_le_unit` + `riemannIntegral_add` +
    `riemannIntegral_const_gen`), joined by `Rabs_le_of_both`. -/
private theorem riemannIntegral_dist_le_unit {f h : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hliph : ∀ x y, Rle (Rabs (Rsub (h x) (h y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfch : ∀ x y, Req x y → Req (h x) (h y))
    (K : Real)
    (hdiff : ∀ x, Rle zero x → Rle x one → Rle (Rabs (Rsub (f x) (h x))) K) :
    Rle (Rabs (Rsub (riemannIntegral hLd hLn hlipf hfcf)
                    (riemannIntegral hLd hLn hliph hfch))) K := by
  have hzL : Qle (⟨0, 1⟩ : Q) L := by
    show (0 : Int) * (L.den : Int) ≤ L.num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hLn
  have hlipK : ∀ x y, Rle (Rabs (Rsub K K)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (L := (⟨0, 1⟩ : Q)) (by decide) hLd hzL (const_lip0 K)
  have hconstK : Req (riemannIntegral hLd hLn hlipK (fun _ _ _ => Req_refl K)) K :=
    riemannIntegral_const_gen K hLd hLn hlipK (fun _ _ _ => Req_refl K)
  -- Generic one-directional comparison: `∫p ≤ ∫q + K` when `p ≤ q + K` on `[0,1]`.
  have oneway : ∀ (p q : Real → Real)
      (hlipp : ∀ x y, Rle (Rabs (Rsub (p x) (p y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
      (hfcp : ∀ x y, Req x y → Req (p x) (p y))
      (hlipq : ∀ x y, Rle (Rabs (Rsub (q x) (q y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
      (hfcq : ∀ x y, Req x y → Req (q x) (q y)),
      (∀ x, Rle zero x → Rle x one → Rle (p x) (Radd (q x) K)) →
      Rle (Rsub (riemannIntegral hLd hLn hlipp hfcp)
                (riemannIntegral hLd hLn hlipq hfcq)) K := by
    intro p q hlipp hfcp hlipq hfcq hpq
    have hlipqK : ∀ x y, Rle (Rabs (Rsub (Radd (q x) K) (Radd (q y) K)))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
      intro x y
      refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans (Rsub_Radd_Radd (q x) K (q y) K)
        (Req_trans (Radd_congr (Req_refl (Rsub (q x) (q y))) (Radd_neg K))
          (Radd_zero (Rsub (q x) (q y))))))) (hlipq x y)
    have hfcqK : ∀ x y, Req x y → Req (Radd (q x) K) (Radd (q y) K) :=
      fun x y hxy => Radd_congr (hfcq x y hxy) (Req_refl K)
    have hadd : Req (riemannIntegral hLd hLn hlipqK hfcqK)
        (Radd (riemannIntegral hLd hLn hlipq hfcq)
              (riemannIntegral hLd hLn hlipK (fun _ _ _ => Req_refl K))) :=
      riemannIntegral_add hLd hLn hlipq hfcq hlipK (fun _ _ _ => Req_refl K) hlipqK hfcqK
    have hle : Rle (riemannIntegral hLd hLn hlipp hfcp)
        (riemannIntegral hLd hLn hlipqK hfcqK) :=
      riemannIntegral_le_unit hLd hLn hlipp hfcp hlipqK hfcqK hpq
    refine Rsub_le_of_le_Radd (Rle_trans hle (Rle_of_Req ?_))
    exact Req_trans hadd (Radd_congr (Req_refl _) hconstK)
  have hpqf : ∀ x, Rle zero x → Rle x one → Rle (f x) (Radd (h x) K) :=
    fun x h0 h1 => Rle_Radd_of_Rsub_le (Rle_trans (Rle_Rabs_self _) (hdiff x h0 h1))
  have hpqh : ∀ x, Rle zero x → Rle x one → Rle (h x) (Radd (f x) K) :=
    fun x h0 h1 => Rle_Radd_of_Rsub_le (Rle_trans
      (Rle_of_Req (Req_symm (Rneg_Rsub_flip (f x) (h x))))
      (Rle_trans (Rle_Rabs_self _) (Rle_trans (Rle_of_Req (Rabs_Rneg _)) (hdiff x h0 h1))))
  refine Rabs_le_of_both (oneway f h hlipf hfcf hliph hfch hpqf) ?_
  exact Rle_trans (Rle_of_Req (Rneg_Rsub_flip _ _)) (oneway h f hliph hfch hlipf hfcf hpqh)

/-- **The compact Mellin moment is Lipschitz in the real dilation scale.** For real scales `c, c'`
    each bounded by the rational `S`,

      `|mellinMoment (dilateTestR c φ) n − mellinMoment (dilateTestR c' φ) n| ≤ φ.L · |c − c'|`.

    Both dilated tests carry the same modulus `L = φ.L·S` and bound `M = φ.M` (independent of the
    scale), so their two moment integrands sit at one common modulus `l2L (dilateTestR c φ)
    (powTest n)`; the pointwise difference `|φ(c·x) − φ(c'·x)|·|clamp01(x)ⁿ| ≤ φ.L·|c−c'|·|x|·1`
    is `≤ φ.L·|c−c'|` on the unit window (`|x| ≤ 1`, `|clamp01(x)ⁿ| ≤ 1`), and the `[0,1]`-window
    distance estimate delivers the integral bound. The continuity engine of the rung-6 rational→real
    scale extension of the half-line dilation covariance. -/
theorem mellinMoment_scale_lipschitz (φ : L2Test) (n : Nat)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c c' : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc'S : Rle (Rabs c') (ofQ S hSd)) :
    Rle (Rabs (Rsub (mellinMoment (dilateTestR c S hSd hSn hcS φ) n)
                    (mellinMoment (dilateTestR c' S hSd hSn hc'S φ) n)))
        (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub c c'))) := by
  have hKnn : Rnonneg (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub c c'))) :=
    Rnonneg_Rmul (Rnonneg_ofQ φ.hLd φ.hLn) (Rnonneg_Rabs _)
  -- Pointwise integrand-difference bound on the unit window.
  have hdiff : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (Rsub (Rmul ((dilateTestR c S hSd hSn hcS φ).f x) ((powTest n).f x))
                      (Rmul ((dilateTestR c' S hSd hSn hc'S φ).f x) ((powTest n).f x))))
        (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub c c'))) := by
    intro x h0 h1
    have hxle1 : Rle (Rabs x) one :=
      Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_of_Rle_zero h0))) h1
    -- Factor the shared weight out of the integrand difference.
    refine Rle_trans (Rle_of_Req (Req_trans
      (Rabs_congr (Req_symm (Rmul_sub_distrib_right
        ((dilateTestR c S hSd hSn hcS φ).f x)
        ((dilateTestR c' S hSd hSn hc'S φ).f x) ((powTest n).f x))))
      (Rabs_Rmul (Rsub ((dilateTestR c S hSd hSn hcS φ).f x)
        ((dilateTestR c' S hSd hSn hc'S φ).f x)) ((powTest n).f x)))) ?_
    -- The dilated `φ`-difference (scale inside `φ`) is `≤ φ.L·|c−c'|`.
    have hA : Rle (Rabs (Rsub ((dilateTestR c S hSd hSn hcS φ).f x)
          ((dilateTestR c' S hSd hSn hc'S φ).f x)))
        (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub c c'))) := by
      refine Rle_trans (φ.hlip (Rmul c x) (Rmul c' x)) ?_
      refine Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn) ?_
      refine Rle_trans (Rle_of_Req (Req_trans
        (Rabs_congr (Req_symm (Rmul_sub_distrib_right c c' x)))
        (Rabs_Rmul (Rsub c c') x))) ?_
      refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs (Rsub c c')) hxle1) ?_
      exact Rle_of_Req (Rmul_one (Rabs (Rsub c c')))
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs ((powTest n).f x)) hA) ?_
    refine Rle_trans (Rmul_le_Rmul_left hKnn (powTest_abs_le_one n x)) ?_
    exact Rle_of_Req (Rmul_one (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub c c'))))
  -- Both moments are `[0,1]` integrals at the common modulus `l2L (dilateTestR c φ) (powTest n)`.
  exact riemannIntegral_dist_le_unit
    (l2L_den (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2L_num (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2lip (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2fc (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2lip (dilateTestR c' S hSd hSn hc'S φ) (powTest n))
    (l2fc (dilateTestR c' S hSd hSn hc'S φ) (powTest n))
    (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub c c'))) hdiff

end Multiplicity.UOR.Bridge.F1Square.Square
