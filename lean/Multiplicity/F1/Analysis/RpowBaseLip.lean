/-
F1 square — **the real power `xᵏ` is base-Lipschitz on a bounded domain** (`RpowBaseLip.lean`): for
real `x, y` with `|x|, |y| ≤ B` (rational `B ≥ 0`), the iterated real power `Rpow` obeys

    `|xᵏ⁺¹ − yᵏ⁺¹|  ≤  (k+1)·Bᵏ · |x − y|`.

The standard telescoping estimate `xⁿ − yⁿ = (x − y)·Σ xⁱyⁿ⁻¹⁻ⁱ`, here as an induction: the abs-bound
`|xᵏ| ≤ Bᵏ` (`Rpow_abs_le`) plus the mixed-product identity
`x·Pₓ − y·Pᵧ = x·(Pₓ − Pᵧ) + (x − y)·Pᵧ` (`mixed_id`) give the step
`|xᵏ⁺² − yᵏ⁺²| ≤ B·((k+1)·Bᵏ·|x−y|) + |x−y|·Bᵏ⁺¹ = (k+2)·Bᵏ⁺¹·|x−y|`.

WHY (rung 6, the polynomial-factor continuity for the covariance capstone). The real-scale dilation
covariance `cⁿ⁺¹·mellinHat(dilateTestR c φ) = mellinHat φ` approximates `c` by rationals `q_k → c`; the
outer polynomial factor `cⁿ⁺¹` must be shown close to `q_kⁿ⁺¹` at the rate `|c − q_k|`. This lemma
supplies exactly that (`B = S` the common scale bound, exponent `n+1`, giving `(n+1)·Sⁿ·|c − q_k|`),
the companion of the already-committed Mellin scale-continuity `mellinHat_scale_split`.

HONEST SCOPE. A general Bishop-real base-Lipschitz bound for the iterated power only. It builds NO
covariance, NO factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.Pow
import Multiplicity.F1Square.Analysis.ExpGen
import Multiplicity.F1Square.Analysis.RealPow
import Multiplicity.F1Square.Analysis.RabsLemmas
import Multiplicity.F1Square.Analysis.ThetaLipschitz
import Multiplicity.F1Square.Analysis.DyadicIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The power's absolute value is bounded by the base power**: `|x| ≤ B ⟹ |xᵏ| ≤ Bᵏ`. Induction:
    `|x·xᵏ| = |x|·|xᵏ| ≤ B·Bᵏ = Bᵏ⁺¹`. -/
private theorem Rpow_abs_le {x : Real} {B : Q} (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hxB : Rle (Rabs x) (ofQ B hBd)) :
    ∀ k, Rle (Rabs (Rpow x k)) (ofQ (qpow B k) (qpow_den_pos hBd k))
  | 0 => Rle_of_Req (Rabs_of_nonneg Rnonneg_one)
  | (k + 1) => by
      show Rle (Rabs (Rmul x (Rpow x k))) (ofQ (qpow B (k + 1)) (qpow_den_pos hBd (k + 1)))
      refine Rle_trans (Rle_of_Req (Rabs_Rmul x (Rpow x k))) ?_
      refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (Rpow x k)) hxB) ?_
      refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hBd hBn) (Rpow_abs_le hBd hBn hxB k)) ?_
      exact Rle_of_Req (Rmul_ofQ_ofQ hBd (qpow_den_pos hBd k))

/-- **The mixed-product telescoping identity** `x·Pₓ − y·Pᵧ ≈ x·(Pₓ − Pᵧ) + (x − y)·Pᵧ`. -/
private theorem mixed_id (x y Px Py : Real) :
    Req (Rsub (Rmul x Px) (Rmul y Py))
        (Radd (Rmul x (Rsub Px Py)) (Rmul (Rsub x y) Py)) := by
  refine Req_symm ?_
  refine Req_trans (Radd_congr (Rmul_sub_distrib x Px Py) (Rmul_sub_distrib_right x y Py)) ?_
  exact Req_trans (Radd_comm _ _) (Radd_Rsub_Rsub (Rmul x Py) (Rmul y Py) (Rmul x Px))

/-- **The real power `xᵏ⁺¹` is base-Lipschitz on `|·| ≤ B`**: for `|x|, |y| ≤ B` (rational `B ≥ 0`),

      `|xᵏ⁺¹ − yᵏ⁺¹| ≤ (k+1)·Bᵏ · |x − y|`.

    Telescoping induction: base `k = 0` is `|x − y| ≤ 1·|x − y|` (`Rpow_one`); the step rewrites
    `xᵏ⁺² − yᵏ⁺²` as `x·(xᵏ⁺¹ − yᵏ⁺¹) + (x − y)·yᵏ⁺¹` (`mixed_id`), bounds `|x| ≤ B` and the two power
    factors by `Rpow_abs_le` and the induction hypothesis, and combines the constants
    `(k+1)·Bᵏ⁺¹ + Bᵏ⁺¹ = (k+2)·Bᵏ⁺¹`. The polynomial-factor continuity the covariance capstone
    consumes for `cⁿ⁺¹` vs `q_kⁿ⁺¹`. -/
theorem Rpow_base_lip {x y : Real} {B : Q} (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hxB : Rle (Rabs x) (ofQ B hBd)) (hyB : Rle (Rabs y) (ofQ B hBd)) :
    ∀ k, Rle (Rabs (Rsub (Rpow x (k + 1)) (Rpow y (k + 1))))
      (Rmul (ofQ (mul (⟨((k : Int) + 1), 1⟩ : Q) (qpow B k))
              (Qmul_den_pos Nat.one_pos (qpow_den_pos hBd k)))
        (Rabs (Rsub x y)))
  | 0 => by
      refine Rle_of_Req (Req_trans
        (Rabs_congr (Rsub_congr (Rpow_one x) (Rpow_one y))) ?_)
      exact Req_symm (Rone_mul (Rabs (Rsub x y)))
  | (k + 1) => by
      show Rle (Rabs (Rsub (Rmul x (Rpow x (k + 1))) (Rmul y (Rpow y (k + 1))))) _
      refine Rle_trans (Rle_of_Req (Rabs_congr
        (mixed_id x y (Rpow x (k + 1)) (Rpow y (k + 1))))) ?_
      refine Rle_trans (Rabs_Radd _ _) ?_
      refine Rle_trans (Radd_le_add
        (Rle_of_Req (Rabs_Rmul x (Rsub (Rpow x (k + 1)) (Rpow y (k + 1)))))
        (Rle_of_Req (Rabs_Rmul (Rsub x y) (Rpow y (k + 1))))) ?_
      refine Rle_trans (Radd_le_add
        (Rle_trans (Rmul_le_Rmul_right
            (Rnonneg_Rabs (Rsub (Rpow x (k + 1)) (Rpow y (k + 1)))) hxB)
          (Rmul_le_Rmul_left (Rnonneg_ofQ hBd hBn) (Rpow_base_lip hBd hBn hxB hyB k)))
        (Rmul_le_Rmul_left (Rnonneg_Rabs (Rsub x y)) (Rpow_abs_le hBd hBn hyB (k + 1)))) ?_
      refine Rle_of_Req ?_
      refine Req_trans (Radd_congr
        (Req_trans (Req_symm (Rmul_assoc (ofQ B hBd)
            (ofQ (mul (⟨((k : Int) + 1), 1⟩ : Q) (qpow B k))
              (Qmul_den_pos Nat.one_pos (qpow_den_pos hBd k))) (Rabs (Rsub x y))))
          (Rmul_congr (Rmul_ofQ_ofQ hBd (Qmul_den_pos Nat.one_pos (qpow_den_pos hBd k)))
            (Req_refl _)))
        (Rmul_comm (Rabs (Rsub x y)) (ofQ (qpow B (k + 1)) (qpow_den_pos hBd (k + 1))))) ?_
      refine Req_trans (Req_symm (Rmul_distrib_right _ _ _)) ?_
      refine Rmul_congr ?_ (Req_refl _)
      refine Req_trans (Radd_ofQ_ofQ _ (qpow_den_pos hBd (k + 1))) ?_
      exact ofQ_congr _ (Qmul_den_pos Nat.one_pos (qpow_den_pos hBd (k + 1)))
        (by simp only [Qeq, mul, add, qpow]; push_cast; ring_uor)

end Multiplicity.UOR.Bridge.F1Square.Analysis
