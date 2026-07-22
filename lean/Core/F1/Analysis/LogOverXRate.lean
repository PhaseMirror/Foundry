/-
F1 square — **the `∫ log/x` layer, part 8b-i: the rate ingredients**
(`LogOverXRate.lean`). The four inputs the `gLx` rate consumes:

  - the schedule arithmetic `5(j+1) ≤ m ⟹ (5m+5)(j+1) ≤ 2^m` (the `m/2^m` slack
    fits the `digammaMidx` schedule);
  - the per-cell log-sum cap at `M = 2^m`: cells of the fold at base `A = c·2^m` are
    `≤ 2m + 4` (`logN_mono` into `(c+1)·2^m`, split by `logN_mul_gen`, bounded by
    `log(c+1) ≤ 2` and `log(2^m) ≤ m`);
  - the capped sample bracket `hsSample ≤ ΔHn + gapQE` (the part-4b upper redone with
    the log-aware gap);
  - the rational collapse `gapQE ≤ E·c/A²` (cells dominated at the common
    denominator).

HONEST SCOPE. Bounds between constructed objects; no integral is evaluated and no
positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogOverXSum

namespace UOR.Bridge.F1Square.Analysis

/-- `m(m+1) ≤ 2^m` for `m ≥ 5`. -/
private theorem lxr_msq : ∀ m, 5 ≤ m → m * (m + 1) ≤ 2 ^ m
  | 0, h => by omega
  | 1, h => by omega
  | 2, h => by omega
  | 3, h => by omega
  | 4, h => by omega
  | 5, _ => by decide
  | (m + 6), _ => by
    have ih : (m + 5) * (m + 6) ≤ 2 ^ (m + 5) := lxr_msq (m + 5) (by omega)
    have hpow : 2 ^ (m + 6) = 2 * 2 ^ (m + 5) := by rw [Nat.pow_succ]; omega
    have hkey : (m + 6) * (m + 6 + 1) = (m + 5) * (m + 6) + 2 * (m + 6) := by
      rw [Nat.mul_comm (m + 6) (m + 6 + 1)]
      exact Nat.add_mul (m + 5) 2 (m + 6)
    have h2 : 2 * (m + 6) ≤ (m + 5) * (m + 6) :=
      Nat.mul_le_mul_right (m + 6) (by omega)
    omega

/-- **The schedule arithmetic**: `5(j+1) ≤ m ⟹ (5m+5)(j+1) ≤ 2^m`. -/
theorem lxr_sched (m j : Nat) (h : 5 * (j + 1) ≤ m) : (5 * m + 5) * (j + 1) ≤ 2 ^ m := by
  have h5 : 5 ≤ m := by omega
  have e1 : 5 * m + 5 = 5 * (m + 1) := by omega
  have h1 : (5 * m + 5) * (j + 1) = (m + 1) * (5 * (j + 1)) := by
    rw [e1, Nat.mul_assoc, Nat.mul_left_comm]
  have h2 : (m + 1) * (5 * (j + 1)) ≤ (m + 1) * m := Nat.mul_le_mul_left (m + 1) h
  have h3 : (m + 1) * m = m * (m + 1) := Nat.mul_comm _ _
  have h4 := lxr_msq m h5
  omega

/-- `log(c+1) ≤ 2` for `c ≤ 3` (`log 4 = 2·log 2 ≤ 2`). -/
theorem logN_succ_le_two (c : Nat) (hc3 : c ≤ 3) :
    Rle (logN (c + 1) (by omega)) (ofQ (⟨2, 1⟩ : Q) Nat.one_pos) := by
  refine Rle_trans (logN_mono (by omega) (show c + 1 ≤ 2 * 2 by omega)) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (logN_mul_gen 2 2 (by omega) (by omega)))) ?_
  refine Rle_trans (Radd_le_add logN_two_le_one logN_two_le_one) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
    (ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos (by decide)))

/-- **The per-cell log-sum cap** at `M = 2^m`, base `A = c·2^m`: every fold cell's
    log sum is at most `2m + 4`. -/
theorem lxr_cap (c m : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    ∀ j, j < 2 ^ m →
    Rle (Radd (logN (c * 2 ^ m + j + 1) (by omega))
        (logN (c * 2 ^ m + j) (show 1 ≤ c * 2 ^ m + j from by
          have := Nat.mul_pos hc1 (show 0 < 2 ^ m from Nat.one_le_two_pow); omega)))
      (ofQ (⟨((2 * m + 4 : Nat) : Int), 1⟩ : Q) Nat.one_pos) := by
  intro j hj
  have hp : (1 : Nat) ≤ 2 ^ m := Nat.one_le_two_pow
  have hcM : 1 ≤ c * 2 ^ m := Nat.mul_pos hc1 hp
  have htop : c * 2 ^ m + j + 1 ≤ (c + 1) * 2 ^ m := by
    have h : (c + 1) * 2 ^ m = c * 2 ^ m + 2 ^ m := Nat.succ_mul c (2 ^ m)
    omega
  have hone : Rle (logN (c * 2 ^ m + j + 1) (by omega))
      (ofQ (⟨((m + 2 : Nat) : Int), 1⟩ : Q) Nat.one_pos) := by
    refine Rle_trans (logN_mono (by omega) htop) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (logN_mul_gen (c + 1) (2 ^ m)
      (by omega) hp))) ?_
    refine Rle_trans (Radd_le_add (logN_succ_le_two c hc3) (logN_two_pow_le m)) ?_
    refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
      (ofQ_congr (b := (⟨((m + 2 : Nat) : Int), 1⟩ : Q))
        (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_))
    show Qeq (add (⟨2, 1⟩ : Q) (⟨(m : Int), 1⟩ : Q)) (⟨((m + 2 : Nat) : Int), 1⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor
  have htwo : Rle (logN (c * 2 ^ m + j) (show 1 ≤ c * 2 ^ m + j from by
      have := Nat.mul_pos hc1 (show 0 < 2 ^ m from Nat.one_le_two_pow); omega))
      (ofQ (⟨((m + 2 : Nat) : Int), 1⟩ : Q) Nat.one_pos) :=
    Rle_trans (logN_mono (by omega) (Nat.le_succ _)) hone
  refine Rle_trans (Radd_le_add hone htwo) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
    (ofQ_congr (b := (⟨((2 * m + 4 : Nat) : Int), 1⟩ : Q))
      (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_))
  show Qeq (add (⟨((m + 2 : Nat) : Int), 1⟩ : Q) (⟨((m + 2 : Nat) : Int), 1⟩ : Q))
    (⟨((2 * m + 4 : Nat) : Int), 1⟩ : Q)
  simp only [Qeq, add]; push_cast; ring_uor

/-- **The capped sample bracket, upper side**: `hsSample ≤ ΔHn + gapQE` under the
    per-cell cap. -/
theorem Hn_sample_upper_cap (A M E : Nat) (hA : 1 ≤ A)
    (hcap : ∀ j, j < M →
      Rle (Radd (logN (A + j + 1) (by omega)) (logN (A + j) (by omega)))
        (ofQ (⟨(E : Int), 1⟩ : Q) Nat.one_pos)) :
    Rle (hsSample A hA M)
      (Radd (Rsub (Hn (A + M) (by omega)) (Hn A hA))
        (ofQ (gapQE A E M) (gapQE_den_pos A E hA M))) :=
  Rle_trans (hsSample_le_foldHi A hA M)
    (Rle_trans (hsFold_gap_cap A E hA M hcap)
      (Radd_le_add
        (Rle_Rsub_of_Radd_le (Rle_trans
          (Rle_of_Req (Radd_comm (hsFoldLo A hA M) (Hn A hA)))
          (Hn_tele_lower A hA M)))
        (Rle_refl _)))

/-- **The rational gap collapse**: `gapQE A E c ≤ E·c/A²` (cells dominated at the
    common denominator `A²`). -/
theorem gapQE_le (A E : Nat) (hA : 1 ≤ A) : ∀ c,
    Qle (gapQE A E c) (⟨((E * c : Nat) : Int), A * A⟩ : Q)
  | 0 => by
    show (0 : Int) * ((A * A : Nat) : Int) ≤ ((E * 0 : Nat) : Int) * 1
    push_cast; omega
  | (c + 1) => by
    have hden : 0 < (A + c) * (A + c + 1) :=
      Nat.mul_pos (show 0 < A + c by omega) (Nat.succ_pos (A + c))
    have hcell : Qle (⟨(E : Int), (A + c) * (A + c + 1)⟩ : Q) (⟨(E : Int), A * A⟩ : Q) := by
      show (E : Int) * ((A * A : Nat) : Int) ≤ (E : Int) * (((A + c) * (A + c + 1) : Nat) : Int)
      have hNat : A * A ≤ (A + c) * (A + c + 1) :=
        Nat.mul_le_mul (Nat.le_add_right A c) (by omega)
      have hInt : ((A * A : Nat) : Int) ≤ (((A + c) * (A + c + 1) : Nat) : Int) :=
        Int.ofNat_le.mpr hNat
      exact Int.mul_le_mul_of_nonneg_left hInt (Int.ofNat_nonneg E)
    have hmid : 0 < (add (⟨((E * c : Nat) : Int), A * A⟩ : Q) (⟨(E : Int), A * A⟩ : Q)).den :=
      add_den_pos (Nat.mul_pos hA hA) (Nat.mul_pos hA hA)
    refine Qle_trans hmid
      (Qadd_le_add (gapQE_le A E hA c) hcell) (Qeq_le ?_)
    show Qeq (add (⟨((E * c : Nat) : Int), A * A⟩ : Q) (⟨(E : Int), A * A⟩ : Q))
      (⟨((E * (c + 1) : Nat) : Int), A * A⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

end UOR.Bridge.F1Square.Analysis
