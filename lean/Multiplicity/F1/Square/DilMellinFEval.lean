/-
F1 square — **the first evaluation of `dilMellinF`: strip the clamp, land the dilated pairing**
(`DilMellinFEval.lean`). The isolated inner `x`-integral of the convolution–Mellin pairing
(`dilMellinF`, from `mellinConv_gpull`) carries a clamp `qBandQ 0 S x` inside `f`. On any window
`[xlo, xlo+xw] ⊆ [0, S]` that clamp is inert, so

    `dilMellinF f ψ S a t  =  innerIonI (dilateTestR (clampedInv a t) f) ψ  [xlo, xlo+xw]`,

the clean interval `L²` pairing of the real-scale dilated test `f(clampedInv(a,t)·x)` against the
weight `ψ`. This is the first *evaluation* of `dilMellinF` — nothing evaluated it before — and it
moves the factorization's inner integral off the clamped `dilIntegrand` form onto the pairing /
dilation-covariance machinery (`window_moment_scale_lipschitz`, `general_window_dilate`, …).

The only content is `qBandQ_eq_of_band` on the affine window point `p = xlo + xw·x ∈ [xlo, xlo+xw] ⊆
[0, S]`, plus `Rmul_comm` (the clamp inert, and `x·c = c·x`), transported across the two different
integrand moduli by `riemannIntegralI_congr_unit_mod`.

HONEST SCOPE. The clamp-stripping evaluation of `dilMellinF` as an interval pairing of a dilated
test. It builds NO real-scale dilation covariance (that reads off the pairing next), NO half-line
assembly, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinConvGPull
import Multiplicity.F1.Square.TwTermPowBand

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **`dilMellinF` is the interval pairing of the dilated test.** On a window `[xlo, xlo+xw] ⊆ [0, S]`
    the clamp `qBandQ 0 S` inside `dilIntegrand` is inert, so `dilMellinF f ψ S a t` equals the interval
    `L²` pairing `innerIonI (dilateTestR (clampedInv a t) f) ψ` over `[xlo, xlo+xw]`. The scale bound
    `S'` of the dilated test is a free parameter (`clampedInv(a,t)` is bounded by `1/a`; any `S' ≥` that
    works). -/
theorem dilMellinF_eq_pairing (f ψ : L2Test) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real)
    (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hxlon : 0 ≤ xlo.num) (hwin : Qle (add xlo xw) S)
    (S' : Q) (hS'd : 0 < S'.den) (hS'n : 0 ≤ S'.num)
    (hcS' : Rle (Rabs (clampedInv a han had t)) (ofQ S' hS'd)) :
    Req (dilMellinF f ψ S hSd a han had t xlo xw hxlo hxw hxwn)
        (innerIonI (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) ψ
          xlo xw hxlo hxw hxwn) := by
  refine riemannIntegralI_congr_unit_mod
    (dilLx_den f ψ a han had) (dilLx_num f ψ a han had)
    (dilIntegrand_lipX f ψ S hSd a han had t)
    (fun x x' h => dilIntegrand_fcX f ψ S hSd a han had t x x' h)
    (l2L_den (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) ψ)
    (l2L_num (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) ψ)
    (l2lip (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) ψ)
    (l2fc (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) ψ)
    xlo xw hxlo hxw hxwn ?_
  intro x h0 h1
  -- the affine window point p = xlo + xw·x
  have hp_nn : Rle (ofQ (⟨0, 1⟩ : Q) (by decide))
      (affineMap xlo xw hxlo hxw x) := by
    refine Rle_trans (Rle_ofQ_ofQ (by decide) hxlo ?_)
      (Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hxw hxwn) (Rnonneg_of_Rle_zero h0)))
    show Qle (⟨0, 1⟩ : Q) xlo
    simp only [Qle]; push_cast; omega
  have hp_hi : Rle (affineMap xlo xw hxlo hxw x) (ofQ S hSd) := by
    have hxwx : Rle (Rmul (ofQ xw hxw) x) (ofQ xw hxw) :=
      Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hxw hxwn) h1)
        (Rle_of_Req (Rmul_one (ofQ xw hxw)))
    refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxwx)
      (Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hxlo hxw))
        (Rle_ofQ_ofQ (add_den_pos hxlo hxw) hSd hwin))
  -- on the window the clamp is inert, so the two integrands agree
  refine Rmul_congr (f.hfc _ _ ?_) (Req_refl _)
  refine Req_trans (Rmul_congr (qBandQ_eq_of_band hp_nn hp_hi) (Req_refl _)) ?_
  exact Rmul_comm (affineMap xlo xw hxlo hxw x) (clampedInv a han had t)

/-- **`dilMellinF` at the moment window `[0,1]` with weight `powTest n` is the moment of the dilated
    test.** Specialising `dilMellinF_eq_pairing` to `ψ = powTest n`, window `[0,1]` (which needs only
    `S ≥ 1`), and collapsing the `[0,1]`-interval pairing to the plain moment via `riemannIntegralI_unit`:

      `dilMellinF f (powTest n) S a t  =  mellinMoment (dilateTestR (clampedInv a t) f) n`.

    This lands the factorization's inner integral, at the moment window, on `mellinMoment` — carrying
    its own rational-scale dilation covariance (`mellinMoment_dilate`). -/
theorem dilMellinF_eq_mellinMoment (f : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) (hS1 : Qle (⟨1, 1⟩ : Q) S)
    (S' : Q) (hS'd : 0 < S'.den) (hS'n : 0 ≤ S'.num)
    (hcS' : Rle (Rabs (clampedInv a han had t)) (ofQ S' hS'd)) :
    Req (dilMellinF f (powTest n) S hSd a han had t (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
          (by decide) (by decide) (by decide))
        (mellinMoment (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) n) := by
  have hwin : Qle (add (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)) S := by
    simp only [Qle, add] at hS1 ⊢; push_cast at hS1 ⊢; omega
  refine Req_trans (dilMellinF_eq_pairing f (powTest n) S hSd a han had t (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
    (by decide) (by decide) (by decide) (by decide) hwin S' hS'd hS'n hcS') ?_
  exact riemannIntegralI_unit
    (l2L_den (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) (powTest n))
    (l2L_num (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) (powTest n))
    (l2lip (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) (powTest n))
    (l2fc (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) (powTest n))

/-- **`dilMellinF` at the tail window `[m+1,m+2]` with weight `powWinTest m n` is the twisted-tail term
    of the dilated test.** The half-line analogue of `dilMellinF_eq_mellinMoment`: on the window
    `[m+1,m+2] ⊆ [0,S]` (needs `m+2 ≤ S`) the clamp is inert, so `dilMellinF f (powWinTest m n) S a t`
    equals the interval pairing `innerIonI (dilateTestR c f) (powWinTest m n) [m+1,m+2]`, which is
    definitionally `twTerm (dilateTestR c f) n m`.

    Summing these over `m` (plus the `[0,1]` moment) is the half-line decomposition `mellinHat =
    mellinMoment + twTail` — the level the prime side reads (tests at prime powers `≥ 1`), which the
    `[0,1]` moment track alone cannot reach. -/
theorem dilMellinF_eq_twTerm (f : L2Test) (n m : Nat) (S : Q) (hSd : 0 < S.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real)
    (hSm : Qle (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) S)
    (S' : Q) (hS'd : 0 < S'.den) (hS'n : 0 ≤ S'.num)
    (hcS' : Rle (Rabs (clampedInv a han had t)) (ofQ S' hS'd)) :
    Req (dilMellinF f (powWinTest m n) S hSd a han had t
          (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide))
        (twTerm (dilateTestR (clampedInv a han had t) S' hS'd hS'n hcS' f) n m) :=
  dilMellinF_eq_pairing f (powWinTest m n) S hSd a han had t
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)
    (by show (0 : Int) ≤ (m : Int) + 1; omega) hSm S' hS'd hS'n hcS'

end Multiplicity.UOR.Bridge.F1Square.Square
