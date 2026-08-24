/-
F1 square — **the compact `[0,1]`-window Mellin dilation covariance** (`CompactMomentDilate.lean`):
the `[0,1]`-window companion of the committed per-window tail dilation
(`window_dilate_powBandGen` + `twTerm_eq_window_powBandGen`), specialised to the moment window
`[0,1]` with the genuine clamped Mellin weight `powTest`.

For a test `φ`, a degree-`n` twist, and a rational scale `s > 0`, the scaled compact integral over
`[0, s]` of `φ` against the wide-band twist `powBandGen 0 (s+1) … n` equals `s^(n+1)` times the
compact moment `mellinMoment` of the `s`-dilated test:

    `∫_0^s (φ · powBandGen_{[0,s+1]}) = s^(n+1) · mellinMoment (dilate_s φ) n`.

The band `[0, s+1]` covers both the moment window `[0,1]` and the scaled window `[0, s]`, so the
un-clamped twist is homogeneous there. Three moves, mirroring the tail bricks with `[m+1,m+2]`
replaced by `[0,1]` and `powWinTest` by `powTest`: STEP A applies the committed per-window dilation
`mellinWindowDilate` at `lo = 0`, `w = 1` (its `hHom` discharged by `powBandGen_dilate_on`); STEP B
swaps the wide-band weight for `powTest n` on the unit window via the different-`L` congruence
`riemannIntegralI_congr_unit_mod` (both weights are `tⁿ` there); STEP C identifies the unit-window
interval integral with `mellinMoment` through `riemannIntegralI_unit`.

HONEST SCOPE. The compact dilation covariance — the scaled compact integral over `[0,s]` of `φ`
against `powBandGen` equals `s^(n+1)` times the compact moment `mellinMoment` of the dilated test,
the `[0,1]`-window companion of the committed per-window tail dilation (`mellinWindowDilate` at
`lo = 0`, `w = 1` + weight-swap to `powTest` + the unit bridge). It builds NO half-line assembly, NO
boundary reconciliation, NO split-point independence, NO full `mellinHat` covariance, NO
factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.TwTermPowBand
import Multiplicity.F1.Square.BernsteinClampMatch
import Multiplicity.F1.Square.IntervalMinorant
import Multiplicity.F1.Square.TestAlgebra

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The wide band `[0, s+1]` covers `0`: `0 ≤ s + 1` since `s > 0`. -/
private theorem band01_le {s : Q} (hsn : 0 < s.num) :
    Qle (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast; omega

/-- The affine unit point `y = 0 + 1·x` is `≥ 0` for `0 ≤ x` — the base bound on `[0,1]`. -/
private theorem aff01_base {x : Real} (h0 : Rle zero x) :
    Rle (ofQ (⟨0, 1⟩ : Q) (by decide))
      (Radd (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x)) :=
  Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
    (Rnonneg_of_Rle_zero h0))

/-- The affine unit point `y = 0 + 1·x` is `≤ 1` for `x ≤ 1` — the top bound on `[0,1]`. -/
private theorem aff01_top {x : Real} (h1 : Rle x one) :
    Rle (Radd (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x))
        (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
  have h1nn : Rnonneg (ofQ (⟨1, 1⟩ : Q) (by decide)) := Rnonneg_ofQ (by decide) (by decide)
  have hxle1 : Rle (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left h1nn h1) (Rle_of_Req (Rmul_one (ofQ (⟨1, 1⟩ : Q) (by decide))))
  have hqeq : Qeq (add (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q) := by decide
  exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle1)
    (Rle_of_Req (Req_trans (Radd_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (add_den_pos (by decide) (by decide)) (by decide) hqeq)))

/-- **The compact `[0,1]`-window Mellin dilation covariance.** For a test `φ`, a degree-`n` twist,
    and a rational scale `s > 0`, the scaled compact integral over `[0, s]` of `φ` against the
    wide-band twist `powBandGen 0 (s+1) … n` equals `s^(n+1)` times the compact moment
    `mellinMoment` of the `s`-dilated test:

      `∫_0^s (φ · powBandGen_{[0,s+1]}) = s^(n+1) · mellinMoment (dilate_s φ) n`.

    STEP A is `mellinWindowDilate` at `lo = 0`, `w = 1`, the band `[0, s+1]` covering `[0,1]` and
    `[0,s]`; its `hHom` is discharged by `powBandGen_dilate_on`. STEP B swaps `powBandGen` for the
    genuine clamped weight `powTest n` on the unit window (`riemannIntegralI_congr_unit_mod`; both
    weights are `tⁿ` there). STEP C identifies the unit-window interval integral with
    `mellinMoment (dilate_s φ) n` through `riemannIntegralI_unit`. The `[0,1]`-window companion of
    `window_dilate_powBandGen`/`twTerm_eq_window_powBandGen`. -/
theorem mellinMoment_dilate (φ : L2Test) (n : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) :
    Req (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide))
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
          (mellinMoment (dilateTest s hsn hsd φ) n)) := by
  have hsnn : Rnonneg (ofQ s hsd) := Rnonneg_ofQ hsd (Int.le_of_lt hsn)
  -- STEP A: the per-window dilation at `lo = 0`, `w = 1`, band `[0, s+1]`.
  refine Req_trans
    (mellinWindowDilate φ
      (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)
      n s hsn hsd (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) ?_) ?_
  · -- `hHom`: degree-`n` homogeneity of `powBandGen` on the unit window under `s`.
    intro x h0 h1
    have hy_base := aff01_base h0
    have boundB := aff01_top h1
    have hc2 : Qle (⟨1, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by simp only [Qle, add]; push_cast; omega
    have hc3 : Qle (⟨0, 1⟩ : Q) (mul s (⟨0, 1⟩ : Q)) := by
      simp only [Qle, mul]; push_cast; omega
    have hc4 : Qle (mul s (⟨1, 1⟩ : Q)) (add s (⟨1, 1⟩ : Q)) :=
      Qle_trans hsd (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)) (Qle_self_add (by decide))
    have hy_hi := Rle_trans boundB (Rle_ofQ_ofQ (by decide) (add_den_pos hsd (by decide)) hc2)
    have hsy_lo := Rle_trans (Rle_ofQ_ofQ (by decide) (Qmul_den_pos hsd (by decide)) hc3)
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hsd (by decide))))
        (Rmul_le_Rmul_left hsnn hy_base))
    have hsy_hi := Rle_trans (Rmul_le_Rmul_left hsnn boundB)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hsd (by decide)))
        (Rle_ofQ_ofQ (Qmul_den_pos hsd (by decide)) (add_den_pos hsd (by decide)) hc4))
    exact powBandGen_dilate_on (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n s hsd
      hy_base hy_hi hsy_lo hsy_hi
  · -- STEPS B, C under the `s^(n+1)` factor.
    refine Rmul_congr (Req_refl _) ?_
    -- STEP C first slot: identify the unit-window `powTest` integral with `mellinMoment`.
    refine Req_trans ?_
      (riemannIntegralI_unit
        (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hLd
        (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hLn
        (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hlip
        (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hfc)
    -- STEP B: swap the wide-band weight for `powTest n` on the unit window.
    refine riemannIntegralI_congr_unit_mod
      (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hLd
      (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hLn
      (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hlip
      (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n)).hfc
      (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hLd
      (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hLn
      (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hlip
      (L2Test.mul (dilateTest s hsn hsd φ) (powTest n)).hfc
      (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) ?_
    intro x h0 h1
    have hy_base := aff01_base h0
    have boundB := aff01_top h1
    have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
    have hy0z : Rle zero (Radd (ofQ (⟨0, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x)) :=
      Rle_trans (Rle_of_Req (Req_symm hz0)) hy_base
    have hc2 : Qle (⟨1, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by simp only [Qle, add]; push_cast; omega
    have hy_hi := Rle_trans boundB (Rle_ofQ_ofQ (by decide) (add_den_pos hsd (by decide)) hc2)
    -- Both weights reduce to `Rpow y n` on the unit window.
    have hpb := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
      (add_den_pos hsd (by decide)) (band01_le hsn) (by decide) n hy_base hy_hi
    have hpt := Req_trans
      (powTest_f_eq (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) x) n)
      (Rpow_congr (clamp01_eq_self hy0z boundB) n)
    exact Req_trans (Rmul_congr (Req_refl _) hpb) (Req_symm (Rmul_congr (Req_refl _) hpt))

end Multiplicity.UOR.Bridge.F1Square.Square
