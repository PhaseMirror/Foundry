/-
F1 square — **general-window scale-Lipschitz of a dilated-test window integral**
(`WindowMomentScaleLip.lean`): the map `c ↦ ∫_{[lo, lo+w]} φ(c·x)·ψ(x) dx` (a window integral with the
REAL scale `c` INSIDE the test `φ`, against an arbitrary weight test `ψ`) is Lipschitz in `c`, with
the rational constant `w·φ.L·(lo+w)·ψ.M`.

WHY (rung 6, extending the continuity engine off `[0,1]`). The compact `[0,1]` moment continuity
(`mellinMoment_scale_lipschitz`) is the unit-window special case. This general-window form is the
reusable primitive the rung-6 assembly needs on TWO fronts: (i) the twisted-tail terms
`twTerm (dilate_c φ) n m = ∫_{[m+1, m+2]}(φ(c·x)·powWinTest m n)` are its instance at
`ψ = powWinTest m n` and window `[m+1, m+2]` — the finite-head continuity of the tail; (ii) the
factorization consumer `dilMellinF f ψ … t = ∫_{[xlo, xw]}(f(clamp x·clampedInv(a,t))·ψ)` is its
instance at the general window `[xlo, xw]`.

The estimate rides on the SAME two facts as the compact case, generalized off `[0,1]`: (1)
`dilateTestR c φ` and `dilateTestR c' φ` share the modulus `L = φ.L·S` and bound `M = φ.M` (both
scale-independent), so the two integrands sit at one common modulus and the general-window distance
estimate `riemannIntegralI_dist_le_window` applies; (2) on the window `[lo, lo+w]` (`lo ≥ 0`) the affine
point `p = lo + w·x` satisfies `0 ≤ p ≤ lo+w`, so the pointwise difference
`|φ(c·p) − φ(c'·p)|·|ψ(p)| ≤ φ.L·|c−c'|·(lo+w)·ψ.M`; the window width `w` then multiplies in.

HONEST SCOPE. Lipschitz-in-scale of one FIXED rational-window dilated-test integral only — a per-window
continuity primitive. It builds NO tail continuity (that needs a uniform-in-scale decay bound across the
infinitely many windows, unbuilt), NO half-line real-scale covariance, NO factorization, NO positivity,
NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.DilateTestR
import Multiplicity.F1.Square.TestAlgebra
import Multiplicity.F1.Square.MulConvRLip

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **General-window scale-Lipschitz of a dilated-test window integral.** For real scales `c, c'` each
    bounded by the rational `S`, a weight test `ψ`, and a rational window `[lo, lo+w]` with `lo ≥ 0`,

      `|∫_{[lo,w]} φ(c·x)·ψ(x) − ∫_{[lo,w]} φ(c'·x)·ψ(x)| ≤ (w · φ.L · (lo+w) · ψ.M) · |c − c'|`.

    Both dilated tests carry the same modulus `L = φ.L·S` and bound `M = φ.M` (scale-independent), so the
    two window integrands sit at one common modulus `l2L (dilateTestR c φ) ψ`; on the window the affine
    point `p = lo + w·x` has `0 ≤ p ≤ lo+w`, so the pointwise difference is
    `|φ(c·p) − φ(c'·p)|·|ψ(p)| ≤ φ.L·|c−c'|·(lo+w)·ψ.M`, and `riemannIntegralI_dist_le_window` multiplies
    by the window width `w`. The per-window continuity primitive of the rung-6 tail/`dilMellinF` fronts. -/
theorem window_moment_scale_lipschitz (φ ψ : L2Test)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c c' : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc'S : Rle (Rabs c') (ofQ S hSd))
    (lo w : Q) (hlod : 0 < lo.den) (hwd : 0 < w.den) (hlon : 0 ≤ lo.num) (hwn : 0 ≤ w.num) :
    Rle (Rabs (Rsub
          (riemannIntegralI (l2L_den (dilateTestR c S hSd hSn hcS φ) ψ)
            (l2L_num (dilateTestR c S hSd hSn hcS φ) ψ)
            (l2lip (dilateTestR c S hSd hSn hcS φ) ψ)
            (l2fc (dilateTestR c S hSd hSn hcS φ) ψ) lo w hlod hwd hwn)
          (riemannIntegralI (l2L_den (dilateTestR c' S hSd hSn hc'S φ) ψ)
            (l2L_num (dilateTestR c' S hSd hSn hc'S φ) ψ)
            (l2lip (dilateTestR c' S hSd hSn hc'S φ) ψ)
            (l2fc (dilateTestR c' S hSd hSn hc'S φ) ψ) lo w hlod hwd hwn)))
        (Rmul (ofQ (mul w (mul (mul φ.L (add lo w)) ψ.M))
                (Qmul_den_pos hwd (Qmul_den_pos (Qmul_den_pos φ.hLd (add_den_pos hlod hwd)) ψ.hMd)))
          (Rabs (Rsub c c'))) := by
  have hQ0d : 0 < (mul (mul φ.L (add lo w)) ψ.M).den :=
    Qmul_den_pos (Qmul_den_pos φ.hLd (add_den_pos hlod hwd)) ψ.hMd
  have hKnn : Rnonneg (Rmul (ofQ (mul (mul φ.L (add lo w)) ψ.M) hQ0d) (Rabs (Rsub c c'))) :=
    Rnonneg_Rmul (Rnonneg_ofQ hQ0d
      (Int.mul_nonneg (Int.mul_nonneg φ.hLn (Qadd_num_nonneg_loc hlon hwn)) ψ.hMn))
      (Rnonneg_Rabs _)
  -- Generalized pointwise bound at a free window point `p` with `0 ≤ p ≤ lo+w`.
  have hpt : ∀ p, Rnonneg p → Rle p (ofQ (add lo w) (add_den_pos hlod hwd)) →
      Rle (Rabs (Rsub (Rmul ((dilateTestR c S hSd hSn hcS φ).f p) (ψ.f p))
                      (Rmul ((dilateTestR c' S hSd hSn hc'S φ).f p) (ψ.f p))))
        (Rmul (ofQ (mul (mul φ.L (add lo w)) ψ.M) hQ0d) (Rabs (Rsub c c'))) := by
    intro p hp_nn hp_hi
    have hp_abs : Rle (Rabs p) (ofQ (add lo w) (add_den_pos hlod hwd)) :=
      Rle_trans (Rle_of_Req (Rabs_of_nonneg hp_nn)) hp_hi
    refine Rle_trans (Rle_of_Req (Req_trans
      (Rabs_congr (Req_symm (Rmul_sub_distrib_right
        ((dilateTestR c S hSd hSn hcS φ).f p) ((dilateTestR c' S hSd hSn hc'S φ).f p) (ψ.f p))))
      (Rabs_Rmul (Rsub ((dilateTestR c S hSd hSn hcS φ).f p)
        ((dilateTestR c' S hSd hSn hc'S φ).f p)) (ψ.f p)))) ?_
    have hA : Rle (Rabs (Rsub ((dilateTestR c S hSd hSn hcS φ).f p)
          ((dilateTestR c' S hSd hSn hc'S φ).f p)))
        (Rmul (ofQ φ.L φ.hLd)
          (Rmul (Rabs (Rsub c c')) (ofQ (add lo w) (add_den_pos hlod hwd)))) := by
      refine Rle_trans (φ.hlip (Rmul c p) (Rmul c' p)) ?_
      refine Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn) ?_
      refine Rle_trans (Rle_of_Req (Req_trans
        (Rabs_congr (Req_symm (Rmul_sub_distrib_right c c' p)))
        (Rabs_Rmul (Rsub c c') p))) ?_
      exact Rmul_le_Rmul_left (Rnonneg_Rabs (Rsub c c')) hp_abs
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (ψ.f p)) hA) ?_
    refine Rle_trans (Rmul_le_Rmul_left
      (Rnonneg_Rmul (Rnonneg_ofQ φ.hLd φ.hLn)
        (Rnonneg_Rmul (Rnonneg_Rabs (Rsub c c')) (Rnonneg_ofQ (add_den_pos hlod hwd)
          (Qadd_num_nonneg_loc hlon hwn)))) (ψ.hbd p)) ?_
    refine Rle_of_Req ?_
    refine Req_trans (Rmul_assoc (ofQ φ.L φ.hLd)
      (Rmul (Rabs (Rsub c c')) (ofQ (add lo w) (add_den_pos hlod hwd))) (ofQ ψ.M ψ.hMd)) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Req_trans (Rmul_assoc (Rabs (Rsub c c')) (ofQ (add lo w) (add_den_pos hlod hwd))
        (ofQ ψ.M ψ.hMd))
        (Rmul_comm (Rabs (Rsub c c'))
          (Rmul (ofQ (add lo w) (add_den_pos hlod hwd)) (ofQ ψ.M ψ.hMd))))) ?_
    refine Req_trans (Req_symm (Rmul_assoc (ofQ φ.L φ.hLd)
      (Rmul (ofQ (add lo w) (add_den_pos hlod hwd)) (ofQ ψ.M ψ.hMd)) (Rabs (Rsub c c')))) ?_
    refine Rmul_congr ?_ (Req_refl _)
    refine Req_trans (Req_symm (Rmul_assoc (ofQ φ.L φ.hLd)
      (ofQ (add lo w) (add_den_pos hlod hwd)) (ofQ ψ.M ψ.hMd))) ?_
    exact Req_trans
      (Rmul_congr (Rmul_ofQ_ofQ φ.hLd (add_den_pos hlod hwd)) (Req_refl _))
      (Rmul_ofQ_ofQ (Qmul_den_pos φ.hLd (add_den_pos hlod hwd)) ψ.hMd)
  -- Instantiate at the affine window point, discharging its membership `0 ≤ p ≤ lo+w`.
  have hdiff : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (Rsub
            (Rmul ((dilateTestR c S hSd hSn hcS φ).f (affineMap lo w hlod hwd x))
                  (ψ.f (affineMap lo w hlod hwd x)))
            (Rmul ((dilateTestR c' S hSd hSn hc'S φ).f (affineMap lo w hlod hwd x))
                  (ψ.f (affineMap lo w hlod hwd x)))))
        (Rmul (ofQ (mul (mul φ.L (add lo w)) ψ.M) hQ0d) (Rabs (Rsub c c'))) := by
    intro x h0 h1
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero h0
    have hp_lo : Rle (ofQ lo hlod) (affineMap lo w hlod hwd x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hwd hwn) hxnn)
    have hp_nn : Rnonneg (affineMap lo w hlod hwd x) :=
      Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ hlod hlon)) hp_lo)
    have hp_hi : Rle (affineMap lo w hlod hwd x) (ofQ (add lo w) (add_den_pos hlod hwd)) :=
      Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _))
          (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hwd hwn) h1)
            (Rle_of_Req (Rmul_one (ofQ w hwd)))))
        (Rle_of_Req (Radd_ofQ_ofQ hlod hwd))
    exact hpt (affineMap lo w hlod hwd x) hp_nn hp_hi
  refine Rle_trans
    (riemannIntegralI_dist_le_window (l2L_den (dilateTestR c S hSd hSn hcS φ) ψ)
      (l2L_num (dilateTestR c S hSd hSn hcS φ) ψ)
      (l2lip (dilateTestR c S hSd hSn hcS φ) ψ) (l2fc (dilateTestR c S hSd hSn hcS φ) ψ)
      (l2lip (dilateTestR c' S hSd hSn hc'S φ) ψ) (l2fc (dilateTestR c' S hSd hSn hc'S φ) ψ)
      lo w (Rmul (ofQ (mul (mul φ.L (add lo w)) ψ.M) hQ0d) (Rabs (Rsub c c')))
      hlod hwd hwn hKnn hdiff) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ w hwd)
    (ofQ (mul (mul φ.L (add lo w)) ψ.M) hQ0d) (Rabs (Rsub c c')))) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ hwd hQ0d) (Req_refl _)

end Multiplicity.UOR.Bridge.F1Square.Square
