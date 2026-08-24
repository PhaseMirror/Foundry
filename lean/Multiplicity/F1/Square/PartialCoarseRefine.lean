/-
F1 square — **the GENERAL common-refinement identity of two uniform tilings** (`PartialCoarseRefine.lean`):
for a fine rational scale `fine` (`0 < fine.num`, `0 < fine.den`) and a positive integer `k`, the
coarse scale `coarse := fine · k` (as `Q`, `= mul fine ⟨k, 1⟩`) has its `coarse`-uniform partial sum
equal to the `fine`-uniform partial sum evaluated at the shifted index `k(N+1)-1`.

Both partial sums are the compact `[0, scale]` moment piece plus the finite scaled twisted tail up to
their respective indices; the committed `uniform_partial_eq_cap` collapses EACH of them to a single
cap integral — the `coarse`-side to `∫_0^{coarse(N+1)}` and the `fine`-side to `∫_0^{fine·k(N+1)}`.
Since `coarse(N+1) = fine·k(N+1)` (`Qeq`, because `coarse.num = fine.num·k` and `coarse.den =
fine.den`, and `(k(N+1)-1)+1 = k(N+1)`), the two caps agree: the cap values match by
`riemannIntegralI_congr_Q` (equal start `0`, `Qeq` width) after the wide-band weights are reconciled
on the shared window `[0, coarse(N+1)]` by the different-`L` window congruence
`riemannIntegralI_congr_unit_mod` (both are `uⁿ` there, `powBandGen_eq_Rpow_on`). This generalizes the
committed `partial_s_eq_partial_refine` (its case `fine = 1/s.den`, `k = s.num.toNat`, `coarse = s`) so
that it applies to BOTH the `s`-side (`fine = 1/q`, `k = p`, `coarse = s`) AND the `1`-side
(`fine = 1/q`, `k = q`, `coarse = 1`) of the width comparison in the tiling-independence step.

HONEST SCOPE. The general common-refinement identity — a coarse-uniform partial sum (`coarse = fine·k`,
`k` a positive integer) equals the fine-uniform partial sum at index `k(N+1)-1`, because both equal the
same cap integral over `[0, coarse(N+1)]`, via the committed `uniform_partial_eq_cap` at both scales
plus `riemannIntegralI_congr_Q` on the equal cap value. It generalizes `partial_s_eq_partial_refine` to
cover both the `s`-side (`k = p`) and the `1`-side (`k = q`) of the width comparison. It builds NO
`Rlim`, NO rung-4b application, NO width-comparison completion, NO factorization, NO positivity, NO
determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay none.
Pure Lean 4 core, no Mathlib, no sorry/native_decide, choice-free; audited by scripts/honesty_audit.sh.
-/

import Multiplicity.F1.Square.UniformPartialCap

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Positivity of the coarse scale `coarse := mul fine ⟨k, 1⟩`.
-- ===========================================================================

/-- The coarse-scale numerator is positive: `coarse.num = fine.num·k > 0`. -/
private theorem cnum_pos (fine : Q) (hfn : 0 < fine.num) (k : Nat) (hk : 0 < k) :
    0 < (mul fine (⟨(k : Int), 1⟩ : Q)).num := by
  have hkI : (0 : Int) < (k : Int) := by exact_mod_cast hk
  exact Int.mul_pos hfn hkI

/-- The coarse-scale denominator is positive: `coarse.den = fine.den·1 > 0`. -/
private theorem cden_pos (fine : Q) (hfd : 0 < fine.den) (k : Nat) :
    0 < (mul fine (⟨(k : Int), 1⟩ : Q)).den :=
  Qmul_den_pos hfd Nat.one_pos

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
-- The general common-refinement bridge.
-- ===========================================================================

/-- **The general common-refinement identity of two uniform tilings.** For a fine rational scale
    `fine` (`0 < fine.num`, `0 < fine.den`) and a positive integer `k`, set `coarse := fine·k`
    (`= mul fine ⟨k, 1⟩`). The `coarse`-uniform partial sum (compact `[0, coarse]` moment plus the
    finite `coarse`-scaled twisted tail up to `N`) equals the `fine`-uniform partial sum evaluated at
    the shifted index `k(N+1)-1`. Both collapse (`uniform_partial_eq_cap` at each scale) to the SAME
    cap integral over `[0, coarse(N+1)]`: the cap band weights are reconciled on the shared window by
    the different-`L` window congruence `riemannIntegralI_congr_unit_mod` (both are `uⁿ` there), and
    the equal cap value `coarse(N+1) = fine·k(N+1)` is discharged by `riemannIntegralI_congr_Q`. It
    generalizes `partial_s_eq_partial_refine` (its case `fine = 1/s.den`, `k = s.num.toNat`,
    `coarse = s`) to both the `s`-side (`k = p`) and the `1`-side (`k = q`). -/
theorem partial_coarse_refine (φ : L2Test) (n N : Nat) (fine : Q)
    (hfn : 0 < fine.num) (hfd : 0 < fine.den) (k : Nat) (hk : 0 < k) :
    Req
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q))
            (by decide) (add_den_pos (cden_pos fine hfd k) (by decide))
            (band01leL (cnum_pos fine hfn k hk)) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q))
            (by decide) (add_den_pos (cden_pos fine hfd k) (by decide))
            (band01leL (cnum_pos fine hfn k hk)) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q))
            (by decide) (add_den_pos (cden_pos fine hfd k) (by decide))
            (band01leL (cnum_pos fine hfn k hk)) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q))
            (by decide) (add_den_pos (cden_pos fine hfd k) (by decide))
            (band01leL (cnum_pos fine hfn k hk)) (by decide) n)).hfc
          (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
          (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q))
          (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
          (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt (cnum_pos fine hfn k hk)) (by decide)))
        (genSum (fun m => scaledTwTerm φ (mul fine (⟨(k : Int), 1⟩ : Q))
          (cnum_pos fine hfn k hk) (cden_pos fine hfd k) n m) N))
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add fine (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hfd (by decide)) (band01leL hfn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add fine (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hfd (by decide)) (band01leL hfn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add fine (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hfd (by decide)) (band01leL hfn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add fine (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hfd (by decide)) (band01leL hfn) (by decide) n)).hfc
          (mul fine (⟨0, 1⟩ : Q)) (mul fine (⟨1, 1⟩ : Q))
          (Qmul_den_pos hfd Nat.one_pos) (Qmul_den_pos hfd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hfn) (by decide)))
        (genSum (fun m => scaledTwTerm φ fine hfn hfd n m)
          (k * (N + 1) - 1))) := by
  have hpNpos : 0 < k * (N + 1) := Nat.mul_pos hk (Nat.succ_pos N)
  have hMint : ((k * (N + 1) - 1 : Nat) : Int) + 1 = (k : Int) * ((N : Int) + 1) := by
    have h : ((k * (N + 1) - 1 : Nat) : Int) + 1 = ((k * (N + 1) : Nat) : Int) := by omega
    rw [h]; push_cast; rfl
  have hlit : (⟨((k * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q)
      = (⟨(k : Int) * ((N : Int) + 1), 1⟩ : Q) := by rw [hMint]
  have startEq : Qeq (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q)) (mul fine (⟨0, 1⟩ : Q)) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have widthEq : Qeq
      (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
        (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q)))
      (Qsub (mul fine (⟨((k * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q))
        (mul fine (⟨0, 1⟩ : Q))) := by
    rw [hlit]; simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  have capvalEq : Qeq (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
      (mul fine (⟨((k * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q)) := by
    rw [hlit]; simp only [Qeq, mul]; push_cast; ring_uor
  refine Req_trans
    (uniform_partial_eq_cap φ n N (mul fine (⟨(k : Int), 1⟩ : Q))
      (cnum_pos fine hfn k hk) (cden_pos fine hfd k))
    (Req_trans
      (Req_trans
        (riemannIntegralI_congr_unit_mod
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (mul fine (⟨(k : Int), 1⟩ : Q)) N) (by decide)
            (capHiL_den (cden_pos fine hfd k) N)
            (caple (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (mul fine (⟨(k : Int), 1⟩ : Q)) N) (by decide)
            (capHiL_den (cden_pos fine hfd k) N)
            (caple (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (mul fine (⟨(k : Int), 1⟩ : Q)) N) (by decide)
            (capHiL_den (cden_pos fine hfd k) N)
            (caple (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL (mul fine (⟨(k : Int), 1⟩ : Q)) N) (by decide)
            (capHiL_den (cden_pos fine hfd k) N)
            (caple (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) (by decide) n)).hfc
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hfc
          (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
          (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
            (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q)))
          (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
            (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos))
          (capWnum (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N)
          (by
            intro x h0 h1
            have hyb := affine_ge_baseL (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
              (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
                (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q)))
              (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
              (Qsub_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos))
              (capWnum (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) h0
            have hyt := affine_le_topL (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
              (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
                (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q)))
              (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
              (Qsub_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos))
              (capWnum (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) h1
            have hlo0 := Rle_trans
              (Rle_ofQ_ofQ (by decide) (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                (hlo_s0L (mul fine (⟨(k : Int), 1⟩ : Q)))) hyb
            have hUpS : Qle
                (add (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
                  (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
                    (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))))
                (capHiL (mul fine (⟨(k : Int), 1⟩ : Q)) N) :=
              Qle_trans (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                (Qeq_le (addstartW_eq N)) (Qle_self_add (by decide))
            have hUpR : Qle
                (add (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
                  (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
                    (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))))
                (capHiL fine (k * (N + 1) - 1)) :=
              Qle_trans (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                (Qeq_le (addstartW_eq N))
                (Qle_trans (Qmul_den_pos (a := fine) hfd Nat.one_pos)
                  (Qeq_le capvalEq) (Qle_self_add (by decide)))
            have hhiS := Rle_trans hyt
              (Rle_ofQ_ofQ
                (add_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                  (Qsub_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                    (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)))
                (capHiL_den (cden_pos fine hfd k) N) hUpS)
            have hhiR := Rle_trans hyt
              (Rle_ofQ_ofQ
                (add_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                  (Qsub_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
                    (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)))
                (capHiL_den (s := fine) hfd (k * (N + 1) - 1)) hUpR)
            have hpbS := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q)
              (capHiL (mul fine (⟨(k : Int), 1⟩ : Q)) N) (by decide)
              (capHiL_den (cden_pos fine hfd k) N)
              (caple (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N) (by decide) n hlo0 hhiS
            have hpbR := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q)
              (capHiL fine (k * (N + 1) - 1)) (by decide)
              (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
              (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n hlo0 hhiR
            exact Req_trans (Rmul_congr (Req_refl _) hpbS)
              (Req_symm (Rmul_congr (Req_refl _) hpbR))))
        (riemannIntegralI_congr_Q
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiL fine (k * (N + 1) - 1)) (by decide)
            (capHiL_den (s := fine) hfd (k * (N + 1) - 1))
            (caple (s := fine) hfn hfd (k * (N + 1) - 1)) (by decide) n)).hfc
          (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q))
          (Qsub (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨(N : Int) + 1, 1⟩ : Q))
            (mul (mul fine (⟨(k : Int), 1⟩ : Q)) (⟨0, 1⟩ : Q)))
          (mul fine (⟨0, 1⟩ : Q))
          (Qsub (mul fine (⟨((k * (N + 1) - 1 : Nat) : Int) + 1, 1⟩ : Q))
            (mul fine (⟨0, 1⟩ : Q)))
          (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos)
            (Qmul_den_pos (cden_pos fine hfd k) Nat.one_pos))
          (capWnum (cnum_pos fine hfn k hk) (cden_pos fine hfd k) N)
          (Qmul_den_pos hfd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hfd Nat.one_pos) (Qmul_den_pos hfd Nat.one_pos))
          (capWnum (s := fine) hfn hfd (k * (N + 1) - 1))
          startEq widthEq))
      (Req_symm
        (uniform_partial_eq_cap φ n (k * (N + 1) - 1) fine hfn hfd)))

end Multiplicity.UOR.Bridge.F1Square.Square
