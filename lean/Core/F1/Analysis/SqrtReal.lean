/-
F1 square — constructive **square root** of a non-negative rational, assembly (2/2): the Bishop limit
`Rsqrt q` of the bisection lower endpoints, via the UOR term-bound → `RReg` → `Rlim` pattern.

The increments `Δ_k = lo_{k+1} − lo_k` are non-negative and bounded by half the bracket width,
`Δ_k ≤ (q+1)/2^{k+1}`, which sits under the digamma envelope `K/((k+1)k)` with `K = 2(q+1)` (since
`(k+1)k ≤ 4·2^k`, `two_mul_env`). So `genSum_RReg` makes the partial sums regular and `Rsqrt q` is
their limit.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.SqrtRat

namespace UOR.Bridge.F1Square.Analysis

/-- The lower endpoints increase: `lo_m ≤ lo_{m+1}`. -/
theorem sqLo_mono (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (m : Nat) :
    Qle (sqLo q m) (sqLo q (m + 1)) := by
  obtain ⟨_, _, hle, _⟩ := sqrtBisect_inv q hqd hq m
  obtain ⟨hl, _⟩ := sqrtBisect_den_pos q hqd m
  simp only [sqLo, sqHi, sqrtBisect]
  split
  · exact Qavg_ge_left hl hle
  · exact Qle_refl _

/-- The increment is at most half the bracket width: `lo_{m+1} − lo_m ≤ (hi_m − lo_m)/2`. -/
theorem sqLo_incr_le (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (m : Nat) :
    Qle (Qsub (sqLo q (m + 1)) (sqLo q m)) (mul (Qsub (sqHi q m) (sqLo q m)) (⟨1, 2⟩ : Q)) := by
  obtain ⟨_, _, hle, _⟩ := sqrtBisect_inv q hqd hq m
  obtain ⟨hl, hh⟩ := sqrtBisect_den_pos q hqd m
  have hw0 : Qle (⟨0, 1⟩ : Q) (mul (Qsub (sqHi q m) (sqLo q m)) (⟨1, 2⟩ : Q)) := by
    refine Qle_trans (by decide : 0 < (mul (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)).den)
      (by decide : Qle (⟨0, 1⟩ : Q) (mul (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q))) ?_
    exact Qmul_le_mul_right (by decide) (Qsub_nonneg_of_le hle)
  simp only [sqLo, sqHi, sqrtBisect]
  split
  · exact Qeq_le (by simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor)
  · refine Qle_trans (by decide : 0 < (⟨0, 1⟩ : Q).den)
      (Qeq_le (by simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor :
        Qeq (Qsub (sqLo q m) (sqLo q m)) (⟨0, 1⟩ : Q))) hw0

/-- The increment term `Δ_k = lo_{k+1} − lo_k` as a non-negative real. -/
def sqrtTerm (q : Q) (hqd : 0 < q.den) (k : Nat) : Real :=
  ofQ (Qsub (sqLo q (k + 1)) (sqLo q k))
    (Qsub_den_pos (sqrtBisect_den_pos q hqd (k + 1)).1 (sqrtBisect_den_pos q hqd k).1)

/-- The scaling constant `K = 2(q+1)` for the digamma envelope. -/
def sqrtK (q : Q) : Q := mul (add q (⟨1, 1⟩ : Q)) (⟨2, 1⟩ : Q)

theorem sqrtK_den_pos (q : Q) (hqd : 0 < q.den) : 0 < (sqrtK q).den :=
  Qmul_den_pos (add_den_pos hqd (by decide)) (by decide)

theorem sqrtK_num_nonneg (q : Q) (hq : Qle (⟨0, 1⟩ : Q) q) : 0 ≤ (sqrtK q).num := by
  have hqn : 0 ≤ q.num := by have := hq; simp only [Qle] at this; simpa using this
  simp only [sqrtK, mul, add]; push_cast; omega

/-- `(q+1)·2^{-(m+1)} ≤ 2(q+1)·((m+1)m)^{-1}` — the geometric increment sits under the digamma
    envelope (`(m+1)m ≤ 4·2^m`). The bracket form `(q+1)·2^{-m}·2^{-1}` is what `width·½` produces. -/
theorem sqrt_env_le (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (m : Nat) (hm : 1 ≤ m) :
    Qle (mul (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q)) (⟨1, 2⟩ : Q))
        (mul (sqrtK q) (⟨1, (m + 1) * m⟩ : Q)) := by
  have hqn : 0 ≤ q.num := by have := hq; simp only [Qle] at this; simpa using this
  have hrn : 0 ≤ (add q (⟨1, 1⟩ : Q)).num := by simp only [add]; push_cast; omega
  have hL : Qeq (mul (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 2 ^ m⟩ : Q)) (⟨1, 2⟩ : Q))
                (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 2 ^ (m + 1)⟩ : Q)) := by
    rw [Nat.pow_succ]; simp only [Qeq, mul]; push_cast; ring_uor
  have hR : Qeq (mul (sqrtK q) (⟨1, (m + 1) * m⟩ : Q))
                (mul (add q (⟨1, 1⟩ : Q)) (⟨2, (m + 1) * m⟩ : Q)) := by
    simp only [Qeq, sqrtK, mul]; push_cast; ring_uor
  have hcmp : Qle (⟨1, 2 ^ (m + 1)⟩ : Q) (⟨2, (m + 1) * m⟩ : Q) := by
    have henv : (m + 1) * m ≤ 4 * 2 ^ m := two_mul_env m
    have hp : (2 : Nat) ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
    simp only [Qle]
    rw [hp]; omega
  refine Qle_trans (Qmul_den_pos (add_den_pos hqd (by decide)) Nat.one_le_two_pow) (Qeq_le hL) ?_
  refine Qle_trans (Qmul_den_pos (add_den_pos hqd (by decide)) (digamma_succ_mul_pos hm))
    (Qmul_le_mul_left hrn hcmp) (Qeq_le (Qeq_symm hR))

/-- **The increment two-sided bound** `|Δ_m| ≤ K/((m+1)m)` (`m ≥ 1`) — the `genSum_RReg` input. -/
theorem sqrtTerm_bound (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (m : Nat) (hm : 1 ≤ m) :
    Rle (Rneg (ofQ (mul (sqrtK q) (⟨1, (m + 1) * m⟩ : Q))
              (Qmul_den_pos (sqrtK_den_pos q hqd) (digamma_succ_mul_pos hm)))) (sqrtTerm q hqd m)
    ∧ Rle (sqrtTerm q hqd m)
          (ofQ (mul (sqrtK q) (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos (sqrtK_den_pos q hqd) (digamma_succ_mul_pos hm))) := by
  have hbpos : Rnonneg (ofQ (mul (sqrtK q) (⟨1, (m + 1) * m⟩ : Q))
      (Qmul_den_pos (sqrtK_den_pos q hqd) (digamma_succ_mul_pos hm))) :=
    Rnonneg_ofQ _ (by
      have := sqrtK_num_nonneg q hq
      simp only [mul]; exact Int.mul_nonneg (by simpa using this) (by decide))
  have htpos : Rnonneg (sqrtTerm q hqd m) :=
    Rnonneg_ofQ _ (by
      have h := Qsub_nonneg_of_le (sqLo_mono q hqd hq m); simp only [Qle] at h; omega)
  refine ⟨?_, ?_⟩
  · exact Rle_trans (Rle_of_Req (Req_symm (Rneg_ofQ _ _)))
      (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg hbpos)) (Rle_zero_of_Rnonneg htpos))
  · refine Rle_ofQ_ofQ _ _ ?_
    refine Qle_trans (Qmul_den_pos (Qsub_den_pos (sqrtBisect_den_pos q hqd m).2
        (sqrtBisect_den_pos q hqd m).1) (by decide)) (sqLo_incr_le q hqd hq m) ?_
    refine Qle_trans (Qmul_den_pos (Qmul_den_pos (add_den_pos hqd (by decide))
        Nat.one_le_two_pow) (by decide))
      (Qeq_le (Qmul_congr (sqrtBisect_width q hqd m) (Qeq_refl _))) (sqrt_env_le q hqd hq m hm)

/-- **The constructive square root of a non-negative rational** — the Bishop limit of the bisection
    lower endpoints (regular by `genSum_RReg`). `(Rsqrt q)² = q` is proved in `SqrtRealSq.lean`. -/
def Rsqrt (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) : Real :=
  Rlim (fun j => genSum (sqrtTerm q hqd) (digammaMidx (sqrtK q) j))
    (genSum_RReg (sqrtTerm q hqd) (sqrtK_den_pos q hqd) (sqrtK_num_nonneg q hq)
      (fun m hm => sqrtTerm_bound q hqd hq m hm))

end UOR.Bridge.F1Square.Analysis
