/-
F1 square — certified integration, **the affine evaluation layer** and **the first evaluated
Weil-slot component**: `∫₀¹ (α + q·x) dx ≈ α + q/2` over any admissible Lipschitz datum, the
interval version through the affine pullback, and the tent test's first pole integral

    `∫_{1/2}^{1} (2x − 1) dx + ∫_{1}^{2} (2 − x) dx  ≈  3/4`   (`tentPoleA_eq`)

— the `∫₀^∞ f(x) dx` part of the pole term `f̃(1)` for the piecewise-linear tent test
(knots `1/2, 1, 2`; the `X = 2` prime-free window: all prime-side evaluations vanish). This is
the first piece of a `WeilSlot` interface field REDUCED in the kernel rather than carried as
data — the Sonine route's step-1/2 boundary moving.

WHAT REMAINS for the full slot (recorded): the `1/x`-weighted pole part (`f̃(0) = log 2` for
the tent) and the archimedean tail (`−1 − 6·log 2 + 3·log 3`) have RATIONAL-FUNCTION
integrands (`2 − 1/x`, `−(x²−x+2)/(x(x+1))`, `−2/(x²−1)` past the support); their
construction needs a globally-Lipschitz clamped-reciprocal gadget over `Rinv` (the
max-with-a-rational clamp `RmaxZero` keeps the argument `≥ a > 0` pointwise, so the
`Rinv` witness is uniform) — the next integration brick.

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.IntegralEval

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Lipschitz data for constant, scaled, and affine integrands (any modulus L
-- dominating the slope).
-- ===========================================================================

/-- A constant integrand is `L`-Lipschitz for every `L ≥ 0`. -/
theorem lip_const (c : Real) {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num) : ∀ x y : Real,
    Rle (Rabs (Rsub c c)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero)) ?_
  exact Rle_zero_of_Rnonneg (Rnonneg_Rmul (Rnonneg_ofQ hLd hLn) (Rnonneg_Rabs _))

/-- A constant integrand respects `≈`. -/
theorem congr_const (c : Real) : ∀ x y : Real, Req x y → Req c c := fun _ _ _ => Req_refl c

/-- The scaled integrand `x ↦ q·x` is `L`-Lipschitz whenever `|q| ≤ L`. -/
theorem lip_scaled (q : Q) (hq : 0 < q.den) {L : Q} (hLd : 0 < L.den)
    (h : Qle (Qabs q) L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rmul (ofQ q hq) x) (Rmul (ofQ q hq) y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr
    (Req_symm (Rmul_sub_distrib (ofQ q hq) x y)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul (ofQ q hq) (Rsub x y))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Rabs_ofQ hq) (Req_refl (Rabs (Rsub x y))))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (Qabs_den_pos hq) hLd h)

/-- The scaled integrand respects `≈`. -/
theorem congr_scaled (q : Q) (hq : 0 < q.den) : ∀ x y : Real, Req x y →
    Req (Rmul (ofQ q hq) x) (Rmul (ofQ q hq) y) :=
  fun _ _ h => Rmul_congr (Req_refl _) h

/-- The affine integrand `x ↦ α + q·x` is `L`-Lipschitz whenever `|q| ≤ L`. -/
theorem lip_affine (α q : Q) (ha : 0 < α.den) (hq : 0 < q.den) {L : Q} (hLd : 0 < L.den)
    (h : Qle (Qabs q) L) : ∀ x y : Real,
    Rle (Rabs (Rsub (Radd (ofQ α ha) (Rmul (ofQ q hq) x))
        (Radd (ofQ α ha) (Rmul (ofQ q hq) y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  have hdrop : Req (Rsub (Radd (ofQ α ha) (Rmul (ofQ q hq) x))
      (Radd (ofQ α ha) (Rmul (ofQ q hq) y)))
      (Rsub (Rmul (ofQ q hq) x) (Rmul (ofQ q hq) y)) := by
    refine Req_trans (Rsub_Radd_Radd (ofQ α ha) (Rmul (ofQ q hq) x)
      (ofQ α ha) (Rmul (ofQ q hq) y)) ?_
    refine Req_trans (Radd_congr (Radd_neg (ofQ α ha)) (Req_refl _)) ?_
    exact Req_trans (Radd_comm zero _) (Radd_zero _)
  exact Rle_trans (Rle_of_Req (Rabs_congr hdrop)) (lip_scaled q hq hLd h x y)

/-- The affine integrand respects `≈`. -/
theorem congr_affine (α q : Q) (ha : 0 < α.den) (hq : 0 < q.den) : ∀ x y : Real, Req x y →
    Req (Radd (ofQ α ha) (Rmul (ofQ q hq) x)) (Radd (ofQ α ha) (Rmul (ofQ q hq) y)) :=
  fun _ _ h => Radd_congr (Req_refl _) (Rmul_congr (Req_refl _) h)

-- ===========================================================================
-- The evaluations on [0,1].
-- ===========================================================================

/-- **`∫₀¹ q·x dx ≈ q/2`** — the scaled-identity evaluation, through `riemannIntegral_smul`
    and the schedule-general `riemannIntegral_id_gen`. -/
theorem riemannIntegral_scaled (q : Q) (hq : 0 < q.den) {L : Q} (hLd : 0 < L.den)
    (hLn : 0 ≤ L.num) (hqL : Qle (Qabs q) L)
    (hlipid : ∀ x y : Real, Rle (Rabs (Rsub x y)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcid : ∀ x y : Real, Req x y → Req x y) :
    Req (riemannIntegral (f := fun x => Rmul (ofQ q hq) x) hLd hLn
        (lip_scaled q hq hLd hqL) (congr_scaled q hq))
      (ofQ (mul q (⟨1, 2⟩ : Q)) (Qmul_den_pos hq (by decide))) := by
  refine Req_trans (riemannIntegral_smul (f := fun x => x) q hq hLd hLn hlipid hfcid
    (lip_scaled q hq hLd hqL) (congr_scaled q hq)) ?_
  refine Req_trans (Rmul_congr (Req_refl (ofQ q hq))
    (riemannIntegral_id_gen hLd hLn hlipid hfcid)) ?_
  exact Rmul_ofQ_ofQ hq (by decide)

/-- **`∫₀¹ (α + q·x) dx ≈ α + q/2`** — the affine evaluation: additivity splits off the
    constant, the scaled part evaluates by `riemannIntegral_scaled`. -/
theorem riemannIntegral_affine (α q : Q) (ha : 0 < α.den) (hq : 0 < q.den) {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num) (hqL : Qle (Qabs q) L)
    (hlipid : ∀ x y : Real, Rle (Rabs (Rsub x y)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcid : ∀ x y : Real, Req x y → Req x y) :
    Req (riemannIntegral (f := fun x => Radd (ofQ α ha) (Rmul (ofQ q hq) x)) hLd hLn
        (lip_affine α q ha hq hLd hqL) (congr_affine α q ha hq))
      (ofQ (add α (mul q (⟨1, 2⟩ : Q)))
        (add_den_pos ha (Qmul_den_pos hq (by decide)))) := by
  refine Req_trans (riemannIntegral_add (f := fun _ => ofQ α ha)
    (g := fun x => Rmul (ofQ q hq) x) hLd hLn
    (lip_const (ofQ α ha) hLd hLn) (congr_const (ofQ α ha))
    (lip_scaled q hq hLd hqL) (congr_scaled q hq)
    (lip_affine α q ha hq hLd hqL) (congr_affine α q ha hq)) ?_
  refine Req_trans (Radd_congr
    (riemannIntegral_const_gen (ofQ α ha) hLd hLn
      (lip_const (ofQ α ha) hLd hLn) (congr_const (ofQ α ha)))
    (riemannIntegral_scaled q hq hLd hLn hqL hlipid hfcid)) ?_
  exact Radd_ofQ_ofQ ha (Qmul_den_pos hq (by decide))

-- ===========================================================================
-- The interval version, through the affine pullback.
-- ===========================================================================

/-- The pullback of an affine integrand along `x ↦ a + w·x` is affine:
    `α + q(a + wx) ≈ (α + qa) + (qw)·x`. -/
theorem affine_pullback_eq (α q a w : Q) (ha : 0 < α.den) (hq : 0 < q.den)
    (haa : 0 < a.den) (hw : 0 < w.den) (x : Real) :
    Req (Radd (ofQ α ha) (Rmul (ofQ q hq) (affineMap a w haa hw x)))
      (Radd (ofQ (add α (mul q a)) (add_den_pos ha (Qmul_den_pos hq haa)))
        (Rmul (ofQ (mul q w) (Qmul_den_pos hq hw)) x)) := by
  refine Req_trans (Radd_congr (Req_refl _)
    (Rmul_distrib (ofQ q hq) (ofQ a haa) (Rmul (ofQ w hw) x))) ?_
  refine Req_trans (Req_symm (Radd_assoc (ofQ α ha)
    (Rmul (ofQ q hq) (ofQ a haa)) (Rmul (ofQ q hq) (Rmul (ofQ w hw) x)))) ?_
  refine Radd_congr
    (Req_trans (Radd_congr (Req_refl _) (Rmul_ofQ_ofQ hq haa))
      (Radd_ofQ_ofQ ha (Qmul_den_pos hq haa))) ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ q hq) (ofQ w hw) x)) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ hq hw) (Req_refl x)

/-- The identity's Lipschitz datum at any modulus `L ≥ 1`. -/
theorem lip_id_ge {L : Q} (hLd : 0 < L.den) (h : Qle (⟨1, 1⟩ : Q) L) : ∀ x y : Real,
    Rle (Rabs (Rsub x y)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Req_symm (Req_trans
    (Rmul_comm (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) (Rmul_one _)))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h)

-- ===========================================================================
-- THE FIRST EVALUATED WEIL-SLOT COMPONENT: the tent test's `∫ f` pole part.
-- The tent (knots 1/2, 1, 2; the X = 2 prime-free window) has
-- `∫₀^∞ f(x) dx = ∫_{1/2}^{1} (2x−1) dx + ∫_{1}^{2} (2−x) dx = 1/4 + 1/2 = 3/4`.
-- ===========================================================================

/-- `∫_{1/2}^{1} (2x − 1) dx ≈ 1/4` — the tent's rising edge, evaluated. -/
theorem tent_piece1 :
    Req (riemannIntegralI (f := fun x => Radd (ofQ (⟨-1, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
        (lip_affine (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
        (congr_affine (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (by decide) (by decide))
        (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
      (ofQ (⟨1, 4⟩ : Q) (by decide)) := by
  show Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) _) _
  refine Req_trans (Rmul_congr (Req_refl (ofQ (⟨1, 2⟩ : Q) (by decide)))
    (Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)) _ _
      (lip_affine (add (⟨-1, 1⟩ : Q) (mul (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q)))
        (mul (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q)) (by decide) (by decide)
        (Qmul_den_pos (by decide) (by decide)) (by decide))
      (congr_affine (add (⟨-1, 1⟩ : Q) (mul (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q)))
        (mul (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q)) (by decide) (by decide))
      (fun x => affine_pullback_eq (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
        (by decide) (by decide) (by decide) (by decide) x))
      (riemannIntegral_affine (add (⟨-1, 1⟩ : Q) (mul (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q)))
        (mul (⟨2, 1⟩ : Q) (⟨1, 2⟩ : Q)) (by decide) (by decide)
        (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
        (by decide)
        (lip_id_ge (Qmul_den_pos (by decide) (by decide)) (by decide))
        congr_id))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) ?_
  exact ofQ_congr (by decide) (by decide) (by decide)

/-- `∫_{1}^{2} (2 − x) dx ≈ 1/2` — the tent's falling edge, evaluated. -/
theorem tent_piece2 :
    Req (riemannIntegralI (f := fun x => Radd (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨-1, 1⟩ : Q) (by decide)) x)) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
        (lip_affine (⟨2, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
        (congr_affine (⟨2, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide))
        (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
      (ofQ (⟨1, 2⟩ : Q) (by decide)) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rmul_congr (Req_refl (ofQ (⟨1, 1⟩ : Q) (by decide)))
    (Req_trans (riemannIntegral_congr (Qmul_den_pos (by decide) (by decide))
      (Int.mul_nonneg (by decide) (by decide)) _ _
      (lip_affine (add (⟨2, 1⟩ : Q) (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)))
        (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide)
        (Qmul_den_pos (by decide) (by decide)) (by decide))
      (congr_affine (add (⟨2, 1⟩ : Q) (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)))
        (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide))
      (fun x => affine_pullback_eq (⟨2, 1⟩ : Q) (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)
        (by decide) (by decide) (by decide) (by decide) x))
      (riemannIntegral_affine (add (⟨2, 1⟩ : Q) (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)))
        (mul (⟨-1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (by decide) (by decide)
        (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
        (by decide)
        (lip_id_ge (Qmul_den_pos (by decide) (by decide)) (by decide))
        congr_id))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) ?_
  exact ofQ_congr (by decide) (by decide) (by decide)

/-- **The tent test's `∫₀^∞ f` pole component, CONSTRUCTED**: the sum of the two certified
    edge integrals. -/
def tentPoleA : Real :=
  Radd
    (riemannIntegralI (f := fun x => Radd (ofQ (⟨-1, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      (lip_affine (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
      (congr_affine (⟨-1, 1⟩ : Q) (⟨2, 1⟩ : Q) (by decide) (by decide))
      (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
    (riemannIntegralI (f := fun x => Radd (ofQ (⟨2, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨-1, 1⟩ : Q) (by decide)) x)) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      (lip_affine (⟨2, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide) (by decide) (by decide))
      (congr_affine (⟨2, 1⟩ : Q) (⟨-1, 1⟩ : Q) (by decide) (by decide))
      (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))

/-- **THE FIRST EVALUATED WEIL-SLOT COMPONENT**: `tentPoleA ≈ 3/4` — a `WeilSlot` interface
    integral reduced in the kernel (constructed AND evaluated), not carried as data. -/
theorem tentPoleA_eq : Req tentPoleA (ofQ (⟨3, 4⟩ : Q) (by decide)) := by
  refine Req_trans (Radd_congr tent_piece1 tent_piece2) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact ofQ_congr (add_den_pos (by decide) (by decide)) (by decide) (by decide)

end UOR.Bridge.F1Square.Analysis
