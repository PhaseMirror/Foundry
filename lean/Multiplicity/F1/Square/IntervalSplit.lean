/-
F1 square — **certified integration, brick 70** (`IntervalSplit.lean`): **EVERY INTERVAL SPLITS AT
ITS MIDPOINT** —

    `∫_a^{a+w} f  ≈  ∫_a^{a+w/2} f  +  ∫_{a+w/2}^{a+w} f`   (`riemannIntegralI_split_half`).

Brick 68 split `[0,1]`; this is the general law, and it is the one downstream work needs, because
iterating it reaches every dyadic sub-interval of every interval.

The mechanism is that the affine pullbacks COMPOSE. `∫_a^{a+w} f` is by definition `w` times the
unit integral of `f ∘ α_{a,w}`, and brick 68 splits that unit integral into the two half-integrals
of `f ∘ α_{a,w} ∘ α_{0,1/2}` and `f ∘ α_{a,w} ∘ α_{1/2,1/2}`. The two composites are exactly the
pullbacks of the two half-intervals (`affineMap_half_left`, `affineMap_half_right`):

    `α_{a,w} ∘ α_{0,1/2} = α_{a,w/2}`,      `α_{a,w} ∘ α_{1/2,1/2} = α_{a+w/2,w/2}`,

so each piece is already the interval integral it should be — once the two certificate moduli are
reconciled, `(L·w)·½` against `L·(w/2)`, which are `Qeq`-equal but not syntactically equal. That
reconciliation is `riemannIntegral_congr_mod`: weaken to a common modulus
(`lip_weaken`), move the certificate (`riemannIntegral_certif_irrel`), then transport the
integrand (`riemannIntegral_congr`). It is the reusable half of this brick.

HONEST SCOPE. One split, at the midpoint of an arbitrary interval, for the Lipschitz class.
Iterating it is left to the consumer — no induction over subdivisions is performed here, and
nothing about non-dyadic split points is claimed. Integration substrate; nothing here touches the
Weil form. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.IntegralPiece

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Half a rational width. -/
def halfQ (w : Q) : Q := mul (⟨1, 2⟩ : Q) w

theorem halfQ_den {w : Q} (hw : 0 < w.den) : 0 < (halfQ w).den := Qmul_den_pos (by decide) hw

theorem halfQ_num {w : Q} (hwn : 0 ≤ w.num) : 0 ≤ (halfQ w).num :=
  Int.mul_nonneg (by show (0 : Int) ≤ 1; decide) hwn

/-- **Certificate-and-integrand transport**: pointwise-equal integrands certified at moduli
    ordered by `Qle` have the same integral. -/
theorem riemannIntegral_congr_mod {f g : Real → Real} {L L' : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hL'd : 0 < L'.den) (hL'n : 0 ≤ L'.num)
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (hq : Qle L L') (hfg : ∀ x, Req (f x) (g x)) :
    Req (riemannIntegral hLd hLn hlipf hfcf) (riemannIntegral hL'd hL'n hlipg hfcg) :=
  Req_trans
    (riemannIntegral_certif_irrel hLd hLn hlipf hfcf hL'd hL'n
      (lip_weaken hLd hL'd hq hlipf) hfcf)
    (riemannIntegral_congr hL'd hL'n (lip_weaken hLd hL'd hq hlipf) hfcf hlipg hfcg hfg)

-- ===========================================================================
-- The affine pullbacks compose.
-- ===========================================================================

/-- `w·0 ≈ 0` as embedded rationals. -/
private theorem mul_zeroQ (w : Q) (hw : 0 < w.den) :
    Req (Rmul (ofQ w hw) (ofQ (⟨0, 1⟩ : Q) (by decide))) zero :=
  Req_trans (Rmul_congr (Req_refl _) (Req_of_seq_Qeq (fun _ => Qeq_refl _)))
    (Rmul_zero (ofQ w hw))

/-- `w·(x/2) ≈ (w/2)·x`. -/
private theorem mul_halfQ (w : Q) (hw : 0 < w.den) (x : Real) :
    Req (Rmul (ofQ w hw) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x))
        (Rmul (ofQ (halfQ w) (halfQ_den hw)) x) := by
  refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
  refine Rmul_congr ?_ (Req_refl x)
  refine Req_trans (Rmul_ofQ_ofQ hw (by decide)) ?_
  exact ofQ_congr _ (halfQ_den hw) (by simp only [Qeq, mul, halfQ]; push_cast; ring_uor)

/-- **The left half's pullback composes**: `α_{a,w} ∘ α_{0,1/2} = α_{a,w/2}`. -/
theorem affineMap_half_left (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (x : Real) :
    Req (affineMap a w ha hw
          (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x))
        (affineMap a (halfQ w) ha (halfQ_den hw) x) := by
  show Req (Radd (ofQ a ha) (Rmul (ofQ w hw)
      (Radd (ofQ (⟨0, 1⟩ : Q) (by decide))
            (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x))))
    (Radd (ofQ a ha) (Rmul (ofQ (halfQ w) (halfQ_den hw)) x))
  refine Radd_congr (Req_refl _) ?_
  refine Req_trans (Rmul_distrib (ofQ w hw) _ _) ?_
  refine Req_trans (Radd_congr (mul_zeroQ w hw) (mul_halfQ w hw x)) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

/-- **The right half's pullback composes**: `α_{a,w} ∘ α_{1/2,1/2} = α_{a+w/2,w/2}`. -/
theorem affineMap_half_right (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (x : Real) :
    Req (affineMap a w ha hw
          (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x))
        (affineMap (add a (halfQ w)) (halfQ w)
          (add_den_pos ha (halfQ_den hw)) (halfQ_den hw) x) := by
  show Req (Radd (ofQ a ha) (Rmul (ofQ w hw)
      (Radd (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x))))
    (Radd (ofQ (add a (halfQ w)) (add_den_pos ha (halfQ_den hw)))
          (Rmul (ofQ (halfQ w) (halfQ_den hw)) x))
  have hhalf : Req (Rmul (ofQ w hw) (ofQ (⟨1, 2⟩ : Q) (by decide)))
      (ofQ (halfQ w) (halfQ_den hw)) :=
    Req_trans (Rmul_ofQ_ofQ hw (by decide))
      (ofQ_congr _ (halfQ_den hw) (by simp only [Qeq, mul, halfQ]; push_cast; ring_uor))
  refine Req_trans (Radd_congr (Req_refl _) (Rmul_distrib (ofQ w hw) _ _)) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr hhalf (mul_halfQ w hw x))) ?_
  refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
  exact Radd_congr (Radd_ofQ_ofQ ha (halfQ_den hw)) (Req_refl _)

-- ===========================================================================
-- The general splitting law.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **EVERY INTERVAL SPLITS AT ITS MIDPOINT**:
    `∫_a^{a+w} f ≈ ∫_a^{a+w/2} f + ∫_{a+w/2}^{a+w} f`. -/
theorem riemannIntegralI_split_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)
      (Radd
        (riemannIntegralI hLd hLn hlip hfc a (halfQ w) ha (halfQ_den hw) (halfQ_num hwn))
        (riemannIntegralI hLd hLn hlip hfc (add a (halfQ w)) (halfQ w)
          (add_den_pos ha (halfQ_den hw)) (halfQ_den hw) (halfQ_num hwn))) := by
  -- the pulled-back integrand on `[a, a+w]`, and its modulus
  have hMd : 0 < (mul L w).den := Qmul_den_pos hLd hw
  have hMn : (0 : Int) ≤ (mul L w).num := Int.mul_nonneg hLn hwn
  have glip := affine_lip hLd hLn hlip a w ha hw hwn
  have gfc : ∀ x y, Req x y →
      Req (f (affineMap a w ha hw x)) (f (affineMap a w ha hw y)) :=
    fun x y h => hfc _ _ (affineMap_congr a w ha hw h)
  -- the moduli agree up to `Qeq`
  have hqL : Qle (mul (mul L w) (⟨1, 2⟩ : Q)) (mul L (halfQ w)) :=
    Qeq_le (by simp only [Qeq, mul, halfQ]; push_cast; ring_uor)
  show Req (Rmul (ofQ w hw) (riemannIntegral hMd hMn glip gfc)) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (riemannIntegral_split_half hMd hMn glip gfc)) ?_
  refine Req_trans (Rmul_distrib (ofQ w hw) _ _) ?_
  refine Radd_congr ?_ ?_
  · refine Req_trans (mul_halfQ w hw _) (Rmul_congr (Req_refl _) ?_)
    exact riemannIntegral_congr_mod _ _ _ _ _ _ _ _ hqL
      (fun x => hfc _ _ (affineMap_half_left a w ha hw x))
  · refine Req_trans (mul_halfQ w hw _) (Rmul_congr (Req_refl _) ?_)
    exact riemannIntegral_congr_mod _ _ _ _ _ _ _ _ hqL
      (fun x => hfc _ _ (affineMap_half_right a w ha hw x))

end Multiplicity.UOR.Bridge.F1Square.Square
