/-
F1 square — `cos` and `sin` on ℝ (v0.13.0 transcendentals).

Both are exponential-type series in the base `−q²`:
  `cos(x) = Σₙ (−x²)ⁿ/(2n)!`,  `sin(x)/x = Σₙ (−x²)ⁿ/(2n+1)!`.
Writing the alternating sign into the base `−q²` avoids any parity case-split. Since `|−q²| ≤ M²` (for
`|q| ≤ M`) and `(2n+off)! ≥ n!`, each term is dominated by the term `(M²)ⁿ/n!` of the exp series at base
`M²` — so the truncation and Lipschitz bounds, and the whole diagonal construction, **reuse the `exp`
machinery** (`expM_diff_bound`, `qpow_diff_bound`, `trunc_reindex`) with base `M²`. (Research-confirmed:
absolute exp-domination beats the Leibniz remainder, which needs a monotonicity threshold.)

`Rcos x` and the auxiliary `RsinAux x = sin(x)/x` are the diagonals; `Rsin x = x · RsinAux x`.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.ExpReal

namespace UOR.Bridge.F1Square.Analysis

/-- `|−a| = |a|`. -/
theorem Qabs_neg (a : Q) : Qabs (neg a) = Qabs a := by
  unfold Qabs neg; simp [Int.natAbs_neg]

/-- The factorial is monotone. -/
theorem fct_mono {a b : Nat} (hab : a ≤ b) : fct a ≤ fct b := by
  induction hab with
  | refl => exact Nat.le_refl _
  | step _ ih => exact Nat.le_trans ih (Nat.le_mul_of_pos_left _ (Nat.succ_pos _))

/-- `|−q²| ≤ M²` when `|q| ≤ M`. -/
theorem qsq_abs_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) :
    Qle (Qabs (neg (mul q q))) ⟨(M * M : Nat), 1⟩ := by
  rw [Qabs_neg, Qabs_mul]
  have h : Qle (mul (Qabs q) (Qabs q)) (mul (⟨(M : Int), 1⟩ : Q) ⟨(M : Int), 1⟩) :=
    Qmul_le_mul (Qabs_den_pos hqd) Nat.one_pos (Qabs_den_pos hqd) (Qabs_num_nonneg q)
      (Qabs_num_nonneg q) hq hq
  refine Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos) h (Qeq_le ?_)
  show (M : Int) * (M : Int) * (1 : Int) = ((M * M : Nat) : Int) * (1 * 1)
  push_cast; ring_uor

/-- The `n`-th term of the `cos`/`sin` series: `(−q²)ⁿ/(2n+off)!`  (`off = 0` for cos, `1` for sin/x). -/
def altTerm (q : Q) (off n : Nat) : Q := mul (qpow (neg (mul q q)) n) ⟨1, fct (2 * n + off)⟩

theorem altTerm_den_pos {q : Q} (hqd : 0 < q.den) (off n : Nat) : 0 < (altTerm q off n).den :=
  Qmul_den_pos (qpow_den_pos (show 0 < (neg (mul q q)).den from Nat.mul_pos hqd hqd) n) (fct_pos _)

/-- The partial sum `Σ_{n=0}^N (−q²)ⁿ/(2n+off)!`. -/
def altSum (q : Q) (off : Nat) : Nat → Q
  | 0 => altTerm q off 0
  | (n + 1) => add (altSum q off n) (altTerm q off (n + 1))

theorem altSum_den_pos {q : Q} (hqd : 0 < q.den) (off : Nat) : ∀ N, 0 < (altSum q off N).den
  | 0 => altTerm_den_pos hqd off 0
  | (n + 1) => add_den_pos (altSum_den_pos hqd off n) (altTerm_den_pos hqd off (n + 1))

/-- **Per-term domination**: `|(−q²)ⁿ/(2n+off)!| ≤ (M²)ⁿ/n!` when `|q| ≤ M`. -/
theorem altTerm_abs_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off n : Nat) : Qle (Qabs (altTerm q off n)) ⟨(npow (M * M) n : Int), fct n⟩ := by
  have h1 : Qabs (altTerm q off n)
      = mul (Qabs (qpow (neg (mul q q)) n)) ⟨1, fct (2 * n + off)⟩ := by
    unfold altTerm; rw [Qabs_mul]; rfl
  rw [h1]
  have hpow : Qle (Qabs (qpow (neg (mul q q)) n)) ⟨(npow (M * M) n : Int), 1⟩ :=
    qpow_abs_le (Nat.mul_pos hqd hqd) (qsq_abs_le hqd hq) n
  have hstep : Qle (mul (Qabs (qpow (neg (mul q q)) n)) ⟨1, fct (2 * n + off)⟩)
      (mul (⟨(npow (M * M) n : Int), 1⟩ : Q) ⟨1, fct (2 * n + off)⟩) :=
    Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide) hpow
  have hlast : Qle (mul (⟨(npow (M * M) n : Int), 1⟩ : Q) ⟨1, fct (2 * n + off)⟩)
      ⟨(npow (M * M) n : Int), fct n⟩ := by
    show ((npow (M * M) n : Int) * 1) * ((fct n : Nat) : Int)
        ≤ (npow (M * M) n : Int) * ((1 * fct (2 * n + off) : Nat) : Int)
    have hf : ((fct n : Nat) : Int) ≤ ((1 * fct (2 * n + off) : Nat) : Int) := by
      have := fct_mono (show n ≤ 2 * n + off by omega); push_cast; omega
    rw [Int.mul_one]
    exact Int.mul_le_mul_of_nonneg_left hf (Int.ofNat_nonneg _)
  exact Qle_trans (Qmul_den_pos Nat.one_pos (fct_pos _)) hstep hlast

/-- **Truncation domination** for the alternating series: `|altSum gap| ≤ S_{M²}(b) − S_{M²}(a)`. -/
theorem altSum_abs_diff_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off : Nat) {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (altSum q off b) (altSum q off a)))
      (Qsub (expSumM (M * M) b) (expSumM (M * M) a)) := by
  induction hab with
  | refl =>
      have h := Qsub_self_num (altSum q off a)
      have h' := Qsub_self_num (expSumM (M * M) a)
      unfold Qle Qabs
      rw [h, h']; simp
  | @step k _ ih =>
      have hstep : Qle (Qabs (Qsub (altSum q off (k + 1)) (altSum q off a)))
          (add (Qabs (Qsub (altSum q off k) (altSum q off a))) (Qabs (altTerm q off (k + 1)))) := by
        have heqabs := Qabs_Qeq (Qsub_add_right (altSum q off k) (altTerm q off (k + 1))
          (altSum q off a))
        refine Qle_congr_left
          (Qabs_den_pos (add_den_pos (Qsub_den_pos (altSum_den_pos hqd off k)
            (altSum_den_pos hqd off a)) (altTerm_den_pos hqd off (k + 1)))) (Qeq_symm heqabs)
          (Qabs_add_le _ _)
      have hbound : Qle (add (Qabs (Qsub (altSum q off k) (altSum q off a))) (Qabs (altTerm q off (k + 1))))
          (add (Qsub (expSumM (M * M) k) (expSumM (M * M) a))
            ⟨(npow (M * M) (k + 1) : Int), fct (k + 1)⟩) :=
        Qadd_le_add ih (altTerm_abs_le hqd hq off (k + 1))
      have hregroupM : Qeq (add (Qsub (expSumM (M * M) k) (expSumM (M * M) a))
            ⟨(npow (M * M) (k + 1) : Int), fct (k + 1)⟩)
          (Qsub (expSumM (M * M) (k + 1)) (expSumM (M * M) a)) :=
        Qeq_symm (Qsub_add_right (expSumM (M * M) k) ⟨(npow (M * M) (k + 1) : Int), fct (k + 1)⟩
          (expSumM (M * M) a))
      refine Qle_trans
        (add_den_pos (Qabs_den_pos (Qsub_den_pos (altSum_den_pos hqd off k) (altSum_den_pos hqd off a)))
          (Qabs_den_pos (altTerm_den_pos hqd off (k + 1))))
        hstep
        (Qle_trans
          (add_den_pos (Qsub_den_pos (expSumM_den_pos (M * M) k) (expSumM_den_pos (M * M) a))
            (fct_pos _))
          hbound (Qeq_le hregroupM))

/-- **The truncation tail bound** for `cos`/`sin`: for `|q| ≤ M` and `2M² ≤ a ≤ b`,
    `|altSum_q(b) − altSum_q(a)| ≤ 2(M²)ᵃ⁺¹/(a+1)!`. -/
theorem altSum_trunc_bound {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off : Nat) {a b : Nat} (ha2 : 2 * (M * M) ≤ a + 2) (hab : a ≤ b) :
    Qle (Qabs (Qsub (altSum q off b) (altSum q off a)))
      ⟨(2 * npow (M * M) (a + 1) : Int), fct (a + 1)⟩ :=
  Qle_trans (Qsub_den_pos (expSumM_den_pos (M * M) b) (expSumM_den_pos (M * M) a))
    (altSum_abs_diff_le hqd hq off hab) (expM_diff_bound (M * M) ha2 hab)

/-- **Per-term Lipschitz bound** for the alternating series, in the base `−q²`. -/
theorem altTerm_diff_bound {q q' : Q} {M : Nat} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) (off n : Nat) :
    Qle (Qabs (Qsub (altTerm q off n) (altTerm q' off n)))
      (mul ⟨(Pbound (M * M) n : Int), fct n⟩
        (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))) := by
  have hnqd : 0 < (neg (mul q q)).den := Nat.mul_pos hqd hqd
  have hnq'd : 0 < (neg (mul q' q')).den := Nat.mul_pos hq'd hq'd
  have hfac : Qeq (Qsub (altTerm q off n) (altTerm q' off n))
      (mul (Qsub (qpow (neg (mul q q)) n) (qpow (neg (mul q' q')) n)) ⟨1, fct (2 * n + off)⟩) := by
    show Qeq (Qsub (mul (qpow (neg (mul q q)) n) ⟨1, fct (2 * n + off)⟩)
        (mul (qpow (neg (mul q' q')) n) ⟨1, fct (2 * n + off)⟩))
      (mul (Qsub (qpow (neg (mul q q)) n) (qpow (neg (mul q' q')) n)) ⟨1, fct (2 * n + off)⟩)
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  have heq1 : Qeq (Qabs (Qsub (altTerm q off n) (altTerm q' off n)))
      (mul (Qabs (Qsub (qpow (neg (mul q q)) n) (qpow (neg (mul q' q')) n))) ⟨1, fct (2 * n + off)⟩) := by
    have h := Qabs_Qeq hfac
    rw [Qabs_mul, show Qabs (⟨1, fct (2 * n + off)⟩ : Q) = ⟨1, fct (2 * n + off)⟩ from rfl] at h
    exact h
  have hb1 : Qle (mul (Qabs (Qsub (qpow (neg (mul q q)) n) (qpow (neg (mul q' q')) n))) ⟨1, fct (2 * n + off)⟩)
      (mul (mul ⟨(Pbound (M * M) n : Int), 1⟩ (Qabs (Qsub (neg (mul q q)) (neg (mul q' q')))))
        ⟨1, fct (2 * n + off)⟩) :=
    Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide)
      (qpow_diff_bound hnqd hnq'd (qsq_abs_le hqd hq) (qsq_abs_le hq'd hq') n)
  have heq2 : Qeq (mul (mul ⟨(Pbound (M * M) n : Int), 1⟩ (Qabs (Qsub (neg (mul q q)) (neg (mul q' q')))))
        ⟨1, fct (2 * n + off)⟩)
      (mul ⟨(Pbound (M * M) n : Int), fct (2 * n + off)⟩
        (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hlast : Qle (mul ⟨(Pbound (M * M) n : Int), fct (2 * n + off)⟩
        (Qabs (Qsub (neg (mul q q)) (neg (mul q' q')))))
      (mul ⟨(Pbound (M * M) n : Int), fct n⟩ (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))) :=
    Qmul_le_mul_right (Qabs_num_nonneg _) (by
      show (Pbound (M * M) n : Int) * ((fct n : Nat) : Int)
          ≤ (Pbound (M * M) n : Int) * ((fct (2 * n + off) : Nat) : Int)
      exact Int.mul_le_mul_of_nonneg_left
        (by have := fct_mono (show n ≤ 2 * n + off by omega); exact_mod_cast this)
        (Int.ofNat_nonneg _))
  exact Qle_trans
    (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (qpow_den_pos hnqd n) (qpow_den_pos hnq'd n))) (fct_pos _))
    (Qeq_le heq1)
    (Qle_trans (Qmul_den_pos (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hnqd hnq'd)))
      (fct_pos _)) hb1
      (Qle_trans (Qmul_den_pos (fct_pos _) (Qabs_den_pos (Qsub_den_pos hnqd hnq'd)))
        (Qeq_le heq2) hlast))

/-- **The Lipschitz sum bound** for the alternating series. -/
theorem altSum_Lip_le {q q' : Q} {M : Nat} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) (off : Nat) :
    ∀ N, Qle (Qabs (Qsub (altSum q off N) (altSum q' off N)))
      (mul (LipS (M * M) N) (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))) := by
  have hnqd : 0 < (neg (mul q q)).den := Nat.mul_pos hqd hqd
  have hnq'd : 0 < (neg (mul q' q')).den := Nat.mul_pos hq'd hq'd
  intro N
  induction N with
  | zero =>
      have halt0 : altSum q off 0 = altSum q' off 0 := rfl
      have h0 : (Qsub (altSum q off 0) (altSum q' off 0)).num = 0 := by
        rw [halt0]; exact Qsub_self_num _
      unfold Qle Qabs
      rw [h0]; simp [LipS, Pbound, mul]
  | succ N ih =>
      have hAd : 0 < (altSum q off N).den := altSum_den_pos hqd off N
      have hCd : 0 < (altSum q' off N).den := altSum_den_pos hq'd off N
      have hBd : 0 < (altTerm q off (N + 1)).den := altTerm_den_pos hqd off (N + 1)
      have hDd : 0 < (altTerm q' off (N + 1)).den := altTerm_den_pos hq'd off (N + 1)
      refine Qle_trans
        (add_den_pos (Qabs_den_pos (Qsub_den_pos hAd hCd)) (Qabs_den_pos (Qsub_den_pos hBd hDd)))
        (Qabs_sub_add4 hAd hBd hCd hDd)
        (Qle_trans
          (add_den_pos (Qmul_den_pos (LipS_den_pos (M * M) N) (Qabs_den_pos (Qsub_den_pos hnqd hnq'd)))
            (Qmul_den_pos (fct_pos (N + 1)) (Qabs_den_pos (Qsub_den_pos hnqd hnq'd))))
          (Qadd_le_add ih (altTerm_diff_bound hqd hq'd hq hq' off (N + 1)))
          (Qeq_le (Qeq_symm (Qmul_add_right (LipS (M * M) N)
            ⟨(Pbound (M * M) (N + 1) : Int), fct (N + 1)⟩
            (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))))))

/-- **The base-difference bridge**: `|−q² − (−q'²)| ≤ 2M·|q − q'|` when `|q|,|q'| ≤ M`
    (since `−q² + q'² = (q'−q)(q'+q)` and `|q'+q| ≤ 2M`). -/
theorem qsq_diff_le {q q' : Q} {M : Nat} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) :
    Qle (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))
      (mul ⟨(2 * M : Nat), 1⟩ (Qabs (Qsub q q'))) := by
  have hfac : Qeq (Qsub (neg (mul q q)) (neg (mul q' q'))) (mul (Qsub q' q) (add q' q)) := by
    simp only [Qeq, Qsub, neg, mul, add]; push_cast; ring_uor
  have heq1 : Qeq (Qabs (Qsub (neg (mul q q)) (neg (mul q' q'))))
      (mul (Qabs (Qsub q' q)) (Qabs (add q' q))) := by
    have h := Qabs_Qeq hfac; rw [Qabs_mul] at h; exact h
  have hsum : Qle (Qabs (add q' q)) ⟨(2 * M : Nat), 1⟩ := by
    refine Qle_trans (add_den_pos (Qabs_den_pos hq'd) (Qabs_den_pos hqd)) (Qabs_add_le q' q) ?_
    refine Qle_trans (add_den_pos Nat.one_pos Nat.one_pos) (Qadd_le_add hq' hq) (Qeq_le ?_)
    show ((M : Int) * 1 + (M : Int) * 1) * (1 : Int) = ((2 * M : Nat) : Int) * (1 * 1)
    push_cast; ring_uor
  have hfinal : Qeq (mul (Qabs (Qsub q' q)) ⟨(2 * M : Nat), 1⟩)
      (mul (⟨(2 * M : Nat), 1⟩ : Q) (Qabs (Qsub q q'))) := by
    rw [Qabs_Qsub_comm q' q]; exact mul_comm _ _
  -- |nq − nq'| ≈ |q'−q|·|q'+q| ≤ |q'−q|·⟨2M,1⟩ ≈ ⟨2M,1⟩·|q−q'|
  exact Qle_trans
    (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hq'd hqd)) (Qabs_den_pos (add_den_pos hq'd hqd)))
    (Qeq_le heq1)
    (Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hq'd hqd)) Nat.one_pos)
      (Qmul_le_mul_left (Qabs_num_nonneg _) hsum) (Qeq_le hfinal))

-- ===========================================================================
-- The diagonal construction for cos and sin/x.
-- ===========================================================================

/-- The reindex constant for the alternating series (truncation base `M²`, Lipschitz factor `8M·Cₙₐₜ`). -/
@[irreducible] def RaltReal_K (x : Real) : Nat :=
  npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
    + 8 * xBound x * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat + 1

/-- The diagonal reindex (shared by cos and sin/x). -/
@[irreducible] def RaltReal_R (x : Real) (j : Nat) : Nat :=
  2 * (xBound x * xBound x) + 4 * (j + 1) * RaltReal_K x

/-- The `j`-th diagonal rational approximant of the alternating series. -/
def RaltReal_seq (x : Real) (off j : Nat) : Q :=
  altSum (x.seq (RaltReal_R x j)) off (RaltReal_R x j)

set_option maxHeartbeats 1000000 in
/-- **The diagonal regularity (one side)** for the alternating series: `j ≤ k ⟹ gap ≤ 1/(j+1)`. -/
theorem RaltReal_diag_le (x : Real) (off : Nat) {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (RaltReal_seq x off j) (RaltReal_seq x off k))) (Qbound j) := by
  have hM : 0 < xBound x := xBound_pos x
  have hB : 0 < xBound x * xBound x := Nat.mul_pos hM hM
  have hK1 : npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1) ≤ RaltReal_K x := by
    unfold RaltReal_K; omega
  have hK2 : 8 * xBound x * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
      ≤ RaltReal_K x := by unfold RaltReal_K; omega
  have hRle : RaltReal_R x j ≤ RaltReal_R x k := by
    unfold RaltReal_R
    have hmul : 4 * (j + 1) * RaltReal_K x ≤ 4 * (k + 1) * RaltReal_K x :=
      Nat.mul_le_mul (Nat.mul_le_mul (Nat.le_refl 4) (Nat.succ_le_succ hjk)) (Nat.le_refl _)
    omega
  have h2B : 2 * (xBound x * xBound x) ≤ RaltReal_R x j := by unfold RaltReal_R; omega
  have htri := Qabs_sub_triangle (a := RaltReal_seq x off j)
    (b := altSum (x.seq (RaltReal_R x k)) off (RaltReal_R x j)) (c := RaltReal_seq x off k)
    (altSum_den_pos (x.den_pos _) off _) (altSum_den_pos (x.den_pos _) off _)
    (altSum_den_pos (x.den_pos _) off _)
  -- Lipschitz part
  have hLip : Qle (Qabs (Qsub (RaltReal_seq x off j)
      (altSum (x.seq (RaltReal_R x k)) off (RaltReal_R x j)))) (⟨1, 2 * (j + 1)⟩ : Q) := by
    have hLS := altSum_Lip_le (x.den_pos (RaltReal_R x j)) (x.den_pos (RaltReal_R x k))
      (canon_bound x (RaltReal_R x j)) (canon_bound x (RaltReal_R x k)) off (RaltReal_R x j)
    have hCle : Qle (LipS (xBound x * xBound x) (RaltReal_R x j))
        ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Int), 1⟩ :=
      Qle_trans (expM_U_den_pos _ _) (LipS_le_U (xBound x * xBound x) (RaltReal_R x j))
        (Qle_toNat (expM_U_num_nonneg _ _) (expM_U_den_pos _ _))
    have hbridge := qsq_diff_le (x.den_pos (RaltReal_R x j)) (x.den_pos (RaltReal_R x k))
      (canon_bound x (RaltReal_R x j)) (canon_bound x (RaltReal_R x k))
    have hxreg : Qle (Qabs (Qsub (x.seq (RaltReal_R x j)) (x.seq (RaltReal_R x k))))
        ⟨2, RaltReal_R x j + 1⟩ := by
      have hanti : Qle (Qbound (RaltReal_R x k)) (Qbound (RaltReal_R x j)) := by
        show (1 : Int) * ((RaltReal_R x j + 1 : Nat) : Int) ≤ 1 * ((RaltReal_R x k + 1 : Nat) : Int)
        rw [Int.one_mul, Int.one_mul]; exact_mod_cast (show RaltReal_R x j + 1 ≤ RaltReal_R x k + 1 by omega)
      have hsum : Qeq (add (Qbound (RaltReal_R x j)) (Qbound (RaltReal_R x j)))
          ⟨2, RaltReal_R x j + 1⟩ := by simp only [Qeq, add, Qbound]; push_cast; ring_uor
      exact Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (x.reg _ _)
        (Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
          (Qadd_le_add (Qle_refl _) hanti) (Qeq_le hsum))
    -- chain to ⟨4M·Cnat, Rj+1⟩ then ≤ ⟨1, 2(j+1)⟩
    have hnqbridge : Qle (Qabs (Qsub (neg (mul (x.seq (RaltReal_R x j)) (x.seq (RaltReal_R x j))))
        (neg (mul (x.seq (RaltReal_R x k)) (x.seq (RaltReal_R x k))))))
        (mul (⟨(2 * xBound x : Nat), 1⟩ : Q) ⟨2, RaltReal_R x j + 1⟩) :=
      Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos _))))
        hbridge (Qmul_le_mul_left (Int.ofNat_nonneg _) hxreg)
    refine Qle_trans (Qmul_den_pos (LipS_den_pos _ _)
        (Qabs_den_pos (Qsub_den_pos (Nat.mul_pos (x.den_pos _) (x.den_pos _))
          (Nat.mul_pos (x.den_pos _) (x.den_pos _))))) hLS ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos
        (Nat.mul_pos (x.den_pos _) (x.den_pos _)) (Nat.mul_pos (x.den_pos _) (x.den_pos _)))))
      (Qmul_le_mul_right (Qabs_num_nonneg _) hCle) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos (Nat.succ_pos _)))
      (Qmul_le_mul_left (Int.ofNat_nonneg _) hnqbridge) ?_
    show ((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Int)
        * ((2 * xBound x : Nat) * 2) * (2 * (j + 1) : Nat)
        ≤ 1 * ((1 * (1 * (RaltReal_R x j + 1)) : Nat) : Int)
    have harith : (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
        * (2 * xBound x * 2) * (2 * (j + 1))
        ≤ 1 * (1 * (1 * (RaltReal_R x j + 1))) := by
      have he : (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
          * (2 * xBound x * 2) * (2 * (j + 1))
          = 8 * xBound x
            * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (j + 1) := by
        have hI : (((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
              * (2 * xBound x * 2) * (2 * (j + 1)) : Nat) : Int)
            = ((8 * xBound x
              * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
                * (j + 1) : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast hI
      have hfin : 8 * xBound x
          * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (j + 1)
          ≤ 4 * (j + 1) * RaltReal_K x := by
        calc 8 * xBound x * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (j + 1)
            ≤ RaltReal_K x * (j + 1) := Nat.mul_le_mul_right _ hK2
          _ = (j + 1) * RaltReal_K x := Nat.mul_comm _ _
          _ ≤ 4 * (j + 1) * RaltReal_K x := by
              rw [Nat.mul_assoc]; exact Nat.le_mul_of_pos_left _ (by decide)
      rw [he]; unfold RaltReal_R; omega
    exact_mod_cast harith
  -- truncation part
  have hTr : Qle (Qabs (Qsub (altSum (x.seq (RaltReal_R x k)) off (RaltReal_R x j))
      (RaltReal_seq x off k))) (⟨1, 2 * (j + 1)⟩ : Q) := by
    have hTB := altSum_trunc_bound (x.den_pos (RaltReal_R x k)) (canon_bound x (RaltReal_R x k)) off
      (a := RaltReal_R x j) (Nat.le_trans h2B (Nat.le_add_right _ 2)) hRle
    rw [Qabs_Qsub_comm]
    refine Qle_trans (fct_pos (RaltReal_R x j + 1)) hTB ?_
    show (2 * npow (xBound x * xBound x) (RaltReal_R x j + 1) : Int) * (2 * (j + 1) : Nat)
        ≤ 1 * ((fct (RaltReal_R x j + 1) : Nat) : Int)
    have hd : 2 * (xBound x * xBound x) + 1 + 4 * (j + 1) * RaltReal_K x = RaltReal_R x j + 1 := by
      unfold RaltReal_R; omega
    have htr := trunc_reindex (xBound x * xBound x) (2 * (j + 1)) (4 * (j + 1) * RaltReal_K x) hB
      (by have h4 : 4 * (j + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
            ≤ 4 * (j + 1) * RaltReal_K x := Nat.mul_le_mul (Nat.le_refl _) hK1
          have he : 2 * (2 * (j + 1)) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
              = 4 * (j + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1) := by
            have hI : ((2 * (2 * (j + 1)) * npow (xBound x * xBound x)
                  (2 * (xBound x * xBound x) + 1) : Nat) : Int)
                = ((4 * (j + 1) * npow (xBound x * xBound x)
                  (2 * (xBound x * xBound x) + 1) : Nat) : Int) := by push_cast; ring_uor
            exact_mod_cast hI
          rw [he]; exact Nat.le_trans h4 (Nat.le_add_right _ 1))
    rw [hd] at htr
    have hcast : (2 * npow (xBound x * xBound x) (RaltReal_R x j + 1)) * (2 * (j + 1))
        ≤ fct (RaltReal_R x j + 1) := htr
    rw [Int.one_mul]; exact_mod_cast hcast
  -- combine
  have hfin : Qeq (add (⟨1, 2 * (j + 1)⟩ : Q) ⟨1, 2 * (j + 1)⟩) (Qbound j) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  exact Qle_trans
    (add_den_pos (Qabs_den_pos (Qsub_den_pos (altSum_den_pos (x.den_pos _) off _)
      (altSum_den_pos (x.den_pos _) off _)))
      (Qabs_den_pos (Qsub_den_pos (altSum_den_pos (x.den_pos _) off _)
        (altSum_den_pos (x.den_pos _) off _))))
    htri (Qle_trans (add_den_pos (by show 0 < 2 * (j + 1); omega) (by show 0 < 2 * (j + 1); omega))
      (Qadd_le_add hLip hTr) (Qeq_le hfin))

/-- The alternating diagonal sequence is Bishop-regular. -/
theorem RaltReal_regular (x : Real) (off : Nat) : IsRegular (RaltReal_seq x off) := by
  intro j k
  rcases Nat.le_total j k with h | h
  · exact Qle_trans (Qbound_den_pos j) (RaltReal_diag_le x off h)
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · have hswap := RaltReal_diag_le x off h
    rw [Qabs_Qsub_comm] at hswap
    exact Qle_trans (Qbound_den_pos k) hswap (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- The alternating diagonal as a constructive real. -/
def RaltReal (x : Real) (off : Nat) : Real :=
  ⟨RaltReal_seq x off, RaltReal_regular x off,
    fun j => altSum_den_pos (x.den_pos _) off (RaltReal_R x j)⟩

/-- **`cos` on ℝ.** -/
def Rcos (x : Real) : Real := RaltReal x 0

/-- `sin(x)/x` on ℝ (the auxiliary series). -/
def RsinAux (x : Real) : Real := RaltReal x 1

/-- **`sin` on ℝ**, as `x · (sin x / x)`. -/
def Rsin (x : Real) : Real := Rmul x (RsinAux x)

end UOR.Bridge.F1Square.Analysis
