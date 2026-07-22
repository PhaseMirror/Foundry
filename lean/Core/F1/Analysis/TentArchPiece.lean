/-
F1 square — **the tent test's archimedean-tail `[1,2]` piece, CONSTRUCTED and EVALUATED**
(`TentArchPiece.lean`):

    `∫_{1}^{2} −(1 + 2/x − 4/(x+1)) dx  ≈  −(1 + 2·log 2 − 4·(log 3 − log 2))`
                                        `=  −1 − 6·log 2 + 4·log 3`     (`tent_arch12`)

— the compact part of the tent's archimedean tail (the PV-cancelled integrand on the support;
the improper part past the support, `∫_2^∞ −2/(x²−1) = −log 3`, is the remaining brick; the
full tail is `−1 − 6·log 2 + 3·log 3`).

HOW. The integrand is totalized with the floor-1 clamp only (`x ≥ 1`, `x+1 ≥ 2` on the
domain); the affine pullback `x = 1+t` is POINTWISE congruent to
`−(1 + 2·gRecip t − 4·gRecip32 t)`, and gateway linearity reduces the value to the two
certified reciprocal integrals `∫₀¹ dx/(1+x) ≈ log 2` (`HarmonicLog.lean`) and
`∫₀¹ dx/(2+x) ≈ log 3 − log 2` (`HarmonicLog32.lean`).

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.HarmonicLog32
import Core.F1.Analysis.TentLogPiece

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The totalized integrand and its Lipschitz datum on the x-domain.
-- ===========================================================================

/-- The `[1,2]` archimedean-tail integrand `−(1 + 2/x − 4/(x+1))`, totalized with the
    floor-1 clamp (`x ≥ 1` and `x+1 ≥ 2` on the domain, so both clamps are inert). -/
def tentArch1 : Real → Real :=
  fun u => Rneg (Radd one
    (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (clampedInv ⟨1, 1⟩ (by decide) (by decide) u))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
        (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd one u)))))

/-- `|2·cI(x) − 2·cI(y)| ≤ 2·|x−y|` (the direct clamp core at factor 2). -/
private theorem s2c_lip (x y : Real) :
    Rle (Rabs (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (clampedInv ⟨1, 1⟩ (by decide) (by decide) x))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (clampedInv ⟨1, 1⟩ (by decide) (by decide) y))))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) x y)) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨2, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))

/-- `|4·cI(1+x) − 4·cI(1+y)| ≤ 4·|x−y|` (the shifted clamp core at factor 4). -/
private theorem s4shift_lip (x y : Real) :
    Rle (Rabs (Rsub (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
        (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd one x)))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
        (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd one y)))))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨4, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide)
      (Radd one x) (Radd one y))
      (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr (Req_trans
        (Rsub_Radd_Radd one x one y)
        (Req_trans (Radd_congr (Radd_neg one) (Req_refl (Rsub x y)))
          (Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y)))))))))) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨4, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))

/-- The `2·A + 4·A ≈ 6·A` collapse. -/
private theorem two_add_four_smul (A : Real) :
    Req (Radd (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) A)
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) A))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) A) := by
  refine Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨2, 1⟩ : Q) (by decide))
    (ofQ (⟨4, 1⟩ : Q) (by decide)) A)) ?_
  refine Rmul_congr ?_ (Req_refl A)
  exact Req_trans (Radd_ofQ_ofQ (a := (⟨2, 1⟩ : Q)) (b := (⟨4, 1⟩ : Q))
    (by decide) (by decide))
    (ofQ_congr (a := add ⟨2, 1⟩ ⟨4, 1⟩) (b := (⟨6, 1⟩ : Q)) (by decide) (by decide)
      (by decide))

/-- The difference shape `(P−Q) − (P'−Q') ≈ (P−P') + (Q'−Q)`. -/
private theorem sub_pair_split (P Q P' Q' : Real) :
    Req (Rsub (Rsub P Q) (Rsub P' Q')) (Radd (Rsub P P') (Rsub Q' Q)) :=
  Req_trans (Rsub_Radd_Radd P (Rneg Q) P' (Rneg Q'))
    (Radd_congr (Req_refl (Rsub P P')) (Rsub_Rneg_pair Q Q'))

/-- `tentArch1` is `6`-Lipschitz. -/
theorem tentArch1_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (tentArch1 x) (tentArch1 y)))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  -- `A(x) − A(y) ≈ Sy − Sx` (neg + const drop), `S := 2·cI − 4·cI(1+·)`
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_Rneg_pair _ _)
    (Req_trans (Rsub_Radd_Radd one _ one _)
      (Req_trans (Radd_congr (Radd_neg one) (Req_refl _))
        (Req_trans (Radd_comm zero _) (Radd_zero _))))))) ?_
  -- `Sy − Sx ≈ (Py−Px) + (Qx−Qy)`
  refine Rle_trans (Rle_of_Req (Rabs_congr (sub_pair_split _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add
    (Rle_trans (s2c_lip y x)
      (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))))
    (s4shift_lip x y)) ?_
  exact Rle_of_Req (two_add_four_smul (Rabs (Rsub x y)))

/-- `tentArch1` respects `≈`. -/
theorem tentArch1_congr : ∀ x y : Real, Req x y → Req (tentArch1 x) (tentArch1 y) :=
  fun _ _ h => Rneg_congr (Radd_congr (Req_refl one) (Rsub_congr
    (Rmul_congr (Req_refl _) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) h))
    (Rmul_congr (Req_refl _) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (Radd_congr (Req_refl one) h)))))

-- ===========================================================================
-- The pullback is pointwise `−(1 + 2·gRecip − 4·gRecip32)`.
-- ===========================================================================

/-- The shifted pullback argument: `1 + (1 + 1·t) ≈ 2 + t`. -/
private theorem arch_arg2 (t : Real) :
    Req (Radd one (affineMap ⟨1, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) t) := by
  refine Req_trans (Radd_congr (Req_refl one)
    (Radd_congr (Req_refl one) (Rone_mul t))) ?_
  refine Req_trans (Req_symm (Radd_assoc one one t)) ?_
  refine Radd_congr ?_ (Req_refl t)
  exact Req_trans (Radd_ofQ_ofQ (a := (⟨1, 1⟩ : Q)) (b := (⟨1, 1⟩ : Q))
    (by decide) (by decide))
    (ofQ_congr (a := add ⟨1, 1⟩ ⟨1, 1⟩) (b := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      (by decide))

/-- **The pullback, pointwise**: `tentArch1(1+t) ≈ −(1 + 2·gRecip t − 4·gRecip32 t)`. -/
theorem tent_arch_pull (t : Real) :
    Req (tentArch1 (affineMap ⟨1, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Rneg (Radd one
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 t))))) :=
  Rneg_congr (Radd_congr (Req_refl one) (Rsub_congr
    (Rmul_congr (Req_refl _) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (Radd_congr (Req_refl _) (Rone_mul t))))
    (Rmul_congr (Req_refl _) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (arch_arg2 t)))))

-- ===========================================================================
-- Lipschitz data for the `gRecip`/`gRecip32` combination, at any modulus L ≥ 6.
-- ===========================================================================

/-- `4·gRecip32` is `L`-Lipschitz for `L ≥ 4`. -/
theorem s4g32_lip {L : Q} (hLd : 0 < L.den) (h4L : Qle ⟨4, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨4, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (gRecip32_lip x y)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨4, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h4L)

theorem s4g32_congr : ∀ x y : Real, Req x y →
    Req (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y)) :=
  fun x y h => Rmul_congr (Req_refl _) (gRecip32_congr x y h)

/-- `−(4·gRecip32)` is `L`-Lipschitz for `L ≥ 4`. -/
theorem n4g32_lip {L : Q} (hLd : 0 < L.den) (h4L : Qle ⟨4, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rneg (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x)))
        (Rneg (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y)))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _))) ?_
  refine Rle_trans (s4g32_lip hLd h4L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

theorem n4g32_congr : ∀ x y : Real, Req x y →
    Req (Rneg (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x)))
      (Rneg (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y))) :=
  fun x y h => Rneg_congr (s4g32_congr x y h)

/-- The inner combination `2·gRecip − 4·gRecip32` is `L`-Lipschitz for `L ≥ 6`. -/
theorem innerG_lip {L : Q} (hLd : 0 < L.den) (h6L : Qle ⟨6, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x)))
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y)))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (sub_pair_split _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add
    (s2g_lip (L := (⟨2, 1⟩ : Q)) (by decide) (by decide) x y)
    (Rle_trans (s4g32_lip (L := (⟨4, 1⟩ : Q)) (by decide) (by decide) y x)
      (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))))) ?_
  refine Rle_trans (Rle_of_Req (two_add_four_smul (Rabs (Rsub x y)))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h6L)

theorem innerG_congr : ∀ x y : Real, Req x y →
    Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x)))
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y))) :=
  fun x y h => Rsub_congr (s2g_congr x y h) (s4g32_congr x y h)

/-- `1 + (2·gRecip − 4·gRecip32)` is `L`-Lipschitz for `L ≥ 6`. -/
theorem XG_lip {L : Q} (hLd : 0 < L.den) (h6L : Qle ⟨6, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub
        (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x))))
        (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y))))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_Radd_Radd one _ one _)
    (Req_trans (Radd_congr (Radd_neg one) (Req_refl _))
      (Req_trans (Radd_comm zero _) (Radd_zero _)))))) ?_
  exact innerG_lip hLd h6L x y

theorem XG_congr : ∀ x y : Real, Req x y →
    Req (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x))))
      (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y)))) :=
  fun x y h => Radd_congr (Req_refl one) (innerG_congr x y h)

/-- The negated combination (the pullback target) is `L`-Lipschitz for `L ≥ 6`. -/
theorem G3_lip {L : Q} (hLd : 0 < L.den) (h6L : Qle ⟨6, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub
        (Rneg (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x)))))
        (Rneg (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y)))))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _))) ?_
  refine Rle_trans (XG_lip hLd h6L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

theorem G3_congr : ∀ x y : Real, Req x y →
    Req (Rneg (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 x)))))
      (Rneg (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 y))))) :=
  fun x y h => Rneg_congr (XG_congr x y h)

end UOR.Bridge.F1Square.Analysis

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- THE [1,2] ARCH PIECE, EVALUATED.
-- ===========================================================================

/-- `gRecip32` at any modulus `L ≥ 1`. -/
theorem gRecip32_lip_at {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (gRecip32 x) (gRecip32 y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
  fun x y => lip_mono Nat.one_pos hLd h1L (Rnonneg_Rabs _) (gRecip32_lip x y)

/-- **`∫₁² −(1 + 2/x − 4/(x+1)) dx ≈ −(1 + 2·log 2 − 4·(log 3 − log 2))`** — the
    archimedean tail's compact `[1,2]` piece, evaluated (`= −1 − 6·log 2 + 4·log 3`). -/
theorem tent_arch12 :
    Req (riemannIntegralI (f := tentArch1) (L := (⟨6, 1⟩ : Q)) (by decide) (by decide)
        tentArch1_lip tentArch1_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide)
        (by decide))
      (Rneg (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
          (Rsub (logN 3 (by omega)) (logN 2 (by omega))))))) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide)) _ _
    (G3_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) G3_congr
    (fun t => tent_arch_pull t)) ?_
  refine Req_trans (riemannIntegral_neg
    (f := fun t => Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 t))))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (XG_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) XG_congr
    (G3_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) G3_congr) ?_
  refine Rneg_congr ?_
  refine Req_trans (riemannIntegral_add
    (f := fun _ => one)
    (g := fun t => Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 t)))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const one (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const one)
    (innerG_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) innerG_congr
    (XG_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) XG_congr) ?_
  refine Radd_congr (riemannIntegral_const_gen one
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const one (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const one)) ?_
  refine Req_trans (riemannIntegral_add
    (f := fun t => Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))
    (g := fun t => Rneg (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 t)))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (s2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g_congr
    (n4g32_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) n4g32_congr
    (innerG_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) innerG_congr) ?_
  refine Radd_congr ?_ ?_
  · refine Req_trans (riemannIntegral_smul (f := gRecip) (⟨2, 1⟩ : Q) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr
      (s2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g_congr) ?_
    exact Rmul_congr (Req_refl _) (riemannIntegral_recip_gen
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr)
  · refine Req_trans (riemannIntegral_neg
      (f := fun t => Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (gRecip32 t))
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (s4g32_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s4g32_congr
      (n4g32_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) n4g32_congr) ?_
    refine Rneg_congr ?_
    refine Req_trans (riemannIntegral_smul (f := gRecip32) (⟨4, 1⟩ : Q) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip32_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip32_congr
      (s4g32_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s4g32_congr) ?_
    exact Rmul_congr (Req_refl _) (riemannIntegral_recip32_gen
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip32_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip32_congr)

end UOR.Bridge.F1Square.Analysis
