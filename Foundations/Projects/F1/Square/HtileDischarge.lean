/-
F1 square — **discharging the tiling-independence hypothesis `htile`** (`HtileDischarge.lean`).

The committed `mellinHat_dilate_covariance` names the half-line Mellin dilation covariance
`s^(n+1)·mellinHat(dilate_s φ) = mellinHat φ` MODULO an explicit tiling-independence hypothesis
`htile` — that the `s`-uniform-tiling improper Mellin integral
`∫_{[0,s]}(φ·powBandGen) + Rlim(scaled sums)` equals the standard `mellinHat φ n`. This file
DISCHARGES `htile`, making the covariance unconditional.

The two reusable infrastructure bricks (STEP 1, STEP 2) are:

- `scaledTwTerm_bound` — the two-sided `Ks/((m+1)m)` decay of the `s`-scaled twisted window integral
  `scaledTwTerm φ s n m`, with `Ks := s^(n+1)·C·2ⁿ`, obtained by scaling the committed
  `twTerm_bound (dilate_s φ)` (`hdec`) through the per-window bridge `scaledTwTerm_eq` and the
  non-negative scalar `s^(n+1)`.
- `scaledTwTerm_schedule_eq` — the rung-4b schedule-independence for the scaled summand: any integer
  schedule `R` growing at least as fast as the canonical `digammaMidx Ks` yields the same `Rlim` as
  that canonical schedule (`genSum_close` + `Rlim_approx_eq`, general in the summand, with the STEP-1
  decay bound). Both fast cofinal `p`- and `q`-based schedules land on the common `digammaMidx`.

HONEST SCOPE. Discharging the tiling-independence hypothesis `htile` of the committed
`mellinHat_dilate_covariance` — both the `s`-uniform and `1`-uniform improper Mellin integrals refine
(`partial_s_eq_partial_refine` / `partial_coarse_refine`) to the common `1/q`-tiling where rung-4b
schedule-independence (`genSum_close` + `Rlim_approx_eq`, general in the summand, with the
`scaledTwTerm` decay bound) identifies their `Rlim`s, making the half-line Mellin dilation covariance
UNCONDITIONAL. `htile` is a non-RH real-analysis fact; discharging it introduces NO factorization, NO
positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
none.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinHatCovariance
import Foundations.F1.Square.MellinHatUniform1
import Foundations.F1.Square.PartialCommonRefine
import Foundations.F1.Square.PartialCoarseRefine
import Foundations.F1.Square.ImproperScheduleIndep
import Foundations.F1.CoreCompat

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- STEP 1 — the scaled twisted window integral obeys the `Ks/((m+1)m)` decay.
-- ===========================================================================

/-- Reassociation of the canonical modulus times the `1/((m+1)m)` tail factor. -/
private theorem Ks_reassoc (s C : Q) (n m : Nat) :
    Qeq (mul (qpow s (n + 1)) (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q)))
        (mul (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
          (⟨1, (m + 1) * m⟩ : Q)) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **The `s`-scaled twisted window decay.** For a test whose dilate `dilate_s φ` has exponent-`(n+2)`
    window decay (modulus `C`), the `s`-scaled twisted window integrals `scaledTwTerm φ s n m` obey the
    gateway's two-sided `Ks/((m+1)m)` bounds with `Ks := s^(n+1)·C·2ⁿ`. The committed
    `twTerm_bound (dilate_s φ)` gives the `C·2ⁿ/((m+1)m)` bound on `twTerm(dilate_s φ)`, and the
    per-window bridge `scaledTwTerm_eq` scales it by the non-negative rational `s^(n+1)`. -/
theorem scaledTwTerm_bound (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) (n : Nat)
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest s hsn hsd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
              (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos
              (Qmul_den_pos (qpow_den_pos hsd (n + 1)) (Qmul_den_pos hCd Nat.one_pos))
              (digamma_succ_mul_pos hm))))
          (scaledTwTerm φ s hsn hsd n m)
      ∧ Rle (scaledTwTerm φ s hsn hsd n m)
          (ofQ (mul (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
              (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos
              (Qmul_den_pos (qpow_den_pos hsd (n + 1)) (Qmul_den_pos hCd Nat.one_pos))
              (digamma_succ_mul_pos hm))) := by
  intro m hm
  obtain ⟨htlo, hthi⟩ := twTerm_bound (dilateTest s hsn hsd φ) n hCd hCn hdec m hm
  have habs_tw : Rle (Rabs (twTerm (dilateTest s hsn hsd φ) n m))
      (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))) :=
    Rabs_le_of_both hthi (Rle_trans (Rle_Rneg htlo) (Rle_of_Req (Rneg_neg _)))
  have hqnn : (0 : Int) ≤ (qpow s (n + 1)).num := qpow_nonneg (Int.le_of_lt hsn) (n + 1)
  have e1 : Req (Rabs (scaledTwTerm φ s hsn hsd n m))
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (Rabs (twTerm (dilateTest s hsn hsd φ) n m))) :=
    Req_trans (Rabs_congr (scaledTwTerm_eq φ s hsn hsd n m))
      (Rabs_Rmul_ofQ_nonneg (qpow_den_pos hsd (n + 1)) hqnn _)
  have hmono : Rle
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (Rabs (twTerm (dilateTest s hsn hsd φ) n m)))
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm)))) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ (qpow_den_pos hsd (n + 1)) hqnn) habs_tw
  have e2 : Req
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))))
      (ofQ (mul (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
          (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos
          (Qmul_den_pos (qpow_den_pos hsd (n + 1)) (Qmul_den_pos hCd Nat.one_pos))
          (digamma_succ_mul_pos hm))) :=
    Req_trans (Rmul_ofQ_ofQ (qpow_den_pos hsd (n + 1)) _)
      (Req_of_seq_Qeq (fun _ => Ks_reassoc s C n m))
  have habs_sc : Rle (Rabs (scaledTwTerm φ s hsn hsd n m))
      (ofQ (mul (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
          (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos
          (Qmul_den_pos (qpow_den_pos hsd (n + 1)) (Qmul_den_pos hCd Nat.one_pos))
          (digamma_succ_mul_pos hm))) :=
    Rle_trans (Rle_of_Req e1) (Rle_trans hmono (Rle_of_Req e2))
  exact ⟨Rneg_le_of_Rabs_le habs_sc, Rle_of_Rabs_le habs_sc⟩

-- ===========================================================================
-- STEP 2 — schedule independence of the scaled twisted tail.
-- ===========================================================================

/-- The canonical modulus `Ks := s^(n+1)·C·2ⁿ` has a positive denominator. -/
private theorem Ks_den (s : Q) (hsd : 0 < s.den) {C : Q} (hCd : 0 < C.den) (n : Nat) :
    0 < (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))).den :=
  Qmul_den_pos (qpow_den_pos hsd (n + 1)) (Qmul_den_pos hCd Nat.one_pos)

/-- The canonical modulus `Ks := s^(n+1)·C·2ⁿ` has a non-negative numerator. -/
private theorem Ks_num (s : Q) (hsn : 0 < s.num) {C : Q} (hCn : 0 ≤ C.num) (n : Nat) :
    (0 : Int) ≤ (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))).num := by
  show (0 : Int) ≤ (qpow s (n + 1)).num * (C.num * ((2 ^ n : Nat) : Int))
  exact Int.mul_nonneg (qpow_nonneg (Int.le_of_lt hsn) (n + 1))
    (Int.mul_nonneg hCn (Int.ofNat_nonneg _))

/-- **Schedule independence of the scaled twisted tail.** Any integer schedule `R` growing at least as
    fast as the canonical `digammaMidx Ks` (with `Ks := s^(n+1)·C·2ⁿ`) yields the same `Rlim` of the
    scaled twisted partial sums as the canonical schedule. `genSum_close` (with the STEP-1 decay bound)
    keeps the two schedules within `1/(j+1)`, and `Rlim_approx_eq` equates the limits. Both the `p`- and
    `q`-based cofinal schedules of the `1/q`-tiling instantiate this with the same canonical
    `digammaMidx`, so they share their `Rlim`. -/
theorem scaledTwTerm_schedule_eq (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) (n : Nat)
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest s hsn hsd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (R : Nat → Nat)
    (hgrow : ∀ j, digammaMidx (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))) j ≤ R j)
    (hRegR : RReg (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m) (R j))) :
    Req
      (Rlim (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m) (R j)) hRegR)
      (Rlim (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
          (digammaMidx (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))) j))
        (genSum_RReg (fun m => scaledTwTerm φ s hsn hsd n m) (Ks_den s hsd hCd n) (Ks_num s hsn hCn n)
          (scaledTwTerm_bound φ s hsn hsd n hCd hCn hdec))) :=
  Rlim_approx_eq (C := 1)
    (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m) (R j))
    (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul (qpow s (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))) j))
    hRegR
    (genSum_RReg (fun m => scaledTwTerm φ s hsn hsd n m) (Ks_den s hsd hCd n) (Ks_num s hsn hCn n)
      (scaledTwTerm_bound φ s hsn hsd n hCd hCn hdec))
    (fun j => genSum_close (fun m => scaledTwTerm φ s hsn hsd n m)
      (Ks_den s hsd hCd n) (Ks_num s hsn hCn n)
      (scaledTwTerm_bound φ s hsn hsd n hCd hCn hdec) R hgrow j)

-- ===========================================================================
-- STEP 3 substrate — regularity transfer and the scale-invariance bridge.
-- ===========================================================================

/-- Regularity is `Req`-congruent (via the real-difference completeness bridge). -/
private theorem RReg_congr {Y Z : Nat → Real} (h : ∀ j, Req (Y j) (Z j)) (hZ : RReg Z) : RReg Y := by
  refine RReg_of_real_bound Y (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
    (fun j k => Qle_refl _) ?_
  intro j k
  refine Rle_trans (Rle_of_Req (Rsub_congr (h j) (h k))) ?_
  intro n
  show Qle (add ((Z j).seq (2 * n + 1)) (neg ((Z k).seq (2 * n + 1))))
        (add (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (⟨2, n + 1⟩ : Q))
  have hr := hZ j k (2 * n + 1)
  have h1 : Qle (add ((Z j).seq (2 * n + 1)) (neg ((Z k).seq (2 * n + 1))))
      (Qabs (Qsub ((Z j).seq (2 * n + 1)) ((Z k).seq (2 * n + 1)))) := Qle_self_Qabs _
  have h2 : Qle (add (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (⟨2, (2 * n + 1) + 1⟩ : Q))
      (add (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (⟨2, n + 1⟩ : Q)) := by
    refine Qadd_le_add (Qle_refl _) ?_
    show (2 : Int) * ((n + 1 : Nat) : Int) ≤ 2 * (((2 * n + 1) + 1 : Nat) : Int)
    push_cast; omega
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos ((Z j).den_pos _) ((Z k).den_pos _)))
    h1 (Qle_trans (add_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (Nat.succ_pos _)) hr h2)

/-- Peel a fixed left-constant off a regular family. -/
private theorem RReg_of_add_const_left (c : Real) (X : Nat → Real)
    (h : RReg (fun j => Radd c (X j))) : RReg X := by
  have hW : RReg (fun j => Radd (Rneg c) (Radd c (X j))) := RReg_add_const (Rneg c) _ h
  refine RReg_congr (fun j => ?_) hW
  have e : Req (Radd (Rneg c) (Radd c (X j))) (X j) :=
    Req_trans (Req_symm (Radd_assoc (Rneg c) c (X j)))
      (Req_trans (Radd_congr (Req_trans (Radd_comm (Rneg c) c) (Radd_neg c)) (Req_refl _))
        (Req_trans (Radd_comm zero (X j)) (Radd_zero (X j))))
  exact Req_symm e

private def capHiB (s : Q) (N : Nat) : Q := add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q)

private theorem capHiB_den {s : Q} (hsd : 0 < s.den) (N : Nat) : 0 < (capHiB s N).den :=
  add_den_pos (Qmul_den_pos hsd Nat.one_pos) (by decide)

private theorem capleB {s : Q} (hsn : 0 < s.num) (hsd : 0 < s.den) (N : Nat) :
    Qle (⟨0, 1⟩ : Q) (capHiB s N) := by
  show Qle (⟨0, 1⟩ : Q) (add (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (⟨1, 1⟩ : Q))
  refine Qle_trans (Qmul_den_pos hsd Nat.one_pos) ?_ (Qle_self_add (by decide))
  simp only [Qle, mul]; push_cast
  have hprod : (0 : Int) ≤ s.num * ((N : Int) + 1) * 1 :=
    Int.mul_nonneg (Int.mul_nonneg (Int.le_of_lt hsn) (by omega)) (by omega)
  omega

private theorem capWnumB {s : Q} (hsn : 0 < s.num) (_hsd : 0 < s.den) (N : Nat) :
    (0 : Int) ≤ (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))).num := by
  have e : (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))).num
      = (s.den : Int) * (s.num * ((N : Int) + 1)) := by
    simp only [Qsub, mul, add, neg]; push_cast; ring_uor
  rw [e]
  exact Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg (Int.le_of_lt hsn) (by omega))

private theorem band01leB {s : Q} (hsn : 0 < s.num) : Qle (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast; omega

private theorem hlo_s0B (s : Q) : Qle (⟨0, 1⟩ : Q) (mul s (⟨0, 1⟩ : Q)) := by
  simp only [Qle, mul]; push_cast; omega

private theorem addstartW_eqB {s : Q} (N : Nat) :
    Qeq (add (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))))
        (mul s (⟨(N : Int) + 1, 1⟩ : Q)) := by
  simp only [Qeq, add, Qsub, mul, neg]; push_cast; ring_uor

private theorem affine_ge_baseB (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    {x : Real} (h0 : Rle zero x) : Rle (ofQ a ha) (affineMap a w ha hw x) :=
  Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ hw hwn) (Rnonneg_of_Rle_zero h0))

private theorem affine_le_topB (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    {x : Real} (h1 : Rle x one) :
    Rle (affineMap a w ha hw x) (ofQ (add a w) (add_den_pos ha hw)) := by
  have hwnn : Rnonneg (ofQ w hw) := Rnonneg_ofQ hw hwn
  have hxle : Rle (Rmul (ofQ w hw) x) (ofQ w hw) :=
    Rle_trans (Rmul_le_Rmul_left hwnn h1) (Rle_of_Req (Rmul_one (ofQ w hw)))
  exact Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _)) hxle)
    (Rle_of_Req (Radd_ofQ_ofQ ha hw))

/-- **Scale-invariance of the uniform partial sum under a `Qeq` rescaling.** Both `s`- and `s'`-uniform
    partial sums collapse (`uniform_partial_eq_cap`) to caps over `[0, s(N+1)]` and `[0, s'(N+1)]`, equal
    because `s ≈ s'`. The band weights are reconciled by `riemannIntegralI_congr_unit_mod` (both `uⁿ` on
    the shared window) and the equal cap value by `riemannIntegralI_congr_Q`. -/
private theorem uniform_scale_bridge (φ : L2Test) (n N : Nat) (s s' : Q)
    (hsn : 0 < s.num) (hsd : 0 < s.den) (hs'n : 0 < s'.num) (hs'd : 0 < s'.den)
    (heq : Qeq s s') :
    Req
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (genSum (fun m => scaledTwTerm φ s hsn hsd n m) N))
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s' (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hs'd (by decide)) (band01leB hs'n) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s' (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hs'd (by decide)) (band01leB hs'n) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s' (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hs'd (by decide)) (band01leB hs'n) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s' (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hs'd (by decide)) (band01leB hs'n) (by decide) n)).hfc
          (mul s' (⟨0, 1⟩ : Q)) (mul s' (⟨1, 1⟩ : Q))
          (Qmul_den_pos hs'd Nat.one_pos) (Qmul_den_pos hs'd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hs'n) (by decide)))
        (genSum (fun m => scaledTwTerm φ s' hs'n hs'd n m) N)) := by
  have startEq : Qeq (mul s (⟨0, 1⟩ : Q)) (mul s' (⟨0, 1⟩ : Q)) :=
    Qmul_congr heq (Qeq_refl _)
  have scaleNeq : Qeq (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s' (⟨(N : Int) + 1, 1⟩ : Q)) :=
    Qmul_congr heq (Qeq_refl _)
  have widthEq : Qeq
      (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
      (Qsub (mul s' (⟨(N : Int) + 1, 1⟩ : Q)) (mul s' (⟨0, 1⟩ : Q))) :=
    Qsub_congr scaleNeq startEq
  refine Req_trans
    (uniform_partial_eq_cap φ n N s hsn hsd)
    (Req_trans
      (Req_trans
        (riemannIntegralI_congr_unit_mod
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s N) (by decide)
            (capHiB_den hsd N) (capleB hsn hsd N) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s N) (by decide)
            (capHiB_den hsd N) (capleB hsn hsd N) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s N) (by decide)
            (capHiB_den hsd N) (capleB hsn hsd N) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s N) (by decide)
            (capHiB_den hsd N) (capleB hsn hsd N) (by decide) n)).hfc
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
          (Qmul_den_pos hsd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
          (capWnumB hsn hsd N)
          (by
            intro x h0 h1
            have hyb := affine_ge_baseB (mul s (⟨0, 1⟩ : Q))
              (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
              (Qmul_den_pos hsd Nat.one_pos)
              (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
              (capWnumB hsn hsd N) h0
            have hyt := affine_le_topB (mul s (⟨0, 1⟩ : Q))
              (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
              (Qmul_den_pos hsd Nat.one_pos)
              (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
              (capWnumB hsn hsd N) h1
            have hlo0 := Rle_trans
              (Rle_ofQ_ofQ (by decide) (Qmul_den_pos hsd Nat.one_pos) (hlo_s0B s)) hyb
            have hUpS : Qle
                (add (mul s (⟨0, 1⟩ : Q))
                  (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))))
                (capHiB s N) :=
              Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addstartW_eqB N))
                (Qle_self_add (by decide))
            have hUpR : Qle
                (add (mul s (⟨0, 1⟩ : Q))
                  (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q))))
                (capHiB s' N) :=
              Qle_trans (Qmul_den_pos hsd Nat.one_pos) (Qeq_le (addstartW_eqB N))
                (Qle_trans (Qmul_den_pos hs'd Nat.one_pos) (Qeq_le scaleNeq)
                  (Qle_self_add (by decide)))
            have hhiS := Rle_trans hyt
              (Rle_ofQ_ofQ
                (add_den_pos (Qmul_den_pos hsd Nat.one_pos)
                  (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)))
                (capHiB_den hsd N) hUpS)
            have hhiR := Rle_trans hyt
              (Rle_ofQ_ofQ
                (add_den_pos (Qmul_den_pos hsd Nat.one_pos)
                  (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)))
                (capHiB_den hs'd N) hUpR)
            have hpbS := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (capHiB s N) (by decide)
              (capHiB_den hsd N) (capleB hsn hsd N) (by decide) n hlo0 hhiS
            have hpbR := powBandGen_eq_Rpow_on (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
              (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n hlo0 hhiR
            exact Req_trans (Rmul_congr (Req_refl _) hpbS)
              (Req_symm (Rmul_congr (Req_refl _) hpbR))))
        (riemannIntegralI_congr_Q
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (capHiB s' N) (by decide)
            (capHiB_den hs'd N) (capleB hs'n hs'd N) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨0, 1⟩ : Q)))
          (mul s' (⟨0, 1⟩ : Q)) (Qsub (mul s' (⟨(N : Int) + 1, 1⟩ : Q)) (mul s' (⟨0, 1⟩ : Q)))
          (Qmul_den_pos hsd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
          (capWnumB hsn hsd N)
          (Qmul_den_pos hs'd Nat.one_pos)
          (Qsub_den_pos (Qmul_den_pos hs'd Nat.one_pos) (Qmul_den_pos hs'd Nat.one_pos))
          (capWnumB hs'n hs'd N)
          startEq widthEq))
      (Req_symm (uniform_partial_eq_cap φ n N s' hs'n hs'd)))

-- ===========================================================================
-- STEP 3 substrate — the trivial-scale (`s = 1`) specializations.
-- ===========================================================================

/-- `qpow ⟨1,1⟩ k` is rationally `1`. -/
private theorem qpow_one_qeq : ∀ k : Nat, Qeq (qpow (⟨1, 1⟩ : Q) k) (⟨1, 1⟩ : Q)
  | 0 => Qeq_refl _
  | (k + 1) => by
      show Qeq (mul (⟨1, 1⟩ : Q) (qpow (⟨1, 1⟩ : Q) k)) (⟨1, 1⟩ : Q)
      have ih := qpow_one_qeq k
      simp only [Qeq, mul] at ih ⊢
      push_cast at ih ⊢
      omega

/-- The `s = 1` scaled twisted window integral obeys the `C·2ⁿ/((m+1)m)` decay directly (the trivial
    scale factor `qpow 1 (n+1) ≈ 1` collapses, so `scaledTwTerm φ 1 ≈ twTerm (dilate_1 φ)`). This gives
    the regularity of the `1`-uniform scaled tail against the ORIGINAL modulus `C·2ⁿ` (schedule
    `digammaMidx (C·2ⁿ)`), matching `mellinHat_eq_uniform1`'s regular-witness slot. -/
private theorem scaledTwTerm_one_bound (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den)
    (hCn : 0 ≤ C.num)
    (hdec1 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))))
          (scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
      ∧ Rle (scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
          (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))) := by
  intro m hm
  have hq1 : Req (ofQ (qpow (⟨1, 1⟩ : Q) (n + 1)) (qpow_den_pos (by decide) (n + 1))) one :=
    Req_of_seq_Qeq (fun _ => qpow_one_qeq (n + 1))
  have heq : Req (scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
      (twTerm (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n m) :=
    Req_trans (scaledTwTerm_eq φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
      (Req_trans (Rmul_congr hq1 (Req_refl _))
        (Req_trans (Rmul_comm one _) (Rmul_one _)))
  obtain ⟨lo, hi⟩ := twTerm_bound (dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ) n hCd hCn
    hdec1 m hm
  exact ⟨Rle_trans lo (Rle_of_Req (Req_symm heq)), Rle_trans (Rle_of_Req heq) hi⟩

/-- The numerator of `qpow ⟨1,d⟩ k` is exactly `1`. -/
private theorem qpow_num_one (d : Nat) : ∀ k : Nat, (qpow (⟨1, d⟩ : Q) k).num = 1
  | 0 => rfl
  | (k + 1) => by
      show ((⟨1, d⟩ : Q).num * (qpow (⟨1, d⟩ : Q) k).num) = 1
      rw [qpow_num_one d k]; rfl

-- ===========================================================================
-- STEP 3 — the discharge of `htile`.
-- ===========================================================================

/-- **DISCHARGE of the tiling-independence hypothesis `htile`.** The `s`-uniform improper Mellin
    integral `∫_{[0,s]}(φ·powBandGen) + Rlim(scaled sums)` equals `mellinHat φ n`. Both sides refine to
    the common `1/q`-tiling (`q = s.den`): the `s`-side by `partial_s_eq_partial_refine` (at the
    `p`-schedule, `p = s.num`), and `mellinHat` — expressed as the `1`-uniform integral by
    `mellinHat_eq_uniform1` — by `uniform_scale_bridge` (scale `1 ≈ ⟨q,q⟩`) then `partial_coarse_refine`
    (at the `q`-schedule). The two resulting `1/q`-tail limits are equal by the rung-4b schedule
    independence `scaledTwTerm_schedule_eq` (both fast cofinal schedules of the same summand, over the
    common canonical `digammaMidx`). The extra decay hypothesis `hdec_fine` (the `1/q`-dilate window
    decay) is the routine boundedness datum the `1/q`-scaled tail's convergence needs — the same KIND of
    hypothesis as `hdec_phi`/`hdec_dil`, NOT a smuggle. -/
theorem htile_holds (φ : L2Test) (n : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_fine : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, s.den⟩ : Q) Int.zero_lt_one hsd φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01leB hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (Rlim (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
          (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) hReg))
      (mellinHat φ n hCd hCn hdec_phi) := by
  -- The `1`-dilate decay and the `1`-uniform regular witness, derived from `hdec_phi`.
  have hdec1 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) :=
    fun m x h0 h1 => Rle_trans (Rle_of_Req (Rabs_congr (dilateTest_one φ _))) (hdec_phi m x h0 h1)
  have hReg1 : RReg (fun j => genSum (fun m => scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) :=
    genSum_RReg (fun m => scaledTwTerm φ (⟨1, 1⟩ : Q) (by decide) (by decide) n m)
      (Qmul_den_pos hCd Nat.one_pos) (Int.mul_nonneg hCn (Int.ofNat_nonneg _))
      (scaledTwTerm_one_bound φ n hCd hCn hdec1)
  have huni := mellinHat_eq_uniform1 φ n hCd hCn hdec_phi hdec1 hReg1
  -- The `p`- and `q`-schedules of the common `1/q`-tiling.
  have hrefS := fun j => partial_s_eq_partial_refine φ n
    (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j) s hsn hsd
  have hrefO := fun j => Req_trans
    (uniform_scale_bridge φ n (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)
      (⟨1, 1⟩ : Q) (mul (⟨1, s.den⟩ : Q) (⟨(s.den : Int), 1⟩ : Q)) (by decide) (by decide)
      (by show (0 : Int) < 1 * (s.den : Int)
          have h : (0 : Int) < (s.den : Int) := by exact_mod_cast hsd
          omega)
      (Qmul_den_pos hsd Nat.one_pos)
      (by simp only [Qeq, mul]; push_cast; ring_uor))
    (partial_coarse_refine φ n (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)
      (⟨1, s.den⟩ : Q) Int.zero_lt_one hsd s.den hsd)
  -- Regular witnesses for the refined (Radd A_fine (genSum …)) families, and the peeled genSums.
  have hRegQ1 := RReg_congr (fun j => Req_symm (hrefS j)) (RReg_add_const _ _ hReg)
  have hRegG1 := RReg_of_add_const_left _ _ hRegQ1
  have hRegQ2 := RReg_congr (fun j => Req_symm (hrefO j)) (RReg_add_const _ _ hReg1)
  have hRegG2 := RReg_of_add_const_left _ _ hRegQ2
  -- The two fast schedules dominate the common canonical `digammaMidx`.
  have hnum : (mul (qpow (⟨1, s.den⟩ : Q) (n + 1)) (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))).num
      = (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num := by
    show (qpow (⟨1, s.den⟩ : Q) (n + 1)).num * (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num = _
    rw [qpow_num_one s.den (n + 1), Int.one_mul]
  have hmid : ∀ j, digammaMidx (mul (qpow (⟨1, s.den⟩ : Q) (n + 1))
        (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))) j
      = digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j :=
    fun j => by simp only [digammaMidx, hnum]
  have hgrow1 : ∀ j, digammaMidx (mul (qpow (⟨1, s.den⟩ : Q) (n + 1))
        (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))) j
      ≤ s.num.toNat * (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1) - 1 := by
    intro j
    rw [hmid j]
    have hp1 : 0 < s.num.toNat := by omega
    have hle : digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1
        ≤ s.num.toNat * (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1) :=
      Nat.le_mul_of_pos_left _ hp1
    omega
  have hgrow2 : ∀ j, digammaMidx (mul (qpow (⟨1, s.den⟩ : Q) (n + 1))
        (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))) j
      ≤ s.den * (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1) - 1 := by
    intro j
    rw [hmid j]
    have hle : digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1
        ≤ s.den * (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1) :=
      Nat.le_mul_of_pos_left _ hsd
    omega
  -- The two fast cofinal `1/q`-tail limits coincide (rung 4b, common summand & canonical).
  have III := Req_trans
    (scaledTwTerm_schedule_eq φ (⟨1, s.den⟩ : Q) Int.zero_lt_one hsd n hCd hCn hdec_fine
      (fun j => s.num.toNat * (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1) - 1)
      hgrow1 hRegG1)
    (Req_symm (scaledTwTerm_schedule_eq φ (⟨1, s.den⟩ : Q) Int.zero_lt_one hsd n hCd hCn hdec_fine
      (fun j => s.den * (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j + 1) - 1)
      hgrow2 hRegG2))
  -- Assemble: htile LHS ≈ Radd A_fine (Rlim G1) ≈ Radd A_fine (Rlim G2) ≈ mellinHat.
  refine Req_trans
    (Req_trans (Req_symm (Rlim_add_const _ _ hReg (RReg_add_const _ _ hReg)))
      (Req_trans (Rlim_congr _ _ (RReg_add_const _ _ hReg) hRegQ1 hrefS)
        (Rlim_add_const _ _ hRegG1 hRegQ1)))
    (Req_trans (Radd_congr (Req_refl _) III)
      (Req_symm (Req_trans huni
        (Req_trans (Req_symm (Rlim_add_const _ _ hReg1 (RReg_add_const _ _ hReg1)))
          (Req_trans (Rlim_congr _ _ (RReg_add_const _ _ hReg1) hRegQ2 hrefO)
            (Rlim_add_const _ _ hRegG2 hRegQ2))))))

/-- **THE HALF-LINE MELLIN DILATION COVARIANCE, UNCONDITIONAL.** The committed
    `mellinHat_dilate_covariance` with its tiling-independence hypothesis `htile` discharged by
    `htile_holds`:

      `s^(n+1) · mellinHat (dilate_s φ) n  =  mellinHat φ n`,

    carrying only the routine decay data (`hdec_dil` for `dilate_s φ`, `hdec_phi` for `φ`, `hdec_fine`
    for `dilate_{1/q} φ`) and the regular witness `hReg`. No `htile`. It builds NO factorization, NO
    positivity, NO determinacy, NO crux; step 4 (band-coupling positivity) is RH. -/
theorem mellinHat_dilate_covariance_uncond (φ : L2Test) (n : Nat) (s : Q)
    (hsn : 0 < s.num) (hsd : 0 < s.den) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_dil : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest s hsn hsd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_fine : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, s.den⟩ : Q) Int.zero_lt_one hsd φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (mellinHat (dilateTest s hsn hsd φ) n hCd hCn hdec_dil))
      (mellinHat φ n hCd hCn hdec_phi) :=
  mellinHat_dilate_covariance φ n s hsn hsd hCd hCn hdec_dil hdec_phi hReg
    (htile_holds φ n s hsn hsd hCd hCn hdec_phi hdec_fine hReg)

end Multiplicity.UOR.Bridge.F1Square.Square
