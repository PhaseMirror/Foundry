/-
F1 square — **the real-bound window estimate** (`WindowBoundReal.lean`): `|∫_a^{a+w} f| ≤ w·K` for a
REAL bound `K` — the variant of `riemannIntegralI_abs_le_window` (`MellinDecay`) whose window bound is
a real number, not a rational.

The rational-bound version suffices for a fixed test, but a PARAMETRIC estimate — bounding the
integral of a difference `f_x − f_{x'}` by `(rational)·|x − x'|`, where `|x − x'|` is a fixed real —
needs the window bound at a real `K = (rational)·|x − x'|`. That is exactly what
`riemannIntegralI_abs_le_window_real` supplies; it is the tool the Lipschitz-in-`x` continuity of the
real-parameter convolution runs through.

The proof is the same as the rational-bound original: window-local comparison against the constant
integrands `±K`, whose interval integrals evaluate to `w·(±K)` through certificate independence.

HONEST SCOPE. A general estimate for the certified interval integral; no positivity, no crux claim.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.MellinDecay

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The real-bound window estimate**: an integrand bounded by a REAL `K ≥ 0` on the affine image of
    `[0,1]` (i.e. on `[a, a+w]`) has `|∫_a^{a+w} f| ≤ w·K`. Same window-local comparison against the
    constants `±K` as the rational-bound `riemannIntegralI_abs_le_window`, now with a real bound. -/
theorem riemannIntegralI_abs_le_window_real {f : Real → Real} {L : Q} (hLd : 0 < L.den)
    (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w : Q) (K : Real) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hbd : ∀ x, Rle zero x → Rle x one → Rle (Rabs (f (affineMap a w ha hw x))) K) :
    Rle (Rabs (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)) (Rmul (ofQ w hw) K) := by
  have hzL : Qle (⟨0, 1⟩ : Q) L := by
    show (0 : Int) * (L.den : Int) ≤ L.num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hLn
  have hlipK := lip_weaken (L := (⟨0, 1⟩ : Q)) (by decide) hLd hzL (const_lip0 K)
  have hlipnK := lip_weaken (L := (⟨0, 1⟩ : Q)) (by decide) hLd hzL (const_lip0 (Rneg K))
  -- the constant interval integrals evaluate: `∫I c ≈ w·c` (certificate independence inside)
  have hconst : ∀ (c : Real) (hlipc : ∀ x y, Rle (Rabs (Rsub c c))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y)))),
      Req (riemannIntegralI (f := fun _ => c) hLd hLn hlipc (fun _ _ _ => Req_refl c)
            a w ha hw hwn)
          (Rmul (ofQ w hw) c) := by
    intro c hlipc
    refine Req_trans (Rmul_congr (Req_refl _) (riemannIntegral_certif_irrel
      (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn) _ _
      (Qmul_den_pos (by decide : 0 < (⟨0, 1⟩ : Q).den) hw)
      (Int.mul_nonneg (by show (0 : Int) ≤ 0; decide) hwn)
      (affine_lip (by decide) (by show (0 : Int) ≤ 0; decide) (const_lip0 c) a w ha hw hwn)
      (fun _ _ _ => Req_refl c))) ?_
    exact riemannIntegralI_const c a w ha hw hwn
  refine Rabs_le_of_both ?_ ?_
  · -- upper: `∫I f ≤ ∫I K = w·K`
    exact Rle_trans (riemannIntegralI_le_unit hLd hLn hlip hfc hlipK
      (fun _ _ _ => Req_refl _) a w ha hw hwn
      (fun x h0 h1 => Rle_trans (Rle_Rabs_self _) (hbd x h0 h1)))
      (Rle_of_Req (hconst K hlipK))
  · -- lower: `−(w·K) ≤ ∫I f`, flipped
    have hlo : Rle (riemannIntegralI (f := fun _ => Rneg K) hLd hLn hlipnK
        (fun _ _ _ => Req_refl _) a w ha hw hwn)
        (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) :=
      riemannIntegralI_le_unit hLd hLn hlipnK (fun _ _ _ => Req_refl _) hlip hfc
        a w ha hw hwn (fun x h0 h1 => Rneg_le_of_Rabs_le (hbd x h0 h1))
    have hval : Req (riemannIntegralI (f := fun _ => Rneg K) hLd hLn hlipnK
        (fun _ _ _ => Req_refl _) a w ha hw hwn)
        (Rneg (Rmul (ofQ w hw) K)) :=
      Req_trans (hconst (Rneg K) hlipnK) (Rmul_neg_right (ofQ w hw) K)
    have h2 : Rle (Rneg (Rmul (ofQ w hw) K))
        (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) :=
      Rle_trans (Rle_of_Req (Req_symm hval)) hlo
    exact Rle_trans (Rle_Rneg h2) (Rle_of_Req (Rneg_neg _))

end Multiplicity.UOR.Bridge.F1Square.Analysis
