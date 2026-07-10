/-
F1 square — the **first Stieltjes constant `γ₁`** (the v0.16.0 ingredient that, with `γ`, `log 4π`,
and `ζ(2)`, gives the second Li coefficient `λ₂`).

`γ₁` is the limit of the **defining sequence**

    g(N) = S(N) − ½·(ln N)²,        S(N) = Σ_{k=1}^N (ln k)/k,

i.e. `γ₁ = lim_{N→∞} [ Σ_{k=1}^N (ln k)/k − ½(ln N)² ] ≈ −0.07282`. Telescoping `½(ln N)²` term by term,
`g(N) = Σ_{k=2}^N d_k` with `d_k = (ln k)/k − ½[(ln k)² − (ln(k−1))²] ≈ (1 − ln k)/(2k²)`.

This module builds the real substrate — the term `(ln k)/k`, the partial sum `S(N)`, and the sequence
`g(N)`. The two analytic theorems that complete `γ₁` are scoped on top of it:
  • **`g` is eventually decreasing** (`d_k ≤ 0` for `k ≥ 4`, from `(ln x)/x` decreasing on `x ≥ 3`),
    giving the **upper bound `γ₁ ≤ g(M)`** for any `M ≥ 4` — *no tail estimate needed* (the omitted
    `d_k` are `≤ 0`); this is the half that `Pos λ₂` consumes (`γ₁ ≤ −0.0445`).
  • **`g` is regular** (the tail `Σ_{k>M} |d_k| ≤ (ln M + 1)/M` via the integral-comparison telescoping
    of `(ln k)/k²`), so `γ₁ := Rlim g` is a genuine constructive real.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.RealPow
import F1Square.Analysis.ComplexZeta
import F1Square.Analysis.GammaAccel

namespace UOR.Bridge.F1Square.Analysis

/-- The harmonic-logarithmic term `(ln k)/k` (for `k ≥ 1`), as a constructive real. -/
def lnOver (k : Nat) (hk : 1 ≤ k) : Real := Rmul (logN k hk) (ofQ ⟨1, k⟩ (by show 0 < k; omega))

/-- Each term `(ln k)/k ≥ 0` (`ln k ≥ 0` for `k ≥ 1`, and `1/k > 0`). -/
theorem lnOver_nonneg (k : Nat) (hk : 1 ≤ k) : Rnonneg (lnOver k hk) :=
  Rnonneg_Rmul (Rnonneg_logN k hk) (Rnonneg_ofQ (by show 0 < k; omega) (by show (0 : Int) ≤ 1; decide))

/-- The partial sum `S(N) = Σ_{k=1}^N (ln k)/k`. -/
def lnSum : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (lnSum n) (lnOver (n + 1) (by omega))

/-- `S(n) ≤ S(n+1)` (the new term is `≥ 0`). -/
theorem lnSum_step (n : Nat) : Rle (lnSum n) (lnSum (n + 1)) :=
  Rle_self_Radd_right (lnOver_nonneg (n + 1) (by omega))

/-- `S` is monotone (non-decreasing). -/
theorem lnSum_mono {a b : Nat} (hab : a ≤ b) : Rle (lnSum a) (lnSum b) := by
  induction hab with
  | refl => exact Rle_refl _
  | step _ ih => exact Rle_trans ih (lnSum_step _)

/-- The **defining sequence** `g(j+1) = S(j+1) − ½·(ln (j+1))²` (indexed from `j = 0`, so no positivity
    hypothesis is needed). `γ₁ = Rlim gSeq`. -/
def gSeq (j : Nat) : Real :=
  Rsub (lnSum (j + 1)) (Rhalf (Rmul (logN (j + 1) (by omega)) (logN (j + 1) (by omega))))

-- ===========================================================================
-- `log k ≥ 1` for `k ≥ 4` — a prerequisite for the `g`-decreasing (upper-bound) half.
-- ===========================================================================

/-- **`log 4 ≥ 1`** — `log 4 = 2·log 2 ≥ 2·½ = 1` (`logN_pow_two` + `logN_2_ge_half`). -/
theorem logN_four_ge_one : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) (logN 4 (by omega)) := by
  have h4 : Req (logN 4 (by omega)) (Rnsmul 2 (logN 2 (by omega))) :=
    Req_trans (logN_eq_of_eq (show (4 : Nat) = 2 ^ 2 from rfl) (by omega) (by omega))
      (logN_pow_two 2)
  -- ofQ 1 ≈ (½ + (½ + 0)) ≤ (log 2 + (log 2 + 0)) = Rnsmul 2 (log 2)
  have hhalf := logN_2_ge_half
  have hmono : Rle (Radd (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd (ofQ (⟨1, 2⟩ : Q) (by decide)) zero))
      (Rnsmul 2 (logN 2 (by omega))) :=
    Radd_le_add hhalf (Radd_le_add hhalf (Rle_refl zero))
  have hsum : Req (Radd (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd (ofQ (⟨1, 2⟩ : Q) (by decide)) zero))
      (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
    refine Req_trans (Radd_congr (Req_refl _) (Radd_zero _)) ?_
    apply Req_of_seq_Qeq; intro n; simp only [Qeq, Radd, ofQ, add]; decide
  exact Rle_trans (Rle_of_Req (Req_symm hsum)) (Rle_trans hmono (Rle_of_Req (Req_symm h4)))

/-- **`log k ≥ 1` for `k ≥ 4`** (`log 4 ≥ 1` and `log` monotone). -/
theorem logN_ge_one {k : Nat} (hk : 4 ≤ k) : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) (logN k (by omega)) :=
  Rle_trans logN_four_ge_one (logN_mono (by omega) hk)

-- ===========================================================================
-- The consecutive-log difference `δ = log(p+1) − log p` and its UPPER bound `δ ≤ 1/p`.
-- ===========================================================================

/-- **`log(p+1) − log p ≤ 1/p`** (`p ≥ 1`): since `exp(δ) = (p+1)/p ≤ 1 + 1/p ≤ exp(1/p)` and `exp`
    reflects `≤`. This is the `(m−1)·δ_m ≤ 1` fact in the `d_m ≤ 0` proof. -/
theorem deltaLog_upper (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (logN (p + 1) (by omega)) (logN p hp)) (ofQ (⟨1, p⟩ : Q) hp) := by
  have hpp : 0 < p := hp
  -- exp(−log p) ≈ 1/p
  have hexpNeg : Req (RexpReal (Rneg (logN p hp))) (ofQ (⟨1, p⟩ : Q) hpp) :=
    RexpReal_neg_eq_recip p hpp (Rexp_logN p hp)
  -- exp(δ) = exp(log(p+1)) · exp(−log p) ≈ (p+1) · (1/p) ≈ (p+1)/p
  have hexpDelta : Req (RexpReal (Rsub (logN (p + 1) (by omega)) (logN p hp)))
      (ofQ (⟨((p : Int) + 1), p⟩ : Q) hpp) := by
    refine Req_trans (RexpReal_add (logN (p + 1) (by omega)) (Rneg (logN p hp))) ?_
    refine Req_trans (Rmul_congr (Rexp_logN (p + 1) (by omega)) hexpNeg) ?_
    refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos hpp) ?_
    exact ofQ_respects (Qmul_den_pos Nat.one_pos hpp) hpp (by simp only [Qeq, mul]; push_cast; ring_uor)
  -- (p+1)/p ≈ 1 + 1/p ≤ exp(1/p)
  have h1add : Req (Radd one (ofQ (⟨1, p⟩ : Q) hpp)) (ofQ (⟨((p : Int) + 1), p⟩ : Q) hpp) := by
    apply Req_of_seq_Qeq; intro n; simp only [Qeq, Radd, one, ofQ, add]; push_cast; ring_uor
  have hge : Rle (ofQ (⟨((p : Int) + 1), p⟩ : Q) hpp) (RexpReal (ofQ (⟨1, p⟩ : Q) hpp)) :=
    Rle_trans (Rle_of_Req (Req_symm h1add))
      (RexpReal_ge_one_add_nonneg (Rnonneg_ofQ hpp (by show (0:Int) ≤ 1; decide)))
  -- exp(δ) ≤ exp(1/p), then reflect
  exact RexpReal_reflects_le (Rnonneg_ofQ hpp (by show (0:Int) ≤ 1; decide))
    (Rle_trans (Rle_of_Req hexpDelta) hge)

-- ===========================================================================
-- The consecutive-log difference LOWER bound `δ ≥ 1/(p+1)` (the sign + tail input for |d_k|).
-- ===========================================================================

/-- `exp(δ) = exp(log(p+1) − log p) ≈ (p+1)/p` (shared by the lower/upper δ bounds). -/
theorem expDelta_eq (p : Nat) (hp : 1 ≤ p) :
    Req (RexpReal (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
      (ofQ (⟨(p : Int) + 1, p⟩ : Q) hp) := by
  have hpp : 0 < p := hp
  have hexpNeg : Req (RexpReal (Rneg (logN p hp))) (ofQ (⟨1, p⟩ : Q) hpp) :=
    RexpReal_neg_eq_recip p hpp (Rexp_logN p hp)
  refine Req_trans (RexpReal_add (logN (p + 1) (Nat.succ_pos p)) (Rneg (logN p hp))) ?_
  refine Req_trans (Rmul_congr (Rexp_logN (p + 1) (Nat.succ_pos p)) hexpNeg) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos hpp) ?_
  exact ofQ_respects (Qmul_den_pos Nat.one_pos hpp) hpp (by simp only [Qeq, mul]; push_cast; ring_uor)

/-- **`expSum(1/(p+1), N) ≤ (p+1)/p`** — the geometric `exp(q) ≤ 1/(1−q)` at `q = 1/(p+1)`
    (`expSum_mul_one_sub_le` + cancel by `(1−q) = p/(p+1)`). -/
theorem expRecip_le (p : Nat) (hp : 1 ≤ p) (N : Nat) :
    Qle (expSum (⟨1, p + 1⟩ : Q) N) (⟨(p : Int) + 1, p⟩ : Q) := by
  have hpp : 0 < p := hp
  have hpInt : (0 : Int) < (p : Int) := by exact_mod_cast hpp
  have hq1 : Qle (⟨1, p + 1⟩ : Q) ⟨1, 1⟩ := by
    show (1 : Int) * 1 ≤ 1 * ((p + 1 : Nat) : Int); push_cast; omega
  have hbase := expSum_mul_one_sub_le (q := ⟨1, p + 1⟩) (by show (0:Int) ≤ 1; decide)
    (Nat.succ_pos p) hq1 N
  refine Qmul_le_cancel_right (c := ⟨(p : Int), p + 1⟩) hpInt (Nat.succ_pos p) ?_
  have hceq : Qeq (mul (⟨(p : Int) + 1, p⟩ : Q) ⟨(p : Int), p + 1⟩) (⟨1, 1⟩ : Q) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hseq : Qeq (mul (expSum (⟨1, p + 1⟩ : Q) N) (⟨(p : Int), p + 1⟩ : Q))
      (mul (expSum (⟨1, p + 1⟩ : Q) N) (Qsub (⟨1, 1⟩ : Q) ⟨1, p + 1⟩)) := by
    apply Qmul_congr (Qeq_refl _); simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_congr_left
    (Qmul_den_pos (expSum_den_pos (Nat.succ_pos p) N) (Qsub_den_pos (by decide) (Nat.succ_pos p)))
    (Qeq_symm hseq) ?_
  exact Qle_trans Nat.one_pos hbase (Qeq_le (Qeq_symm hceq))

/-- **`exp(1/(p+1)) ≤ (p+1)/p`** (the real geometric bound, the diagonal of `expRecip_le`). -/
theorem Rexp_recip_le (p : Nat) (hp : 1 ≤ p) :
    Rle (RexpReal (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) (ofQ (⟨(p : Int) + 1, p⟩ : Q) hp) := by
  have hpp : 0 < p := hp
  intro j
  show Qle (expSum (⟨1, p + 1⟩ : Q) (RexpReal_R (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) j))
    (add (⟨(p : Int) + 1, p⟩ : Q) ⟨2, j + 1⟩)
  exact Qle_trans hpp (expRecip_le p hp _) (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **`log(p+1) − log p ≥ 1/(p+1)`** (`p ≥ 1`): `exp(1/(p+1)) ≤ (p+1)/p = exp(δ)` + `exp` reflects `≤`.
    With `deltaLog_upper`, `δ ∈ [1/(p+1), 1/p]`. -/
theorem deltaLog_lower (p : Nat) (hp : 1 ≤ p) :
    Rle (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
  RexpReal_reflects_le (Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p)))
    (Rle_trans (Rexp_recip_le p hp) (Rle_of_Req (Req_symm (expDelta_eq p hp))))

-- ===========================================================================
-- **Tight upper bound for `2·artanh(1/(2p+1)) = log(p+1) − log p`** — the small-argument artanh whose
-- fast-converging series gives a *tight* rational ceiling for the consecutive-log difference `δ`. The
-- coarse `deltaLog_upper` (`δ ≤ 1/p`) overestimates each `δ` by `Θ(1/p²)`, which accumulates to a
-- `Θ(1)` offset across a length-`N` log sum — fatal for the `γ₁` numeric. The artanh bound's overshoot
-- is `Θ(1/p⁵)` (summably tiny), so the accumulated log bound stays within the `γ₁ ≤ −0.0445` budget.
-- ===========================================================================

/-- **`2·artanh(1/(2p+1)) ≤ 2·(artSum(1/(2p+1), T) + tail)`** (`p ≥ 1`), `tail = 1/((2p+1)^{2T+1}·4p(p+1))`,
    uniformly in the artanh depth `T` — the `Rlog2c_le` pattern at the variable small base `1/(2p+1)`. The
    `γ₁`-numeric input once paired with the identity `δ = log(p+1) − log p = 2·artanh(1/(2p+1))`. -/
theorem twoArtanhRecip_le (p T : Nat) (hp : 1 ≤ p) :
    Rle (TwoArtanhConst (⟨1, 2 * p + 1⟩ : Q) ⟨1, 2 * p + 1⟩ (Nat.succ_pos _)
          (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _)
          (by show (1 : Int).toNat < 2 * p + 1; omega) (Qle_refl _))
        (ofQ (mul (⟨2, 1⟩ : Q) (add (artSum (⟨1, 2 * p + 1⟩ : Q) T)
              ⟨1, npow (2 * p + 1) (2 * T + 1) * (4 * p * (p + 1))⟩))
          (Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (Nat.succ_pos _) T)
            (Nat.mul_pos (npow_pos (Nat.succ_pos _) _)
              (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos _)))))) := by
  have htaild : 0 < npow (2 * p + 1) (2 * T + 1) * (4 * p * (p + 1)) :=
    Nat.mul_pos (npow_pos (Nat.succ_pos _) _)
      (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos _))
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨1, 2 * p + 1⟩ ⟨1, 2 * p + 1⟩)).num := by
    show 0 < (add (⟨1, 1⟩ : Q) (neg (mul ⟨1, 2 * p + 1⟩ ⟨1, 2 * p + 1⟩))).num
    simp only [add, neg, mul]
    have h9 : ((9 : Nat) : Int) ≤ (((2 * p + 1) * (2 * p + 1) : Nat) : Int) :=
      by exact_mod_cast Nat.mul_le_mul (show 3 ≤ 2 * p + 1 by omega) (show 3 ≤ 2 * p + 1 by omega)
    push_cast at h9 ⊢; omega
  unfold TwoArtanhConst RartanhConst
  apply Rmul_ofQ_le (by decide) (by decide)
    (add_den_pos (artSum_den_pos (Nat.succ_pos _) T) htaild)
  intro m
  show Qle (artSum ((ofQ (⟨1, 2 * p + 1⟩ : Q) (Nat.succ_pos _)).seq (Rartanh_R ⟨1, 2 * p + 1⟩ m))
      (Rartanh_R ⟨1, 2 * p + 1⟩ m))
    (add (artSum (⟨1, 2 * p + 1⟩ : Q) T) ⟨1, npow (2 * p + 1) (2 * T + 1) * (4 * p * (p + 1))⟩)
  exact artSum_le_value (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _) htaild hWn T
    (deltaTail_eq p T) (Rartanh_R ⟨1, 2 * p + 1⟩ m)

-- The pure-`Int` polynomial identities behind the `exp(2·artanh(1/(2p+1))) = (p+1)/p` instantiation
-- (clean atoms for `ring_uor`, no `Nat.cast` — `g·(1−τ) = 1+τ` and `K·(1−τ) = 1` at `τ = 1/(2p+1)`).

/-- `g·(1−τ) = 1+τ` cleared, `g = (p+1)/p`, `τ = 1/(2p+1)`: `(p+1)·2p·(2p+1) = (2p+2)·(p·(2p+1))`. -/
private theorem twoArtanh_hg_int (P : Int) :
    (P + 1) * (1 * (2 * P + 1) + -1) * (1 * (2 * P + 1))
      = (1 * (2 * P + 1) + 1) * (P * (1 * (2 * P + 1))) := by ring_uor

/-- `K·(1−τ) = 1` cleared, `K = (2p+1)/(2p)`, `τ = 1/(2p+1)`: `2p·(2p+1) = (2p+1)·2p`. -/
private theorem twoArtanh_hKF_int (P : Int) :
    1 * (2 * P * (1 * (2 * P + 1)))
      = (2 * P + 1) * (1 * (2 * P + 1) + -1) * 1 := by ring_uor

/-- The cleared per-index regularity budget `hBC` for the `exp(2·artanh(1/(2p+1)))` instantiation,
    `C = (L+2)(2p+1)²`: the slack `RHS − LHS = 4(L+2)(2p+1)²(j+1)²·p(p−1) ≥ 0` (the `p(p−1) ≥ 0`
    factor is exactly the `p ≥ 1` margin). Pure `Int` so `ring_uor` sees clean atoms. -/
private theorem twoArtanh_hBC_int (L P J : Int) (hP : 1 ≤ P) (hL : 0 ≤ L) (hJ : 0 ≤ J) :
    (L * ((2 * P + 1) * (2 * (2 * P + 1))) * (2 * P * (1 * (J + 1)))
        + (2 * P + 1) * (4 * (2 * P + 1)) * (1 * (2 * P * (1 * (J + 1))))) * (J + 1)
      ≤ (L + 2) * (2 * P + 1) * (2 * P + 1)
          * (1 * (2 * P * (1 * (J + 1))) * (2 * P * (1 * (J + 1)))) := by
  have key : (L + 2) * (2 * P + 1) * (2 * P + 1)
        * (1 * (2 * P * (1 * (J + 1))) * (2 * P * (1 * (J + 1))))
      - (L * ((2 * P + 1) * (2 * (2 * P + 1))) * (2 * P * (1 * (J + 1)))
        + (2 * P + 1) * (4 * (2 * P + 1)) * (1 * (2 * P * (1 * (J + 1))))) * (J + 1)
      = 4 * (L + 2) * ((2 * P + 1) * (2 * P + 1)) * ((J + 1) * (J + 1)) * (P * (P - 1)) := by ring_uor
  have hprod : 0 ≤ 4 * (L + 2) * ((2 * P + 1) * (2 * P + 1)) * ((J + 1) * (J + 1)) * (P * (P - 1)) :=
    Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg
      (by omega : (0 : Int) ≤ 4 * (L + 2))
      (Int.mul_nonneg (by omega) (by omega)))
      (Int.mul_nonneg (by omega) (by omega)))
      (Int.mul_nonneg (by omega) (by omega))
  omega

/-- **`exp(2·artanh(1/(2p+1))) = (p+1)/p`** (`p ≥ 1`) — the exp/artanh real identity at the small base
    `τ = 1/(2p+1)`, with `g = (p+1)/p`, `K = (2p+1)/(2p)`, `M' = 3`. Instantiates `Rexp_two_artanh_ofQ`
    (the `Rexp_log_nat` pattern, at a base that is *not* `tmap` of a nat). Paired with `expDelta_eq`
    (`exp(δ) = (p+1)/p`) and `RexpReal_inj`, this pins `δ = log(p+1) − log p = 2·artanh(1/(2p+1))`. -/
theorem Rexp_twoArtanhRecip (p : Nat) (hp : 1 ≤ p) :
    Req (RexpReal (TwoArtanhConst (⟨1, 2 * p + 1⟩ : Q) ⟨1, 2 * p + 1⟩ (Nat.succ_pos _)
          (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _)
          (by show (1 : Int).toNat < 2 * p + 1; omega) (Qle_refl _)))
      (ofQ (⟨(p : Int) + 1, p⟩ : Q) hp) := by
  refine Rexp_two_artanh_ofQ (⟨1, 2 * p + 1⟩ : Q) ⟨1, 2 * p + 1⟩ ⟨(p : Int) + 1, p⟩ ⟨2 * (p : Int) + 1, 2 * p⟩
    3 ((expM_U 3 (2 * 3)).num.toNat)
    (((expM_U 3 (2 * 3)).num.toNat + 2) * (2 * p + 1) * (2 * p + 1))
    (Nat.succ_pos _) (by show (0 : Int) ≤ 1; decide)
    (by show Qle (⟨1, 2 * p + 1⟩ : Q) ⟨1, 1⟩; simp only [Qle]; push_cast; omega)
    (by show (1 : Int).toNat < 2 * p + 1; omega)
    (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _)
    (by show (1 : Int).toNat < 2 * p + 1; omega) (Qle_refl _)
    hp ?_ (Nat.mul_pos (by decide) hp) (by show (0 : Int) ≤ 2 * (p : Int) + 1; omega) ?_
    rfl ?_ ?_
  · -- hg : g·(1−τ) = 1+τ
    simp only [Qeq, mul, Qsub, add, neg]; push_cast; exact twoArtanh_hg_int p
  · -- hKF : 1 ≤ K·(1−τ)   (in fact = 1)
    refine Qeq_le ?_
    simp only [Qeq, mul, Qsub, add, neg]; push_cast; exact twoArtanh_hKF_int p
  · -- hM2 : K·2 ≤ ⟨3,1⟩
    simp only [Qle, mul]; push_cast; omega
  · -- hBC : the per-index regularity budget
    intro j
    simp only [Qle, add, mul]
    push_cast
    exact twoArtanh_hBC_int (↑(expM_U 3 6).num.toNat) (p : Int) (j : Int)
      (by exact_mod_cast hp) (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)

/-- **`artanh τ ≥ 0`** (for `τ ≥ 0`): each artanh partial sum has non-negative numerator
    (`artSum_nonneg`), so every approximant clears the regularity floor `−1/(n+1)`. -/
theorem Rnonneg_RartanhConst (τ ρ : Q) (hτd : 0 < τ.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hρlt : ρ.num.toNat < ρ.den) (hb : Qle (Qabs τ) ρ) (hτ0 : 0 ≤ τ.num) :
    Rnonneg (RartanhConst τ ρ hτd hρ0 hρd hρlt hb) := by
  intro n
  show Qle (neg (Qbound n)) (artSum τ (Rartanh_R ρ n))
  have hnum : 0 ≤ (artSum τ (Rartanh_R ρ n)).num := artSum_nonneg hτ0 hτd _
  have hpp : (0 : Int) ≤ (artSum τ (Rartanh_R ρ n)).num * ((n : Int) + 1) :=
    Int.mul_nonneg hnum (by omega)
  simp only [Qle, neg, Qbound]; push_cast; omega

/-- **`ofQ(artSum τ T) ≤ artanh τ`** (partial sum ≤ limit, `τ ≥ 0`) — valid for any depth `T` within the
    base reindex `Rartanh_R ρ 0 = ρ.den²+4ρ.den` (so `T ≤ that` ⟹ every diagonal depth `≥ T`, and
    `artSum` is monotone in depth). The tight log *lower* bound's artanh input. -/
theorem ofQ_artSum_le_RartanhConst (τ ρ : Q) (hτd : 0 < τ.den) (hρ0 : 0 ≤ ρ.num)
    (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den) (hb : Qle (Qabs τ) ρ) (hτ0 : 0 ≤ τ.num)
    (T : Nat) (hT : T ≤ ρ.den * ρ.den + 4 * ρ.den) :
    Rle (ofQ (artSum τ T) (artSum_den_pos hτd T)) (RartanhConst τ ρ hτd hρ0 hρd hρlt hb) := by
  intro n
  show Qle (artSum τ T) (add (artSum τ (Rartanh_R ρ n)) ⟨2, n + 1⟩)
  have hge : T ≤ Rartanh_R ρ n := by
    unfold Rartanh_R
    have h1 : ρ.den * ρ.den + 4 * ρ.den ≤ (ρ.den * ρ.den + 4 * ρ.den) * (n + 1) :=
      Nat.le_mul_of_pos_right _ (Nat.succ_pos n)
    omega
  exact Qle_trans (artSum_den_pos hτd (Rartanh_R ρ n)) (artSum_mono hτ0 hτd hge)
    (Qle_self_add (p := (⟨2, n + 1⟩ : Q)) (by show (0 : Int) ≤ 2; decide))

/-- **`log(p+1) − log p = 2·artanh(1/(2p+1))`** (`p ≥ 1`) — pinned by `exp` injectivity on non-negatives:
    both sides are `≥ 0` and exponentiate to `(p+1)/p` (`expDelta_eq` and `Rexp_twoArtanhRecip`). -/
theorem deltaLog_eq_twoArtanh (p : Nat) (hp : 1 ≤ p) :
    Req (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (TwoArtanhConst (⟨1, 2 * p + 1⟩ : Q) ⟨1, 2 * p + 1⟩ (Nat.succ_pos _)
          (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _)
          (by show (1 : Int).toNat < 2 * p + 1; omega) (Qle_refl _)) := by
  refine RexpReal_inj (Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p)))
    (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 2; decide))
      (Rnonneg_RartanhConst _ _ _ _ _ _ _ (by show (0 : Int) ≤ 1; decide))) ?_
  exact Req_trans (expDelta_eq p hp) (Req_symm (Rexp_twoArtanhRecip p hp))

/-- The depth-`T` rational `δ`-ceiling at step `p` (`= 2·(artSum(1/(2p+1),T) + tail)`), the RHS value
    of `deltaLog_upper_tight p T`. -/
def dPlusQ (T p : Nat) : Q :=
  mul (⟨2, 1⟩ : Q) (add (artSum (⟨1, 2 * p + 1⟩ : Q) T)
    ⟨1, npow (2 * p + 1) (2 * T + 1) * (4 * p * (p + 1))⟩)

theorem dPlusQ_den_pos (T p : Nat) (hp : 1 ≤ p) : 0 < (dPlusQ T p).den :=
  Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (Nat.succ_pos _) T)
    (Nat.mul_pos (npow_pos (Nat.succ_pos _) _)
      (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos _))))

/-- **Tight upper bound on the consecutive-log difference**: `log(p+1) − log p ≤ dPlusQ T p`
    (`= 2·(artSum(1/(2p+1), T) + tail)`, `tail = 1/((2p+1)^{2T+1}·4p(p+1))`) — the `deltaLog_eq_twoArtanh`
    identity composed with `twoArtanhRecip_le`. Summably-tight (`Θ(1/p⁵)` overshoot) vs `deltaLog_upper`. -/
theorem deltaLog_upper_tight (p T : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (dPlusQ T p) (dPlusQ_den_pos T p hp)) :=
  Rle_trans (Rle_of_Req (deltaLog_eq_twoArtanh p hp)) (twoArtanhRecip_le p T hp)

/-- The depth-`T` rational `δ`-floor at step `p` (`= 2·artSum(1/(2p+1),T)`, no tail — the artanh partial
    sum *under*-estimates), the RHS value of `deltaLog_lower_tight p T`. -/
def dMinusQ (T p : Nat) : Q := mul (⟨2, 1⟩ : Q) (artSum (⟨1, 2 * p + 1⟩ : Q) T)

theorem dMinusQ_den_pos (T p : Nat) : 0 < (dMinusQ T p).den :=
  Qmul_den_pos (by decide) (artSum_den_pos (Nat.succ_pos _) T)

/-- **Tight lower bound on the consecutive-log difference**: `log(p+1) − log p ≥ dMinusQ T p`
    (`= 2·artSum(1/(2p+1),T)`, `p ≥ 1`, depth `T ≤ (2p+1)²+4(2p+1)`) — `deltaLog_eq_twoArtanh` with the
    partial-sum lower bound `ofQ_artSum_le_RartanhConst`. The `½log²` lower-bound input. -/
theorem deltaLog_lower_tight (p T : Nat) (hp : 1 ≤ p)
    (hT : T ≤ (2 * p + 1) * (2 * p + 1) + 4 * (2 * p + 1)) :
    Rle (ofQ (dMinusQ T p) (dMinusQ_den_pos T p))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide)
    (artSum_den_pos (Nat.succ_pos _) T)))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 2; decide))
    (ofQ_artSum_le_RartanhConst (⟨1, 2 * p + 1⟩ : Q) ⟨1, 2 * p + 1⟩ (Nat.succ_pos _)
      (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _)
      (by show (1 : Int).toNat < 2 * p + 1; omega) (Qle_refl _) (by show (0 : Int) ≤ 1; decide) T hT)) ?_
  exact Rle_of_Req (Req_symm (deltaLog_eq_twoArtanh p hp))

-- ===========================================================================
-- **Fixed-denominator round-up** — the key to a *feasible* final `decide`. Accumulating the per-step
-- `δ` bounds with honest `Qadd` multiplies denominators (`∏(2p+1)^{2T+1}`, astronomical). Rounding each
-- partial sum *up* to a fixed denominator `D` keeps every accumulator a single `⟨·, D⟩`, so the final
-- numeric check is one big-integer comparison. The round-up overshoot is `< 1/D` per step (negligible).
-- ===========================================================================

/-- Round `q` *up* to denominator `D`: `⌈q·D⌉/D` via `(q.num·D) ediv q.den + 1` (a safe ceiling — the
    `+1` covers the floor, overshooting by `< 1/D`). -/
def qRoundUp (q : Q) (D : Nat) : Q := ⟨q.num * (D : Int) / (q.den : Int) + 1, D⟩

/-- **`q ≤ qRoundUp q D`** — the round-up dominates (`q.den > 0`). The `+1` ceiling clears the floored
    division: `(⌊a/b⌋+1)·b = a − a%b + b ≥ a + 1 > a` (`Int.ediv_add_emod` + `0 ≤ a%b < b`). -/
theorem qRoundUp_ge (q : Q) (hqd : 0 < q.den) (D : Nat) : Qle q (qRoundUp q D) := by
  show q.num * (D : Int) ≤ (q.num * (D : Int) / (q.den : Int) + 1) * (q.den : Int)
  have hb : (0 : Int) < (q.den : Int) := by exact_mod_cast hqd
  have hdm := Int.ediv_add_emod (q.num * (D : Int)) (q.den : Int)
  have hmlt := Int.emod_lt_of_pos (q.num * (D : Int)) hb
  have hmnn := Int.emod_nonneg (q.num * (D : Int)) (by omega : (q.den : Int) ≠ 0)
  have key : (q.num * (D : Int) / (q.den : Int) + 1) * (q.den : Int)
      = (q.den : Int) * (q.num * (D : Int) / (q.den : Int)) + (q.den : Int) := by
    rw [Int.add_mul, Int.one_mul, Int.mul_comm (q.num * (D : Int) / (q.den : Int)) (q.den : Int)]
  rw [key]; omega

theorem qRoundUp_den_pos (q : Q) (D : Nat) (hD : 0 < D) : 0 < (qRoundUp q D).den := hD

/-- Round `q` *down* to denominator `D`: `⌊q·D⌋/D` via `(q.num·D) ediv q.den` (a safe floor). -/
def qRoundDown (q : Q) (D : Nat) : Q := ⟨q.num * (D : Int) / (q.den : Int), D⟩

/-- **`qRoundDown q D ≤ q`** — the round-down is dominated (`q.den > 0`): `⌊a/b⌋·b = a − a%b ≤ a`
    (`Int.ediv_add_emod` + `0 ≤ a%b`). -/
theorem qRoundDown_le (q : Q) (hqd : 0 < q.den) (D : Nat) : Qle (qRoundDown q D) q := by
  show (q.num * (D : Int) / (q.den : Int)) * (q.den : Int) ≤ q.num * (D : Int)
  have hb : (0 : Int) < (q.den : Int) := by exact_mod_cast hqd
  have hdm := Int.ediv_add_emod (q.num * (D : Int)) (q.den : Int)
  have hmnn := Int.emod_nonneg (q.num * (D : Int)) (by omega : (q.den : Int) ≠ 0)
  rw [Int.mul_comm (q.num * (D : Int) / (q.den : Int)) (q.den : Int)]; omega

theorem qRoundDown_den_pos (q : Q) (D : Nat) (hD : 0 < D) : 0 < (qRoundDown q D).den := hD

-- ===========================================================================
-- **Per-term tight log upper bound, accumulated at fixed denominator `D`.** `logBound T D k` is a
-- rational `≥ log(k+1)`, built by adding the depth-`T` artanh `δ`-ceiling at each step and rounding up
-- to `D`. `logN_le_logBound` proves `log(k+1) ≤ ofQ(logBound T D k)` — the `.seq`-blowup-free input to
-- the `lnSum` bound (each step is `Radd_le_add` + `Radd_ofQ_ofQ`, never `.seq`).
-- ===========================================================================

/-- `logBound T D k` is a rational upper bound for `log(k+1)`, at fixed denominator `D`. -/
def logBound (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (k + 1) => qRoundUp (add (logBound T D k) (dPlusQ T (k + 1))) D

theorem logBound_den_pos (T D : Nat) (hD : 0 < D) : ∀ k, 0 < (logBound T D k).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`log(k+1) ≤ ofQ(logBound T D k)`** — the accumulated per-term log bound, via `deltaLog_upper_tight`
    at each step (`Radd_le_add` + round-up), never touching `.seq`. -/
theorem logN_le_logBound (T D : Nat) (hD : 0 < D) :
    ∀ k, Rle (logN (k + 1) (Nat.succ_pos k)) (ofQ (logBound T D k) (logBound_den_pos T D hD k)) := by
  intro k
  induction k with
  | zero =>
    have h0 : Req (ofQ (logBound T D 0) (logBound_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req (Req_trans logN_one (Req_symm h0))
  | succ k ih =>
    have hb1 := logBound_den_pos T D hD k
    have hb2 := dPlusQ_den_pos T (k + 1) (Nat.succ_pos k)
    have hadd := add_den_pos hb1 hb2
    refine Rle_trans (Rle_of_Req (Req_symm (Radd_Rsub_self (logN (k + 1) (Nat.succ_pos k))
      (logN (k + 2) (Nat.succ_pos (k + 1)))))) ?_
    refine Rle_trans (Radd_le_add ih (deltaLog_upper_tight (k + 1) T (Nat.succ_pos k))) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hb1 hb2)) ?_
    exact Rle_ofQ_ofQ hadd (logBound_den_pos T D hD (k + 1))
      (qRoundUp_ge (add (logBound T D k) (dPlusQ T (k + 1))) hadd D)

/-- `logLowBound T D k` is a rational *lower* bound for `log(k+1)`, at fixed denominator `D` (round down). -/
def logLowBound (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (k + 1) => qRoundDown (add (logLowBound T D k) (dMinusQ T (k + 1))) D

theorem logLowBound_den_pos (T D : Nat) (hD : 0 < D) : ∀ k, 0 < (logLowBound T D k).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`ofQ(logLowBound T D k) ≤ log(k+1)`** — the accumulated per-term log *lower* bound (`depth T ≤ 21`),
    via `deltaLog_lower_tight` at each step (`Radd_le_add` + round-down). The `½log²` lower-bound input. -/
theorem logN_ge_logLowBound (T D : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    ∀ k, Rle (ofQ (logLowBound T D k) (logLowBound_den_pos T D hD k)) (logN (k + 1) (Nat.succ_pos k)) := by
  intro k
  induction k with
  | zero =>
    have h0 : Req (ofQ (logLowBound T D 0) (logLowBound_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req (Req_trans h0 (Req_symm logN_one))
  | succ k ih =>
    have hlk := logLowBound_den_pos T D hD k
    have hmk := dMinusQ_den_pos T (k + 1)
    have hadd := add_den_pos hlk hmk
    have hT' : T ≤ (2 * (k + 1) + 1) * (2 * (k + 1) + 1) + 4 * (2 * (k + 1) + 1) := by
      have h3 : 3 ≤ 2 * (k + 1) + 1 := by omega
      have hsq : 9 ≤ (2 * (k + 1) + 1) * (2 * (k + 1) + 1) := Nat.mul_le_mul h3 h3
      omega
    refine Rle_trans (Rle_ofQ_ofQ (logLowBound_den_pos T D hD (k + 1)) hadd
      (qRoundDown_le (add (logLowBound T D k) (dMinusQ T (k + 1))) hadd D)) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ hlk hmk))) ?_
    refine Rle_trans (Radd_le_add ih (deltaLog_lower_tight (k + 1) T (Nat.succ_pos k) hT')) ?_
    exact Rle_of_Req (Radd_Rsub_self (logN (k + 1) (Nat.succ_pos k)) (logN (k + 2) (Nat.succ_pos (k + 1))))

/-- `lnSumBound T D k` is a rational upper bound for `lnSum k = Σ_{i=1}^k (log i)/i`, at fixed
    denominator `D` (each new term `(log(k+1))/(k+1) ≤ logBound k · 1/(k+1)`, then round up). -/
def lnSumBound (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (k + 1) => qRoundUp (add (lnSumBound T D k) (mul (logBound T D k) ⟨1, k + 1⟩)) D

theorem lnSumBound_den_pos (T D : Nat) (hD : 0 < D) : ∀ k, 0 < (lnSumBound T D k).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`lnSum k ≤ ofQ(lnSumBound T D k)`** — the partial-sum `Σ (log i)/i` bounded term-by-term via
    `logN_le_logBound`, accumulated at fixed denominator `D` (no `.seq`). The `g(N)`-numeric input. -/
theorem lnSum_le_lnSumBound (T D : Nat) (hD : 0 < D) :
    ∀ k, Rle (lnSum k) (ofQ (lnSumBound T D k) (lnSumBound_den_pos T D hD k)) := by
  intro k
  induction k with
  | zero =>
    have h0 : Req (ofQ (lnSumBound T D 0) (lnSumBound_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req (Req_symm h0)
  | succ k ih =>
    have hbk := logBound_den_pos T D hD k
    have hmuld : 0 < (mul (logBound T D k) (⟨1, k + 1⟩ : Q)).den := Qmul_den_pos hbk (Nat.succ_pos k)
    have hadd := add_den_pos (lnSumBound_den_pos T D hD k) hmuld
    -- the new term `(log(k+1))/(k+1) ≤ ofQ(logBound k · 1/(k+1))`
    have hov : Rle (lnOver (k + 1) (Nat.succ_pos k)) (ofQ (mul (logBound T D k) ⟨1, k + 1⟩) hmuld) :=
      Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos k) (by show (0 : Int) ≤ 1; decide))
        (logN_le_logBound T D hD k)) (Rle_of_Req (Rmul_ofQ_ofQ hbk (Nat.succ_pos k)))
    refine Rle_trans (Radd_le_add ih hov) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnSumBound_den_pos T D hD k) hmuld)) ?_
    exact Rle_ofQ_ofQ hadd (lnSumBound_den_pos T D hD (k + 1))
      (qRoundUp_ge (add (lnSumBound T D k) (mul (logBound T D k) ⟨1, k + 1⟩)) hadd D)

-- ===========================================================================
-- **Assembled `g(N)` upper bound** `gSeq N ≤ ofQ(gBound)` — the upper `lnSum` bound minus the lower
-- `½log²` bound, both rational at fixed `D`. The single rational that the `γ₁ ≤ −0.0445` numeric checks.
-- ===========================================================================

/-- `½·ofQ(q) = ofQ(q/2)` (`Rhalf` is pointwise `·½`). -/
theorem Rhalf_ofQ (q : Q) (hd : 0 < q.den) :
    Req (Rhalf (ofQ q hd)) (ofQ (mul (⟨1, 2⟩ : Q) q) (Qmul_den_pos (by decide) hd)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- `−ofQ(q) = ofQ(−q)`. -/
theorem Rneg_ofQ (q : Q) (hd : 0 < q.den) :
    Req (Rneg (ofQ q hd)) (ofQ (neg q) (by exact hd)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

theorem dMinusQ_num_nonneg (T p : Nat) : 0 ≤ (dMinusQ T p).num :=
  Int.mul_nonneg (by decide)
    (artSum_nonneg (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _) T)

theorem logLowBound_num_nonneg (T D : Nat) : ∀ k, 0 ≤ (logLowBound T D k).num
  | 0 => by show (0 : Int) ≤ 0; decide
  | (k + 1) => by
    show 0 ≤ (add (logLowBound T D k) (dMinusQ T (k + 1))).num * (D : Int) / _
    refine Int.ediv_nonneg (Int.mul_nonneg ?_ (Int.ofNat_nonneg _)) (Int.ofNat_nonneg _)
    show (0 : Int) ≤ (logLowBound T D k).num * _ + (dMinusQ T (k + 1)).num * _
    exact Int.add_nonneg (Int.mul_nonneg (logLowBound_num_nonneg T D k) (Int.ofNat_nonneg _))
      (Int.mul_nonneg (dMinusQ_num_nonneg T (k + 1)) (Int.ofNat_nonneg _))

/-- The assembled rational upper bound for `g(N) = lnSum(N+1) − ½(log(N+1))²`: the upper `lnSum` bound
    minus the lower `½log²` bound (from `logLowBound`), at fixed denominator `D`, depth `T ≤ 21`. -/
def gBound (T D N : Nat) : Q :=
  Qsub (lnSumBound T D (N + 1))
    (mul (⟨1, 2⟩ : Q) (mul (logLowBound T D N) (logLowBound T D N)))

theorem gBound_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound T D N).den :=
  Qsub_den_pos (lnSumBound_den_pos T D hD (N + 1))
    (Qmul_den_pos (by decide) (Qmul_den_pos (logLowBound_den_pos T D hD N)
      (logLowBound_den_pos T D hD N)))

/-- **`g(N) ≤ ofQ(gBound T D N)`** — `g(N) = lnSum(N+1) − ½(log(N+1))²` bounded above by the upper
    `lnSum` bound minus the lower `½log²` bound (`logN_ge_logLowBound`, squared monotonically), at fixed
    denominator `D`, artanh depth `T ≤ 21`. The rational fed to the `γ₁ ≤ −0.0445` numeric. -/
theorem gSeq_le_gBound (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (gSeq N) (ofQ (gBound T D N) (gBound_den_pos T D N hD)) := by
  have hLLd := logLowBound_den_pos T D hD N
  have hUd := lnSumBound_den_pos T D hD (N + 1)
  have hlow := logN_ge_logLowBound T D hD hT N
  have hlownn : Rnonneg (ofQ (logLowBound T D N) hLLd) := Rnonneg_ofQ hLLd (logLowBound_num_nonneg T D N)
  have hlognn : Rnonneg (logN (N + 1) (Nat.succ_pos N)) := Rnonneg_logN _ _
  -- `LL² ≤ log²` and halve
  have hhalf : Rle (Rhalf (Rmul (ofQ (logLowBound T D N) hLLd) (ofQ (logLowBound T D N) hLLd)))
      (Rhalf (Rmul (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))) :=
    Rhalf_le_Rhalf (Rle_trans (Rmul_le_Rmul_right hlownn hlow) (Rmul_le_Rmul_left hlognn hlow))
  -- `g(N) = lnSum(N+1) − ½log² ≤ ofQ(U) − ½LL²`
  refine Rle_trans (Rsub_le_sub (lnSum_le_lnSumBound T D hD (N + 1)) hhalf) ?_
  -- collapse the RHS reals to one `ofQ`
  have hsqd : 0 < (mul (logLowBound T D N) (logLowBound T D N)).den := Qmul_den_pos hLLd hLLd
  refine Rle_of_Req (Req_trans (Radd_congr (Req_refl _) (Req_trans (Rneg_congr
    (Req_trans (Rhalf_congr (Rmul_ofQ_ofQ hLLd hLLd)) (Rhalf_ofQ _ hsqd)))
    (Rneg_ofQ _ (Qmul_den_pos (by decide) hsqd)))) ?_)
  exact Radd_ofQ_ofQ hUd (by exact Qmul_den_pos (by decide) hsqd)

/-- The linear identity `(a + b) + (a − b) ≈ a + a`. -/
theorem addsub_linear (a b : Real) : Req (Radd (Radd a b) (Rsub a b)) (Radd a a) :=
  Req_trans (Radd_swap a b a (Rneg b))
    (Req_trans (Radd_congr (Req_refl _) (Radd_neg b)) (Radd_zero _))

/-- The quadratic identity `(a² − b²) + (a − b)² ≈ (a − b)·(a + a)` ( = `2aδ`, `δ = a − b`). -/
theorem sq_diff_identity (a b : Real) :
    Req (Radd (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b)))
        (Rmul (Rsub a b) (Radd a a)) := by
  refine Req_trans (Radd_congr (Req_symm (Rmul_sub_add_self a b)) (Req_refl _)) ?_
  refine Req_trans (Req_symm (Rmul_distrib (Rsub a b) (Radd a b) (Rsub a b))) ?_
  exact Rmul_congr (Req_refl _) (addsub_linear a b)

/-- `x − y ≤ z` from `x ≤ z + y`. -/
theorem Rsub_le_of_le_add {x y z : Real} (h : Rle x (Radd z y)) : Rle (Rsub x y) z :=
  Rle_trans (Rsub_le_sub h (Rle_refl y))
    (Rle_of_Req (Req_trans (Radd_assoc z y (Rneg y))
      (Req_trans (Radd_congr (Req_refl z) (Radd_neg y)) (Radd_zero z))))

/-- **`½a² − ½b² + ½(a−b)² ≈ a·(a−b)`** (`= aδ`). The combined `½`-identity. -/
theorem half_combine (a b : Real) :
    Req (Radd (Rsub (Rhalf (Rmul a a)) (Rhalf (Rmul b b))) (Rhalf (Rmul (Rsub a b) (Rsub a b))))
        (Rmul a (Rsub a b)) := by
  refine Req_trans (Radd_congr (Req_symm (Rhalf_Rsub (Rmul a a) (Rmul b b))) (Req_refl _)) ?_
  refine Req_trans
    (Req_symm (Rhalf_Radd (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b)))) ?_
  refine Req_trans (Rhalf_congr (sq_diff_identity a b)) ?_
  refine Req_trans (Rhalf_congr (Rmul_distrib (Rsub a b) a a)) ?_
  refine Req_trans (Rhalf_Radd (Rmul (Rsub a b) a) (Rmul (Rsub a b) a)) ?_
  exact Req_trans (Rhalf_double (Rmul (Rsub a b) a)) (Rmul_comm (Rsub a b) a)

-- ===========================================================================
-- The per-step `d = g(p+1) − g(p) = (ln(p+1))/(p+1) − ½((ln(p+1))² − (ln p)²)` and its bounds.
-- ===========================================================================

/-- The per-step difference `d_{p+1} = g(p+1) − g(p)` (`p ≥ 1`). -/
def dStep (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (lnOver (p + 1) (Nat.succ_pos p))
    (Rsub (Rhalf (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p))))
          (Rhalf (Rmul (logN p hp) (logN p hp))))

/-- **`d_{p+1} ≤ ½·δ²`** (`δ = log(p+1) − log p`): the half of the upper |d| bound (with `½δ² ≤
    1/(2p²)`). Since `d = lnOver(p+1) − (½L²−½L'²)` and `lnOver(p+1) = L·(1/(p+1)) ≤ L·δ`
    (`δ ≥ 1/(p+1)`), and `½L²−½L'²+½δ² = L·δ`. -/
theorem dStep_le_half_sq (p : Nat) (hp : 1 ≤ p) :
    Rle (dStep p hp)
      (Rhalf (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                   (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) := by
  have ha : Rnonneg (logN (p + 1) (Nat.succ_pos p)) := Rnonneg_logN (p + 1) (Nat.succ_pos p)
  -- lnOver(p+1) = L·(1/(p+1)) ≤ L·δ
  have hle : Rle (lnOver (p + 1) (Nat.succ_pos p))
      (Rmul (logN (p + 1) (Nat.succ_pos p))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) :=
    Rmul_le_Rmul_left ha (deltaLog_lower p hp)
  apply Rsub_le_of_le_add
  refine Rle_trans hle (Rle_of_Req ?_)
  refine Req_trans (Req_symm (half_combine (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) ?_
  exact Radd_comm _ _

/-- **`d_{p+1} ≤ 1/(2p²)`** — the numeric upper bound (`½δ² ≤ ½(1/p)²`, `δ ≤ 1/p`). -/
theorem dStep_le (p : Nat) (hp : 1 ≤ p) :
    Rle (dStep p hp) (ofQ (⟨1, 2 * p * p⟩ : Q) (Nat.mul_pos (Nat.mul_pos (by decide) hp) hp)) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hδle : Rle (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) (ofQ (⟨1, p⟩ : Q) hp) :=
    deltaLog_upper p hp
  have hpp : 0 < p := hp
  have hofqnn : Rnonneg (ofQ (⟨1, p⟩ : Q) hp) := Rnonneg_ofQ hpp (by show (0 : Int) ≤ 1; decide)
  have hsq : Rle (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                       (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
                 (Rmul (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p⟩ : Q) hp)) :=
    Rle_trans (Rmul_le_Rmul_left hδnn hδle) (Rmul_le_Rmul_right hofqnn hδle)
  refine Rle_trans (dStep_le_half_sq p hp) ?_
  refine Rle_trans (Rhalf_le_Rhalf hsq) (Rle_of_Req ?_)
  refine Req_trans (Rhalf_congr (Rmul_ofQ_ofQ hpp hpp)) ?_
  apply Req_of_seq_Qeq; intro n; simp only [Rhalf, ofQ, mul, Qeq]; push_cast; ring_uor

/-- **`d_{p+1} ≥ −log(p+1)/(p(p+1))`** — the numeric lower bound. Since `d = lnOver(p+1) −
    (½a²−½b²)` and `½a²−½b² ≤ a·δ` (the `½δ² ≥ 0` slack), `d ≥ lnOver(p+1) − a·δ = −a·(δ − 1/(p+1))`
    and `δ − 1/(p+1) ≤ 1/p − 1/(p+1) = 1/(p(p+1))`. -/
theorem dStep_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (Rmul (logN (p + 1) (Nat.succ_pos p)) (ofQ (⟨1, p * (p + 1)⟩ : Q)
        (Nat.mul_pos hp (Nat.succ_pos p)))))
      (dStep p hp) := by
  have hpp : 0 < p := hp
  have ha : Rnonneg (logN (p + 1) (Nat.succ_pos p)) := Rnonneg_logN (p + 1) (Nat.succ_pos p)
  -- abbreviations (defeq to the underlying log terms)
  let a := logN (p + 1) (Nat.succ_pos p)
  let b := logN p hp
  let δ := Rsub a b
  -- h1 : ½a² − ½b² ≤ a·δ  (slack ½δ² ≥ 0, via half_combine)
  have h1 : Rle (Rsub (Rhalf (Rmul a a)) (Rhalf (Rmul b b))) (Rmul a δ) :=
    Rle_trans (Rle_self_Radd_right (Rhalf_nonneg (Rnonneg_Rmul_self δ)))
      (Rle_of_Req (half_combine a b))
  -- step2 : lnOver(p+1) − a·δ ≤ dStep
  have hstep2 : Rle (Rsub (lnOver (p + 1) (Nat.succ_pos p)) (Rmul a δ)) (dStep p hp) :=
    Rsub_le_sub (Rle_refl _) h1
  -- heq3 : lnOver(p+1) − a·δ = −(a·(δ − 1/(p+1)))
  have heq3 : Req (Rsub (lnOver (p + 1) (Nat.succ_pos p)) (Rmul a δ))
      (Rneg (Rmul a (Rsub δ (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))) := by
    refine Req_trans (Req_symm (Rmul_sub_distrib a (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) δ)) ?_
    refine Req_trans (Rmul_congr (Req_refl a)
      (Req_symm (Rneg_Rsub δ (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))) ?_
    exact Rmul_neg_right a (Rsub δ (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
  -- h4 : δ − 1/(p+1) ≤ 1/(p(p+1))
  have h4 : Rle (Rsub δ (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
      (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rsub_le_sub (deltaLog_upper p hp) (Rle_refl _)) (Rle_of_Req ?_)
    apply Req_of_seq_Qeq; intro n; simp only [Rsub, Radd, Rneg, ofQ, add, neg, Qeq]; push_cast; ring_uor
  -- combine
  refine Rle_trans (Rle_Rneg (Rmul_le_Rmul_left ha h4)) ?_
  exact Rle_trans (Rle_of_Req (Req_symm heq3)) hstep2

-- ===========================================================================
-- The per-step gSeq identity and its two-sided bounds (the dyadic-tail input).
-- ===========================================================================

/-- `(−x) − (−y) ≈ −(x − y)`. -/
theorem Rsub_Rneg_Rneg (x y : Real) : Req (Rsub (Rneg x) (Rneg y)) (Rneg (Rsub x y)) := by
  apply Req_of_seq_Qeq; intro n; simp only [Qeq, Rsub, Radd, Rneg, neg, add]; push_cast; ring_uor

/-- **`gSeq(j+1) − gSeq j ≈ dStep(j+1)`** — the consecutive gSeq difference is the per-step `d`. -/
theorem gSeq_step_eq (j : Nat) :
    Req (Rsub (gSeq (j + 1)) (gSeq j)) (dStep (j + 1) (Nat.succ_pos j)) := by
  have hAC : Req (Rsub (lnSum (j + 2)) (lnSum (j + 1)))
      (lnOver (j + 2) (Nat.succ_pos (j + 1))) := by
    show Req (Rsub (Radd (lnSum (j + 1)) (lnOver (j + 2) (by omega))) (lnSum (j + 1)))
             (lnOver (j + 2) (Nat.succ_pos (j + 1)))
    refine Req_trans (Rsub_congr (Radd_comm (lnSum (j + 1)) (lnOver (j + 2) (by omega)))
      (Req_refl _)) ?_
    refine Req_trans (Radd_assoc (lnOver (j + 2) (by omega)) (lnSum (j + 1))
      (Rneg (lnSum (j + 1)))) ?_
    exact Req_trans (Radd_congr (Req_refl _) (Radd_neg (lnSum (j + 1)))) (Radd_zero _)
  unfold gSeq dStep
  refine Req_trans (Rsub_Radd_Radd (lnSum (j + 2))
    (Rneg (Rhalf (Rmul (logN (j + 2) (by omega)) (logN (j + 2) (by omega)))))
    (lnSum (j + 1))
    (Rneg (Rhalf (Rmul (logN (j + 1) (by omega)) (logN (j + 1) (by omega)))))) ?_
  -- Radd (Rsub A C) (Rsub (Rneg X) (Rneg Y)) ≈ Radd (lnOver(j+2)) (Rneg (Rsub X Y))
  --   = Rsub (lnOver(j+2)) (Rsub X Y)  (defeq)
  exact Radd_congr hAC (Rsub_Rneg_Rneg _ _)

/-- **`(a − b) + (b − c) ≈ a − c`** — the telescoping split for the gap induction. -/
theorem Rsub_split (a b c : Real) : Req (Radd (Rsub a b) (Rsub b c)) (Rsub a c) := by
  refine Req_trans (Req_symm (Radd_assoc (Rsub a b) b (Rneg c))) ?_
  refine Radd_congr ?_ (Req_refl _)
  refine Req_trans (Radd_assoc a (Rneg b) b) ?_
  exact Req_trans (Radd_congr (Req_refl a) (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b)))
    (Radd_zero a)

/-- **Per-step gSeq upper bound** `gSeq(j+1) − gSeq j ≤ 1/(2(j+1)²)`. -/
theorem gSeq_step_le (j : Nat) :
    Rle (Rsub (gSeq (j + 1)) (gSeq j))
      (ofQ (⟨1, 2 * (j + 1) * (j + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos j))) :=
  Rle_trans (Rle_of_Req (gSeq_step_eq j)) (dStep_le (j + 1) (Nat.succ_pos j))

/-- **Per-step gSeq lower bound** `gSeq(j+1) − gSeq j ≥ −log(j+2)/((j+1)(j+2))`. -/
theorem gSeq_step_ge (j : Nat) :
    Rle (Rneg (Rmul (logN (j + 2) (Nat.succ_pos (j + 1)))
        (ofQ (⟨1, (j + 1) * (j + 2)⟩ : Q) (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
      (Rsub (gSeq (j + 1)) (gSeq j)) :=
  Rle_trans (dStep_ge (j + 1) (Nat.succ_pos j)) (Rle_of_Req (Req_symm (gSeq_step_eq j)))

-- ===========================================================================
-- The UPPER gap bound `gSeq(N+d) − gSeq N ≤ 1/(2N)` (clean rational telescoping).
-- ===========================================================================

/-- Rational partial sum `Σ_{p≤j} 1/(2p²)` of the per-step upper bounds. -/
def Usum : Nat → Q
  | 0 => ⟨0, 1⟩
  | (j + 1) => add (Usum j) ⟨1, 2 * (j + 1) * (j + 1)⟩

theorem Usum_den_pos : ∀ j, 0 < (Usum j).den
  | 0 => by decide
  | (j + 1) => add_den_pos (Usum_den_pos j)
      (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos j))

/-- `a + (x − y) ≈ (x + a) − y` on ℚ (general, so `ring_uor` sees only the three atoms). -/
theorem Qadd_Qsub_comm (a x y : Q) : Qeq (add a (Qsub x y)) (Qsub (add x a) y) := by
  simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor

/-- **Upper gap bound, U-form** (`d`-induction): `gSeq(N+d) − gSeq N ≤ Usum(N+d) − Usum N`.
    Each step adds exactly the per-step bound `1/(2(N+d+1)²)` (`gSeq_step_le`); the `Rsub_split`
    telescopes and the combine is a pure rational rearrangement (`Radd_ofQ_ofQ` + `ofQ_congr`). -/
theorem gSeq_diff_le_U (N : Nat) (d : Nat) :
    Rle (Rsub (gSeq (N + d)) (gSeq N))
        (ofQ (Qsub (Usum (N + d)) (Usum N))
          (Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N))) := by
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans (Radd_neg (gSeq N)) (Req_symm ?_)
      apply Req_of_seq_Qeq; intro n
      simp only [ofQ, zero, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      exact Rle_trans
        (Rle_of_Req (Req_symm (Rsub_split (gSeq (N + d + 1)) (gSeq (N + d)) (gSeq N))))
        (Rle_trans
          (Radd_le_add (gSeq_step_le (N + d)) ih)
          (Rle_of_Req (Req_trans
            (Radd_ofQ_ofQ _ _)
            (ofQ_congr _ _ (Qadd_Qsub_comm _ (Usum (N + d)) (Usum N))))))

/-- Telescoping sum on ℚ: `(p − q) + (r − p) ≈ r − q`. -/
theorem Qadd_Qsub_telescope (p q r : Q) : Qeq (add (Qsub p q) (Qsub r p)) (Qsub r q) := by
  simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor

/-- **Per-step telescoping inequality** `1/(2(m+1)²) ≤ 1/(2m) − 1/(2(m+1))` (the difference is
    `4(m+1) ≥ 0`). -/
theorem Usum_step_ineq (m : Nat) :
    Qle (⟨1, 2 * (m + 1) * (m + 1)⟩ : Q) (Qsub (⟨1, 2 * m⟩ : Q) ⟨1, 2 * (m + 1)⟩) := by
  simp only [Qle, Qsub, add, neg]
  push_cast
  have key : (1 * (2 * ((m : Int) + 1)) + (-1) * (2 * (m : Int))) * (2 * ((m : Int) + 1) * ((m : Int) + 1))
      - 1 * (2 * (m : Int) * (2 * ((m : Int) + 1))) = 4 * (m : Int) + 4 := by ring_uor
  have hm : (0 : Int) ≤ (m : Int) := Int.ofNat_nonneg m
  omega

/-- **Rational telescoping tail bound** `Usum(N+d) − Usum N ≤ 1/(2N) − 1/(2(N+d))` (for `N ≥ 1`). -/
theorem Usum_tail_le (N : Nat) (hN : 1 ≤ N) (d : Nat) :
    Qle (Qsub (Usum (N + d)) (Usum N)) (Qsub (⟨1, 2 * N⟩ : Q) ⟨1, 2 * (N + d)⟩) := by
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      -- den-positivity abbreviations
      have hA : 0 < (⟨1, 2 * ((N + d) + 1) * ((N + d) + 1)⟩ : Q).den :=
        Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos (N + d))) (Nat.succ_pos (N + d))
      have hC : 0 < (Qsub (⟨1, 2 * N⟩ : Q) ⟨1, 2 * (N + d)⟩).den :=
        Qsub_den_pos (Nat.mul_pos (by decide) hN) (Nat.mul_pos (by decide) (by omega))
      have hD : 0 < (Qsub (⟨1, 2 * (N + d)⟩ : Q) ⟨1, 2 * (N + d + 1)⟩).den :=
        Qsub_den_pos (Nat.mul_pos (by decide) (by omega)) (Nat.mul_pos (by decide) (by omega))
      have hB : 0 < (Qsub (Usum (N + d)) (Usum N)).den :=
        Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N)
      -- step: A + (1/(2N) − 1/(2(N+d))) ≤ 1/(2N) − 1/(2(N+d+1))
      have hstep : Qle (add (⟨1, 2 * ((N + d) + 1) * ((N + d) + 1)⟩ : Q)
            (Qsub (⟨1, 2 * N⟩ : Q) ⟨1, 2 * (N + d)⟩))
          (Qsub (⟨1, 2 * N⟩ : Q) ⟨1, 2 * (N + d + 1)⟩) :=
        Qle_trans (add_den_pos hD hC)
          (Qadd_le_add (Usum_step_ineq (N + d)) (Qle_refl _))
          (Qeq_le (Qadd_Qsub_telescope _ _ _))
      -- assemble: LHS ≈ A + (Usum(N+d) − Usum N) ≤ A + (1/(2N) − 1/(2(N+d))) ≤ target
      exact Qle_trans (add_den_pos hA hB)
        (Qeq_le (Qeq_symm (Qadd_Qsub_comm _ (Usum (N + d)) (Usum N))))
        (Qle_trans (add_den_pos hA hC) (Qadd_le_add (Qle_refl _) ih) hstep)

-- ===========================================================================
-- The LOWER gap bound (dyadic blocks): prerequisite `log 2 ≤ 1`.
-- ===========================================================================

/-- **`log 2 ≤ 1`** — `exp(1) ≥ 1 + 1 = 2 = exp(log 2)`, and `exp` reflects `≤`. (The convergence of
    the γ₁ dyadic tail only needs a constant bound on `log 2`, not the tight `0.6931`.) -/
theorem logN_2_le_one : Rle (logN 2 (by omega)) (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
  apply RexpReal_reflects_le (Rnonneg_ofQ (by decide) (by decide))
  refine Rle_trans (Rle_of_Req (Rexp_logN 2 (by omega))) ?_
  refine Rle_trans (Rle_of_Req ?_) (RexpReal_ge_one_add_nonneg
    (Rnonneg_ofQ (by decide) (by decide) : Rnonneg (ofQ (⟨1, 1⟩ : Q) (by decide))))
  apply Req_of_seq_Qeq; intro n
  simp only [ofQ, one, Radd, add, Qeq]; push_cast

/-- **The UPPER gap bound** `gSeq(N+d) − gSeq N ≤ 1/(2N) − 1/(2(N+d)) ≤ 1/(2N)` (for `N ≥ 1`). -/
theorem gSeq_diff_le (N : Nat) (hN : 1 ≤ N) (d : Nat) :
    Rle (Rsub (gSeq (N + d)) (gSeq N))
        (ofQ (Qsub (⟨1, 2 * N⟩ : Q) ⟨1, 2 * (N + d)⟩)
          (Qsub_den_pos (Nat.mul_pos (by decide) hN) (Nat.mul_pos (by decide) (by omega)))) :=
  Rle_trans (gSeq_diff_le_U N d) (Rle_ofQ_ofQ _ _ (Usum_tail_le N hN d))

/-- **Block log cap** `log(j+2) ≤ a+2` whenever `j+2 ≤ 2^{a+2}` (so `log(j+2) ≤ log(2^{a+2}) =
    (a+2)·log 2 ≤ a+2`). The per-block bound on the `logN` factor of the lower gap. -/
theorem logN_le_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (logN (j + 2) (by omega)) (ofQ (⟨(a + 2 : Int), 1⟩ : Q) Nat.one_pos) := by
  refine Rle_trans (logN_mono (by omega) hj) ?_
  refine Rle_trans (Rle_of_Req (logN_pow_two (a + 2))) ?_
  refine Rle_trans (Rle_of_Req (Rnsmul_eq_Rmul_ofQ (logN 2 (by omega)) (a + 2))) ?_
  refine Rle_trans (Rmul_le_Rmul_left
    (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg (a + 2))) logN_2_le_one) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos (by decide))
    (ofQ_congr _ _ (by simp only [mul, Qeq]; push_cast; ring_uor)))

/-- **Per-step block lower bound** `gSeq(j+1) − gSeq j ≥ −(a+2)/((j+1)(j+2))` for `j+2 ≤ 2^{a+2}`
    (the `logN` factor capped by `a+2` via `logN_le_block`). -/
theorem gSeq_step_ge_block (a j : Nat) (hj : j + 2 ≤ 2 ^ (a + 2)) :
    Rle (Rneg (ofQ (⟨(a + 2 : Int), (j + 1) * (j + 2)⟩ : Q)
        (Nat.mul_pos (Nat.succ_pos j) (by omega))))
      (Rsub (gSeq (j + 1)) (gSeq j)) := by
  refine Rle_trans (Rle_Rneg ?_) (gSeq_step_ge j)
  -- Rmul (logN(j+2)) (ofQ 1/((j+1)(j+2))) ≤ ofQ (a+2)/((j+1)(j+2))
  refine Rle_trans (Rmul_le_Rmul_right
    (Rnonneg_ofQ (Nat.mul_pos (Nat.succ_pos j) (by omega)) (by show (0 : Int) ≤ 1; decide))
    (logN_le_block a j hj)) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos (Nat.mul_pos (Nat.succ_pos j) (by omega)))
    (ofQ_congr _ _ (by simp only [mul, Qeq]; push_cast; ring_uor)))

/-- Rational partial sum `Σ_{p≤j} (a+2)/(p(p+1))` of the per-step block lower bounds. -/
def Vsum (a : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (j + 1) => add (Vsum a j) ⟨(a + 2 : Int), (j + 1) * (j + 2)⟩

theorem Vsum_den_pos (a : Nat) : ∀ j, 0 < (Vsum a j).den
  | 0 => Nat.one_pos
  | (j + 1) => add_den_pos (Vsum_den_pos a j) (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))

/-- **Inner block lower gap bound** (`d`-induction within block `a`): for `N+d+1 ≤ 2^{a+2}`,
    `gSeq(N+d) − gSeq N ≥ −(Vsum a (N+d) − Vsum a N)`. Each step uses the rational per-step block
    bound `gSeq_step_ge_block`; the structure mirrors `gSeq_diff_le_U` (Rsub_split + Rneg of the
    ofQ-sum). -/
theorem gSeq_diff_ge_block (a N : Nat) : ∀ (d : Nat), N + d + 1 ≤ 2 ^ (a + 2) →
    Rle (Rneg (ofQ (Qsub (Vsum a (N + d)) (Vsum a N))
          (Qsub_den_pos (Vsum_den_pos a (N + d)) (Vsum_den_pos a N))))
        (Rsub (gSeq (N + d)) (gSeq N)) := by
  intro d
  induction d with
  | zero =>
      intro _
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (gSeq N)))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, ofQ, zero, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      intro hd
      have ihd := ih (by omega)
      have hstepd : 0 < (⟨(a + 2 : Int), (N + d + 1) * (N + d + 2)⟩ : Q).den :=
        Nat.mul_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hgapd : 0 < (Qsub (Vsum a (N + d)) (Vsum a N)).den :=
        Qsub_den_pos (Vsum_den_pos a (N + d)) (Vsum_den_pos a N)
      have heq : Req (Rneg (ofQ (Qsub (Vsum a (N + d + 1)) (Vsum a N))
            (Qsub_den_pos (Vsum_den_pos a (N + d + 1)) (Vsum_den_pos a N))))
          (Radd (Rneg (ofQ (⟨(a + 2 : Int), (N + d + 1) * (N + d + 2)⟩ : Q) hstepd))
                (Rneg (ofQ (Qsub (Vsum a (N + d)) (Vsum a N)) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (Qeq_symm (Qadd_Qsub_comm _ (Vsum a (N + d)) (Vsum a N))))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (gSeq_step_ge_block a (N + d) (by omega)) ihd)
          (Rle_of_Req (Rsub_split (gSeq (N + d + 1)) (gSeq (N + d)) (gSeq N))))

/-- The Vsum increment telescopes exactly: `(a+2)/((m+1)(m+2)) = (a+2)/(m+1) − (a+2)/(m+2)`. -/
theorem Vsum_step_eq (a m : Nat) :
    Qeq (⟨(a + 2 : Int), (m + 1) * (m + 2)⟩ : Q)
        (Qsub (⟨(a + 2 : Int), m + 1⟩ : Q) ⟨(a + 2 : Int), m + 2⟩) := by
  simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor

/-- **Rational telescoping tail bound** `Vsum a (N+d) − Vsum a N = (a+2)/(N+1) − (a+2)/(N+d+1)`. -/
theorem Vsum_tail_le (a N : Nat) (d : Nat) :
    Qle (Qsub (Vsum a (N + d)) (Vsum a N))
        (Qsub (⟨(a + 2 : Int), N + 1⟩ : Q) ⟨(a + 2 : Int), N + d + 1⟩) := by
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hA : 0 < (⟨(a + 2 : Int), (N + d + 1) * (N + d + 2)⟩ : Q).den :=
        Nat.mul_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hC : 0 < (Qsub (⟨(a + 2 : Int), N + 1⟩ : Q) ⟨(a + 2 : Int), N + d + 1⟩).den :=
        Qsub_den_pos (Nat.succ_pos N) (Nat.succ_pos (N + d))
      have hD : 0 < (Qsub (⟨(a + 2 : Int), N + d + 1⟩ : Q) ⟨(a + 2 : Int), N + d + 2⟩).den :=
        Qsub_den_pos (Nat.succ_pos (N + d)) (Nat.succ_pos (N + d + 1))
      have hB : 0 < (Qsub (Vsum a (N + d)) (Vsum a N)).den :=
        Qsub_den_pos (Vsum_den_pos a (N + d)) (Vsum_den_pos a N)
      have hstep : Qle (add (⟨(a + 2 : Int), (N + d + 1) * (N + d + 2)⟩ : Q)
            (Qsub (⟨(a + 2 : Int), N + 1⟩ : Q) ⟨(a + 2 : Int), N + d + 1⟩))
          (Qsub (⟨(a + 2 : Int), N + 1⟩ : Q) ⟨(a + 2 : Int), N + d + 2⟩) :=
        Qle_trans (add_den_pos hD hC)
          (Qadd_le_add (Qeq_le (Vsum_step_eq a (N + d))) (Qle_refl _))
          (Qeq_le (Qadd_Qsub_telescope _ _ _))
      exact Qle_trans (add_den_pos hA hB)
        (Qeq_le (Qeq_symm (Qadd_Qsub_comm _ (Vsum a (N + d)) (Vsum a N))))
        (Qle_trans (add_den_pos hA hC) (Qadd_le_add (Qle_refl _) ih) hstep)

/-- `(c/(P+1) − c/(2P+1)) ≤ c/P` for `c ≥ 0` (difference `= c(P²+3P+1) ≥ 0`). The per-block fraction
    cleanup, with abstract `c, P` so `ring_uor`/`omega` see only small atoms. -/
theorem Qsub_block_le (c : Int) (hc : 0 ≤ c) (P : Nat) :
    Qle (Qsub (⟨c, P + 1⟩ : Q) ⟨c, P + P + 1⟩) ⟨c, P⟩ := by
  simp only [Qle, Qsub, add, neg]
  push_cast
  have hP : (0 : Int) ≤ (P : Int) := Int.ofNat_nonneg P
  have h1 : (0 : Int) ≤ c * (P : Int) * (P : Int) := Int.mul_nonneg (Int.mul_nonneg hc hP) hP
  have h2 : (0 : Int) ≤ c * (P : Int) := Int.mul_nonneg hc hP
  have key : c * (((P : Int) + 1) * ((P : Int) + (P : Int) + 1))
        - (c * ((P : Int) + (P : Int) + 1) + -c * ((P : Int) + 1)) * (P : Int)
      = c * (P : Int) * (P : Int) + 3 * (c * (P : Int)) + c := by ring_uor
  omega

/-- **Per-block lower bound** `gSeq(2^{a+1}) − gSeq(2^a) ≥ −(a+2)/2^a`. The full block `[2^a, 2^{a+1})`
    via `gSeq_diff_ge_block` (N=d=2^a) and the telescoped `Vsum_tail_le`, the bound `(a+2)/(2^a+1) ≤
    (a+2)/2^a`. -/
theorem gSeq_block_ge (a : Nat) :
    Rle (Rneg (ofQ (⟨(a + 2 : Int), 2 ^ a⟩ : Q) (Nat.pos_pow_of_pos a (by decide))))
        (Rsub (gSeq (2 ^ (a + 1))) (gSeq (2 ^ a))) := by
  have e1 : (2 : Nat) ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
  have e2 : (2 : Nat) ^ (a + 2) = 2 ^ (a + 1) + 2 ^ (a + 1) := by rw [Nat.pow_succ]; omega
  have hp1 : 1 ≤ (2 : Nat) ^ (a + 1) := Nat.one_le_two_pow
  have hcon : 2 ^ a + 2 ^ a + 1 ≤ 2 ^ (a + 2) := by omega
  rw [e1]
  refine Rle_trans (Rle_Rneg ?_) (gSeq_diff_ge_block a (2 ^ a) (2 ^ a) hcon)
  have hmid : 0 < (Qsub (⟨(a + 2 : Int), 2 ^ a + 1⟩ : Q) ⟨(a + 2 : Int), 2 ^ a + 2 ^ a + 1⟩).den :=
    Qsub_den_pos (Nat.succ_pos (2 ^ a)) (Nat.succ_pos (2 ^ a + 2 ^ a))
  exact Rle_trans
    (Rle_ofQ_ofQ (Qsub_den_pos (Vsum_den_pos a (2 ^ a + 2 ^ a)) (Vsum_den_pos a (2 ^ a))) hmid
      (Vsum_tail_le a (2 ^ a) (2 ^ a)))
    (Rle_ofQ_ofQ hmid (Nat.pos_pow_of_pos a (by decide))
      (Qsub_block_le ((a : Int) + 2) (by have := Int.ofNat_nonneg a; omega) (2 ^ a)))

/-- Rational sum of per-block lower bounds `Σ_{i<e} (A+i+2)/2^{A+i}`. -/
def Wsum (A : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (e + 1) => add (Wsum A e) ⟨(A + e + 2 : Int), 2 ^ (A + e)⟩

theorem Wsum_den_pos (A : Nat) : ∀ e, 0 < (Wsum A e).den
  | 0 => Nat.one_pos
  | (e + 1) => add_den_pos (Wsum_den_pos A e) (Nat.pos_pow_of_pos (A + e) (by decide))

/-- **Outer block lower bound** (`e`-induction over blocks): `gSeq(2^{A+e}) − gSeq(2^A) ≥ −Wsum A e`.
    Chains `gSeq_block_ge` over consecutive dyadic blocks (same lower-side telescoping pattern as
    `gSeq_diff_ge_block`). -/
theorem gSeq_diff_ge_outer (A : Nat) : ∀ e,
    Rle (Rneg (ofQ (Wsum A e) (Wsum_den_pos A e))) (Rsub (gSeq (2 ^ (A + e))) (gSeq (2 ^ A))) := by
  intro e
  induction e with
  | zero =>
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (gSeq (2 ^ A))))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, Wsum, ofQ, zero, neg, Qeq]; push_cast
  | succ e ih =>
      have hstepd : 0 < (⟨(A + e + 2 : Int), 2 ^ (A + e)⟩ : Q).den :=
        Nat.pos_pow_of_pos (A + e) (by decide)
      have hgapd : 0 < (Wsum A e).den := Wsum_den_pos A e
      have heq : Req (Rneg (ofQ (Wsum A (e + 1)) (Wsum_den_pos A (e + 1))))
          (Radd (Rneg (ofQ (⟨(A + e + 2 : Int), 2 ^ (A + e)⟩ : Q) hstepd))
                (Rneg (ofQ (Wsum A e) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (by simp only [Wsum, Qeq, add]; push_cast; ring_uor))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (gSeq_block_ge (A + e)) ih)
          (Rle_of_Req (Rsub_split (gSeq (2 ^ (A + e + 1))) (gSeq (2 ^ (A + e))) (gSeq (2 ^ A)))))

/-- Forward telescoping sum on ℚ: `(p − q) + (q − r) ≈ p − r`. -/
theorem Qadd_Qsub_fwd (p q r : Q) : Qeq (add (Qsub p q) (Qsub q r)) (Qsub p r) := by
  simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor

/-- **Geometric tail bound** `Wsum A e ≤ (2A+6)/2^A − (2(A+e)+6)/2^{A+e} ≤ (2A+6)/2^A`. The block sum
    telescopes (`T(m) := (2m+6)/2^m` is the discrete antiderivative of `Σ(m+2)/2^m`); bounded by `T(A)`. -/
theorem Wsum_tail_le (A : Nat) : ∀ e,
    Qle (Wsum A e) (Qsub (⟨(2 * A + 6 : Int), 2 ^ A⟩ : Q) ⟨(2 * (A + e) + 6 : Int), 2 ^ (A + e)⟩)
  | 0 => by
      simp only [Nat.add_zero]
      apply Qeq_le
      simp only [Wsum, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | (e + 1) => by
      have hT : 0 < (Qsub (⟨(2 * A + 6 : Int), 2 ^ A⟩ : Q) ⟨(2 * (A + e) + 6 : Int), 2 ^ (A + e)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos A (by decide)) (Nat.pos_pow_of_pos (A + e) (by decide))
      have hS : 0 < (Qsub (⟨(2 * (A + e) + 6 : Int), 2 ^ (A + e)⟩ : Q)
          ⟨(2 * (A + e + 1) + 6 : Int), 2 ^ (A + e + 1)⟩).den :=
        Qsub_den_pos (Nat.pos_pow_of_pos (A + e) (by decide)) (Nat.pos_pow_of_pos (A + e + 1) (by decide))
      -- inc = T(A+e) − T(A+e+1)  (the increment, in the literal form `Wsum` uses)
      have h2 : (2 : Nat) ^ (A + e + 1) = 2 * 2 ^ (A + e) := by rw [Nat.pow_succ]; omega
      have hinc : Qeq (⟨(A + e + 2 : Int), 2 ^ (A + e)⟩ : Q)
          (Qsub (⟨(2 * (A + e) + 6 : Int), 2 ^ (A + e)⟩ : Q) ⟨(2 * (A + e + 1) + 6 : Int), 2 ^ (A + e + 1)⟩) := by
        simp only [h2, Qsub, add, neg, Qeq]; push_cast; ring_uor
      -- Wsum A (e+1) = Wsum A e + inc ≤ (T(A) − T(A+e)) + (T(A+e) − T(A+e+1)) = T(A) − T(A+e+1)
      exact Qle_trans (add_den_pos hT hS)
        (Qadd_le_add (Wsum_tail_le A e) (Qeq_le hinc))
        (Qeq_le (Qadd_Qsub_fwd _ _ _))

-- ===========================================================================
-- The reindex `M(j) = 2j+8` and its domination `2^{M(j)} ≥ (j+1)(2·M(j)+6)`.
-- ===========================================================================

/-- `m < 2^m`. -/
theorem lt_two_pow (m : Nat) : m < 2 ^ m := by
  induction m with
  | zero => decide
  | succ k ih => rw [Nat.pow_succ]; omega

/-- `4j + 22 ≤ 2^{j+8}` (linear ≤ exponential, the block-log factor at the reindex). -/
theorem lin_le_two_pow (j : Nat) : 4 * j + 22 ≤ 2 ^ (j + 8) := by
  induction j with
  | zero => decide
  | succ k ih =>
      have hp : (2 : Nat) ^ (k + 1 + 8) = 2 ^ (k + 8) * 2 := by
        rw [show k + 1 + 8 = (k + 8) + 1 from by omega, Nat.pow_succ]
      omega

/-- **Reindex domination** `(j+1)·(4j+22) ≤ 2^{2j+8}` — i.e. `2^{M(j)} ≥ (j+1)(2·M(j)+6)` for
    `M(j) = 2j+8`, so the lower tail `(2M(j)+6)/2^{M(j)} ≤ 1/(j+1)`. -/
theorem gamma_domination (j : Nat) : (j + 1) * (4 * j + 22) ≤ 2 ^ (2 * j + 8) := by
  have h1 : j + 1 ≤ 2 ^ j := lt_two_pow j
  have h2 : 4 * j + 22 ≤ 2 ^ (j + 8) := lin_le_two_pow j
  have h3 : (j + 1) * (4 * j + 22) ≤ 2 ^ j * 2 ^ (j + 8) := Nat.mul_le_mul h1 h2
  have h4 : (2 : Nat) ^ j * 2 ^ (j + 8) = 2 ^ (2 * j + 8) := by
    rw [← Nat.pow_add]; congr 1; omega
  omega

-- ===========================================================================
-- The reindexed sequence `gSeqDyadic j = gSeq(2^{2j+8})` and its pairwise Cauchy bounds → RReg → Rlim.
-- ===========================================================================

/-- The dyadic reindex exponent `M(j) = 2j+8`. -/
def gammaMidx (j : Nat) : Nat := 2 * j + 8

theorem gammaMidx_mono {j k : Nat} (h : j ≤ k) : gammaMidx j ≤ gammaMidx k := by
  simp only [gammaMidx]; omega

/-- The reindexed partial-`γ₁` sequence `gSeq(2^{M(j)})`. -/
def gSeqDyadic (j : Nat) : Real := gSeq (2 ^ gammaMidx j)

/-- `1/a ≤ 1/b` when `b ≤ a`. -/
theorem Qunit_le {a b : Nat} (h : b ≤ a) : Qle (⟨1, a⟩ : Q) ⟨1, b⟩ := by
  simp only [Qle]; push_cast; omega

/-- `1/a − 1/b ≤ 1/a` (the subtracted term is nonnegative; difference `a² ≥ 0`). -/
theorem Qsub_unit_le (a b : Nat) : Qle (Qsub (⟨1, a⟩ : Q) ⟨1, b⟩) ⟨1, a⟩ := by
  simp only [Qle, Qsub, add, neg]; push_cast
  have ha : (0 : Int) ≤ (a : Int) := Int.ofNat_nonneg a
  have key : (1 : Int) * ((a : Int) * (b : Int)) - (1 * (b : Int) + -1 * (a : Int)) * (a : Int)
      = (a : Int) * (a : Int) := by ring_uor
  have h1 : (0 : Int) ≤ (a : Int) * (a : Int) := Int.mul_nonneg ha ha
  omega

/-- `j+1 ≤ 2·2^{M(j)}` (from the domination — the reindex is far enough out). -/
theorem succ_le_two_pow_midx (j : Nat) : j + 1 ≤ 2 * 2 ^ gammaMidx j := by
  have hd := gamma_domination j
  have hle : j + 1 ≤ (j + 1) * (4 * j + 22) := Nat.le_mul_of_pos_right _ (by omega)
  simp only [gammaMidx]; omega

/-- **Pairwise Cauchy (upper)**: for `j ≤ k`, `gSeqDyadic k − gSeqDyadic j ≤ 1/(j+1)`. -/
theorem gamma_pair_le {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (gSeqDyadic k) (gSeqDyadic j)) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  simp only [gSeqDyadic]
  have hpow : 2 ^ gammaMidx j ≤ 2 ^ gammaMidx k :=
    Nat.pow_le_pow_right (by omega) (gammaMidx_mono hjk)
  obtain ⟨d, hd⟩ := Nat.le.dest hpow
  rw [← hd]
  refine Rle_trans (gSeq_diff_le (2 ^ gammaMidx j) Nat.one_le_two_pow d) (Rle_ofQ_ofQ _ _ ?_)
  exact Qle_trans (Nat.mul_pos (by decide) (Nat.pos_pow_of_pos _ (by decide)))
    (Qsub_unit_le (2 * 2 ^ gammaMidx j) (2 * (2 ^ gammaMidx j + d)))
    (Qunit_le (succ_le_two_pow_midx j))

/-- `c₁/a − c₂/b ≤ c₁/a` when `c₂ ≥ 0` (subtracting a nonnegative; difference `c₂·a² ≥ 0`). -/
theorem Qsub_le_left (c₁ c₂ : Int) (hc₂ : 0 ≤ c₂) (a b : Nat) :
    Qle (Qsub (⟨c₁, a⟩ : Q) ⟨c₂, b⟩) ⟨c₁, a⟩ := by
  simp only [Qle, Qsub, add, neg]; push_cast
  have ha : (0 : Int) ≤ (a : Int) := Int.ofNat_nonneg a
  have key : c₁ * ((a : Int) * (b : Int)) - (c₁ * (b : Int) + -c₂ * (a : Int)) * (a : Int)
      = c₂ * ((a : Int) * (a : Int)) := by ring_uor
  have h1 : (0 : Int) ≤ c₂ * ((a : Int) * (a : Int)) := Int.mul_nonneg hc₂ (Int.mul_nonneg ha ha)
  omega

/-- `(2·M(j)+6)/2^{M(j)} ≤ 1/(j+1)` — the lower-tail anchor bound, directly from `gamma_domination`. -/
theorem gamma_T_le (j : Nat) :
    Qle (⟨(2 * gammaMidx j + 6 : Int), 2 ^ gammaMidx j⟩ : Q) ⟨1, j + 1⟩ := by
  simp only [Qle, gammaMidx]; push_cast
  have hcast : (((j + 1) * (4 * j + 22) : Nat) : Int) ≤ ((2 ^ (2 * j + 8) : Nat) : Int) := by
    exact_mod_cast gamma_domination j
  push_cast at hcast
  have key : (2 * (2 * (j : Int) + 8) + 6) * ((j : Int) + 1) = ((j : Int) + 1) * (4 * (j : Int) + 22) := by
    ring_uor
  omega

/-- **Pairwise Cauchy (lower)**: for `j ≤ k`, `gSeqDyadic k − gSeqDyadic j ≥ −1/(j+1)`. -/
theorem gamma_pair_ge {j k : Nat} (hjk : j ≤ k) :
    Rle (Rneg (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) (Rsub (gSeqDyadic k) (gSeqDyadic j)) := by
  simp only [gSeqDyadic]
  obtain ⟨e, he⟩ := Nat.le.dest (gammaMidx_mono hjk)
  rw [← he]
  refine Rle_trans (Rle_Rneg ?_) (gSeq_diff_ge_outer (gammaMidx j) e)
  have hmid1 : 0 < (Qsub (⟨(2 * gammaMidx j + 6 : Int), 2 ^ gammaMidx j⟩ : Q)
      ⟨(2 * (gammaMidx j + e) + 6 : Int), 2 ^ (gammaMidx j + e)⟩).den :=
    Qsub_den_pos (Nat.pos_pow_of_pos _ (by decide)) (Nat.pos_pow_of_pos _ (by decide))
  have hmid2 : 0 < (⟨(2 * gammaMidx j + 6 : Int), 2 ^ gammaMidx j⟩ : Q).den :=
    Nat.pos_pow_of_pos _ (by decide)
  exact Rle_trans (Rle_ofQ_ofQ (Wsum_den_pos (gammaMidx j) e) hmid1 (Wsum_tail_le (gammaMidx j) e))
    (Rle_trans (Rle_ofQ_ofQ hmid1 hmid2
      (Qsub_le_left _ (2 * (gammaMidx j + e) + 6) (by omega) _ _))
      (Rle_ofQ_ofQ hmid2 (Nat.succ_pos j) (gamma_T_le j)))

/-- **The reindexed sequence is regular** (`RReg`): pairwise `|gSeqDyadic j − gSeqDyadic k| ≤
    1/(j+1) + 1/(k+1)`, from the two pairwise Cauchy bounds. The input to Bishop's `Rlim`. -/
theorem gSeqDyadic_RReg : RReg gSeqDyadic := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · exact Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (gSeqDyadic k) (gSeqDyadic j))))
      (Rle_trans (Rle_trans (Rle_Rneg (gamma_pair_ge hjk)) (Rle_of_Req (Rneg_neg _)))
        (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (by show (0 : Int) ≤ 1; decide))))
  · exact Rle_trans (gamma_pair_le hkj)
      (Rle_ofQ_ofQ (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Qle_trans (b := add ⟨1, k + 1⟩ ⟨1, j + 1⟩)
          (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qle_self_add (p := ⟨1, j + 1⟩) (by show (0 : Int) ≤ 1; decide))
          (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))))

/-- **The first Stieltjes constant `γ₁`**, as a genuine constructive real: the Bishop limit of the
    reindexed defining sequence `gSeq(2^{2j+8})`. `γ₁ ≈ −0.07282`. -/
def Rgamma1 : Real := Rlim gSeqDyadic gSeqDyadic_RReg

-- ===========================================================================
-- One-sided Archimedean: `a − b ≤ C/(k+1)` for every `k` ⟹ `a ≤ b`. (The numeric γ₁ bound input.)
-- ===========================================================================

/-- **One-sided Archimedean**: if `a − b ≤ C/(k+1)` (as reals) for *every* `k`, then `a ≤ b`. The
    half of `Req_of_Rle_ofQ_all` that gives the inequality (vanishing real bound forces `≤`). -/
theorem Rle_of_Rsub_le_all {a b : Real} {C : Nat}
    (hab : ∀ k, Rle (Rsub a b) (ofQ ⟨(C : Int), k + 1⟩ (Nat.succ_pos k))) : Rle a b := by
  intro n
  have hub : Qle (Qsub (a.seq n) (b.seq n)) ⟨2, n + 1⟩ := by
    apply Qarch_gen (C := C) (Qsub_den_pos (a.den_pos n) (b.den_pos n)) (Nat.succ_pos n)
    intro k
    exact Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      (seq_diff_le a b ⟨(C : Int), k + 1⟩ (Nat.succ_pos k) (hab k) n)
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  exact Qle_add_of_Qsub_le (a.den_pos n) (b.den_pos n) (Nat.succ_pos n) hub

/-- `x − y ≤ z ⟹ x ≤ y + z` (real). -/
theorem Rle_add_of_Rsub_le {x y z : Real} (h : Rle (Rsub x y) z) : Rle x (Radd y z) := by
  have heq : Req (Radd (Rsub x y) y) x :=
    Req_trans (Radd_assoc x (Rneg y) y)
      (Req_trans (Radd_congr (Req_refl x) (Req_trans (Radd_comm (Rneg y) y) (Radd_neg y)))
        (Radd_zero x))
  exact Rle_trans (Rle_of_Req (Req_symm heq))
    (Rle_trans (Radd_le_add h (Rle_refl y)) (Rle_of_Req (Radd_comm z y)))

/-- **`gSeq M ≤ gSeq N + 1/(2N)`** for `M ≥ N ≥ 1` (the upper gap bound, collapsed to a single anchor). -/
theorem gSeq_le_anchor {N M : Nat} (hN : 1 ≤ N) (hNM : N ≤ M) :
    Rle (gSeq M) (Radd (gSeq N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hNM
  exact Rle_add_of_Rsub_le
    (Rle_trans (gSeq_diff_le N hN d) (Rle_ofQ_ofQ _ _ (Qsub_unit_le (2 * N) (2 * (N + d)))))

/-- **`γ₁ ≤ gSeq N + 1/(2N)`** for any small `N ∈ [1, 256]`: each reindexed term `gSeqDyadic k`
    (`= gSeq(2^{2k+8})`, with `2^{2k+8} ≥ 256 ≥ N`) is `≤ gSeq N + 1/(2N)`, so the limit is too
    (one-sided Archimedean via the `RTendsTo` rate `2/(k+1)`). -/
theorem Rgamma1_le_gSeq {N : Nat} (hN : 1 ≤ N) (hN256 : N ≤ 256) :
    Rle Rgamma1 (Radd (gSeq N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have hN2k : N ≤ 2 ^ (2 * k + 8) := by
    have h8 : (2 : Nat) ^ 8 ≤ 2 ^ (2 * k + 8) := Nat.pow_le_pow_right (by omega) (by omega)
    have : (256 : Nat) = 2 ^ 8 := by decide
    omega
  have htend : Rle (Rsub Rgamma1 (gSeqDyadic k)) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    RTendsTo_to_Rle_lower (Rlim_tendsTo gSeqDyadic gSeqDyadic_RReg) k
  have hanchor : Rle (gSeqDyadic k)
      (Radd (gSeq N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) :=
    gSeq_le_anchor hN hN2k
  have hzB : Req (Radd zero (Radd (gSeq N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))))
      (Radd (gSeq N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) :=
    Req_trans (Radd_comm zero _) (Radd_zero _)
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split Rgamma1 (gSeqDyadic k) _))) ?_
  refine Rle_trans (Radd_le_add htend
    (Rsub_le_of_le_add (Rle_trans hanchor (Rle_of_Req (Req_symm hzB))))) ?_
  exact Rle_of_Req (Radd_zero _)

-- ===========================================================================
-- **`γ₁ ≤ −0.0445`** — the numeric gate to `Pos λ₂`. With `γ₁ ≤ g(200) + 1/400` (`Rgamma1_le_gSeq`)
-- and `g(200) ≤ ofQ(gBound 2 10⁶ 200)` (`gSeq_le_gBound`), the bound reduces to one big-integer
-- comparison `gBound 2 10⁶ 200 + 1/400 ≤ −445/10000`, discharged by a kernel `decide` (≈ −0.0512,
-- margin ≈ 0.007; depth `T = 2`, denominator `D = 10⁶`). Axiom-free.
-- ===========================================================================

set_option maxRecDepth 20000 in
/-- The numeric heart: `gBound 2 10⁶ 200 + 1/400 ≤ −445/10000` — a single big-integer comparison
    (kernel `decide`, no `native_decide`). -/
theorem gBound200_le_neg :
    Qle (add (gBound 2 1000000 200) (⟨1, 2 * 200⟩ : Q)) (⟨-445, 10000⟩ : Q) := by decide

/-- **`γ₁ ≤ −0.0445`** (`= −445/10000`) — the first Stieltjes constant's numeric upper bound, the gate to
    `Pos λ₂` (`λ₂ = 1 + γ − γ² − 2γ₁ − log 4π + ¾ζ(2)`, where `−2γ₁ ≥ 0.089`). Chains the constructive
    `Rgamma1 = Rlim gSeqDyadic` to `g(200) + 1/400` (`Rgamma1_le_gSeq`), then to `ofQ(gBound 2 10⁶ 200)`
    (`gSeq_le_gBound`, the tight artanh-telescope log bounds at fixed denominator), then the numeric
    `gBound200_le_neg`. -/
theorem Rgamma1_le_neg445 : Rle Rgamma1 (ofQ (⟨-445, 10000⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma1_le_gSeq (show 1 ≤ 200 by decide) (show 200 ≤ 256 by decide)) ?_
  refine Rle_trans (Radd_le_add (gSeq_le_gBound 2 1000000 200 (by decide) (by decide))
    (Rle_refl _)) ?_
  have hgbd : 0 < (gBound 2 1000000 200).den := gBound_den_pos 2 1000000 200 (by decide)
  have h200 : 0 < (⟨1, 2 * 200⟩ : Q).den := Nat.mul_pos (by decide) (by decide)
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hgbd h200)) ?_
  exact Rle_ofQ_ofQ (add_den_pos hgbd h200) (by decide) gBound200_le_neg

set_option maxRecDepth 40000 in
/-- The tighter numeric heart at artanh depth `T = 4`: `gBound 4 10⁶ 200 + 1/400 ≤ −55/1000`
    (kernel `decide`). The deeper per-term log bounds (`T = 4` vs `T = 2`) shrink the `gBound`
    over-estimate, pushing the bracket from `−0.0445` to `−0.055`. -/
theorem gBound200_T4_le_neg055 :
    Qle (add (gBound 4 1000000 200) (⟨1, 2 * 200⟩ : Q)) (⟨-55, 1000⟩ : Q) := by decide

/-- **`γ₁ ≤ −0.055`** — a tighter upper bracket on the first Stieltjes constant (true `≈ −0.0728`),
    via artanh depth `T = 4` (vs `Rgamma1_le_neg445`'s `T = 2`). Same chain
    (`Rgamma1_le_gSeq` → `gSeq_le_gBound` → numeric), tightening the dominant `−6γ₁` contribution to the
    `Pos Rlambda3` (`λ₃`) certificate. The residual gap to the true value is the `gSeq` Euler–Maclaurin
    overshoot `+(ln N)/(2N)` (the convergence, not the bound depth — raising `T` further plateaus),
    whose removal is the remaining `GammaTwoBracket`-scale acceleration. -/
theorem Rgamma1_le_neg055 : Rle Rgamma1 (ofQ (⟨-55, 1000⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma1_le_gSeq (show 1 ≤ 200 by decide) (show 200 ≤ 256 by decide)) ?_
  refine Rle_trans (Radd_le_add (gSeq_le_gBound 4 1000000 200 (by decide) (by decide))
    (Rle_refl _)) ?_
  have hgbd : 0 < (gBound 4 1000000 200).den := gBound_den_pos 4 1000000 200 (by decide)
  have h200 : 0 < (⟨1, 2 * 200⟩ : Q).den := Nat.mul_pos (by decide) (by decide)
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hgbd h200)) ?_
  exact Rle_ofQ_ofQ (add_den_pos hgbd h200) (by decide) gBound200_T4_le_neg055

end UOR.Bridge.F1Square.Analysis
