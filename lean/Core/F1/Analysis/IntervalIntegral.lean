/-
F1 square — certified integration over a **general bounded interval** `[a, a+w]` (rational endpoints),
via the affine change of variables `x ↦ a + w·x` pulling it back to `[0,1]`.

`∫_a^{a+w} f = w · ∫₀¹ (x ↦ f(a + w·x))`. The pulled-back integrand `g x = f(a + w·x)` is Lipschitz
with constant `L·w` (the affine map has slope `w`), and respects `≈`, so the `[0,1]` gateway
(`riemannIntegral`) applies. This is the stepping stone to the half-line `∫₁^∞` (a convergent sum of
unit-interval integrals) that the Mellin link to the completed ζ needs, and to Track-2's windowed
Weil pairing.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.DyadicIntegral
import Core.F1.Analysis.RabsLemmas

namespace UOR.Bridge.F1Square.Analysis

/-- The affine pullback `x ↦ a + w·x` mapping `[0,1]` onto `[a, a+w]`. -/
def affineMap (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (x : Real) : Real :=
  Radd (ofQ a ha) (Rmul (ofQ w hw) x)

/-- The affine pullback respects `≈`. -/
theorem affineMap_congr (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) {x y : Real} (h : Req x y) :
    Req (affineMap a w ha hw x) (affineMap a w ha hw y) :=
  Radd_congr (Req_refl _) (Rmul_congr (Req_refl _) h)

/-- The affine difference collapses the offset: `(a + w·x) − (a + w·y) ≈ w·(x − y)`. -/
theorem affineMap_diff (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (x y : Real) :
    Req (Rsub (affineMap a w ha hw x) (affineMap a w ha hw y)) (Rmul (ofQ w hw) (Rsub x y)) := by
  refine Req_trans (Rsub_Radd_Radd (ofQ a ha) (Rmul (ofQ w hw) x) (ofQ a ha) (Rmul (ofQ w hw) y)) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ a ha)) (Req_refl _)) ?_
  refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
  exact Req_symm (Rmul_sub_distrib (ofQ w hw) x y)

/-- The pulled-back integrand `g x = f(a + w·x)` is `(L·w)`-Lipschitz (slope-`w` chain rule). -/
theorem affine_lip {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (x y : Real) :
    Rle (Rabs (Rsub (f (affineMap a w ha hw x)) (f (affineMap a w ha hw y))))
        (Rmul (ofQ (mul L w) (Qmul_den_pos hLd hw)) (Rabs (Rsub x y))) := by
  have step2 : Req (Rabs (Rsub (affineMap a w ha hw x) (affineMap a w ha hw y)))
      (Rmul (ofQ w hw) (Rabs (Rsub x y))) :=
    Req_trans (Rabs_congr (affineMap_diff a w ha hw x y)) (Rabs_Rmul_ofQ_nonneg hw hwn (Rsub x y))
  have step3 : Req (Rmul (ofQ L hLd) (Rmul (ofQ w hw) (Rabs (Rsub x y))))
      (Rmul (ofQ (mul L w) (Qmul_den_pos hLd hw)) (Rabs (Rsub x y))) :=
    Req_trans (Req_symm (Rmul_assoc _ _ _)) (Rmul_congr (Rmul_ofQ_ofQ hLd hw) (Req_refl _))
  exact Rle_trans (hlip _ _)
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hLd hLn) (Rle_of_Req step2)) (Rle_of_Req step3))

/-- **The certified integral over `[a, a+w]`** (`w ≥ 0`): `∫_a^{a+w} f = w · ∫₀¹ f(a + w·x)`. -/
def riemannIntegralI {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Real :=
  Rmul (ofQ w hw)
    (riemannIntegral (f := fun x => f (affineMap a w ha hw x)) (L := mul L w)
      (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlip a w ha hw hwn)
      (fun x y h => hfc _ _ (affineMap_congr a w ha hw h)))

/-- The constant integrand's Lipschitz witness at the zero modulus. -/
theorem const_lip0 (c : Real) : ∀ x y,
    Rle (Rabs (Rsub c c)) (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  have hL : Req (Rabs (Rsub c c)) zero := Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero
  have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  have hR : Req (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) zero :=
    Req_trans (Rmul_congr hz0 (Req_refl _))
      (Req_trans (Rmul_comm zero (Rabs (Rsub x y))) (Rmul_zero (Rabs (Rsub x y))))
  exact Rle_trans (Rle_of_Req hL) (Rle_of_Req (Req_symm hR))

/-- **`∫_a^{a+w} c = w·c`** — the interval integral of a constant integrand. (`g = a+w·x ↦ c` is the
    constant `c`, so the inner `∫₀¹ c = c`, scaled by the width `w`.) -/
theorem riemannIntegralI_const (c : Real) (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI (f := fun _ => c) (L := (⟨0, 1⟩ : Q)) (by decide) (by decide)
          (const_lip0 c) (fun _ _ _ => Req_refl c) a w ha hw hwn)
        (Rmul (ofQ w hw) c) :=
  Rmul_congr (Req_refl _) (riemannIntegral_const_gen c _ _ _ _)

/-- **`∫_a^{a+w} f ≥ 0` for `f ≥ 0`** (width `w ≥ 0`) — inherits from the unit-interval positivity,
    scaled by the non-negative width. -/
theorem riemannIntegralI_nonneg {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Rnonneg (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) :=
  Rnonneg_Rmul (Rnonneg_ofQ hw hwn)
    (riemannIntegral_nonneg _ _ _ _ (fun x => hfnn (affineMap a w ha hw x)))

/-- **`∫_a^{a+w} f ≤ ∫_a^{a+w} g` for `f ≤ g`** (shared modulus `L`, width `w ≥ 0`) — inherits from
    the unit-interval monotonicity, scaled by the non-negative width. -/
theorem riemannIntegralI_le {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y)) (hfg : ∀ x, Rle (f x) (g x))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Rle (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)
        (riemannIntegralI hLd hLn hlipg hfcg a w ha hw hwn) :=
  Rmul_le_Rmul_left (Rnonneg_ofQ hw hwn)
    (riemannIntegral_le _ _ _ _ _ _ (fun x => hfg (affineMap a w ha hw x)))

/-- **The interval integral is additive in the integrand** `∫ₐ^{a+w} (f+g) = ∫ₐ^{a+w} f + ∫ₐ^{a+w} g`
    — `riemannIntegral_add` on the affine-rescaled integrands (shared Lipschitz constant `L`), then
    `Rmul_distrib` through the width factor. -/
theorem riemannIntegralI_add {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (hlipfg : ∀ x y, Rle (Rabs (Rsub (Radd (f x) (g x)) (Radd (f y) (g y))))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcfg : ∀ x y, Req x y → Req (Radd (f x) (g x)) (Radd (f y) (g y)))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlipfg hfcfg a w ha hw hwn)
        (Radd (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)
              (riemannIntegralI hLd hLn hlipg hfcg a w ha hw hwn)) := by
  refine Req_trans (Rmul_congr (Req_refl (ofQ w hw))
    (riemannIntegral_add (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlipf a w ha hw hwn)
      (fun x y h => hfcf _ _ (affineMap_congr a w ha hw h))
      (affine_lip hLd hLn hlipg a w ha hw hwn)
      (fun x y h => hfcg _ _ (affineMap_congr a w ha hw h))
      (affine_lip hLd hLn hlipfg a w ha hw hwn)
      (fun x y h => hfcfg _ _ (affineMap_congr a w ha hw h)))) ?_
  exact Rmul_distrib (ofQ w hw) _ _

/-- **`∫ₐ^{a+w} f ≈ ∫ₐ^{a+w} g` for `f ≈ g` pointwise** (shared `L`) — the interval integral respects
    `≈` of the integrand, by antisymmetry of `riemannIntegralI_le`. -/
theorem riemannIntegralI_congr {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (hfg : ∀ x, Req (f x) (g x)) :
    Req (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)
        (riemannIntegralI hLd hLn hlipg hfcg a w ha hw hwn) :=
  Rle_antisymm
    (riemannIntegralI_le hLd hLn hlipf hfcf hlipg hfcg (fun x => Rle_of_Req (hfg x)) a w ha hw hwn)
    (riemannIntegralI_le hLd hLn hlipg hfcg hlipf hfcf (fun x => Rle_of_Req (Req_symm (hfg x)))
      a w ha hw hwn)

/-- **The interval integral respects negation** `∫ₐ^{a+w} (−f) = −∫ₐ^{a+w} f` — `riemannIntegral_neg`
    on the affine-rescaled integrand, then `Rmul_neg_right` through the width factor. -/
theorem riemannIntegralI_neg {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipnf : ∀ x y, Rle (Rabs (Rsub (Rneg (f x)) (Rneg (f y)))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcnf : ∀ x y, Req x y → Req (Rneg (f x)) (Rneg (f y)))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlipnf hfcnf a w ha hw hwn)
        (Rneg (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)) :=
  Req_trans (Rmul_congr (Req_refl (ofQ w hw))
    (riemannIntegral_neg (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlipf a w ha hw hwn)
      (fun x y h => hfcf _ _ (affineMap_congr a w ha hw h))
      (affine_lip hLd hLn hlipnf a w ha hw hwn)
      (fun x y h => hfcnf _ _ (affineMap_congr a w ha hw h))))
    (Rmul_neg_right _ _)

/-- **The interval integral respects a constant scalar** `∫ₐ^{a+w} (q·f) = q·∫ₐ^{a+w} f` for `q : ℚ`
    — `riemannIntegral_smul` on the affine-rescaled integrand, then left-commute the scalar `q` past
    the width factor `w` (`w·(q·I) ≈ q·(w·I)` via `Rmul_assoc`/`Rmul_comm`). -/
theorem riemannIntegralI_smul {f : Real → Real} {L : Q} (q : Q) (hq : 0 < q.den)
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipqf : ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hq) (f x)) (Rmul (ofQ q hq) (f y))))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcqf : ∀ x y, Req x y → Req (Rmul (ofQ q hq) (f x)) (Rmul (ofQ q hq) (f y)))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlipqf hfcqf a w ha hw hwn)
        (Rmul (ofQ q hq) (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)) := by
  refine Req_trans (Rmul_congr (Req_refl (ofQ w hw))
    (riemannIntegral_smul (f := fun x => f (affineMap a w ha hw x)) q hq
      (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlipf a w ha hw hwn)
      (fun x y h => hfcf _ _ (affineMap_congr a w ha hw h))
      (affine_lip hLd hLn hlipqf a w ha hw hwn)
      (fun x y h => hfcqf _ _ (affineMap_congr a w ha hw h)))) ?_
  exact Req_trans (Req_symm (Rmul_assoc (ofQ w hw) (ofQ q hq) _))
    (Req_trans (Rmul_congr (Rmul_comm (ofQ w hw) (ofQ q hq)) (Req_refl _))
      (Rmul_assoc (ofQ q hq) (ofQ w hw) _))

end UOR.Bridge.F1Square.Analysis
