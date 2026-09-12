/-
F1 square — **the `s`-uniform-tiling partial sum as a single cap integral** (`UniformPartialCap.lean`):
the compact `[0,s]` moment piece plus the finite `s`-scaled twisted partial sum, assembled into a
single interval integral over the scaled cap `[0, s(N+1)]`.

The committed `s`-uniform improper Mellin integral is `∫_0^s (φ · powBandGen) + Rlim(genSum scaledTwTerm)`.
Its `N`-th partial sum — the compact moment integral (the `mellinMoment_dilate` LHS) plus the finite
scaled tail `genSum scaledTwTerm … N` — equals a SINGLE cap integral of `φ` against the wide-band
power weight over `[0, s(N+1)]`:

    `∫_0^s (φ · powBandGen_{[0,s+1]}) + Σ_{m<N} scaledTwTerm φ s … m
        = ∫_0^{s(N+1)} (φ · powBandGen_{[0,s(N+1)+1]})`.

ROUTE. (i) The tail: `genSum scaledTwTerm … N = s^(n+1)·genSum(twTerm(dilate_s φ)) N` (`genSum_scaled_eq`,
`genSum ≡ RsumN`) `= ∫_{s}^{s(N+1)} (φ · powBandGen_{[0,(s+1)(N+2)]})` (`reschedule_finite`, the covering
band `[0,(s+1)(N+2)]` making `hhiN`/`hhisN` hold), then reconciled to the cap band by the different-`L`
window congruence `riemannIntegralI_congr_unit_mod` (both weights are `uⁿ` on `[s,s(N+1)]`) and to the
split-window endpoints by `riemannIntegralI_congr_Q`. (ii) The join: `riemannIntegralI_split_at` splits
the cap `[0,s(N+1)]` at `s` into `[0,s] + [s,s(N+1)]`, and the compact `[0,s]` piece is reconciled to the
`mellinMoment_dilate` band `[0,s+1]` by `riemannIntegralI_congr_unit_mod` (both `uⁿ` on `[0,s]`).

HONEST SCOPE. The `s`-uniform-tiling partial sum (compact `[0,s]` moment `+` finite `genSum scaledTwTerm`
up to `N`) expressed as a single cap integral over `[0, s(N+1)]`, via the committed `reschedule_finite`,
`genSum_scaled_eq`, `riemannIntegralI_split_at`, and the different-`L` window congruence for the band
reconciliation. It builds NO Cauchy-at-infinity, NO schedule comparison, NO width-comparison completion,
NO factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.RescheduleFinite
import Foundations.F1.Square.ScaledTwistedTail
import Foundations.F1.Square.CompactMomentDilate
import Foundations.F1.Square.IntervalSplitAtCap
import Foundations.F1.Square.RationalWindowDilate

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The two cap endpoints.
-- ===========================================================================

/-- The cap band upper endpoint `s(N+1)+1` — covers the whole scaled cap `[0, s(N+1)]`. -/
private def capHi (s : Q) (N : Nat) : Q := add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q)

/-- The reschedule covering band upper endpoint `(s+1)(N+2)` — covers both the integer windows
    `[m+1,m+2]` and the scaled windows `[s(m+1),s(m+2)]` up to `m = N`. -/
private def resHi (s : Q) (N : Nat) : Q := mul (add s (⟨1, 1⟩ : Q)) (⟨(N : Int) + 2, 1⟩ : Q)

-- ===========================================================================
-- Rational-order side conditions.
-- ===========================================================================

/-- `0 ≤ s+1` — the low end of the compact band `[0, s+1]`. -/
private theorem band01le {s : Q} (hsn : 0 < s.num) : Qle (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast; omega

/-- `1 ≤ s+1`. -/
private theorem one_le_sp1 {s : Q} (hsn : 0 < s.num) : Qle (⟨1, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast
  have hexp : (s.num * 1 + 1 * (s.den : Int)) * 1 - 1 * ((s.den : Int) * 1) = s.num * 1 := by ring_uor
  omega

/-- `s ≤ s+1`. -/
private theorem s_le_sp1 (s : Q) : Qle s (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast
  have hd : (0 : Int) ≤ (s.den : Int) * (s.den : Int) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  have hexp : (s.num * 1 + 1 * (s.den : Int)) * (s.den : Int) - s.num * ((s.den : Int) * 1)
      = (s.den : Int) * (s.den : Int) := by ring_uor
  omega

/-- The cap band upper endpoint has a positive denominator. -/
private theorem capHi_den {s : Q} (hsd : 0 < s.den) (N : Nat) : 0 < (capHi s N).den := by
  show 0 < (add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).den
  exact add_den_pos (Qmul_den_pos hsd Nat.one_pos) (by decide)

/-- The reschedule band upper endpoint has a positive denominator. -/
private theorem resHi_den {s : Q} (hsd : 0 < s.den) (N : Nat) : 0 < (resHi s N).den := by
  show 0 < (mul (add s (⟨1, 1⟩ : Q)) (⟨(N : Int) + 2, 1⟩ : Q)).den
  exact Qmul_den_pos (add_den_pos hsd (by decide)) Nat.one_pos

/-- `0 ≤ s·(N+1)`. -/
private theorem hlo_mulNp1 {s : Q} (hsn : 0 < s.num) (N : Nat) :
    Qle (⟨0, 1⟩ : Q) (mul s (⟨(N : Int) + 1, 1⟩ : Q)) := by
  simp only [Qle, mul]; push_cast
  have hprod : (0 : Int) ≤ s.num * ((N : Int) + 1) * 1 :=
    Int.mul_nonneg (Int.mul_nonneg (Int.le_of_lt hsn) (by omega)) (by omega)
  omega

/-- `0 ≤ s·1`. -/
private theorem hlo_s1 {s : Q} (hsn : 0 < s.num) : Qle (⟨0, 1⟩ : Q) (mul s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, mul]; push_cast
  have hprod : (0 : Int) ≤ s.num * 1 * 1 :=
    Int.mul_nonneg (Int.mul_nonneg (Int.le_of_lt hsn) (by omega)) (by omega)
  omega

/-- `0 ≤ s·0`. -/
private theorem hlo_s0 (s : Q) : Qle (⟨0, 1⟩ : Q) (mul s (⟨0, 1⟩ : Q)) := by
  simp only [Qle, mul]; push_cast; omega

/-- `N+2 ≤ (s+1)(N+2)` — the reschedule band covers the top integer window. -/
private theorem resHi_ge_Np2 {s : Q} (hsn : 0 < s.num) (N : Nat) :
    Qle (⟨(N : Int) + 2, 1⟩ : Q) (resHi s N) := by
  have e1 : Qeq (⟨(N : Int) + 2, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) (⟨(N : Int) + 2, 1⟩ : Q)) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hmono : Qle (mul (⟨1, 1⟩ : Q) (⟨(N : Int) + 2, 1⟩ : Q)) (resHi s N) :=
    qmul_le_right_mono (one_le_sp1 hsn) (by show (0 : Int) ≤ (N : Int) + 2; omega)
  exact Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos) (Qeq_le e1) hmono

/-- `0 ≤ (s+1)(N+2)`. -/
private theorem res_le {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (⟨0, 1⟩ : Q) (resHi s N) := by
  refine Qle_trans Nat.one_pos ?_ (resHi_ge_Np2 hsn N)
  show Qle (⟨0, 1⟩ : Q) (⟨(N : Int) + 2, 1⟩ : Q)
  simp only [Qle]; push_cast; omega

/-- `N+1 ≤ (s+1)(N+2)` — the reschedule `hhiN`. -/
private theorem hhiN_res {s : Q} (hsn : 0 < s.num) (N : Nat) :
    Qle (⟨(N : Int) + 1, 1⟩ : Q) (resHi s N) :=
  Qle_trans Nat.one_pos
    (by simp only [Qle]; push_cast; omega : Qle (⟨(N : Int) + 1, 1⟩ : Q) (⟨(N : Int) + 2, 1⟩ : Q))
    (resHi_ge_Np2 hsn N)

/-- `s(N+1) ≤ (s+1)(N+2)` — the reschedule `hhisN`. -/
private theorem hhisN_res {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (resHi s N) := by
  have hs : (0 : Int) ≤ s.num := Int.le_of_lt hsn
  have step1 : Qle (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨(N : Int) + 2, 1⟩ : Q)) :=
    qmul_le_left_mono hs (by simp only [Qle]; push_cast; omega)
  have step2 : Qle (mul s (⟨(N : Int) + 2, 1⟩ : Q)) (resHi s N) :=
    qmul_le_right_mono (s_le_sp1 s) (by show (0 : Int) ≤ (N : Int) + 2; omega)
  exact Qle_trans (Qmul_den_pos hsd Nat.one_pos) step1 step2

/-- `0 ≤ s(N+1)+1` — the cap band low end. -/
private theorem cap_le {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (⟨0, 1⟩ : Q) (capHi s N) := by
  show Qle (⟨0, 1⟩ : Q) (add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q))
  exact Qle_trans (Qmul_den_pos hsd Nat.one_pos) (hlo_mulNp1 hsn N) (Qle_self_add (by decide))

-- ===========================================================================
-- The window endpoint `Qeq`/`Qle` bridges (all three tilings agree numerically).
-- ===========================================================================

/-- `0·s + 1·s ≡ 1·s`. -/
private theorem addS0S1_eq_S1 (s : Q) :
    Qeq (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))) (mul s (⟨1, 1⟩ : Q)) := by
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- `0·s + 1·s ≡ s`. -/
private theorem addS0S1_eq_s (s : Q) :
    Qeq (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))) s := by
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- `0·s + 1·s ≤ s(N+1)+1`. -/
private theorem addS0S1_le_cap {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))) (capHi s N) := by
  refine Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addS0S1_eq_S1 s)) ?_
  show Qle (mul s (⟨1, 1⟩ : Q)) (add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q))
  refine Qle_trans (Qmul_den_pos hsd Nat.one_pos) ?_ (Qle_self_add (by decide))
  exact qmul_le_left_mono (Int.le_of_lt hsn) (by simp only [Qle]; push_cast; omega)

/-- `0·s + 1·s ≤ s+1`. -/
private theorem addS0S1_le_sp1 {s : Q} (hsd : 0 < s.den) :
    Qle (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))) (add s (⟨1, 1⟩ : Q)) :=
  Qle_trans hsd (Qeq_le (addS0S1_eq_s s)) (Qle_self_add (by decide))

/-- `1·s + (s(N+1) − 1·s) ≡ s(N+1)`. -/
private theorem addS1Wr_eq {s : Q} (N : Nat) :
    Qeq (add (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))))
        (mul s (⟨(N : Int) + 1, 1⟩ : Q)) := by
  simp only [Qeq, add, Qsub, mul, neg]; push_cast; ring_uor

/-- The reschedule cap `[s, s(N+1)]` upper endpoint sits under `s(N+1)+1`. -/
private theorem addS1Wr_le_cap {s : Q} (hsd : 0 < s.den) (N : Nat) :
    Qle (add (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))))
        (capHi s N) := by
  show Qle _ (add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q))
  exact Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addS1Wr_eq N)) (Qle_self_add (by decide))

/-- The reschedule cap `[s, s(N+1)]` upper endpoint sits under `(s+1)(N+2)`. -/
private theorem addS1Wr_le_res {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (add (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))))
        (resHi s N) :=
  Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addS1Wr_eq N)) (hhisN_res hsn hsd N)

/-- `1·s ≤ s(N+1) − 0·s` — the split-point width bound. -/
private theorem w1_le_capW {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))) := by
  have eW : Qeq (mul s (⟨(N : Int) + 1, 1⟩ : Q))
      (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  refine Qle_trans (Qmul_den_pos hsd Nat.one_pos) ?_ (Qeq_le eW)
  exact qmul_le_left_mono (Int.le_of_lt hsn) (by simp only [Qle]; push_cast; omega)

/-- The reschedule cap width `[s, s(N+1)]` reconciles with the split right-piece width. -/
private theorem wr_eq_capWsub {s : Q} (N : Nat) :
    Qeq (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
        (Qsub (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))) (mul s (⟨1, 1⟩ : Q))) := by
  simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor

-- ===========================================================================
-- Width nonnegativity numerators.
-- ===========================================================================

/-- `0 ≤ (s(N+1) − 0·s).num`. -/
private theorem capW_num {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    (0 : Int) ≤ (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))).num := by
  have e : (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))).num
      = (s.den : Int) * (s.num * ((N : Int) + 1)) := by
    simp only [Qsub, mul, add, neg]; push_cast; ring_uor
  rw [e]
  exact Int.mul_nonneg (Int.ofNat_nonneg _)
    (Int.mul_nonneg (Int.le_of_lt hsn) (by omega))

/-- `0 ≤ (s(N+1) − 1·s).num`. -/
private theorem wr_num {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    (0 : Int) ≤ (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))).num := by
  have e : (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))).num
      = (s.den : Int) * (s.num * (N : Int)) := by
    simp only [Qsub, mul, add, neg]; push_cast; ring_uor
  rw [e]
  exact Int.mul_nonneg (Int.ofNat_nonneg _)
    (Int.mul_nonneg (Int.le_of_lt hsn) (Int.ofNat_nonneg _))

/-- `0 ≤ ((s(N+1) − 0·s) − 1·s).num` — the split right-piece width. -/
private theorem capW_sub_w1_num {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    (0 : Int) ≤ (Qsub (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
      (mul s (⟨1, 1⟩ : Q))).num := by
  have e : (Qsub (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))) (mul s (⟨1, 1⟩ : Q))).num
      = (s.den : Int) * ((s.den : Int) * (s.num * (N : Int))) := by
    simp only [Qsub, mul, add, neg]; push_cast; ring_uor
  rw [e]
  exact Int.mul_nonneg (Int.ofNat_nonneg _)
    (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg (Int.le_of_lt hsn) (Int.ofNat_nonneg _)))

-- ===========================================================================
-- Affine window bounds and the `genSum ≡ RsumN` bridge.
-- ===========================================================================

/-- The affine window point sits above its base: `a ≤ a + w·x` on `[0,1]` (`w ≥ 0`). -/
private theorem affine_ge_base (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    {x : Real} (h0 : Rle zero x) : Rle (ofQ a ha) (affineMap a w ha hw x) :=
  Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0))

/-- The affine window point sits below its top: `a + w·x ≤ a + w` on `[0,1]` (`w ≥ 0`). -/
private theorem affine_le_top (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    {x : Real} (h1 : Rle x one) :
    Rle (affineMap a w ha hw x) (ofQ (add a w) (add_den_pos ha hw)) := by
  have hwnn : Rnonneg (ofQ w hw) := Rnonneg_ofQ hw hwn
  have hxle : Rle (Rmul (ofQ w hw) x) (ofQ w hw) :=
    Rle_trans (Rmul_le_Rmul_left hwnn h1) (Rle_of_Req (Rmul_one (ofQ w hw)))
  exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle)
    (Rle_of_Req (Radd_ofQ_ofQ ha hw))

/-- `genSum` and `RsumN` are the same left fold. -/
private theorem genSum_RsumN_loc (T : Nat → Real) : ∀ N, Req (genSum T N) (RsumN T N)
  | 0 => Req_refl zero
  | (M + 1) => Radd_congr (genSum_RsumN_loc T M) (Req_refl _)

-- ===========================================================================
-- THE `s`-UNIFORM PARTIAL SUM AS A CAP INTEGRAL.
-- ===========================================================================

/-- **THE `s`-UNIFORM-TILING PARTIAL SUM AS A SINGLE CAP INTEGRAL.** The compact `[0,s]` moment piece
    (the `mellinMoment_dilate` LHS, against `powBandGen_{[0,s+1]}`) plus the finite `s`-scaled twisted
    partial sum `genSum scaledTwTerm … N` equals a single interval integral of `φ` against the
    wide-band power weight over the scaled cap `[0, s(N+1)]`:

      `∫_0^s (φ · powBandGen_{[0,s+1]}) + Σ_{m<N} scaledTwTerm φ s … m
          = ∫_0^{s(N+1)} (φ · powBandGen_{[0,s(N+1)+1]})`.

    The tail is `genSum_scaled_eq` (`= s^(n+1)·genSum(twTerm(dilate_s φ))`, `genSum ≡ RsumN`) fed into
    `reschedule_finite` at the covering band `[0,(s+1)(N+2)]`, then reconciled to the cap band by the
    different-`L` window congruence `riemannIntegralI_congr_unit_mod` and to the split-window endpoints
    by `riemannIntegralI_congr_Q`. The join is `riemannIntegralI_split_at` at `s`, with the compact
    piece reconciled to `[0,s+1]` by the same window congruence. -/
theorem uniform_partial_eq_cap (φ : L2Test) (n N : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) :
    Req
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (genSum (fun m => scaledTwTerm φ s hsn hsd n m) N))
      (riemannIntegralI
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
        (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
        (Qmul_den_pos hsd Nat.one_pos)
        (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
        (capW_num hsn hsd N)) := by
  -- ---- the tail: genSum scaledTwTerm N ≈ the split right piece ----
  have tail : Req (genSum (fun m => scaledTwTerm φ s hsn hsd n m) N)
      (riemannIntegralI
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
        (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
        (Qsub (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))) (mul s (⟨1, 1⟩ : Q)))
        (add_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
        (Qsub_den_pos (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
          (Qmul_den_pos hsd Nat.one_pos))
        (capW_sub_w1_num hsn hsd N)) := by
    refine Req_trans (genSum_scaled_eq φ s hsn hsd n N) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (genSum_RsumN_loc _ N)) ?_
    refine Req_trans
      (reschedule_finite φ n N s hsn hsd (⟨0, 1⟩ : Q) (resHi s N) (by decide) (resHi_den hsd N)
        (res_le hsn hsd N) (by decide) (by decide) (hlo_s1 hsn) (hhiN_res hsn N)
        (hhisN_res hsn hsd N)) ?_
    -- swap the covering band `[0,(s+1)(N+2)]` for the cap band `[0,s(N+1)+1]` on `[s,s(N+1)]`
    refine Req_trans
      (riemannIntegralI_congr_unit_mod
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (resHi s N) (by decide)
          (resHi_den hsd N) (res_le hsn hsd N) (by decide) n)).hLd
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (resHi s N) (by decide)
          (resHi_den hsd N) (res_le hsn hsd N) (by decide) n)).hLn
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (resHi s N) (by decide)
          (resHi_den hsd N) (res_le hsn hsd N) (by decide) n)).hlip
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (resHi s N) (by decide)
          (resHi_den hsd N) (res_le hsn hsd N) (by decide) n)).hfc
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
        (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
        (Qmul_den_pos hsd Nat.one_pos)
        (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
        (wr_num hsn hsd N)
        (by
          intro x h0 h1
          have hyb := affine_ge_base (mul s (⟨1, 1⟩ : Q))
            (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
            (Qmul_den_pos hsd Nat.one_pos)
            (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
            (wr_num hsn hsd N) h0
          have hyt := affine_le_top (mul s (⟨1, 1⟩ : Q))
            (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
            (Qmul_den_pos hsd Nat.one_pos)
            (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
            (wr_num hsn hsd N) h1
          have hlo0 : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) _ :=
            Rle_trans (Rle_ofQ_ofQ (by decide) (Qmul_den_pos hsd Nat.one_pos) (hlo_s1 hsn)) hyb
          have hhiR : Rle _ (ofQ (resHi s N) (resHi_den hsd N)) :=
            Rle_trans hyt (Rle_ofQ_ofQ
              (add_den_pos (Qmul_den_pos hsd Nat.one_pos)
                (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)))
              (resHi_den hsd N) (addS1Wr_le_res hsn hsd N))
          have hhiC : Rle _ (ofQ (capHi s N) (capHi_den hsd N)) :=
            Rle_trans hyt (Rle_ofQ_ofQ
              (add_den_pos (Qmul_den_pos hsd Nat.one_pos)
                (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)))
              (capHi_den hsd N) (addS1Wr_le_cap hsd N))
          have hpbR := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (resHi s N) (by decide)
            (resHi_den hsd N) (res_le hsn hsd N) (by decide) n hlo0 hhiR
          have hpbC := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (capHi s N) (by decide)
            (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n hlo0 hhiC
          exact Req_trans (Rmul_congr (Req_refl _) hpbR)
            (Req_symm (Rmul_congr (Req_refl _) hpbC)))) ?_
    -- reconcile the reschedule cap window `[s, s(N+1)]` with the split right-piece window
    exact riemannIntegralI_congr_Q
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
      (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
      (add (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
      (Qsub (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))) (mul s (⟨1, 1⟩ : Q)))
      (Qmul_den_pos hsd Nat.one_pos)
      (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
      (wr_num hsn hsd N)
      (add_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
      (Qsub_den_pos (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
        (Qmul_den_pos hsd Nat.one_pos))
      (capW_sub_w1_num hsn hsd N)
      (Qeq_symm (addS0S1_eq_S1 s)) (wr_eq_capWsub N)
  -- ---- the compact piece: M ≈ the split left piece ----
  have Mrecon : Req
      (riemannIntegralI
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
          (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hLd
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
          (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hLn
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
          (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hlip
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
          (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hfc
        (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
        (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
      (riemannIntegralI
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
        (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
        (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
        (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
        (Int.mul_nonneg (Int.le_of_lt hsn) (by decide))) := by
    refine riemannIntegralI_congr_unit_mod
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hLd
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hLn
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hlip
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
        (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n)).hfc
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
      (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
        (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
      (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
      (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
      (Int.mul_nonneg (Int.le_of_lt hsn) (by decide))
      (by
        intro x h0 h1
        have hyb := affine_ge_base (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)) h0
        have hyt := affine_le_top (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)) h1
        have hlo0 : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) _ :=
          Rle_trans (Rle_ofQ_ofQ (by decide) (Qmul_den_pos hsd Nat.one_pos) (hlo_s0 s)) hyb
        have hhiSp : Rle _ (ofQ (add s (⟨1, 1⟩ : Q)) (add_den_pos hsd (by decide))) :=
          Rle_trans hyt (Rle_ofQ_ofQ
            (add_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
            (add_den_pos hsd (by decide)) (addS0S1_le_sp1 hsd))
        have hhiC : Rle _ (ofQ (capHi s N) (capHi_den hsd N)) :=
          Rle_trans hyt (Rle_ofQ_ofQ
            (add_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
            (capHi_den hsd N) (addS0S1_le_cap hsn hsd N))
        have hpbSp := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
          (add_den_pos hsd (by decide)) (band01le hsn) (by decide) n hlo0 hhiSp
        have hpbC := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (capHi s N) (by decide)
          (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n hlo0 hhiC
        exact Req_trans (Rmul_congr (Req_refl _) hpbSp)
          (Req_symm (Rmul_congr (Req_refl _) hpbC)))
  -- ---- the split of the cap `[0, s(N+1)]` at `s` ----
  have splitAt := riemannIntegralI_split_at
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
      (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLd
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
      (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hLn
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
      (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hlip
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHi s N) (by decide)
      (capHi_den hsd N) (cap_le hsn hsd N) (by decide) n)).hfc
    (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
    (mul s (⟨1, 1⟩ : Q))
    (Qmul_den_pos hsd Nat.one_pos)
    (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
    (capW_num hsn hsd N)
    (Qmul_den_pos hsd Nat.one_pos) (Int.mul_pos hsn (by decide))
    (w1_le_capW hsn hsd N) (capW_sub_w1_num hsn hsd N)
  exact Req_trans (Radd_congr Mrecon tail) (Req_symm splitAt)

end Multiplicity.UOR.Bridge.F1Square.Square
