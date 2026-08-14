/-
F1 square — **the real-window partial evaluates as a scaled moment** (`RiwSeqMoment.lean`): the
rational partial `∫_0^s (f · powBandGen_{[0,B]})` — the `riwSeq` term at the FIXED-band twist weight —
equals `s^(n+1) · mellinMoment (dilate_s f) n`, for any rational `s > 0` whose window `[0,s]` sits under
the fixed band (`s + 1 ≤ B`).

Three known-lemma steps, on top of the built `mellinMoment_dilate` (which is stated at the `s`-dependent
band `[0, s+1]`):
1. `riemannIntegralI_congr_Q` — bridge the window `[0, s]` written as `[⟨0,1⟩, s]` (the `riwSeq` shape)
   to `[mul s ⟨0,1⟩, mul s ⟨1,1⟩]` (the `mellinMoment_dilate` shape); the two are `Qeq`-equal windows.
2. `riemannIntegralI_congr_unit_mod` — swap the FIXED band `[0,B]` for `[0, s+1]` on that window: on
   `[0, s]` both weights are `xⁿ` (`powBandGen_eq_Rpow_on`, `p = s·x ≤ s ≤ min(B, s+1)`).
3. `mellinMoment_dilate`.

WHY. `riwI (f·powBandGen_{[0,B]}) = Rlim_k ∫_0^{qk k} (f·powBandGen)` with a FIXED band `B` (so the
integrand is constant across the `Rlim`); this lemma evaluates each term as
`(qk k)^(n+1)·mellinMoment(dilate_{qk k} f) n`. Passing the `Rlim` then gives the real-scale moment
covariance `mellinMoment(dilateTestR c f) n = c^{-(n+1)}·riwI …` — the factorization's inner integral at
a real scale.

HONEST SCOPE. The per-`s` evaluation of the real-window partial as a scaled moment. It builds NO `Rlim`
interchange (the covariance capstone), NO half-line assembly, NO factorization `M[f⋆g]=M[f]·M[g]`, NO
positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CompactMomentDilate
import Multiplicity.F1Square.Square.IntervalPiece
import Multiplicity.F1Square.Square.RationalWindowDilate

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The real-window partial at the fixed-band twist weight is the scaled moment.** For rational
    `s > 0` with `s + 1 ≤ B`,

      `∫_0^s (f · powBandGen_{[0,B]}) = s^(n+1) · mellinMoment (dilate_s f) n`. -/
theorem riwSeq_term_eq_moment (f : L2Test) (n : Nat) (s B : Q)
    (hsn : 0 < s.num) (hsd : 0 < s.den) (hBd : 0 < B.den)
    (hsB : Qle (add s (⟨1, 1⟩ : Q)) B) :
    Req (riemannIntegralI
          (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd
            (Qle_trans (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) hsB) (by decide) n)).hLd
          (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd
            (Qle_trans (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) hsB) (by decide) n)).hLn
          (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd
            (Qle_trans (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) hsB) (by decide) n)).hlip
          (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd
            (Qle_trans (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) hsB) (by decide) n)).hfc
          (⟨0, 1⟩ : Q) s (by decide) hsd (Int.le_of_lt hsn))
        (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
          (mellinMoment (dilateTest s hsn hsd f) n)) := by
  -- abbreviations for the two bands
  have hleB : Qle (⟨0, 1⟩ : Q) B :=
    Qle_trans (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) hsB
  have hsleB : Qle s B :=
    Qle_trans (add_den_pos hsd (by decide)) (Qle_self_add (by decide)) hsB
  -- STEP 1: bridge the window [⟨0,1⟩, s] → [mul s ⟨0,1⟩, mul s ⟨1,1⟩]
  refine Req_trans (riemannIntegralI_congr_Q
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hLd
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hLn
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hlip
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hfc
    (⟨0, 1⟩ : Q) s (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
    (by decide) hsd (Int.le_of_lt hsn)
    (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide))
    (Int.mul_nonneg (Int.le_of_lt hsn) (by decide))
    (by simp only [Qeq, mul]; push_cast; ring_uor)
    (by simp only [Qeq, mul]; push_cast; ring_uor)) ?_
  -- STEP 2 + 3: swap the fixed band for [0, s+1] then apply mellinMoment_dilate
  refine Req_trans ?_ (mellinMoment_dilate f n s hsn hsd)
  -- STEP 2: the band swap on the window [mul s ⟨0,1⟩, mul s ⟨1,1⟩]
  refine riemannIntegralI_congr_unit_mod
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hLd
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hLn
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hlip
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)).hfc
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) (by decide) n)).hLd
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) (by decide) n)).hLn
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) (by decide) n)).hlip
    (L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) (by decide) n)).hfc
    (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
    (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide))
    (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)) ?_
  intro x h0 h1
  -- the affine window point p = mul s ⟨0,1⟩ + mul s ⟨1,1⟩ · x ∈ [0, s]
  have hsnn : Rnonneg (ofQ (mul s (⟨1, 1⟩ : Q)) (Qmul_den_pos hsd (by decide))) :=
    Rnonneg_ofQ (Qmul_den_pos hsd (by decide))
      (Int.mul_nonneg (Int.le_of_lt hsn) (by decide))
  have hp0lo : Rle (ofQ (mul s (⟨0, 1⟩ : Q)) (Qmul_den_pos hsd (by decide)))
      (affineMap (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)) x) :=
    Rle_self_Radd_right (Rnonneg_Rmul hsnn (Rnonneg_of_Rle_zero h0))
  have hptop : Rle (affineMap (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)) x)
      (ofQ (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
        (add_den_pos (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)))) := by
    refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _))
      (Rle_trans (Rmul_le_Rmul_left hsnn h1) (Rle_of_Req (Rmul_one _)))) ?_
    exact Rle_of_Req (Radd_ofQ_ofQ (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)))
  -- `mul s ⟨0,1⟩ ≈ 0` and `mul s ⟨0,1⟩ + mul s ⟨1,1⟩ ≈ s`
  have hbaseQ : Qle (⟨0, 1⟩ : Q) (mul s (⟨0, 1⟩ : Q)) := by
    simp only [Qle, mul]; push_cast; omega
  have hsumeq : Qeq (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))) s := by
    simp only [Qeq, add, mul]; push_cast; ring_uor
  have hp_lo : Rle (ofQ (⟨0, 1⟩ : Q) (by decide))
      (affineMap (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)) x) :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (Qmul_den_pos hsd (by decide)) hbaseQ) hp0lo
  have hp_hiB : Rle (affineMap (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)) x) (ofQ B hBd) :=
    Rle_trans hptop (Rle_ofQ_ofQ (add_den_pos (Qmul_den_pos hsd (by decide))
      (Qmul_den_pos hsd (by decide))) hBd
      (Qle_trans hsd (Qeq_le hsumeq) hsleB))
  have hp_hiS : Rle (affineMap (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide)) x)
      (ofQ (add s (⟨1, 1⟩ : Q)) (add_den_pos hsd (by decide))) :=
    Rle_trans hptop (Rle_ofQ_ofQ (add_den_pos (Qmul_den_pos hsd (by decide))
      (Qmul_den_pos hsd (by decide))) (add_den_pos hsd (by decide))
      (Qle_trans hsd (Qeq_le hsumeq) (Qle_self_add (by decide))))
  -- both weights are Rpow p n on the window
  refine Rmul_congr (Req_refl _) ?_
  exact Req_trans
    (powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n hp_lo hp_hiB)
    (Req_symm (powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (by simp only [Qle, add]; push_cast; omega) (by decide) n hp_lo hp_hiS))

end Multiplicity.UOR.Bridge.F1Square.Square
