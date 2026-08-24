/-
F1 square — **the common-refinement identity of the two uniform tilings** (`PartialCommonRefine.lean`):
for a rational scale `s = ⟨p, q⟩` (`p = s.num > 0`, `q = s.den`), the `s`-uniform partial sum equals
the `(1/q)`-uniform partial sum evaluated at the shifted index `p(N+1)-1`.

Both partial sums are the compact `[0, scale]` moment piece plus the finite scaled twisted tail up to
their respective indices; the committed `uniform_partial_eq_cap` collapses EACH of them to a single
cap integral — the `s`-side to `∫_0^{s(N+1)}` and the `(1/q)`-side to `∫_0^{(1/q)·p(N+1)}`. Since
`s(N+1) = p(N+1)/q = (1/q)·p(N+1)` (`Qeq`, using `(p : Int) = s.num`), the two caps agree: the cap
values match by `riemannIntegralI_congr_Q` (equal start `0`, `Qeq` width) after the wide-band weights
are reconciled on the shared window `[0, s(N+1)]` by the different-`L` window congruence
`riemannIntegralI_congr_unit_mod` (both are `uⁿ` there, `powBandGen_eq_Rpow_on`). This is the step that
lets rung 4b compare the widths of the two tilings as fast cofinal schedules of the SAME summand.

HONEST SCOPE. The common-refinement identity — the `s`-uniform partial sum equals the `(1/q)`-uniform
partial sum at the shifted index `p(N+1)-1` (`q = s.den`, `p = s.num`), because both equal the same cap
integral over `[0, s(N+1)]`, via the committed `uniform_partial_eq_cap` at both scales plus
`riemannIntegralI_congr_Q` on the equal cap value. It builds NO `Rlim`, NO rung-4b application, NO
width-comparison completion, NO factorization, NO positivity, NO determinacy, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay none.
Pure Lean 4 core, no Mathlib, no sorry/native_decide, choice-free; audited by scripts/honesty_audit.sh.
-/

import Multiplicity.F1.Square.UniformPartialCap

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local copies of the cap-band substrate (the originals are `private` to
-- `UniformPartialCap.lean`; each of these is definitionally equal to its twin,
-- so the two `uniform_partial_eq_cap` cap integrals unify with the ones built here).
-- ===========================================================================

/-- The cap band upper endpoint `s(N+1)+1` — covers the whole scaled cap `[0, s(N+1)]`. -/
private def capHiL (s : Q) (N : Nat) : Q := add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q)

/-- The cap band upper endpoint has a positive denominator. -/
private theorem capHiL_den {s : Q} (hsd : 0 < s.den) (N : Nat) : 0 < (capHiL s N).den :=
  add_den_pos (Qmul_den_pos hsd Nat.one_pos) (by decide)

/-- `0 ≤ s(N+1)+1` — the cap band low end. -/
private theorem caple {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (⟨0, 1⟩ : Q) (capHiL s N) := by
  show Qle (⟨0, 1⟩ : Q) (add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q))
  refine Qle_trans (Qmul_den_pos hsd Nat.one_pos) ?_ (Qle_self_add (by decide))
  simp only [Qle, mul]; push_cast
  have hprod : (0 : Int) ≤ s.num * ((N : Int) + 1) * 1 :=
    Int.mul_nonneg (Int.mul_nonneg (Int.le_of_lt hsn) (by omega)) (by omega)
  omega

/-- `0 ≤ (s(N+1) − 0·s).num` — the cap width numerator. -/
private theorem capWnum {s : Q} (hsn : 0 < s.num) (_hsd : 0 < s.den) (N : Nat) :
    (0 : Int) ≤ (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))).num := by
  have e : (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))).num
      = (s.den : Int) * (s.num * ((N : Int) + 1)) := by
    simp only [Qsub, mul, add, neg]; push_cast; ring_uor
  rw [e]
  exact Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg (Int.le_of_lt hsn) (by omega))

/-- `0 ≤ s+1` — the low end of the compact band `[0, s+1]`. -/
private theorem band01leL {s : Q} (hsn : 0 < s.num) : Qle (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast; omega

/-- `0 ≤ s·0`. -/
private theorem hlo_s0L (s : Q) : Qle (⟨0, 1⟩ : Q) (mul s (⟨0, 1⟩ : Q)) := by
  simp only [Qle, mul]; push_cast; omega

/-- `0·s + (s(N+1) − 0·s) ≡ s(N+1)` — the cap window collapses back to `s(N+1)`. -/
private theorem addstartW_eq {s : Q} (N : Nat) :
    Qeq (add (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))))
        (mul s (⟨(N : Int) + 1, 1⟩ : Q)) := by
  simp only [Qeq, add, Qsub, mul, neg]; push_cast; ring_uor

/-- The affine window point sits above its base: `a ≤ a + w·x` on `[0,1]` (`w ≥ 0`). -/
private theorem affine_ge_baseL (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    {x : Real} (h0 : Rle zero x) : Rle (ofQ a ha) (affineMap a w ha hw x) :=
  Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0))

/-- The affine window point sits below its top: `a + w·x ≤ a + w` on `[0,1]` (`w ≥ 0`). -/
private theorem affine_le_topL (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    {x : Real} (h1 : Rle x one) :
    Rle (affineMap a w ha hw x) (ofQ (add a w) (add_den_pos ha hw)) := by
  have hwnn : Rnonneg (ofQ w hw) := Rnonneg_ofQ hw hwn
  have hxle : Rle (Rmul (ofQ w hw) x) (ofQ w hw) :=
    Rle_trans (Rmul_le_Rmul_left hwnn h1) (Rle_of_Req (Rmul_one (ofQ w hw)))
  exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle)
    (Rle_of_Req (Radd_ofQ_ofQ ha hw))

-- ===========================================================================
-- The common-refinement bridge.
-- ===========================================================================

/-- **The common-refinement identity of the two uniform tilings.** For a rational scale `s = ⟨p, q⟩`
    with `p = s.num > 0` and `q = s.den`, the `s`-uniform partial sum (compact `[0,s]` moment plus the
    finite `s`-scaled twisted tail up to `N`) equals the `(1/q)`-uniform partial sum evaluated at the
    shifted index `p(N+1)-1`. Both collapse (`uniform_partial_eq_cap` at each scale) to the SAME cap
    integral over `[0, s(N+1)]`: the cap band weights are reconciled on the shared window by the
    different-`L` window congruence `riemannIntegralI_congr_unit_mod` (both are `uⁿ` there), and the
    equal cap value `s(N+1) = (1/q)·p(N+1)` is discharged by `riemannIntegralI_congr_Q`. -/
theorem partial_s_eq_partial_refine (φ : L2Test) (n N : Nat) (s : Q)
    (hsn : 0 < s.num) (hsd : 0 < s.den) :
    Req
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (genSum (fun m => scaledTwTerm φ s hsn hsd n m) N))
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, s.den⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL Int.zero_lt_one) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, s.den⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL Int.zero_lt_one) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, s.den⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL Int.zero_lt_one) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (⟨1, s.den⟩ : Q) (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leL Int.zero_lt_one) (by decide) n)).hfc
          (mul (⟨1, s.den⟩ : Q) (⟨0, 1⟩ : Q)) (mul (⟨1, s.den⟩ : Q) (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt Int.zero_lt_one) (by decide)))
        (genSum (fun m => scaledTwTerm φ (⟨1, s.den⟩ : Q) Int.zero_lt_one hsd n m)
          (s.num.toNat * (N + 1) - 1))) := by
  have hpeq : (s.num.toNat : Int) = s.num := Int.toNat_of_nonneg (Int.le_of_lt hsn)
  have hp1 : 0 < s.num.toNat := by omega
  have hpNpos : 0 < s.num.toNat * (N + 1) := Nat.mul_pos hp1 (Nat.succ_pos N)
  have hMint : ((s.num.toNat * (N + 1) - 1 : Nat) : Int) + 1 = s.num * ((N : Int) + 1) := by
    have h : ((s.num.toNat * (N + 1) - 1 : Nat) : Int) + 1
        = ((s.num.toNat * (N + 1) : Nat) : Int) := by omega
    rw [h]; push_cast; rw [hpeq]
  have hlit : (⟨((s.num.toNat * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q)
      = (⟨s.num * ((N : Int) + 1), 1⟩ : Q) := by rw [hMint]
  have startEq : Qeq (mul s (⟨0, 1⟩ : Q)) (mul (⟨1, s.den⟩ : Q) (⟨0, 1⟩ : Q)) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have widthEq : Qeq
      (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
      (Qsub (mul (⟨1, s.den⟩ : Q) (⟨((s.num.toNat * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q))
        (mul (⟨1, s.den⟩ : Q) (⟨0, 1⟩ : Q))) := by
    rw [hlit]; simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  have capvalEq : Qeq (mul s (⟨(N : Int) + 1, 1⟩ : Q))
      (mul (⟨1, s.den⟩ : Q) (⟨((s.num.toNat * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q)) := by
    rw [hlit]; simp only [Qeq, mul]; push_cast; ring_uor
  refine Req_trans
    (uniform_partial_eq_cap φ n N s hsn hsd)
    (Req_trans
      (Req_trans
        (riemannIntegralI_congr_unit_mod
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL s N) (by decide)
            (capHiL_den hsd N) (caple hsn hsd N) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL s N) (by decide)
            (capHiL_den hsd N) (caple hsn hsd N) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL s N) (by decide)
            (capHiL_den hsd N) (caple hsn hsd N) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL s N) (by decide)
            (capHiL_den hsd N) (caple hsn hsd N) (by decide) n)).hfc
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
          (Qmul_den_pos hsd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
          (capWnum hsn hsd N)
          (by
            intro x h0 h1
            have hyb := affine_ge_baseL (mul s (⟨0, 1⟩ : Q))
              (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
              (Qmul_den_pos hsd Nat.one_pos)
              (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
              (capWnum hsn hsd N) h0
            have hyt := affine_le_topL (mul s (⟨0, 1⟩ : Q))
              (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
              (Qmul_den_pos hsd Nat.one_pos)
              (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
              (capWnum hsn hsd N) h1
            have hlo0 := Rle_trans
              (Rle_ofQ_ofQ (by decide) (Qmul_den_pos hsd Nat.one_pos) (hlo_s0L s)) hyb
            have hUpS : Qle
                (add (mul s (⟨0, 1⟩ : Q))
                  (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))))
                (capHiL s N) :=
              Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addstartW_eq N))
                (Qle_self_add (by decide))
            have hUpR : Qle
                (add (mul s (⟨0, 1⟩ : Q))
                  (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))))
                (capHiL (⟨1, s.den⟩ : Q) (s.num.toNat * (N + 1) - 1)) :=
              Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addstartW_eq N))
                (Qle_trans (Qmul_den_pos (a := (⟨1, s.den⟩ : Q)) hsd Nat.one_pos) (Qeq_le capvalEq)
                  (Qle_self_add (by decide)))
            have hhiS := Rle_trans hyt
              (Rle_ofQ_ofQ
                (add_den_pos (Qmul_den_pos hsd Nat.one_pos)
                  (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)))
                (capHiL_den hsd N) hUpS)
            have hhiR := Rle_trans hyt
              (Rle_ofQ_ofQ
                (add_den_pos (Qmul_den_pos hsd Nat.one_pos)
                  (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)))
                (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1)) hUpR)
            have hpbS := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (capHiL s N) (by decide)
              (capHiL_den hsd N) (caple hsn hsd N) (by decide) n hlo0 hhiS
            have hpbR := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q)
              (capHiL (⟨1, s.den⟩ : Q) (s.num.toNat * (N + 1) - 1)) (by decide)
              (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
              (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
              (by decide) n hlo0 hhiR
            exact Req_trans (Rmul_congr (Req_refl _) hpbS)
              (Req_symm (Rmul_congr (Req_refl _) hpbR))))
        (riemannIntegralI_congr_Q
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (⟨1, s.den⟩ : Q)
            (s.num.toNat * (N + 1) - 1)) (by decide)
            (capHiL_den (s := (⟨1, s.den⟩ : Q)) hsd (s.num.toNat * (N + 1) - 1))
            (caple (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
            (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
          (mul (⟨1, s.den⟩ : Q) (⟨0, 1⟩ : Q))
          (Qsub (mul (⟨1, s.den⟩ : Q) (⟨((s.num.toNat * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q))
            (mul (⟨1, s.den⟩ : Q) (⟨0, 1⟩ : Q)))
          (Qmul_den_pos hsd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
          (capWnum hsn hsd N)
          (Qmul_den_pos hsd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
          (capWnum (s := (⟨1, s.den⟩ : Q)) Int.zero_lt_one hsd (s.num.toNat * (N + 1) - 1))
          startEq widthEq))
      (Req_symm
        (uniform_partial_eq_cap φ n (s.num.toNat * (N + 1) - 1) (⟨1, s.den⟩ : Q)
          Int.zero_lt_one hsd)))

end Multiplicity.UOR.Bridge.F1Square.Square
