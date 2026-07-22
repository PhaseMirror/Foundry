/-
F1 square — **the tent test's `f̃(0)` Weil-slot component, CONSTRUCTED and EVALUATED**
(`TentLogPiece.lean`):

    `∫_{1/2}^{1} (2 − 1/x) dx + ∫_{1}^{2} (2/x − 1) dx  ≈  log 2`   (`tentPoleB_eq`)

— the `∫₀^∞ f(x)/x dx` part of the pole term for the piecewise-linear tent test (knots
`1/2, 1, 2`; the `X = 2` prime-free window). With `tentPoleA_eq` (`∫ f = 3/4`) this completes
the tent's pole block `f̃(1) + f̃(0) = 3/4 + log 2` — the second `WeilSlot` interface integral
reduced in the kernel rather than carried as data.

HOW. The reciprocal integrands are totalized by the `clampedInv` gadget with the floor-1 clamp
throughout — on `[1/2, 1]` via the identity `1/x = 2·(1/(2x))` (`2x ∈ [1,2]`, so the SAME
`clampedInv 1` realizes both pieces; no second clamp floor, no scaling identity needed). Both
affine pullbacks are then POINTWISE `≈` to affine combinations of the harmonic integrand
`gRecip t = 1/max(1+t,1)`:

    piece 1 pullback:  `2 − 2·gRecip t`     piece 2 pullback:  `2·gRecip t − 1`,

so `riemannIntegral_congr` + the gateway's linearity (`_const/_smul/_neg/_add`) reduce both
values to `∫₀¹ dx/(1+x) ≈ log 2` (`HarmonicLog.lean`): piece 1 `= (1/2)(2 − 2·log 2) = 1 − log 2`,
piece 2 `= 2·log 2 − 1`, sum `= log 2`.

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.HarmonicLog
import Core.F1.Analysis.AffineIntegral

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Difference-shape helpers.
-- ===========================================================================

/-- `(−a) − (−b) ≈ b − a`. -/
theorem Rsub_Rneg_pair (a b : Real) : Req (Rsub (Rneg a) (Rneg b)) (Rsub b a) :=
  Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_involutive b)) (Radd_comm (Rneg a) b)

/-- `(c − a) − (c − b) ≈ b − a`. -/
theorem Rsub_const_sub (c a b : Real) :
    Req (Rsub (Rsub c a) (Rsub c b)) (Rsub b a) := by
  refine Req_trans (Rsub_Radd_Radd c (Rneg a) c (Rneg b)) ?_
  refine Req_trans (Radd_congr (Radd_neg c) (Rsub_Rneg_pair a b)) ?_
  exact Req_trans (Radd_comm zero (Rsub b a)) (Radd_zero (Rsub b a))

/-- `2·x ≈ x + x`. -/
theorem Rmul_two_eq (x : Real) :
    Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x) (Radd x x) := by
  refine Req_trans (Rmul_congr (Req_symm (Req_trans (Radd_ofQ_ofQ (a := (⟨1, 1⟩ : Q))
    (b := (⟨1, 1⟩ : Q)) (by decide) (by decide))
    (ofQ_congr (by decide) (by decide) (by decide)))) (Req_refl x)) ?_
  refine Req_trans (Rmul_distrib_right one one x) ?_
  exact Radd_congr (Rone_mul x) (Rone_mul x)

-- ===========================================================================
-- The two totalized integrands (floor-1 clamp only) and their Lipschitz data.
-- ===========================================================================

/-- Piece-1 integrand `f₁ u = 2 − 2·(1/max(2u,1))` — equals `2 − 1/u` on `[1/2, 1]`. -/
def tentF1 : Real → Real :=
  fun u => Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
    (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) u)))

/-- Piece-2 integrand `f₂ u = 2·(1/max(u,1)) − 1` — equals `2/u − 1` on `[1, 2]`. -/
def tentF2 : Real → Real :=
  fun u => Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
    (clampedInv ⟨1, 1⟩ (by decide) (by decide) u)) one

/-- The scaled-argument clamp core is `2`-Lipschitz: `|cI(2x) − cI(2y)| ≤ 2|x−y|`. -/
private theorem core1_lip (x y : Real) :
    Rle (Rabs (Rsub (clampedInv ⟨1, 1⟩ (by decide) (by decide)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x))
      (clampedInv ⟨1, 1⟩ (by decide) (by decide)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) y))))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide)
    (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) y)) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) x y))) ?_
  exact Rabs_Rmul_ofQ_nonneg (by decide) (by decide) (Rsub x y)

/-- `tentF1` is `4`-Lipschitz. -/
theorem tentF1_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (tentF1 x) (tentF1 y)))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_const_sub _ _ _))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (core1_lip y x)) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc _ _ _))) ?_
  refine Rle_of_Req (Rmul_congr (Rmul_ofQ_ofQ (by decide) (by decide)) ?_)
  exact Req_trans (Rabs_congr (Req_symm (Rneg_Rsub x y))) (Rabs_Rneg (Rsub x y))

/-- `tentF1` respects `≈`. -/
theorem tentF1_congr : ∀ x y : Real, Req x y → Req (tentF1 x) (tentF1 y) :=
  fun _ _ h => Rsub_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) (Rmul_congr (Req_refl _) h)))

/-- `tentF2` is `2`-Lipschitz. -/
theorem tentF2_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (tentF2 x) (tentF2 y)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  have hdrop : Req (Rsub (tentF2 x) (tentF2 y))
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (clampedInv ⟨1, 1⟩ (by decide) (by decide) x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (clampedInv ⟨1, 1⟩ (by decide) (by decide) y))) := by
    refine Req_trans (Rsub_Radd_Radd _ (Rneg one) _ (Rneg one)) ?_
    refine Req_trans (Radd_congr (Req_refl _) (Radd_neg (Rneg one))) ?_
    exact Radd_zero _
  refine Rle_trans (Rle_of_Req (Rabs_congr hdrop)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) x y)) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨2, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))

/-- `tentF2` respects `≈`. -/
theorem tentF2_congr : ∀ x y : Real, Req x y → Req (tentF2 x) (tentF2 y) :=
  fun _ _ h => Rsub_congr (Rmul_congr (Req_refl _)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) h)) (Req_refl one)

end UOR.Bridge.F1Square.Analysis

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The pulled-back integrands are pointwise affine in `gRecip`.
-- ===========================================================================

/-- `|y − x| ≈ |x − y|`. -/
theorem Rabs_Rsub_swap (x y : Real) : Req (Rabs (Rsub y x)) (Rabs (Rsub x y)) :=
  Req_trans (Rabs_congr (Req_symm (Rneg_Rsub x y))) (Rabs_Rneg (Rsub x y))

/-- The scaled pullback argument: `2·(1/2 + (1/2)t) ≈ 1 + t`. -/
theorem tent_arg1 (t : Real) :
    Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (affineMap ⟨1, 2⟩ ⟨1, 2⟩ (by decide) (by decide) t))
      (Radd one t) := by
  refine Req_trans (Rmul_distrib (ofQ (⟨2, 1⟩ : Q) (by decide))
    (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) t)) ?_
  refine Radd_congr
    (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (by decide) (by decide) (by decide)))
    ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨2, 1⟩ : Q) (by decide))
    (ofQ (⟨1, 2⟩ : Q) (by decide)) t)) ?_
  refine Req_trans (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
    (ofQ_congr (a := mul ⟨2, 1⟩ ⟨1, 2⟩) (b := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (by decide))) (Req_refl t)) ?_
  exact Rone_mul t

/-- **Piece-1 pullback, pointwise**: `tentF1(1/2 + t/2) ≈ 2 − 2·gRecip t`. -/
theorem tent_pull1 (t : Real) :
    Req (tentF1 (affineMap ⟨1, 2⟩ ⟨1, 2⟩ (by decide) (by decide) t))
      (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))) :=
  Rsub_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) (tent_arg1 t)))

/-- **Piece-2 pullback, pointwise**: `tentF2(1 + t) ≈ 2·gRecip t − 1`. -/
theorem tent_pull2 (t : Real) :
    Req (tentF2 (affineMap ⟨1, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t)) one) :=
  Rsub_congr (Rmul_congr (Req_refl _)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (Radd_congr (Req_refl _) (Rone_mul t)))) (Req_refl one)

-- ===========================================================================
-- Lipschitz data for the `gRecip` combinations, at any modulus `L ≥ 2`.
-- ===========================================================================

/-- `gRecip` at any modulus `L ≥ 1`. -/
theorem gRecip_lip_at {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (gRecip x) (gRecip y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
  fun x y => lip_mono Nat.one_pos hLd h1L (Rnonneg_Rabs _) (gRecip_lip x y)

/-- `2·gRecip` is `L`-Lipschitz for `L ≥ 2`. -/
theorem s2g_lip {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (gRecip_lip x y)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨2, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h2L)

theorem s2g_congr : ∀ x y : Real, Req x y →
    Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)) :=
  fun x y h => Rmul_congr (Req_refl _) (gRecip_congr x y h)

/-- `−(2·gRecip)` is `L`-Lipschitz for `L ≥ 2`. -/
theorem n2g_lip {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)))
        (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _))) ?_
  refine Rle_trans (s2g_lip hLd h2L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

theorem n2g_congr : ∀ x y : Real, Req x y →
    Req (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)))
      (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))) :=
  fun x y h => Rneg_congr (s2g_congr x y h)

/-- `2 − 2·gRecip` is `L`-Lipschitz for `L ≥ 2`. -/
theorem G1_lip {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)))
        (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_const_sub _ _ _))) ?_
  refine Rle_trans (s2g_lip hLd h2L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

theorem G1_congr : ∀ x y : Real, Req x y →
    Req (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)))
      (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))) :=
  fun x y h => Rsub_congr (Req_refl _) (s2g_congr x y h)

/-- `2·gRecip − 1` is `L`-Lipschitz for `L ≥ 2`. -/
theorem G2_lip {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)) one)
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)) one)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  have hdrop : Req (Rsub (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)) one)
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)) one))
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y))) :=
    Rsub_shift_drop _ _ one
  exact Rle_trans (Rle_of_Req (Rabs_congr hdrop)) (s2g_lip hLd h2L x y)

theorem G2_congr : ∀ x y : Real, Req x y →
    Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x)) one)
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)) one) :=
  fun x y h => Rsub_congr (s2g_congr x y h) (Req_refl one)

end UOR.Bridge.F1Square.Analysis

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- THE TWO PIECE EVALUATIONS AND THE ASSEMBLED f̃(0) COMPONENT.
-- ===========================================================================

/-- **`∫_{1/2}^{1} (2 − 1/x) dx ≈ 1 − log 2`** — piece 1, evaluated. -/
theorem tent_pieceB1 :
    Req (riemannIntegralI (f := tentF1) (L := (⟨4, 1⟩ : Q)) (by decide) (by decide)
        tentF1_lip tentF1_congr (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
      (Rsub one (logN 2 (by omega))) := by
  show Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) _) _
  refine Req_trans (y := Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))))
    (Rmul_congr (Req_refl (ofQ (⟨1, 2⟩ : Q) (by decide)))
      (Req_trans (riemannIntegral_congr
        (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide)) _ _
        (G1_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) G1_congr
        (fun t => tent_pull1 t)) ?hval)) ?fin
  case hval =>
    refine Req_trans (riemannIntegral_add
      (f := fun _ => ofQ (⟨2, 1⟩ : Q) (by decide))
      (g := fun t => Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t)))
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (lip_const (ofQ (⟨2, 1⟩ : Q) (by decide)) (Qmul_den_pos (by decide) (by decide))
        (Int.mul_nonneg (by decide) (by decide)))
      (congr_const (ofQ (⟨2, 1⟩ : Q) (by decide)))
      (n2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) n2g_congr
      (G1_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) G1_congr) ?_
    refine Radd_congr (riemannIntegral_const_gen (ofQ (⟨2, 1⟩ : Q) (by decide))
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (lip_const (ofQ (⟨2, 1⟩ : Q) (by decide)) (Qmul_den_pos (by decide) (by decide))
        (Int.mul_nonneg (by decide) (by decide)))
      (congr_const (ofQ (⟨2, 1⟩ : Q) (by decide)))) ?_
    refine Req_trans (riemannIntegral_neg
      (f := fun t => Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (s2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g_congr
      (n2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) n2g_congr) ?_
    refine Rneg_congr ?_
    refine Req_trans (riemannIntegral_smul (f := gRecip) (⟨2, 1⟩ : Q) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr
      (s2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g_congr) ?_
    exact Rmul_congr (Req_refl _) (riemannIntegral_recip_gen
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr)
  case fin =>
    refine Req_trans (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
      (ofQ (⟨2, 1⟩ : Q) (by decide))
      (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))))) ?_
    refine Radd_congr
      (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
        (ofQ_congr (a := mul ⟨1, 2⟩ ⟨2, 1⟩) (b := (⟨1, 1⟩ : Q)) (by decide) (by decide)
          (by decide)))
      ?_
    refine Req_trans (Rmul_neg_right (ofQ (⟨1, 2⟩ : Q) (by decide)) _) ?_
    refine Rneg_congr ?_
    refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide))
      (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))) ?_
    refine Req_trans (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (a := mul ⟨1, 2⟩ ⟨2, 1⟩) (b := (⟨1, 1⟩ : Q)) (by decide) (by decide)
        (by decide))) (Req_refl (logN 2 (by omega)))) ?_
    exact Rone_mul (logN 2 (by omega))

/-- **`∫_{1}^{2} (2/x − 1) dx ≈ 2·log 2 − 1`** — piece 2, evaluated. -/
theorem tent_pieceB2 :
    Req (riemannIntegralI (f := tentF2) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
        tentF2_lip tentF2_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))) one) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide)) _ _
    (G2_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) G2_congr
    (fun t => tent_pull2 t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := fun t => Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip t))
    (g := fun _ => Rneg one)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (s2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g_congr
    (lip_const (Rneg one) (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const (Rneg one))
    (G2_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) G2_congr) ?_
  refine Radd_congr ?_ (riemannIntegral_const_gen (Rneg one)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const (Rneg one) (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const (Rneg one)))
  refine Req_trans (riemannIntegral_smul (f := gRecip) (⟨2, 1⟩ : Q) (by decide)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr
    (s2g_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g_congr) ?_
  exact Rmul_congr (Req_refl _) (riemannIntegral_recip_gen
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr)

/-- **The tent test's `∫₀^∞ f(x)/x dx` pole component, CONSTRUCTED**: the sum of the two
    certified interval integrals. -/
def tentPoleB : Real :=
  Radd
    (riemannIntegralI (f := tentF1) (L := (⟨4, 1⟩ : Q)) (by decide) (by decide)
      tentF1_lip tentF1_congr (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
    (riemannIntegralI (f := tentF2) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      tentF2_lip tentF2_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))

/-- **THE SECOND EVALUATED WEIL-SLOT COMPONENT**: `tentPoleB ≈ log 2` — the tent's `f̃(0)`
    pole integral reduced in the kernel: `(1 − log 2) + (2·log 2 − 1) = log 2`. -/
theorem tentPoleB_eq : Req tentPoleB (logN 2 (by omega)) := by
  refine Req_trans (Radd_congr tent_pieceB1 tent_pieceB2) ?_
  refine Req_trans (Radd_Rsub_Rsub one (logN 2 (by omega))
    (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))) ?_
  refine Req_trans (Rsub_congr (Rmul_two_eq (logN 2 (by omega)))
    (Req_refl (logN 2 (by omega)))) ?_
  refine Req_trans (Radd_assoc (logN 2 (by omega)) (logN 2 (by omega))
    (Rneg (logN 2 (by omega)))) ?_
  refine Req_trans (Radd_congr (Req_refl (logN 2 (by omega)))
    (Radd_neg (logN 2 (by omega)))) ?_
  exact Radd_zero (logN 2 (by omega))

end UOR.Bridge.F1Square.Analysis
