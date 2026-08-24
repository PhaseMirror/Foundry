/-
F1 square — **the per-window rational-scale Mellin dilation at the twist weight**
(`WindowDilatePow.lean`): the committed per-window rational-scale Mellin dilation
(`mellinWindowDilate`) INSTANTIATED at the twist weight `powBandGen`, on the integer window
`[m+1, m+2]`, with the weight taken over a WIDE band `[lo, hi]` that covers both the window and
its `s`-scaling `[s·(m+1), s·(m+2)]`.

The only real content is DISCHARGING the `hHom` hypothesis of `mellinWindowDilate` — the degree-`n`
homogeneity of the weight on the window under the scale `s` — using the committed
`powBandGen_dilate_on` (sub-brick 2). Its four membership facts are supplied by the affine/scaling
algebra: with `y = affineMap (m+1) 1 x` for `0 ≤ x ≤ 1`, both `y ∈ [m+1, m+2] ⊆ [lo, hi]` and
`s·y ∈ [s·(m+1), s·(m+2)] ⊆ [lo, hi]`, chained from the band-containment hypotheses `hc1`–`hc4`
through `Rle_ofQ_ofQ`, `Rmul_ofQ_ofQ`, the `Rmul`/`Radd` monotonicities and `Rle_self_Radd_right`.

The resulting integral identity is exactly `mellinWindowDilate`'s conclusion at `P = powBandGen`,
`lo = m+1`, `w = 1`:

    `∫_{s·(m+1)}^{s·(m+2)} (φ · powBandGen) = s^(n+1) · ∫_{m+1}^{m+2} (dilate_s φ · powBandGen)`.

HONEST SCOPE. The per-window rational-scale Mellin dilation instantiated at the twist weight
`powBandGen` over a band covering both the integer window and its `s`-scaling, with `hHom`
discharged by `powBandGen_dilate_on` — the integral identity
`∫_{[s(m+1),s(m+2)]}(φ·powBandGen) = s^(n+1)·∫_{[m+1,m+2]}(dilate_s φ·powBandGen)`. It builds NO
weight-swap to `twTerm`, NO half-line assembly, NO factorization, NO positivity, NO determinacy,
NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.RationalWindowDilate
import Multiplicity.F1.Analysis.CosSinBound
import Multiplicity.F1.Analysis.Pi

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The per-window rational-scale Mellin dilation at the twist weight `powBandGen`.** On the
    integer window `[m+1, m+2]`, with the weight `powBandGen lo hi … n` taken over a band `[lo, hi]`
    containing both the window (`hc1`, `hc2`) and its `s`-scaling (`hc3`, `hc4`),

      `∫_{s·(m+1)}^{s·(m+2)} (φ · powBandGen) = s^(n+1) · ∫_{m+1}^{m+2} (dilate_s φ · powBandGen)`.

    This is `mellinWindowDilate` applied at `P = powBandGen … n`, `lo = m+1`, `w = 1`; the only new
    content is the `hHom` discharge via `powBandGen_dilate_on` together with the four membership
    facts of the affine window point `y = affineMap (m+1) 1 x` and its scaling `s·y`. -/
theorem window_dilate_powBandGen
    (φ : L2Test) (n m : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi) (hlon : 0 ≤ lo.num)
    (hc1 : Qle lo (⟨(m : Int) + 1, 1⟩ : Q))
    (hc2 : Qle (⟨(m : Int) + 2, 1⟩ : Q) hi)
    (hc3 : Qle lo (mul s (⟨(m : Int) + 1, 1⟩ : Q)))
    (hc4 : Qle (mul s (⟨(m : Int) + 2, 1⟩ : Q)) hi) :
    Req (riemannIntegralI
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLd
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLn
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hlip
          (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hfc
          (mul s (⟨(m : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
          (riemannIntegralI
            (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen lo hi hlod hhid hle hlon n)).hLd
            (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen lo hi hlod hhid hle hlon n)).hLn
            (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen lo hi hlod hhid hle hlon n)).hlip
            (L2Test.mul (dilateTest s hsn hsd φ) (powBandGen lo hi hlod hhid hle hlon n)).hfc
            (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide))) := by
  -- Window endpoints as rationals with unit denominators.
  have hlo' : 0 < (⟨(m : Int) + 1, 1⟩ : Q).den := Nat.one_pos
  have hw' : 0 < (⟨1, 1⟩ : Q).den := Nat.one_pos
  have hm2' : 0 < (⟨(m : Int) + 2, 1⟩ : Q).den := Nat.one_pos
  have hsnn : Rnonneg (ofQ s hsd) := Rnonneg_ofQ hsd (Int.le_of_lt hsn)
  have hw'nn : Rnonneg (ofQ (⟨1, 1⟩ : Q) hw') := Rnonneg_ofQ hw' (by decide)
  -- Apply the committed per-window dilation; the residual goal is exactly `hHom`.
  refine mellinWindowDilate φ (powBandGen lo hi hlod hhid hle hlon n) n s hsn hsd
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) ?_
  intro x h0 h1
  -- The affine window point `y = (m+1) + 1·x` and its endpoints (in `Radd`/`Rmul` form, defeq to
  -- `affineMap (m+1) 1 x`).
  -- (m+1) ≤ y : the offset `1·x` is non-negative.
  have hy_base :
      Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo')
        (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x)) :=
    Rle_self_Radd_right (Rnonneg_Rmul hw'nn (Rnonneg_of_Rle_zero h0))
  -- 1·x ≤ 1 : from `x ≤ 1`.
  have hxle1 : Rle (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x) (ofQ (⟨1, 1⟩ : Q) hw') :=
    Rle_trans (Rmul_le_Rmul_left hw'nn h1)
      (Rle_of_Req (Rmul_one (ofQ (⟨1, 1⟩ : Q) hw')))
  -- y ≤ (m+2) : add the offset bound to the base.
  have hqeq : Qeq (add (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨(m : Int) + 2, 1⟩ : Q) := by
    simp only [Qeq, add]; push_cast; ring_uor
  have boundB :
      Rle (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x))
        (ofQ (⟨(m : Int) + 2, 1⟩ : Q) hm2') :=
    Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle1)
      (Rle_of_Req (Req_trans (Radd_ofQ_ofQ hlo' hw')
        (ofQ_congr (add_den_pos hlo' hw') hm2' hqeq)))
  -- The four membership facts consumed by `powBandGen_dilate_on`.
  have hy_lo :
      Rle (ofQ lo hlod)
        (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x)) :=
    Rle_trans (Rle_ofQ_ofQ hlod hlo' hc1) hy_base
  have hy_hi :
      Rle (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x))
        (ofQ hi hhid) :=
    Rle_trans boundB (Rle_ofQ_ofQ hm2' hhid hc2)
  have hsy_lo :
      Rle (ofQ lo hlod)
        (Rmul (ofQ s hsd)
          (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x))) :=
    Rle_trans (Rle_ofQ_ofQ hlod (Qmul_den_pos hsd hlo') hc3)
      (Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hsd hlo')))
        (Rmul_le_Rmul_left hsnn hy_base))
  have hsy_hi :
      Rle (Rmul (ofQ s hsd)
            (Radd (ofQ (⟨(m : Int) + 1, 1⟩ : Q) hlo') (Rmul (ofQ (⟨1, 1⟩ : Q) hw') x)))
          (ofQ hi hhid) :=
    Rle_trans (Rmul_le_Rmul_left hsnn boundB)
      (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hsd hm2'))
        (Rle_ofQ_ofQ (Qmul_den_pos hsd hm2') hhid hc4))
  exact powBandGen_dilate_on lo hi hlod hhid hle hlon n s hsd hy_lo hy_hi hsy_lo hsy_hi

end Multiplicity.UOR.Bridge.F1Square.Square
