/-
F1 square — **the bump test's slot integrals, CONSTRUCTED and EVALUATED** (`BumpPieces.lean`):
the three `WeilSlot` interface components of the OFF-CENTER tent with knots `1, 2, 3`
(`f(x) = x−1` on `[1,2]`, `3−x` on `[2,3]` — the first realized test whose support MEETS
the primes; `Square/BumpSlot.lean` assembles the slot):

    `∫₁³ f dx                       ≈ 1`                                   (`bumpPoleA_eq`)
    `∫₁³ f(x)/x dx                  ≈ (1 − log 2) + (3·(log 3 − log 2) − 1)` (`bumpPoleB_eq`)
    `∫₁³ f(x)/(x − x⁻¹) dx          ≈ (1 − (log 3 − log 2))`
                                    `+ ((−1 + log 2) + 2·(log 4 − log 3))` (`bumpArchTail_eq`)

HOW. The pole integrals are the affine/reciprocal pieces over `[1,2]` and `[2,3]` through the
certified gateway. The archimedean tail is COMPACT for this test — `f(1) = 0` kills the
`(2/x)·f(1)` subtraction and the improper remainder past the support — and the PV-cancelled
integrand reduces by exact rational algebra on each piece:
`(x−1)/(x−x⁻¹) = x/(x+1) = 1 − 1/(x+1)` on `[1,2]`, and by partial fractions
`x(3−x)/(x²−1) = −1 + 1/(x−1) + 2/(x+1)` on `[2,3]`. Every reciprocal is totalized with the
floor-1 clamp (inert on the domains) and evaluates through the general-base harmonic bridge
`∫₀¹ dx/(c+x) ≈ log(c+1) − log c` (`HarmonicLogC.lean`).

HONEST SCOPE. Substrate for the crux route's step 2; no positivity claim here. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.HarmonicLogC
import Core.F1.Analysis.TentArchPiece

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Shared algebra helpers.
-- ===========================================================================

/-- `(a − c) − (b − c) ≈ a − b` (right-constant drop). -/
private theorem bmp_sub_cc (a b c : Real) :
    Req (Rsub (Rsub a c) (Rsub b c)) (Rsub a b) := by
  refine Req_trans (Rsub_Radd_Radd a (Rneg c) b (Rneg c)) ?_
  refine Req_trans (Radd_congr (Req_refl (Rsub a b)) (Radd_neg (Rneg c))) ?_
  exact Radd_zero (Rsub a b)

/-- `(c + a) − (c + b) ≈ a − b` (left-constant drop). -/
private theorem bmp_add_cc (c a b : Real) :
    Req (Rsub (Radd c a) (Radd c b)) (Rsub a b) := by
  refine Req_trans (Rsub_Radd_Radd c a c b) ?_
  refine Req_trans (Radd_congr (Radd_neg c) (Req_refl (Rsub a b))) ?_
  exact Req_trans (Radd_comm zero (Rsub a b)) (Radd_zero (Rsub a b))

/-- The `1·A + 2·A ≈ 3·A` collapse. -/
private theorem one_add_two_smul (A : Real) :
    Req (Radd (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) A)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) A))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) A) := by
  refine Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨1, 1⟩ : Q) (by decide))
    (ofQ (⟨2, 1⟩ : Q) (by decide)) A)) ?_
  refine Rmul_congr ?_ (Req_refl A)
  exact Req_trans (Radd_ofQ_ofQ (a := (⟨1, 1⟩ : Q)) (b := (⟨2, 1⟩ : Q))
    (by decide) (by decide))
    (ofQ_congr (a := add ⟨1, 1⟩ ⟨2, 1⟩) (b := (⟨3, 1⟩ : Q)) (by decide) (by decide)
      (by decide))

/-- The generic shifted clamp `x ↦ 1/max(b+x, 1)` is `1`-Lipschitz. -/
private theorem shiftClamp_lip (b : Q) (hb : 0 < b.den) (x y : Real) :
    Rle (Rabs (Rsub (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ b hb) x))
        (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ b hb) y))))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide)
    (Radd (ofQ b hb) x) (Radd (ofQ b hb) y)) ?_
  refine Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr ?_))
  refine Req_trans (Rsub_Radd_Radd (ofQ b hb) x (ofQ b hb) y) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ b hb)) (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- The generic shifted clamp respects `≈`. -/
private theorem shiftClamp_congr (b : Q) (hb : 0 < b.den) {x y : Real} (h : Req x y) :
    Req (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ b hb) x))
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ b hb) y)) :=
  clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) (Radd_congr (Req_refl _) h)

/-- The generic pullback argument: `b + (a + 1·t) ≈ s + t` whenever `b + a = s`. -/
private theorem shift_arg (b a s : Q) (hb : 0 < b.den) (ha : 0 < a.den) (hs : 0 < s.den)
    (hsum : Qeq (add b a) s) (t : Real) :
    Req (Radd (ofQ b hb) (affineMap a ⟨1, 1⟩ ha (by decide) t)) (Radd (ofQ s hs) t) := by
  refine Req_trans (Radd_congr (Req_refl (ofQ b hb))
    (Radd_congr (Req_refl (ofQ a ha)) (Rone_mul t))) ?_
  refine Req_trans (Req_symm (Radd_assoc (ofQ b hb) (ofQ a ha) t)) ?_
  exact Radd_congr (Req_trans (Radd_ofQ_ofQ hb ha)
    (ofQ_congr (add_den_pos hb ha) hs hsum)) (Req_refl t)

-- ===========================================================================
-- The `∫ f` pole component: two affine edges.
-- ===========================================================================

/-- `∫₁² (x − 1) dx ≈ 1/2` — the bump's rising edge, evaluated. -/
theorem bump_pieceA1 :
    Req (riemannIntegralI (f := fun x => Radd (ofQ (⟨-1, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x)) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
        (lip_affine (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
        (congr_affine (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide))
        (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (ofQ (⟨1, 2⟩ : Q) (by decide)) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
    (Int.mul_nonneg (by decide) (by decide)) _ _
    (lip_affine (add (⟨-1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)))
      (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (by decide))
    (congr_affine (add (⟨-1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)))
      (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide))
    (fun x => affine_pullback_eq (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      (by decide) (by decide) (by decide) (by decide) x))
    (riemannIntegral_affine (add (⟨-1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)))
      (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (by decide)
      (lip_id_ge (Qmul_den_pos (by decide) (by decide)) (by decide))
      congr_id)) ?_
  exact ofQ_congr (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (by decide) (by decide)

/-- `∫₂³ (3 − x) dx ≈ 1/2` — the bump's falling edge, evaluated. -/
theorem bump_pieceA2 :
    Req (riemannIntegralI (f := fun x => Radd (ofQ (⟨3, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨-1, 1⟩ : Q) (by decide)) x)) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
        (lip_affine (⟨3, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
        (congr_affine (⟨3, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide))
        (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (ofQ (⟨1, 2⟩ : Q) (by decide)) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
    (Int.mul_nonneg (by decide) (by decide)) _ _
    (lip_affine (add (⟨3, 1⟩ : Q) (mul (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
      (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (by decide))
    (congr_affine (add (⟨3, 1⟩ : Q) (mul (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
      (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide))
    (fun x => affine_pullback_eq (⟨3, 1⟩ : Q) (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)
      (by decide) (by decide) (by decide) (by decide) x))
    (riemannIntegral_affine (add (⟨3, 1⟩ : Q) (mul (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
      (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (by decide)
      (lip_id_ge (Qmul_den_pos (by decide) (by decide)) (by decide))
      congr_id)) ?_
  exact ofQ_congr (add_den_pos (add_den_pos (by decide) (Qmul_den_pos (by decide) (by decide)))
    (Qmul_den_pos (Qmul_den_pos (by decide) (by decide)) (by decide)))
    (by decide) (by decide)

/-- **The bump test's `∫ f` pole component, CONSTRUCTED**: the sum of the two edges. -/
def bumpPoleA : Real :=
  Radd
    (riemannIntegralI (f := fun x => Radd (ofQ (⟨-1, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x)) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (lip_affine (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
      (congr_affine (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide))
      (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
    (riemannIntegralI (f := fun x => Radd (ofQ (⟨3, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨-1, 1⟩ : Q) (by decide)) x)) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (lip_affine (⟨3, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
      (congr_affine (⟨3, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide))
      (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))

/-- **`bumpPoleA ≈ 1`**: the bump's `f̃(1)` pole integral, reduced in the kernel. -/
theorem bumpPoleA_eq : Req bumpPoleA (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
  refine Req_trans (Radd_congr bump_pieceA1 bump_pieceA2) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact ofQ_congr (add_den_pos (by decide) (by decide)) (by decide) (by decide)

-- ===========================================================================
-- The `∫ f/x` pole component (`f̃(0)`): `1 − 1/x` and `3/x − 1`.
-- ===========================================================================

/-- The `[1,2]` integrand `(x−1)/x = 1 − 1/x`, totalized with the floor-1 clamp. -/
def bumpB1 : Real → Real :=
  fun u => Rsub one (clampedInv ⟨1, 1⟩ (by decide) (by decide) u)

/-- The `[2,3]` integrand `(3−x)/x = 3/x − 1`, totalized with the floor-1 clamp. -/
def bumpB2 : Real → Real :=
  fun u => Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
    (clampedInv ⟨1, 1⟩ (by decide) (by decide) u)) one

/-- `bumpB1` is `1`-Lipschitz. -/
theorem bumpB1_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (bumpB1 x) (bumpB1 y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_const_sub one _ _))) ?_
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

/-- `bumpB1` respects `≈`. -/
theorem bumpB1_congr : ∀ x y : Real, Req x y → Req (bumpB1 x) (bumpB1 y) :=
  fun _ _ h => Rsub_congr (Req_refl one)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) h)

/-- `bumpB2` is `3`-Lipschitz. -/
theorem bumpB2_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (bumpB2 x) (bumpB2 y)))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (bmp_sub_cc _ _ one))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨3, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) x y)) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨3, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))

/-- `bumpB2` respects `≈`. -/
theorem bumpB2_congr : ∀ x y : Real, Req x y → Req (bumpB2 x) (bumpB2 y) :=
  fun _ _ h => Rsub_congr (Rmul_congr (Req_refl _)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) h)) (Req_refl one)

/-- `1 − gRecip` at any modulus `L ≥ 1` (the pulled-back `[1,2]` integrand). -/
private theorem B1t_lip {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rsub one (gRecip x)) (Rsub one (gRecip y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_const_sub one (gRecip x) (gRecip y)))) ?_
  refine Rle_trans (gRecip_lip_at hLd h1L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

private theorem B1t_congr : ∀ x y : Real, Req x y →
    Req (Rsub one (gRecip x)) (Rsub one (gRecip y)) :=
  fun x y h => Rsub_congr (Req_refl one) (gRecip_congr x y h)

/-- `Rneg ∘ gRecip` at any modulus `L ≥ 1`. -/
private theorem ngR_lip {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rneg (gRecip x)) (Rneg (gRecip y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _))) ?_
  refine Rle_trans (gRecip_lip_at hLd h1L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

private theorem ngR_congr : ∀ x y : Real, Req x y →
    Req (Rneg (gRecip x)) (Rneg (gRecip y)) :=
  fun x y h => Rneg_congr (gRecip_congr x y h)

/-- `3·gRecipC 2` at any modulus `L ≥ 3`. -/
private theorem s3g2_lip {L : Q} (hLd : 0 < L.den) (h3L : Qle ⟨3, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 x))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨3, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (gRecipC_lip 2 x y)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨3, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h3L)

private theorem s3g2_congr : ∀ x y : Real, Req x y →
    Req (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 x))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 y)) :=
  fun x y h => Rmul_congr (Req_refl _) (gRecipC_congr 2 x y h)

/-- `3·gRecipC 2 − 1` at any modulus `L ≥ 3` (the pulled-back `[2,3]` integrand). -/
private theorem B2t_lip {L : Q} (hLd : 0 < L.den) (h3L : Qle ⟨3, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub
        (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 x)) one)
        (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 y)) one)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (bmp_sub_cc _ _ one))) ?_
  exact s3g2_lip hLd h3L x y

private theorem B2t_congr : ∀ x y : Real, Req x y →
    Req (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 x)) one)
      (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 y)) one) :=
  fun x y h => Rsub_congr (s3g2_congr x y h) (Req_refl one)

/-- The `[1,2]` pullback, pointwise: `bumpB1(1 + t) ≈ 1 − gRecip t`. -/
private theorem bumpB1_pull (t : Real) :
    Req (bumpB1 (affineMap ⟨1, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Rsub one (gRecip t)) :=
  Rsub_congr (Req_refl one) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_congr (Req_refl _) (Rone_mul t)))

/-- The `[2,3]` pullback, pointwise: `bumpB2(2 + t) ≈ 3·gRecipC 2 t − 1`. -/
private theorem bumpB2_pull (t : Real) :
    Req (bumpB2 (affineMap ⟨2, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 t)) one) :=
  Rsub_congr (Rmul_congr (Req_refl _) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_congr (Req_refl _) (Rone_mul t)))) (Req_refl one)

/-- `∫₁² (1 − 1/x) dx ≈ 1 − log 2` — the `f̃(0)` rising piece, evaluated. -/
theorem bump_pieceB1 :
    Req (riemannIntegralI (f := bumpB1) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
        bumpB1_lip bumpB1_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rsub one (logN 2 (by omega))) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
    (Int.mul_nonneg (by decide) (by decide)) _ _
    (B1t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) B1t_congr
    (fun t => bumpB1_pull t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := fun _ => one) (g := fun t => Rneg (gRecip t))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const one (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const one)
    (ngR_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) ngR_congr
    (B1t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) B1t_congr) ?_
  refine Radd_congr (riemannIntegral_const_gen one
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const one (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const one)) ?_
  refine Req_trans (riemannIntegral_neg (f := gRecip)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr
    (ngR_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) ngR_congr) ?_
  exact Rneg_congr (riemannIntegral_recip_gen
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr)

/-- `∫₂³ (3/x − 1) dx ≈ 3·(log 3 − log 2) − 1` — the `f̃(0)` falling piece, evaluated. -/
theorem bump_pieceB2 :
    Req (riemannIntegralI (f := bumpB2) (L := (⟨3, 1⟩ : Q)) (by decide) (by decide)
        bumpB2_lip bumpB2_congr (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
        (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) one) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
    (Int.mul_nonneg (by decide) (by decide)) _ _
    (B2t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) B2t_congr
    (fun t => bumpB2_pull t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := fun t => Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (gRecipC 2 t))
    (g := fun _ => Rneg one)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (s3g2_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s3g2_congr
    (lip_const (Rneg one) (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const (Rneg one))
    (B2t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) B2t_congr) ?_
  refine Radd_congr ?_ (riemannIntegral_const_gen (Rneg one)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const (Rneg one) (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const (Rneg one)))
  refine Req_trans (riemannIntegral_smul (f := gRecipC 2) (⟨3, 1⟩ : Q) (by decide)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at 2 (Qmul_den_pos (by decide) (by decide)) (by decide)) (gRecipC_congr 2)
    (s3g2_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s3g2_congr) ?_
  exact Rmul_congr (Req_refl _) (riemannIntegral_recipC_gen 2 (by omega)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at 2 (Qmul_den_pos (by decide) (by decide)) (by decide)) (gRecipC_congr 2))

/-- **The bump test's `∫ f/x` pole component, CONSTRUCTED**: the sum of the two pieces. -/
def bumpPoleB : Real :=
  Radd
    (riemannIntegralI (f := bumpB1) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      bumpB1_lip bumpB1_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
    (riemannIntegralI (f := bumpB2) (L := (⟨3, 1⟩ : Q)) (by decide) (by decide)
      bumpB2_lip bumpB2_congr (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))

/-- **`bumpPoleB ≈ (1 − log 2) + (3·(log 3 − log 2) − 1)`** (`= 3·log 3 − 4·log 2`): the
    bump's `f̃(0)` pole integral, reduced in the kernel. -/
theorem bumpPoleB_eq : Req bumpPoleB
    (Radd (Rsub one (logN 2 (by omega)))
      (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide))
        (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) one)) :=
  Radd_congr bump_pieceB1 bump_pieceB2

-- ===========================================================================
-- The archimedean tail (COMPACT for this test: `f(1) = 0`):
-- `x/(x+1) = 1 − 1/(x+1)` on `[1,2]`, `−1 + 1/(x−1) + 2/(x+1)` on `[2,3]`.
-- ===========================================================================

/-- The `[1,2]` tail integrand `(x−1)/(x−x⁻¹) = 1 − 1/(x+1)`, totalized. -/
def bumpT1 : Real → Real :=
  fun u => Rsub one (gRecip u)

/-- The `[2,3]` tail integrand `x(3−x)/(x²−1) = −1 + 1/(x−1) + 2/(x+1)`, totalized. -/
def bumpT2 : Real → Real :=
  fun u => Radd
    (Radd (Rneg one)
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ (⟨-1, 1⟩ : Q) (by decide)) u)))
    (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip u))

/-- `bumpT1` is `1`-Lipschitz. -/
theorem bumpT1_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (bumpT1 x) (bumpT1 y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
  B1t_lip (by decide) (by decide)

/-- `bumpT1` respects `≈`. -/
theorem bumpT1_congr : ∀ x y : Real, Req x y → Req (bumpT1 x) (bumpT1 y) :=
  B1t_congr

/-- `2·gRecip` at any modulus `L ≥ 2`. -/
private theorem s2gR_lip {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) : ∀ x y : Real,
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

private theorem s2gR_congr : ∀ x y : Real, Req x y →
    Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip x))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecip y)) :=
  fun x y h => Rmul_congr (Req_refl _) (gRecip_congr x y h)

/-- The `−1 + 1/(x−1)` part of `bumpT2`, at modulus `1`. -/
private theorem T2a_lip (x y : Real) :
    Rle (Rabs (Rsub
        (Radd (Rneg one) (clampedInv ⟨1, 1⟩ (by decide) (by decide)
          (Radd (ofQ (⟨-1, 1⟩ : Q) (by decide)) x)))
        (Radd (Rneg one) (clampedInv ⟨1, 1⟩ (by decide) (by decide)
          (Radd (ofQ (⟨-1, 1⟩ : Q) (by decide)) y)))))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (bmp_add_cc (Rneg one) _ _))) ?_
  exact shiftClamp_lip (⟨-1, 1⟩ : Q) (by decide) x y

private theorem T2a_congr : ∀ x y : Real, Req x y →
    Req (Radd (Rneg one) (clampedInv ⟨1, 1⟩ (by decide) (by decide)
        (Radd (ofQ (⟨-1, 1⟩ : Q) (by decide)) x)))
      (Radd (Rneg one) (clampedInv ⟨1, 1⟩ (by decide) (by decide)
        (Radd (ofQ (⟨-1, 1⟩ : Q) (by decide)) y))) :=
  fun _ _ h => Radd_congr (Req_refl (Rneg one)) (shiftClamp_congr (⟨-1, 1⟩ : Q) (by decide) h)

/-- `bumpT2` is `3`-Lipschitz. -/
theorem bumpT2_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (bumpT2 x) (bumpT2 y)))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (T2a_lip x y)
    (s2gR_lip (L := (⟨2, 1⟩ : Q)) (by decide) (by decide) x y)) ?_
  exact Rle_of_Req (one_add_two_smul (Rabs (Rsub x y)))

/-- `bumpT2` respects `≈`. -/
theorem bumpT2_congr : ∀ x y : Real, Req x y → Req (bumpT2 x) (bumpT2 y) :=
  fun x y h => Radd_congr (T2a_congr x y h) (s2gR_congr x y h)

/-- `1 − gRecipC 2` at any modulus `L ≥ 1` (the pulled-back `[1,2]` tail integrand). -/
private theorem T1t_lip {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rsub one (gRecipC 2 x)) (Rsub one (gRecipC 2 y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_const_sub one (gRecipC 2 x) (gRecipC 2 y)))) ?_
  refine Rle_trans (gRecipC_lip_at 2 hLd h1L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

private theorem T1t_congr : ∀ x y : Real, Req x y →
    Req (Rsub one (gRecipC 2 x)) (Rsub one (gRecipC 2 y)) :=
  fun x y h => Rsub_congr (Req_refl one) (gRecipC_congr 2 x y h)

/-- `Rneg ∘ gRecipC 2` at any modulus `L ≥ 1`. -/
private theorem ng2_lip {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rneg (gRecipC 2 x)) (Rneg (gRecipC 2 y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _))) ?_
  refine Rle_trans (gRecipC_lip_at 2 hLd h1L y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

private theorem ng2_congr : ∀ x y : Real, Req x y →
    Req (Rneg (gRecipC 2 x)) (Rneg (gRecipC 2 y)) :=
  fun x y h => Rneg_congr (gRecipC_congr 2 x y h)

/-- `−1 + gRecip` at any modulus `L ≥ 1` (the pulled-back `1/(x−1)` part). -/
private theorem T2at_lip {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Radd (Rneg one) (gRecip x)) (Radd (Rneg one) (gRecip y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (bmp_add_cc (Rneg one) _ _))) ?_
  exact gRecip_lip_at hLd h1L x y

private theorem T2at_congr : ∀ x y : Real, Req x y →
    Req (Radd (Rneg one) (gRecip x)) (Radd (Rneg one) (gRecip y)) :=
  fun x y h => Radd_congr (Req_refl (Rneg one)) (gRecip_congr x y h)

/-- `2·gRecipC 3` at any modulus `L ≥ 2`. -/
private theorem s2g3_lip {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm
    (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) _ _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (gRecipC_lip 3 x y)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl (ofQ (⟨2, 1⟩ : Q) (by decide)))
    (Rone_mul (Rabs (Rsub x y))))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h2L)

private theorem s2g3_congr : ∀ x y : Real, Req x y →
    Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 x))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 y)) :=
  fun x y h => Rmul_congr (Req_refl _) (gRecipC_congr 3 x y h)

/-- The full pulled-back `[2,3]` tail integrand at any modulus `L ≥ 3`. -/
private theorem T2t_lip {L : Q} (hLd : 0 < L.den) (h3L : Qle ⟨3, 1⟩ L) : ∀ x y : Real,
    Rle (Rabs (Rsub
        (Radd (Radd (Rneg one) (gRecip x))
          (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 x)))
        (Radd (Radd (Rneg one) (gRecip y))
          (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 y)))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add
    (T2at_lip (L := (⟨1, 1⟩ : Q)) (by decide) (by decide) x y)
    (s2g3_lip (L := (⟨2, 1⟩ : Q)) (by decide) (by decide) x y)) ?_
  refine Rle_trans (Rle_of_Req (one_add_two_smul (Rabs (Rsub x y)))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h3L)

private theorem T2t_congr : ∀ x y : Real, Req x y →
    Req (Radd (Radd (Rneg one) (gRecip x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 x)))
      (Radd (Radd (Rneg one) (gRecip y))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 y))) :=
  fun x y h => Radd_congr (T2at_congr x y h) (s2g3_congr x y h)

/-- The `[1,2]` tail pullback, pointwise: `bumpT1(1 + t) ≈ 1 − gRecipC 2 t`. -/
private theorem bumpT1_pull (t : Real) :
    Req (bumpT1 (affineMap ⟨1, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Rsub one (gRecipC 2 t)) :=
  Rsub_congr (Req_refl one) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (shift_arg (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q)
      (by decide) (by decide) (by decide) (by decide) t))

/-- The `[2,3]` tail pullback, pointwise:
    `bumpT2(2 + t) ≈ (−1 + gRecip t) + 2·gRecipC 3 t`. -/
private theorem bumpT2_pull (t : Real) :
    Req (bumpT2 (affineMap ⟨2, 1⟩ ⟨1, 1⟩ (by decide) (by decide) t))
      (Radd (Radd (Rneg one) (gRecip t))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 t))) :=
  Radd_congr
    (Radd_congr (Req_refl (Rneg one)) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (shift_arg (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)
        (by decide) (by decide) (by decide) (by decide) t)))
    (Rmul_congr (Req_refl _) (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (shift_arg (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q) (⟨3, 1⟩ : Q)
        (by decide) (by decide) (by decide) (by decide) t)))

/-- `∫₁² (1 − 1/(x+1)) dx ≈ 1 − (log 3 − log 2)` — the tail's rising piece, evaluated. -/
theorem bump_pieceT1 :
    Req (riemannIntegralI (f := bumpT1) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
        bumpT1_lip bumpT1_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Rsub one (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
    (Int.mul_nonneg (by decide) (by decide)) _ _
    (T1t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) T1t_congr
    (fun t => bumpT1_pull t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := fun _ => one) (g := fun t => Rneg (gRecipC 2 t))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const one (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const one)
    (ng2_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) ng2_congr
    (T1t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) T1t_congr) ?_
  refine Radd_congr (riemannIntegral_const_gen one
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (lip_const one (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)))
    (congr_const one)) ?_
  refine Req_trans (riemannIntegral_neg (f := gRecipC 2)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at 2 (Qmul_den_pos (by decide) (by decide)) (by decide)) (gRecipC_congr 2)
    (ng2_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) ng2_congr) ?_
  exact Rneg_congr (riemannIntegral_recipC_gen 2 (by omega)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at 2 (Qmul_den_pos (by decide) (by decide)) (by decide)) (gRecipC_congr 2))

/-- `∫₂³ (−1 + 1/(x−1) + 2/(x+1)) dx ≈ (−1 + log 2) + 2·(log 4 − log 3)` — the tail's
    falling piece, evaluated. -/
theorem bump_pieceT2 :
    Req (riemannIntegralI (f := bumpT2) (L := (⟨3, 1⟩ : Q)) (by decide) (by decide)
        bumpT2_lip bumpT2_congr (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (Radd (Radd (Rneg one) (logN 2 (by omega)))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rsub (logN 4 (by omega)) (logN 3 (by omega))))) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
    (Int.mul_nonneg (by decide) (by decide)) _ _
    (T2t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) T2t_congr
    (fun t => bumpT2_pull t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := fun t => Radd (Rneg one) (gRecip t))
    (g := fun t => Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (gRecipC 3 t))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (T2at_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) T2at_congr
    (s2g3_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g3_congr
    (T2t_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) T2t_congr) ?_
  refine Radd_congr ?_ ?_
  · refine Req_trans (riemannIntegral_add
      (f := fun _ => Rneg one) (g := gRecip)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (lip_const (Rneg one) (Qmul_den_pos (by decide) (by decide))
        (Int.mul_nonneg (by decide) (by decide)))
      (congr_const (Rneg one))
      (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr
      (T2at_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) T2at_congr) ?_
    refine Radd_congr (riemannIntegral_const_gen (Rneg one)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (lip_const (Rneg one) (Qmul_den_pos (by decide) (by decide))
        (Int.mul_nonneg (by decide) (by decide)))
      (congr_const (Rneg one))) ?_
    exact riemannIntegral_recip_gen
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecip_lip_at (Qmul_den_pos (by decide) (by decide)) (by decide)) gRecip_congr
  · refine Req_trans (riemannIntegral_smul (f := gRecipC 3) (⟨2, 1⟩ : Q) (by decide)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecipC_lip_at 3 (Qmul_den_pos (by decide) (by decide)) (by decide)) (gRecipC_congr 3)
      (s2g3_lip (Qmul_den_pos (by decide) (by decide)) (by decide)) s2g3_congr) ?_
    exact Rmul_congr (Req_refl _) (riemannIntegral_recipC_gen 3 (by omega)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecipC_lip_at 3 (Qmul_den_pos (by decide) (by decide)) (by decide)) (gRecipC_congr 3))

/-- **The bump test's archimedean tail, CONSTRUCTED**: the sum of the two compact pieces
    (the improper remainder past the support vanishes identically — `f(1) = 0`). -/
def bumpArchTail : Real :=
  Radd
    (riemannIntegralI (f := bumpT1) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      bumpT1_lip bumpT1_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
    (riemannIntegralI (f := bumpT2) (L := (⟨3, 1⟩ : Q)) (by decide) (by decide)
      bumpT2_lip bumpT2_congr (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))

/-- **`bumpArchTail ≈ (1 − (log 3 − log 2)) + ((−1 + log 2) + 2·(log 4 − log 3))`**
    (`= 6·log 2 − 3·log 3`, using `log 4 = 2·log 2`): the bump's full archimedean tail,
    reduced in the kernel. -/
theorem bumpArchTail_eq : Req bumpArchTail
    (Radd (Rsub one (Rsub (logN 3 (by omega)) (logN 2 (by omega))))
      (Radd (Radd (Rneg one) (logN 2 (by omega)))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rsub (logN 4 (by omega)) (logN 3 (by omega)))))) :=
  Radd_congr bump_pieceT1 bump_pieceT2

end UOR.Bridge.F1Square.Analysis
