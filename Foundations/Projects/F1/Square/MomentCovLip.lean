/-
F1 square — **the moment covariance combination is scale-Lipschitz** (`MomentCovLip.lean`): the object
`H(c) = cⁿ⁺¹ · mellinMoment (dilateTestR c f) n` — whose `Rlim` along a fast rational sequence is the
real-window integral `riwI` (`riwSeq_term_eq_moment`) — is Lipschitz in the REAL dilation scale `c`:

    `|H(c) − H(c')|  ≤  Sⁿ⁺¹·(f.L·(powTest n).M)·|c−c'|  +  (f.M/(n+1))·((n+1)Sⁿ)·|c−c'|`.

The MOMENT analog of `covComb_scale_split`, but with NO tail — so a clean single Lipschitz (no
`head_j`/`4/(j+1)` split). `H(c) − H(c')` splits by the mixed-product identity into
`cⁿ⁺¹·(M_c − M_c') + (cⁿ⁺¹ − c'ⁿ⁺¹)·M_c'`; the first is `|cⁿ⁺¹| ≤ Sⁿ⁺¹` times the moment
scale-continuity `window_moment_scale_lipschitz` (bridged from the `[0,1]`-interval integral to
`mellinMoment` by `riemannIntegralI_unit`), the second is the moment bound
`mellinMoment_abs_le` (`f.M/(n+1)`, scale-independent) times the polynomial base-Lipschitz
`Rpow_base_lip`.

WHY (the Rlim-interchange capstone). With `H` Lipschitz and `qk → c` fast, `Rlim_k H(qk k) = H(c)`,
so `riwI (f·powBandGen_{[0,B]}) = c^{n+1}·mellinMoment(dilateTestR c f) n` — the real-scale moment
covariance, i.e. the factorization's inner integral evaluated at a real scale.

HONEST SCOPE. The scale-Lipschitz continuity of the moment covariance combination `H`. It builds NO
`Rlim` interchange (the capstone), NO real-scale moment covariance, NO half-line assembly, NO
factorization, NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.WindowMomentScaleLip
import Foundations.F1.Square.MomentDecay
import Foundations.F1.Square.IntervalMinorant
import Foundations.F1.Analysis.RpowBaseLip

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- local re-derivations of the two CovCombScaleCont privates
private theorem Rpow_abs_le_loc {x : Real} {B : Q} (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hxB : Rle (Rabs x) (ofQ B hBd)) :
    ∀ k, Rle (Rabs (Rpow x k)) (ofQ (qpow B k) (qpow_den_pos hBd k))
  | 0 => Rle_of_Req (Rabs_of_nonneg Rnonneg_one)
  | (k + 1) => by
      show Rle (Rabs (Rmul x (Rpow x k))) (ofQ (qpow B (k + 1)) (qpow_den_pos hBd (k + 1)))
      refine Rle_trans (Rle_of_Req (Rabs_Rmul x (Rpow x k))) ?_
      refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (Rpow x k)) hxB) ?_
      refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hBd hBn) (Rpow_abs_le_loc hBd hBn hxB k)) ?_
      exact Rle_of_Req (Rmul_ofQ_ofQ hBd (qpow_den_pos hBd k))

private theorem mixed_id_loc (x y Px Py : Real) :
    Req (Rsub (Rmul x Px) (Rmul y Py))
        (Radd (Rmul x (Rsub Px Py)) (Rmul (Rsub x y) Py)) := by
  refine Req_symm ?_
  refine Req_trans (Radd_congr (Rmul_sub_distrib x Px Py) (Rmul_sub_distrib_right x y Py)) ?_
  exact Req_trans (Radd_comm _ _) (Radd_Rsub_Rsub (Rmul x Py) (Rmul y Py) (Rmul x Px))

/-- **The `[0,1]`-interval integral of `dilateTestR c f · powTest n` is the moment.** -/
private theorem moment_eq_interval (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) :
    Req (mellinMoment (dilateTestR c S hSd hSn hcS φ) n)
        (riemannIntegralI (l2L_den (dilateTestR c S hSd hSn hcS φ) (powTest n))
          (l2L_num (dilateTestR c S hSd hSn hcS φ) (powTest n))
          (l2lip (dilateTestR c S hSd hSn hcS φ) (powTest n))
          (l2fc (dilateTestR c S hSd hSn hcS φ) (powTest n))
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)) :=
  Req_symm (riemannIntegralI_unit
    (l2L_den (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2L_num (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2lip (dilateTestR c S hSd hSn hcS φ) (powTest n))
    (l2fc (dilateTestR c S hSd hSn hcS φ) (powTest n)))

/-- **The moment covariance combination `H(c) = cⁿ⁺¹·mellinMoment(dilateTestR c f) n` is
    scale-Lipschitz.** -/
theorem moment_covComb_scale_lip (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c c' : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc'S : Rle (Rabs c') (ofQ S hSd)) :
    Rle (Rabs (Rsub
          (Rmul (Rpow c (n + 1)) (mellinMoment (dilateTestR c S hSd hSn hcS φ) n))
          (Rmul (Rpow c' (n + 1)) (mellinMoment (dilateTestR c' S hSd hSn hc'S φ) n))))
        (Radd
          (Rmul (ofQ (qpow S (n + 1)) (qpow_den_pos hSd (n + 1)))
            (Rmul (ofQ (mul (⟨1, 1⟩ : Q)
                (mul (mul φ.L (add (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q))) (powTest n).M))
                (Qmul_den_pos (by decide)
                  (Qmul_den_pos (Qmul_den_pos φ.hLd (add_den_pos (by decide) (by decide)))
                    (powTest n).hMd)))
              (Rabs (Rsub c c'))))
          (Rmul (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n)))
            (Rmul (ofQ (mul (⟨(n : Int) + 1, 1⟩ : Q) (qpow S n))
                    (Qmul_den_pos Nat.one_pos (qpow_den_pos hSd n)))
              (Rabs (Rsub c c'))))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (mixed_id_loc (Rpow c (n + 1)) (Rpow c' (n + 1))
    (mellinMoment (dilateTestR c S hSd hSn hcS φ) n)
    (mellinMoment (dilateTestR c' S hSd hSn hc'S φ) n)))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Radd_le_add ?_ ?_
  · -- |cⁿ⁺¹·(M_c − M_c')| ≤ Sⁿ⁺¹ · (moment scale-Lipschitz bound)
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rpow_abs_le_loc hSd hSn hcS (n + 1))) ?_
    refine Rmul_le_Rmul_left (Rnonneg_ofQ (qpow_den_pos hSd (n + 1)) (qpow_nonneg hSn (n + 1))) ?_
    -- |M_c − M_c'| ≤ window_moment bound, bridging the moment to the [0,1]-interval integral
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
      (moment_eq_interval φ n S hSd hSn c hcS)
      (moment_eq_interval φ n S hSd hSn c' hc'S)))) ?_
    exact window_moment_scale_lipschitz φ (powTest n) S hSd hSn c c' hcS hc'S
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide)
  · -- |(cⁿ⁺¹ − c'ⁿ⁺¹)·M_c'| ≤ (moment bound) · (Rpow base-Lipschitz)
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs _)
      (mellinMoment_abs_le (dilateTestR c' S hSd hSn hc'S φ) n)) ?_
    refine Rle_trans (Rmul_le_Rmul_right ?_ (Rpow_base_lip hSd hSn hcS hc'S n)) ?_
    · exact Rnonneg_ofQ (Qmul_den_pos φ.hMd (Nat.succ_pos n))
        (Qmul_num_nonneg φ.hMn (by show (0 : Int) ≤ 1; decide))
    · exact Rle_of_Req (Rmul_comm _ _)

end Multiplicity.UOR.Bridge.F1Square.Square
