/-
F1 square — **the pre-Hilbert layer, brick 119** (`ContinuousMomentGenNeg.lean`): **the continuous
Mellin transform is NEGATION-compatible** — `compactMomentGenLim (−φ) s ≈ −compactMomentGenLim φ s`
(`compactMomentGenLim_neg`), the second structural law of the transform pair.

WHY (the Sonine route, step 3, the transform PAIR). With additivity (brick 118) this makes the
continuous transform a genuine linear map on the test class (subtraction follows, next brick). The
proof mirrors additivity: at each floor the compact moment flips sign (`innerI_neg_left`,
`compactMoment (−φ) = −compactMoment φ`, using `(−φ).M = φ.M` so brick 117 gives the same rate), and
`Req_of_geom_rate` passes the two-floor bound to the limit.

HONEST SCOPE. Negation-compatibility of the continuous transform. NOT the full pairing/inversion.
Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentGenLinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|a − b| = |b − a|` (local copy). -/
private theorem abs_sub_swap2 (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

/-- Distance triangle through a midpoint (local copy). -/
private theorem abs_sub_tri2 (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- `|(−a) − (−b)| = |a − b|` — negation is an isometry of the distance. -/
private theorem abs_sub_neg2 (a b : Real) : Req (Rabs (Rsub (Rneg a) (Rneg b))) (Rabs (Rsub a b)) := by
  refine Req_trans (Rabs_congr ?_) (Rabs_Rneg (Rsub a b))
  exact Req_trans (Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_Rneg b)) (Radd_comm (Rneg a) b))
    (Req_symm (Rneg_Rsub a b))

set_option maxHeartbeats 1600000 in
/-- **★ THE CONTINUOUS TRANSFORM IS NEGATION-COMPATIBLE**: `compactMomentGenLim (−φ) s ≈
    −compactMomentGenLim φ s`. At each floor `innerI_neg_left` flips the sign; the brick-117 rate on
    `−φ` and `φ` (equal, since `(−φ).M = φ.M`) controls the limit; `Req_of_geom_rate` closes it. -/
theorem compactMomentGenLim_neg (φ : L2Test) {s : Real} (hs : Rnonneg s) (σ : Q) (hσd : 0 < σ.den)
    (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) :
    Req (compactMomentGenLim (L2Test.neg φ) hs σ hσd hσn hsB)
        (Rneg (compactMomentGenLim φ hs σ hσd hσn hsB)) := by
  refine Req_of_geom_rate (add (mul φ.M (⟨2, 1⟩ : Q)) (mul φ.M (⟨2, 1⟩ : Q)))
    (Qadd_num_nonneg_loc (Qmul_num_nonneg φ.hMn (by decide)) (Qmul_num_nonneg φ.hMn (by decide)))
    (add_den_pos (Qmul_den_pos φ.hMd (by decide)) (Qmul_den_pos φ.hMd (by decide))) (fun m => ?_)
  have hFn : Req (compactMomentF (L2Test.neg φ) m hs σ hσd hσn hsB)
      (Rneg (compactMomentF φ m hs σ hσd hσn hsB)) :=
    innerI_neg_left φ (compactPowTestF m hs σ hσd hσn hsB)
  have hRn := compactMomentF_dist_lim (L2Test.neg φ) hs σ hσd hσn hsB m
  have hRφ := compactMomentF_dist_lim φ hs σ hσd hσn hsB m
  refine Rle_trans (abs_sub_tri2 (compactMomentGenLim (L2Test.neg φ) hs σ hσd hσn hsB)
    (Rneg (compactMomentF φ m hs σ hσd hσn hsB))
    (Rneg (compactMomentGenLim φ hs σ hσd hσn hsB))) ?_
  -- first term ≤ C_φ/2^m
  have hfst : Rle (Rabs (Rsub (compactMomentGenLim (L2Test.neg φ) hs σ hσd hσn hsB)
      (Rneg (compactMomentF φ m hs σ hσd hσn hsB))))
      (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos m))) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _) (Req_symm hFn)))) ?_
    exact Rle_trans (Rle_of_Req (abs_sub_swap2 _ _)) hRn
  -- second term ≤ C_φ/2^m
  have hsnd : Rle (Rabs (Rsub (Rneg (compactMomentF φ m hs σ hσd hσn hsB))
      (Rneg (compactMomentGenLim φ hs σ hσd hσn hsB))))
      (ofQ (mul (mul φ.M (⟨2, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd (by decide)) (two_pow_pos m))) :=
    Rle_trans (Rle_of_Req (abs_sub_neg2 _ _)) hRφ
  refine Rle_trans (Radd_le_add hfst hsnd) (Rle_of_Req ?_)
  refine Req_trans (Radd_ofQ_ofQ _ _) (ofQ_congr _ _ ?_)
  simp only [Qeq, add, mul]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
