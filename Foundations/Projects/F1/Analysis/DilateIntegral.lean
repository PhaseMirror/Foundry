/-
F1 square — **the linear change of variables for the certified interval integral** (`DilateIntegral.lean`):
the multiplicative-substitution engine of the transform bridge's Wall 1 (Haar measure).

    `∫_{s·lo}^{s·(lo+w)} f(y) dy  ≈  s · ∫_lo^{lo+w} f(s·x) dx`     (rational scale `s > 0`)

— the affine substitution `y = s·x` at the value level, for any bounded-Lipschitz integrand `f`. The
proof is by GLOBAL affine distributivity: both sides pull back to `[0,1]` with integrands that are
pointwise equal everywhere (`s·(lo + w·t) = (s·lo) + (s·w)·t`), so no window restriction is needed;
the two natural Lipschitz moduli (`L·(s·w)` vs `(L·s)·w`) are reconciled through
`riemannIntegral_certif_irrel` (the integral value is independent of the modulus certificate).

- `dilate_lip` / `dilate_fc` — the dilated integrand `x ↦ f(s·x)` is `(L·s)`-Lipschitz and respects
  `≈` (the slope-`s` chain rule).
- `riemannIntegralI_dilate` — the change-of-variables identity above.

HONEST SCOPE. This is the LINEAR (Lebesgue) substitution `y = s·x`, the covariance of the *unweighted*
interval integral. It is the engine of — but NOT yet — Haar invariance: `∫ φ dx/x = ∫ φ(ax) dx/x`
needs this carried through the `1/x` weight (the `(1/s)·(1/x)` clamp simplification on the window),
which is the next brick. This is not the convolution `⋆` and not the Mellin theorem; the whole-space
positivity those would carry is step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.IntervalIntegral
import Foundations.F1.Analysis.IntegralCertIrrel

set_option maxHeartbeats 1000000

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The dilated integrand respects `≈`** — `x ↦ f(s·x)` is a congruence. -/
theorem dilate_fc {f : Real → Real} (hfc : ∀ x y, Req x y → Req (f x) (f y)) (s : Q)
    (hs : 0 < s.den) : ∀ x y, Req x y →
    Req (f (Rmul (ofQ s hs) x)) (f (Rmul (ofQ s hs) y)) :=
  fun _ _ h => hfc _ _ (Rmul_congr (Req_refl _) h)

/-- **The dilated integrand is `(L·s)`-Lipschitz** — `|f(s·x) − f(s·y)| ≤ L·|s·x − s·y| = (L·s)·|x−y|`
    (slope-`s` chain rule; `s ≥ 0` so `|s| = s`). -/
theorem dilate_lip {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (s : Q) (hs : 0 < s.den) (hsn : 0 ≤ s.num) : ∀ x y,
    Rle (Rabs (Rsub (f (Rmul (ofQ s hs) x)) (f (Rmul (ofQ s hs) y))))
        (Rmul (ofQ (mul L s) (Qmul_den_pos hLd hs)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (hlip (Rmul (ofQ s hs) x) (Rmul (ofQ s hs) y)) (Rle_of_Req ?_)
  refine Req_trans (Rmul_congr (Req_refl _)
    (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ s hs) x y)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rabs_Rmul (ofQ s hs) (Rsub x y))) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Rmul_congr (Rabs_ofQ_nonneg hs hsn) (Req_refl _))) ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ L hLd) (ofQ s hs) (Rabs (Rsub x y)))) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ hLd hs) (Req_refl _)

/-- **The linear change of variables** `∫_{s·lo}^{s·(lo+w)} f ≈ s · ∫_lo^{lo+w} f(s·x)` — the affine
    substitution `y = s·x` for the certified interval integral. The two pulled-back `[0,1]` integrands
    are pointwise equal everywhere (`s·(lo + w·t) = (s·lo) + (s·w)·t`); the differing Lipschitz moduli
    are reconciled by certificate-independence. -/
theorem riemannIntegralI_dilate {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (s lo w : Q) (hs : 0 < s.den) (hsn : 0 ≤ s.num) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlip hfc (mul s lo) (mul s w)
          (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) (Int.mul_nonneg hsn hwn))
        (Rmul (ofQ s hs)
          (riemannIntegralI (Qmul_den_pos hLd hs) (Int.mul_nonneg hLn hsn)
            (dilate_lip hLd hLn hlip s hs hsn) (dilate_fc hfc s hs)
            lo w hlo hw hwn)) := by
  -- The two pulled-back integrands (over [0,1]).
  -- h_L t = f (affineMap (s·lo) (s·w) t),  h_R t = f (s · affineMap lo w t).
  -- harg: they agree pointwise everywhere.
  have harg : ∀ t : Real,
      Req (f (affineMap (mul s lo) (mul s w) (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) t))
          (f (Rmul (ofQ s hs) (affineMap lo w hlo hw t))) := by
    intro t
    refine hfc _ _ ?_
    -- affineMap (s·lo) (s·w) t = (s·lo) + (s·w)·t ≈ s·(lo + w·t) = s · affineMap lo w t
    refine Req_symm ?_
    show Req (Rmul (ofQ s hs) (Radd (ofQ lo hlo) (Rmul (ofQ w hw) t)))
             (Radd (ofQ (mul s lo) (Qmul_den_pos hs hlo)) (Rmul (ofQ (mul s w) (Qmul_den_pos hs hw)) t))
    refine Req_trans (Rmul_distrib (ofQ s hs) (ofQ lo hlo) (Rmul (ofQ w hw) t)) ?_
    refine Radd_congr (Rmul_ofQ_ofQ hs hlo) ?_
    exact Req_trans (Req_symm (Rmul_assoc (ofQ s hs) (ofQ w hw) t))
      (Rmul_congr (Rmul_ofQ_ofQ hs hw) (Req_refl t))
  -- h_L carries an MR-modulus cert, borrowed from h_R's cert through harg.
  have certL_MR : ∀ x y,
      Rle (Rabs (Rsub (f (affineMap (mul s lo) (mul s w) (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) x))
                      (f (affineMap (mul s lo) (mul s w) (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) y))))
          (Rmul (ofQ (mul (mul L s) w) (Qmul_den_pos (Qmul_den_pos hLd hs) hw)) (Rabs (Rsub x y))) := by
    intro x y
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (harg x) (harg y)))) ?_
    exact affine_lip (Qmul_den_pos hLd hs) (Int.mul_nonneg hLn hsn)
      (dilate_lip hLd hLn hlip s hs hsn) lo w hlo hw hwn x y
  -- The core equality of the two [0,1] integrals: certif_irrel (ML→MR) then congr (h_L→h_R).
  have core :
      Req (riemannIntegral (Qmul_den_pos hLd (Qmul_den_pos hs hw))
              (Int.mul_nonneg hLn (Int.mul_nonneg hsn hwn))
              (affine_lip hLd hLn hlip (mul s lo) (mul s w)
                (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) (Int.mul_nonneg hsn hwn))
              (fun x y h => hfc _ _ (affineMap_congr (mul s lo) (mul s w)
                (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) h)))
          (riemannIntegral (Qmul_den_pos (Qmul_den_pos hLd hs) hw)
              (Int.mul_nonneg (Int.mul_nonneg hLn hsn) hwn)
              (affine_lip (Qmul_den_pos hLd hs) (Int.mul_nonneg hLn hsn)
                (dilate_lip hLd hLn hlip s hs hsn) lo w hlo hw hwn)
              (fun x y h => dilate_fc hfc s hs _ _ (affineMap_congr lo w hlo hw h))) := by
    refine Req_trans
      (riemannIntegral_certif_irrel (Qmul_den_pos hLd (Qmul_den_pos hs hw))
        (Int.mul_nonneg hLn (Int.mul_nonneg hsn hwn))
        (affine_lip hLd hLn hlip (mul s lo) (mul s w)
          (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) (Int.mul_nonneg hsn hwn))
        (fun x y h => hfc _ _ (affineMap_congr (mul s lo) (mul s w)
          (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) h))
        (Qmul_den_pos (Qmul_den_pos hLd hs) hw) (Int.mul_nonneg (Int.mul_nonneg hLn hsn) hwn)
        certL_MR
        (fun x y h => hfc _ _ (affineMap_congr (mul s lo) (mul s w)
          (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) h))) ?_
    exact riemannIntegral_congr (Qmul_den_pos (Qmul_den_pos hLd hs) hw)
      (Int.mul_nonneg (Int.mul_nonneg hLn hsn) hwn)
      certL_MR
      (fun x y h => hfc _ _ (affineMap_congr (mul s lo) (mul s w)
        (Qmul_den_pos hs hlo) (Qmul_den_pos hs hw) h))
      (affine_lip (Qmul_den_pos hLd hs) (Int.mul_nonneg hLn hsn)
        (dilate_lip hLd hLn hlip s hs hsn) lo w hlo hw hwn)
      (fun x y h => dilate_fc hfc s hs _ _ (affineMap_congr lo w hlo hw h))
      harg
  -- Assemble: LHS = ofQ(s·w)·(RI h_L) ≈ ofQ(s·w)·(RI h_R) ≈ ofQ s·(ofQ w·(RI h_R)) = RHS.
  refine Req_trans (Rmul_congr (Req_refl (ofQ (mul s w) (Qmul_den_pos hs hw))) core) ?_
  exact Req_trans (Rmul_congr (Req_symm (Rmul_ofQ_ofQ hs hw)) (Req_refl _))
    (Rmul_assoc (ofQ s hs) (ofQ w hw) _)

end Multiplicity.UOR.Bridge.F1Square.Analysis
