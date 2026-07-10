/-
F1 square — the everywhere-defined exponential `exp` on ℝ (the v0.12.0 transcendental, commit 2/2).

`exp(x)` for a *real* `x` is built as the **diagonal of rational partial sums**: the `j`-th approximant
is `S_{R j}(x_{R j})`, where `S_N(q) = Σ_{i≤N} qⁱ/i!` (already `expSum`, defined for any rational `q`)
and `R j` is a single reindex serving both the argument index and the truncation depth. The resulting
sequence of *rationals* is itself Bishop-regular — `|exp(x)_j − exp(x)_k| ≤ 1/(j+1) + 1/(k+1)` — so it
*is* a constructive real directly (no `ofQ`/`Rlim` needed). The regularity rests on three rational
bounds on `expSum`: a geometric tail bound (truncation, for `|q| ≤ M`), a Lipschitz bound, and a
factorial-growth estimate converting the tail to a `1/(j+1)` reindex. This file builds those bounds
(starting with the `qpow` facts), then assembles the diagonal.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.ExpGen
import F1Square.Analysis.Zeta
import F1Square.Analysis.Complete

namespace UOR.Bridge.F1Square.Analysis

/-- `a·(b·c) ≈ b·(a·c)`. -/
theorem Qmul_left_comm (a b c : Q) : Qeq (mul a (mul b c)) (mul b (mul a c)) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- `qⁿ⁺ᵐ ≈ qⁿ · qᵐ`. -/
theorem qpow_add (q : Q) (hqd : 0 < q.den) (a : Nat) :
    ∀ b, Qeq (qpow q (a + b)) (mul (qpow q a) (qpow q b))
  | 0 => by
      rw [Nat.add_zero]
      show Qeq (qpow q a) (mul (qpow q a) ⟨1, 1⟩)
      simp only [Qeq, mul]; push_cast; ring_uor
  | (b + 1) => by
      show Qeq (mul q (qpow q (a + b))) (mul (qpow q a) (mul q (qpow q b)))
      exact Qeq_trans (Qmul_den_pos hqd (Qmul_den_pos (qpow_den_pos hqd a) (qpow_den_pos hqd b)))
        (Qmul_congr (Qeq_refl q) (qpow_add q hqd a b))
        (Qmul_left_comm q (qpow q a) (qpow q b))

/-- `|qⁱ| = |q|ⁱ` (the absolute value of a power is the power of the absolute value). -/
theorem qpow_abs (q : Q) : ∀ i, Qeq (Qabs (qpow q i)) (qpow (Qabs q) i)
  | 0 => by rfl
  | (i + 1) => by
      have h1 : Qabs (qpow q (i + 1)) = mul (Qabs q) (Qabs (qpow q i)) := Qabs_mul q (qpow q i)
      rw [h1]
      show Qeq (mul (Qabs q) (Qabs (qpow q i))) (mul (Qabs q) (qpow (Qabs q) i))
      exact Qmul_congr (Qeq_refl (Qabs q)) (qpow_abs q i)

/-- Powers are monotone in the base on non-negative rationals: `0 ≤ a ≤ b ⟹ aⁱ ≤ bⁱ`. -/
theorem qpow_base_mono {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) (ha0 : 0 ≤ a.num)
    (hab : Qle a b) : ∀ i, Qle (qpow a i) (qpow b i)
  | 0 => Qle_refl _
  | (i + 1) => by
      show Qle (mul a (qpow a i)) (mul b (qpow b i))
      exact Qmul_le_mul ha hb (qpow_den_pos ha i) ha0 (qpow_nonneg ha0 i) hab
        (qpow_base_mono ha hb ha0 hab i)

-- ===========================================================================
-- The dominating series `Σ Mⁱ/i!` (integer `M ≥ 1`) and its rigorous tail bound.
-- ===========================================================================

/-- The partial sums `Σ_{i=0}^N Mⁱ/i!` of the exponential series at an integer `M`. -/
def expSumM (M : Nat) : Nat → Q
  | 0 => ⟨1, 1⟩
  | (n + 1) => add (expSumM M n) ⟨(npow M (n + 1) : Int), fct (n + 1)⟩

theorem expSumM_den_pos (M : Nat) : ∀ N, 0 < (expSumM M N).den
  | 0 => Nat.one_pos
  | (n + 1) => add_den_pos (expSumM_den_pos M n) (fct_pos (n + 1))

theorem expSumM_step (M N : Nat) : Qle (expSumM M N) (expSumM M (N + 1)) := by
  show Qle (expSumM M N) (add (expSumM M N) ⟨(npow M (N + 1) : Int), fct (N + 1)⟩)
  exact Qle_self_add (Int.ofNat_nonneg _)

theorem expSumM_le (M : Nat) {a b : Nat} (hab : a ≤ b) : Qle (expSumM M a) (expSumM M b) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (expSumM_den_pos M _) ih (expSumM_step M _)

-- The telescoping-step inequality `2(m·p)·f ≤ p·((n+2)·f)` from `2m ≤ n+2` (explicit-ℤ core so
-- `ring_uor` reifies clean variables, not cast atoms).
private theorem expM_step_core (m p f n : Int) (hf : 0 ≤ p * f) (hkey : 2 * m ≤ n + 2) :
    2 * (m * p) * f ≤ p * ((n + 2) * f) := by
  have hmul := Int.mul_le_mul_of_nonneg_right hkey hf
  have e1 : 2 * (m * p) * f = 2 * m * (p * f) := by ring_uor
  have e2 : p * ((n + 2) * f) = (n + 2) * (p * f) := by ring_uor
  rw [e1, e2]; exact hmul

/-- The telescoping step for the `M`-series: `Mᴺ⁺¹/(N+1)! + 2Mᴺ⁺²/(N+2)! ≤ 2Mᴺ⁺¹/(N+1)!`, valid once
    `2M ≤ N+2` (where the series enters its geometric tail). -/
theorem expM_step_le (M N : Nat) (h : 2 * M ≤ N + 2) :
    Qle (add (⟨(npow M (N + 1) : Int), fct (N + 1)⟩ : Q) ⟨(2 * npow M (N + 2) : Int), fct (N + 2)⟩)
        ⟨(2 * npow M (N + 1) : Int), fct (N + 1)⟩ := by
  have h1 : Qle (⟨(2 * npow M (N + 2) : Int), fct (N + 2)⟩ : Q) ⟨(npow M (N + 1) : Int), fct (N + 1)⟩ := by
    unfold Qle
    rw [fct_succ (N + 1), npow_succ M (N + 1)]
    push_cast
    exact expM_step_core (M : Int) (npow M (N + 1) : Int) (fct (N + 1) : Int) (N : Int)
      (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)) (by exact_mod_cast h)
  exact Qle_trans (add_den_pos (fct_pos _) (fct_pos _))
    (Qadd_le_add (Qle_refl _) h1)
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))

/-- The telescoping upper sequence `U(N) := S_M(N) + 2Mᴺ⁺¹/(N+1)!`. -/
def expM_U (M N : Nat) : Q := add (expSumM M N) ⟨(2 * npow M (N + 1) : Int), fct (N + 1)⟩

theorem expM_U_den_pos (M N : Nat) : 0 < (expM_U M N).den :=
  add_den_pos (expSumM_den_pos M N) (fct_pos (N + 1))

/-- `U` is decreasing once `2M ≤ N+2`. -/
theorem expM_U_step (M N : Nat) (h : 2 * M ≤ N + 2) : Qle (expM_U M (N + 1)) (expM_U M N) := by
  have hassoc : Qeq (expM_U M (N + 1))
      (add (expSumM M N) (add (⟨(npow M (N + 1) : Int), fct (N + 1)⟩ : Q)
        ⟨(2 * npow M (N + 2) : Int), fct (N + 2)⟩)) :=
    add_assoc (expSumM M N) ⟨(npow M (N + 1) : Int), fct (N + 1)⟩
      ⟨(2 * npow M (N + 2) : Int), fct (N + 2)⟩
  refine Qle_congr_left
    (add_den_pos (expSumM_den_pos M N) (add_den_pos (fct_pos _) (fct_pos _)))
    (Qeq_symm hassoc) ?_
  exact Qadd_le_add (Qle_refl (expSumM M N)) (expM_step_le M N h)

/-- `U` is decreasing on the geometric tail `a ≥ 2M − 2`. -/
theorem expM_U_le (M : Nat) {a b : Nat} (ha2 : 2 * M ≤ a + 2) (hab : a ≤ b) :
    Qle (expM_U M b) (expM_U M a) := by
  induction hab with
  | refl => exact Qle_refl _
  | @step k hk ih =>
      have hkb : 2 * M ≤ k + 2 := Nat.le_trans ha2 (Nat.add_le_add_right hk 2)
      exact Qle_trans (expM_U_den_pos M _) (expM_U_step M k hkb) ih

/-- **The rigorous tail bound for the `M`-series**: for `2M ≤ a ≤ b`,
    `S_M(b) − S_M(a) ≤ 2Mᵃ⁺¹/(a+1)!`. -/
theorem expM_diff_bound (M : Nat) {a b : Nat} (ha2 : 2 * M ≤ a + 2) (hab : a ≤ b) :
    Qle (Qsub (expSumM M b) (expSumM M a)) ⟨(2 * npow M (a + 1) : Int), fct (a + 1)⟩ := by
  have hb : Qle (expSumM M b) (add (expSumM M a) ⟨(2 * npow M (a + 1) : Int), fct (a + 1)⟩) :=
    Qle_trans (expM_U_den_pos M b) (Qle_self_add (Int.ofNat_nonneg _)) (expM_U_le M ha2 hab)
  have hsub := Qsub_le_sub (z := expSumM M a) hb
  refine Qle_trans
    (Qsub_den_pos (add_den_pos (expSumM_den_pos M a) (fct_pos _)) (expSumM_den_pos M a)) hsub ?_
  exact Qeq_le (Qsub_add_cancel (expSumM M a) ⟨(2 * npow M (a + 1) : Int), fct (a + 1)⟩)

-- ===========================================================================
-- Termwise domination: a general-q exp partial-sum gap is bounded by the M-series gap.
-- ===========================================================================

/-- `qⁱ` at an integer base `M`: `(M/1)ⁱ = Mⁱ/1`. -/
theorem qpow_nat_base (M : Nat) : ∀ i, qpow (⟨(M : Int), 1⟩ : Q) i = ⟨(npow M i : Int), 1⟩
  | 0 => rfl
  | (i + 1) => by
      have hc : ((npow M (i + 1) : Nat) : Int) = (M : Int) * ((npow M i : Nat) : Int) := by
        rw [npow_succ]; push_cast; ring_uor
      rw [qpow_succ, qpow_nat_base M i, hc]
      rfl

/-- **Termwise domination**: `|qⁱ/i!| ≤ Mⁱ/i!` when `|q| ≤ M`. -/
theorem expTerm_abs_le_M {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (i : Nat) : Qle (Qabs (expTerm q i)) ⟨(npow M i : Int), fct i⟩ := by
  -- |qⁱ| ≤ Mⁱ
  have hpowabs : Qle (Qabs (qpow q i)) ⟨(npow M i : Int), 1⟩ := by
    have h1 : Qle (Qabs (qpow q i)) (qpow (Qabs q) i) := Qeq_le (qpow_abs q i)
    have h2 : Qle (qpow (Qabs q) i) (qpow (⟨(M : Int), 1⟩ : Q) i) :=
      qpow_base_mono (Qabs_den_pos hqd) Nat.one_pos (Qabs_num_nonneg q) hq i
    have h3 : qpow (⟨(M : Int), 1⟩ : Q) i = ⟨(npow M i : Int), 1⟩ := qpow_nat_base M i
    rw [h3] at h2
    exact Qle_trans (qpow_den_pos (Qabs_den_pos hqd) i) h1 h2
  -- multiply by 1/i!
  have hmul := Qmul_le_mul_right (a := Qabs (qpow q i)) (b := ⟨(npow M i : Int), 1⟩)
    (c := ⟨1, fct i⟩) (by show (0:Int) ≤ 1; decide) hpowabs
  -- |expTerm q i| = |qⁱ|·(1/i!)  and  Mⁱ·(1/i!) ≈ Mⁱ/i!
  have he1 : Qabs (expTerm q i) = mul (Qabs (qpow q i)) ⟨1, fct i⟩ := by
    show Qabs (mul (qpow q i) ⟨1, fct i⟩) = mul (Qabs (qpow q i)) ⟨1, fct i⟩
    rw [Qabs_mul]; rfl
  rw [he1]
  refine Qle_trans (Qmul_den_pos Nat.one_pos (fct_pos i)) hmul (Qeq_le ?_)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **Truncation domination**: for `|q| ≤ M` and `a ≤ b`, the general-`q` partial-sum gap is bounded
    (in absolute value) by the `M`-series gap. (Triangle inequality over the added terms.) -/
theorem expSum_abs_diff_le_M {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (expSum q b) (expSum q a))) (Qsub (expSumM M b) (expSumM M a)) := by
  induction hab with
  | refl =>
      have h := Qsub_self_num (expSum q a)
      have h' := Qsub_self_num (expSumM M a)
      unfold Qle Qabs
      rw [h, h']; simp
  | @step k _ ih =>
      have hstep : Qle (Qabs (Qsub (expSum q (k + 1)) (expSum q a)))
          (add (Qabs (Qsub (expSum q k) (expSum q a))) (Qabs (expTerm q (k + 1)))) := by
        have heqabs := Qabs_Qeq (Qsub_add_right (expSum q k) (expTerm q (k + 1)) (expSum q a))
        refine Qle_congr_left
          (Qabs_den_pos (add_den_pos (Qsub_den_pos (expSum_den_pos hqd k) (expSum_den_pos hqd a))
            (expTerm_den_pos hqd (k + 1)))) (Qeq_symm heqabs) (Qabs_add_le _ _)
      have hbound : Qle (add (Qabs (Qsub (expSum q k) (expSum q a))) (Qabs (expTerm q (k + 1))))
          (add (Qsub (expSumM M k) (expSumM M a)) ⟨(npow M (k + 1) : Int), fct (k + 1)⟩) :=
        Qadd_le_add ih (expTerm_abs_le_M hqd hq (k + 1))
      have hregroupM : Qeq (add (Qsub (expSumM M k) (expSumM M a)) ⟨(npow M (k + 1) : Int), fct (k + 1)⟩)
          (Qsub (expSumM M (k + 1)) (expSumM M a)) :=
        Qeq_symm (Qsub_add_right (expSumM M k) ⟨(npow M (k + 1) : Int), fct (k + 1)⟩ (expSumM M a))
      refine Qle_trans
        (add_den_pos (Qabs_den_pos (Qsub_den_pos (expSum_den_pos hqd k) (expSum_den_pos hqd a)))
          (Qabs_den_pos (expTerm_den_pos hqd (k + 1))))
        hstep
        (Qle_trans
          (add_den_pos (Qsub_den_pos (expSumM_den_pos M k) (expSumM_den_pos M a)) (fct_pos _))
          hbound (Qeq_le hregroupM))

/-- **The truncation tail bound**: for `|q| ≤ M` and `2M ≤ a ≤ b`,
    `|S_q(b) − S_q(a)| ≤ 2Mᵃ⁺¹/(a+1)!`. -/
theorem expSum_trunc_bound {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    {a b : Nat} (ha2 : 2 * M ≤ a + 2) (hab : a ≤ b) :
    Qle (Qabs (Qsub (expSum q b) (expSum q a))) ⟨(2 * npow M (a + 1) : Int), fct (a + 1)⟩ :=
  Qle_trans (Qsub_den_pos (expSumM_den_pos M b) (expSumM_den_pos M a))
    (expSum_abs_diff_le_M hqd hq hab) (expM_diff_bound M ha2 hab)

-- ===========================================================================
-- Lipschitz: the per-power difference bound `|qⁱ − q'ⁱ| ≤ (i·Mⁱ⁻¹)·|q−q'|`.
-- ===========================================================================

/-- `|qⁱ| ≤ Mⁱ` when `|q| ≤ M` (the power's absolute value is dominated). -/
theorem qpow_abs_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (i : Nat) :
    Qle (Qabs (qpow q i)) ⟨(npow M i : Int), 1⟩ := by
  have h1 : Qle (Qabs (qpow q i)) (qpow (Qabs q) i) := Qeq_le (qpow_abs q i)
  have h2 : Qle (qpow (Qabs q) i) (qpow (⟨(M : Int), 1⟩ : Q) i) :=
    qpow_base_mono (Qabs_den_pos hqd) Nat.one_pos (Qabs_num_nonneg q) hq i
  rw [qpow_nat_base M i] at h2
  exact Qle_trans (qpow_den_pos (Qabs_den_pos hqd) i) h1 h2

/-- The Lipschitz coefficient `i·Mⁱ⁻¹` for `qⁱ`, recursively (avoiding `i−1`):
    `P(0)=0`, `P(i+1)=M·P(i) + Mⁱ`. -/
def Pbound (M : Nat) : Nat → Nat
  | 0 => 0
  | (i + 1) => M * Pbound M i + npow M i

/-- **Per-power Lipschitz bound**: `|qⁱ − q'ⁱ| ≤ (i·Mⁱ⁻¹)·|q − q'|` when `|q|,|q'| ≤ M`. -/
theorem qpow_diff_bound {q q' : Q} {M : Nat} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) :
    ∀ i, Qle (Qabs (Qsub (qpow q i) (qpow q' i)))
      (mul ⟨(Pbound M i : Int), 1⟩ (Qabs (Qsub q q')))
  | 0 => by
      show Qle (Qabs (Qsub (qpow q 0) (qpow q' 0))) (mul ⟨(0 : Int), 1⟩ (Qabs (Qsub q q')))
      have h0 : (Qsub (qpow q 0) (qpow q' 0)).num = 0 := rfl
      unfold Qle Qabs mul
      rw [h0]; simp
  | (i + 1) => by
      have ihh := qpow_diff_bound hqd hq'd hq hq' i
      have hqpid : 0 < (qpow q i).den := qpow_den_pos hqd i
      have hqp'id : 0 < (qpow q' i).den := qpow_den_pos hq'd i
      -- identity: q^{i+1} − q'^{i+1} = q·(qⁱ − q'ⁱ) + (q − q')·q'ⁱ
      have hid : Qeq (Qsub (qpow q (i + 1)) (qpow q' (i + 1)))
          (add (mul q (Qsub (qpow q i) (qpow q' i))) (mul (Qsub q q') (qpow q' i))) := by
        show Qeq (Qsub (mul q (qpow q i)) (mul q' (qpow q' i)))
          (add (mul q (Qsub (qpow q i) (qpow q' i))) (mul (Qsub q q') (qpow q' i)))
        simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
      -- triangle
      have htri : Qle (Qabs (Qsub (qpow q (i + 1)) (qpow q' (i + 1))))
          (add (Qabs (mul q (Qsub (qpow q i) (qpow q' i))))
            (Qabs (mul (Qsub q q') (qpow q' i)))) :=
        Qle_congr_left
          (Qabs_den_pos (add_den_pos (Qmul_den_pos hqd (Qsub_den_pos hqpid hqp'id))
            (Qmul_den_pos (Qsub_den_pos hqd hq'd) hqp'id)))
          (Qeq_symm (Qabs_Qeq hid)) (Qabs_add_le _ _)
      -- bound each summand
      have hP1 : Qle (Qabs (mul q (Qsub (qpow q i) (qpow q' i))))
          (mul ⟨(M : Int), 1⟩ (mul ⟨(Pbound M i : Int), 1⟩ (Qabs (Qsub q q')))) := by
        rw [Qabs_mul]
        exact Qmul_le_mul (Qabs_den_pos hqd) Nat.one_pos
          (Qabs_den_pos (Qsub_den_pos hqpid hqp'id)) (Qabs_num_nonneg q) (Qabs_num_nonneg _) hq ihh
      have hP2 : Qle (Qabs (mul (Qsub q q') (qpow q' i)))
          (mul (Qabs (Qsub q q')) ⟨(npow M i : Int), 1⟩) := by
        rw [Qabs_mul]
        exact Qmul_le_mul_left (Qabs_num_nonneg _) (qpow_abs_le hq'd hq' i)
      have hsum := Qadd_le_add hP1 hP2
      -- regroup to Pbound M (i+1) · |q − q'|
      have hfactor : Qeq
          (add (mul ⟨(M : Int), 1⟩ (mul ⟨(Pbound M i : Int), 1⟩ (Qabs (Qsub q q'))))
            (mul (Qabs (Qsub q q')) ⟨(npow M i : Int), 1⟩))
          (mul ⟨(Pbound M (i + 1) : Int), 1⟩ (Qabs (Qsub q q'))) := by
        simp only [Pbound, Qeq, mul, add]; push_cast; ring_uor
      refine Qle_trans ?_ htri (Qle_trans ?_ hsum (Qeq_le hfactor))
      · exact add_den_pos (Qabs_den_pos (Qmul_den_pos hqd (Qsub_den_pos hqpid hqp'id)))
          (Qabs_den_pos (Qmul_den_pos (Qsub_den_pos hqd hq'd) hqp'id))
      · exact add_den_pos (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
          (Qabs_den_pos (Qsub_den_pos hqd hq'd))))
          (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hqd hq'd)) Nat.one_pos)

/-- **Per-term Lipschitz bound**: `|qⁱ/i! − q'ⁱ/i!| ≤ (Pbound M i / i!)·|q − q'|`. -/
theorem expTerm_diff_bound {q q' : Q} {M : Nat} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) (i : Nat) :
    Qle (Qabs (Qsub (expTerm q i) (expTerm q' i)))
      (mul ⟨(Pbound M i : Int), fct i⟩ (Qabs (Qsub q q'))) := by
  have hfac : Qeq (Qsub (expTerm q i) (expTerm q' i))
      (mul (Qsub (qpow q i) (qpow q' i)) ⟨1, fct i⟩) := by
    show Qeq (Qsub (mul (qpow q i) ⟨1, fct i⟩) (mul (qpow q' i) ⟨1, fct i⟩))
      (mul (Qsub (qpow q i) (qpow q' i)) ⟨1, fct i⟩)
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  have heq1 : Qeq (Qabs (Qsub (expTerm q i) (expTerm q' i)))
      (mul (Qabs (Qsub (qpow q i) (qpow q' i))) ⟨1, fct i⟩) := by
    have h := Qabs_Qeq hfac
    rw [Qabs_mul, show Qabs (⟨1, fct i⟩ : Q) = ⟨1, fct i⟩ from rfl] at h
    exact h
  have hb1 : Qle (mul (Qabs (Qsub (qpow q i) (qpow q' i))) ⟨1, fct i⟩)
      (mul (mul ⟨(Pbound M i : Int), 1⟩ (Qabs (Qsub q q'))) ⟨1, fct i⟩) :=
    Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide) (qpow_diff_bound hqd hq'd hq hq' i)
  have heq2 : Qeq (mul (mul ⟨(Pbound M i : Int), 1⟩ (Qabs (Qsub q q'))) ⟨1, fct i⟩)
      (mul ⟨(Pbound M i : Int), fct i⟩ (Qabs (Qsub q q'))) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  exact Qle_trans
    (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (qpow_den_pos hqd i) (qpow_den_pos hq'd i))) (fct_pos i))
    (Qeq_le heq1)
    (Qle_trans (Qmul_den_pos (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hqd hq'd)))
      (fct_pos i)) hb1 (Qeq_le heq2))

/-- The Lipschitz partial sum `Σ_{i=0}^N Pbound M i / i!`. -/
def LipS (M : Nat) : Nat → Q
  | 0 => ⟨(Pbound M 0 : Int), fct 0⟩
  | (n + 1) => add (LipS M n) ⟨(Pbound M (n + 1) : Int), fct (n + 1)⟩

theorem LipS_den_pos (M : Nat) : ∀ N, 0 < (LipS M N).den
  | 0 => fct_pos 0
  | (n + 1) => add_den_pos (LipS_den_pos M n) (fct_pos (n + 1))

/-- **The Lipschitz sum bound**: `|S_q(N) − S_{q'}(N)| ≤ (LipS M N)·|q − q'|`. -/
theorem expSum_Lip_le {q q' : Q} {M : Nat} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) :
    ∀ N, Qle (Qabs (Qsub (expSum q N) (expSum q' N))) (mul (LipS M N) (Qabs (Qsub q q')))
  | 0 => by
      have h0 : (Qsub (expSum q 0) (expSum q' 0)).num = 0 := rfl
      unfold Qle Qabs
      rw [h0]; simp [LipS, Pbound, mul]
  | (N + 1) => by
      have ih := expSum_Lip_le hqd hq'd hq hq' N
      have hAd : 0 < (expSum q N).den := expSum_den_pos hqd N
      have hCd : 0 < (expSum q' N).den := expSum_den_pos hq'd N
      have hBd : 0 < (expTerm q (N + 1)).den := expTerm_den_pos hqd (N + 1)
      have hDd : 0 < (expTerm q' (N + 1)).den := expTerm_den_pos hq'd (N + 1)
      refine Qle_trans
        (add_den_pos (Qabs_den_pos (Qsub_den_pos hAd hCd)) (Qabs_den_pos (Qsub_den_pos hBd hDd)))
        (Qabs_sub_add4 hAd hBd hCd hDd)
        (Qle_trans
          (add_den_pos (Qmul_den_pos (LipS_den_pos M N) (Qabs_den_pos (Qsub_den_pos hqd hq'd)))
            (Qmul_den_pos (fct_pos (N + 1)) (Qabs_den_pos (Qsub_den_pos hqd hq'd))))
          (Qadd_le_add ih (expTerm_diff_bound hqd hq'd hq hq' (N + 1)))
          (Qeq_le (Qeq_symm (Qmul_add_right (LipS M N)
            ⟨(Pbound M (N + 1) : Int), fct (N + 1)⟩ (Qabs (Qsub q q'))))))

/-- Closed form of the Lipschitz coefficient: `Pbound M (i+1) = (i+1)·Mⁱ`. -/
theorem Pbound_closed (M : Nat) : ∀ i, Pbound M (i + 1) = (i + 1) * npow M i
  | 0 => by simp [Pbound, npow]
  | (i + 1) => by
      show M * Pbound M (i + 1) + npow M (i + 1) = (i + 1 + 1) * npow M (i + 1)
      rw [Pbound_closed M i]
      have hgoal : (M : Int) * (((i : Int) + 1) * (npow M i : Int)) + (npow M (i + 1) : Int)
          = ((i : Int) + 1 + 1) * (npow M (i + 1) : Int) := by
        rw [npow_succ]; push_cast; ring_uor
      exact_mod_cast hgoal

/-- The `M`-series partial sum is bounded by its tail-`U` value at `2M`, for every `N`. -/
theorem expSumM_le_U (M N : Nat) : Qle (expSumM M N) (expM_U M (2 * M)) := by
  rcases Nat.le_total N (2 * M) with h | h
  · exact Qle_trans (expSumM_den_pos M (2 * M)) (expSumM_le M h)
      (Qle_self_add (Int.ofNat_nonneg _))
  · exact Qle_trans (expM_U_den_pos M N) (Qle_self_add (Int.ofNat_nonneg _))
      (expM_U_le M (by omega) h)

/-- The Lipschitz partial sum shifts to the `M`-series: `LipS M (N+1) ≈ S_M(N)`. -/
theorem LipS_shift (M : Nat) : ∀ N, Qeq (LipS M (N + 1)) (expSumM M N)
  | 0 => rfl
  | (N + 1) => by
      have hterm : Qeq (⟨(Pbound M (N + 2) : Int), fct (N + 2)⟩ : Q)
          ⟨(npow M (N + 1) : Int), fct (N + 1)⟩ := by
        show (Pbound M (N + 2) : Int) * (fct (N + 1) : Int)
            = (npow M (N + 1) : Int) * (fct (N + 2) : Int)
        rw [Pbound_closed M (N + 1), fct_succ (N + 1)]
        push_cast; ring_uor
      show Qeq (add (LipS M (N + 1)) ⟨(Pbound M (N + 2) : Int), fct (N + 2)⟩)
        (add (expSumM M N) ⟨(npow M (N + 1) : Int), fct (N + 1)⟩)
      exact Qadd_congr (LipS_shift M N) hterm

/-- **The Lipschitz coefficient is uniformly bounded**: `LipS M N ≤ U_M(2M)` for every `N`. -/
theorem LipS_le_U (M : Nat) : ∀ N, Qle (LipS M N) (expM_U M (2 * M))
  | 0 => by
      have h : Qle (LipS M 0) (expSumM M 0) := by
        show Qle (⟨(0 : Int), fct 0⟩ : Q) ⟨1, 1⟩
        show (0 : Int) * 1 ≤ 1 * ((fct 0 : Nat) : Int)
        rw [Int.zero_mul, Int.one_mul]; exact Int.ofNat_nonneg _
      exact Qle_trans (expSumM_den_pos M 0) h (expSumM_le_U M 0)
  | (N + 1) =>
      Qle_trans (expSumM_den_pos M N) (Qeq_le (LipS_shift M N)) (expSumM_le_U M N)

-- ===========================================================================
-- Factorial growth: the super-fast factorial tail converts to a `1/(j+1)` reindex.
-- ===========================================================================

/-- `2ᵈ ≥ d + 1`. -/
theorem two_pow_ge (d : Nat) : d + 1 ≤ npow 2 d := by
  induction d with
  | zero => decide
  | succ n ih =>
      have : npow 2 (n + 1) = 2 * npow 2 n := npow_succ 2 n
      rw [this]
      have hpos : 1 ≤ npow 2 n := npow_pos (by decide) n
      omega

/-- **Factorial growth**: for `d ≥ 0`, `Mᵃ⁺¹·(2M+1)! · 2ᵈ ≤ (a+1)! · M²ᴹ⁺¹` with `a = 2M + d`
    (the factorial outpaces the exponential by a factor `2` every step past `2M`). -/
theorem fct_ge_geom (M : Nat) : ∀ d,
    npow M (2 * M + 1 + d) * fct (2 * M + 1) * npow 2 d
      ≤ fct (2 * M + 1 + d) * npow M (2 * M + 1)
  | 0 => by
      rw [show npow 2 0 = 1 from rfl, Nat.mul_one]
      exact Nat.le_of_eq (Nat.mul_comm _ _)
  | (d + 1) => by
      have ih := fct_ge_geom M d
      have ihInt : (npow M (2 * M + 1 + d) : Int) * (fct (2 * M + 1) : Int) * (npow 2 d : Int)
          ≤ (fct (2 * M + 1 + d) : Int) * (npow M (2 * M + 1) : Int) := by exact_mod_cast ih
      have goalInt : (npow M (2 * M + 1 + (d + 1)) : Int) * (fct (2 * M + 1) : Int)
            * (npow 2 (d + 1) : Int)
          ≤ (fct (2 * M + 1 + (d + 1)) : Int) * (npow M (2 * M + 1) : Int) := by
        have e1 : (npow M (2 * M + 1 + (d + 1)) : Int) * (fct (2 * M + 1) : Int) * (npow 2 (d + 1) : Int)
            = (2 * M : Int) * ((npow M (2 * M + 1 + d) : Int) * (fct (2 * M + 1) : Int)
              * (npow 2 d : Int)) := by
          rw [show 2 * M + 1 + (d + 1) = (2 * M + 1 + d) + 1 from by omega,
            npow_succ M (2 * M + 1 + d), npow_succ 2 d]; push_cast; ring_uor
        have e2 : (fct (2 * M + 1 + (d + 1)) : Int) * (npow M (2 * M + 1) : Int)
            = (((2 * M + 1 + d) + 1 : Nat) : Int) * ((fct (2 * M + 1 + d) : Int)
              * (npow M (2 * M + 1) : Int)) := by
          rw [show 2 * M + 1 + (d + 1) = (2 * M + 1 + d) + 1 from by omega,
            fct_succ (2 * M + 1 + d)]; push_cast; ring_uor
        rw [e1, e2]
        have s1 : (2 : Int) * (M : Int) * ((npow M (2 * M + 1 + d) : Int) * (fct (2 * M + 1) : Int)
              * (npow 2 d : Int))
            ≤ (2 : Int) * (M : Int) * ((fct (2 * M + 1 + d) : Int) * (npow M (2 * M + 1) : Int)) :=
          Int.mul_le_mul_of_nonneg_left ihInt (by omega)
        have s2 : (2 : Int) * (M : Int) * ((fct (2 * M + 1 + d) : Int) * (npow M (2 * M + 1) : Int))
            ≤ (((2 * M + 1 + d) + 1 : Nat) : Int) * ((fct (2 * M + 1 + d) : Int)
              * (npow M (2 * M + 1) : Int)) :=
          Int.mul_le_mul_of_nonneg_right (by push_cast; omega)
            (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
        exact Int.le_trans s1 s2
      exact_mod_cast goalInt

/-- **Truncation reindex**: `2·Mᵃ⁺¹·e ≤ (a+1)!` for `a = 2M + d` whenever `2e·M²ᴹ⁺¹ ≤ d+1`
    (so the factorial tail at depth `a` is `≤ 1/e`). -/
theorem trunc_reindex (M e d : Nat) (hM : 0 < M) (h : 2 * e * npow M (2 * M + 1) ≤ d + 1) :
    2 * npow M (2 * M + 1 + d) * e ≤ fct (2 * M + 1 + d) := by
  have h2eP : 2 * e * npow M (2 * M + 1) ≤ fct (2 * M + 1) * npow 2 d :=
    Nat.le_trans (Nat.le_trans h (two_pow_ge d)) (Nat.le_mul_of_pos_left _ (fct_pos (2 * M + 1)))
  have step1 : 2 * npow M (2 * M + 1 + d) * e * npow M (2 * M + 1)
      ≤ npow M (2 * M + 1 + d) * fct (2 * M + 1) * npow 2 d := by
    have hrw1 : 2 * npow M (2 * M + 1 + d) * e * npow M (2 * M + 1)
        = npow M (2 * M + 1 + d) * (2 * e * npow M (2 * M + 1)) := by
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
    have hrw2 : npow M (2 * M + 1 + d) * (fct (2 * M + 1) * npow 2 d)
        = npow M (2 * M + 1 + d) * fct (2 * M + 1) * npow 2 d := by
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
    rw [hrw1, ← hrw2]
    exact Nat.mul_le_mul (Nat.le_refl _) h2eP
  have chain : npow M (2 * M + 1) * (2 * npow M (2 * M + 1 + d) * e)
      ≤ npow M (2 * M + 1) * fct (2 * M + 1 + d) := by
    have e3 : npow M (2 * M + 1) * (2 * npow M (2 * M + 1 + d) * e)
        = 2 * npow M (2 * M + 1 + d) * e * npow M (2 * M + 1) := by
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
    have e4 : npow M (2 * M + 1) * fct (2 * M + 1 + d)
        = fct (2 * M + 1 + d) * npow M (2 * M + 1) := Nat.mul_comm _ _
    rw [e3, e4]
    exact Nat.le_trans step1 (fct_ge_geom M d)
  exact Nat.le_of_mul_le_mul_left chain (npow_pos hM (2 * M + 1))

/-- **General factorial decay** (coefficient form of `trunc_reindex`): if `c·Bⁱ ≤ d+1` at the base
    exponent `2B+1`, then `c·B^{2B+1+d} ≤ (2B+1+d)!`. Factorial beats the geometric `2^d` slack. -/
theorem npow_fct_decay (B c d : Nat) (hB : 0 < B) (h : c * npow B (2 * B + 1) ≤ d + 1) :
    c * npow B (2 * B + 1 + d) ≤ fct (2 * B + 1 + d) := by
  have hcP : c * npow B (2 * B + 1) ≤ fct (2 * B + 1) * npow 2 d :=
    Nat.le_trans (Nat.le_trans h (two_pow_ge d)) (Nat.le_mul_of_pos_left _ (fct_pos (2 * B + 1)))
  have step1 : c * npow B (2 * B + 1 + d) * npow B (2 * B + 1)
      ≤ npow B (2 * B + 1 + d) * fct (2 * B + 1) * npow 2 d := by
    have hrw1 : c * npow B (2 * B + 1 + d) * npow B (2 * B + 1)
        = npow B (2 * B + 1 + d) * (c * npow B (2 * B + 1)) := by
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
    have hrw2 : npow B (2 * B + 1 + d) * (fct (2 * B + 1) * npow 2 d)
        = npow B (2 * B + 1 + d) * fct (2 * B + 1) * npow 2 d := by
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
    rw [hrw1, ← hrw2]
    exact Nat.mul_le_mul (Nat.le_refl _) hcP
  have chain : npow B (2 * B + 1) * (c * npow B (2 * B + 1 + d))
      ≤ npow B (2 * B + 1) * fct (2 * B + 1 + d) := by
    have e3 : npow B (2 * B + 1) * (c * npow B (2 * B + 1 + d))
        = c * npow B (2 * B + 1 + d) * npow B (2 * B + 1) := by
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
    have e4 : npow B (2 * B + 1) * fct (2 * B + 1 + d) = fct (2 * B + 1 + d) * npow B (2 * B + 1) :=
      Nat.mul_comm _ _
    rw [e3, e4]
    exact Nat.le_trans step1 (fct_ge_geom B d)
  exact Nat.le_of_mul_le_mul_left chain (npow_pos hB (2 * B + 1))

/-- **Coefficient truncation bound**: `c·B^{2B+1+d}/(2B+1+d)! ≤ 1/e` when `c·e·Bⁱ ≤ d+1` (base exp `2B+1`). -/
theorem truncCoef_Q (B c e d : Nat) (hB : 0 < B) (h : c * e * npow B (2 * B + 1) ≤ d + 1) :
    Qle (⟨(c * npow B (2 * B + 1 + d) : Int), fct (2 * B + 1 + d)⟩ : Q) ⟨1, e⟩ := by
  have key : c * npow B (2 * B + 1 + d) * e ≤ fct (2 * B + 1 + d) := by
    rw [Nat.mul_right_comm c (npow B (2 * B + 1 + d)) e]
    exact npow_fct_decay B (c * e) d hB h
  show (c * npow B (2 * B + 1 + d) : Int) * ((e : Nat) : Int) ≤ 1 * ((fct (2 * B + 1 + d) : Nat) : Int)
  have hI : ((c * npow B (2 * B + 1 + d) * e : Nat) : Int) ≤ ((fct (2 * B + 1 + d) : Nat) : Int) := by
    exact_mod_cast key
  push_cast at hI ⊢; omega

/-- **Coefficient truncation at an explicit exponent**: `c·B^E / E! ≤ 1/e` when `E ≥ 2B+1` and
    `c·e·Bⁱ ≤ E−(2B+1)+1` (base exp `2B+1`). -/
theorem truncCoef_QE (B c e E : Nat) (hB : 0 < B) (hE : 2 * B + 1 ≤ E)
    (hcond : c * e * npow B (2 * B + 1) ≤ E - (2 * B + 1) + 1) :
    Qle (⟨(c * npow B E : Int), fct E⟩ : Q) ⟨1, e⟩ := by
  have hd : 2 * B + 1 + (E - (2 * B + 1)) = E := by omega
  have h := truncCoef_Q B c e (E - (2 * B + 1)) hB hcond
  rw [hd] at h; exact h

/-- The `M`-series partial sums have non-negative numerators. -/
theorem expSumM_num_nonneg (M : Nat) : ∀ N, 0 ≤ (expSumM M N).num
  | 0 => by show (0 : Int) ≤ 1; decide
  | (n + 1) => by
      show (0 : Int) ≤ (expSumM M n).num * (fct (n + 1) : Int)
        + (npow M (n + 1) : Int) * ((expSumM M n).den : Int)
      exact Int.add_nonneg (Int.mul_nonneg (expSumM_num_nonneg M n) (Int.ofNat_nonneg _))
        (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))

/-- `U_M(N)` has a non-negative numerator. -/
theorem expM_U_num_nonneg (M N : Nat) : 0 ≤ (expM_U M N).num := by
  show (0 : Int) ≤ (expSumM M N).num * (fct (N + 1) : Int)
    + (2 * npow M (N + 1) : Int) * ((expSumM M N).den : Int)
  exact Int.add_nonneg (Int.mul_nonneg (expSumM_num_nonneg M N) (Int.ofNat_nonneg _))
    (Int.mul_nonneg (Int.mul_nonneg (by decide) (Int.ofNat_nonneg _)) (Int.ofNat_nonneg _))

/-- A non-negative rational is `≤` its numerator (as `num/1`). -/
theorem Qle_toNat {q : Q} (hq : 0 ≤ q.num) (hd : 0 < q.den) : Qle q ⟨(q.num.toNat : Int), 1⟩ := by
  show q.num * 1 ≤ (q.num.toNat : Int) * (q.den : Int)
  rw [Int.toNat_of_nonneg hq, Int.mul_one]
  have h := Int.mul_le_mul_of_nonneg_left
    (show (1 : Int) ≤ (q.den : Int) by exact_mod_cast hd) hq
  rwa [Int.mul_one] at h

-- ===========================================================================
-- The diagonal construction: exp(x) for a real x.
-- ===========================================================================

/-- The combined reindex constant: `M²ᴹ⁺¹ + Cₙₐₜ + 1`, where `Cₙₐₜ` bounds the Lipschitz coefficient
    and `M²ᴹ⁺¹` drives the truncation. -/
@[irreducible] def RexpReal_K (x : Real) : Nat :=
  npow (xBound x) (2 * xBound x + 1) + (expM_U (xBound x) (2 * xBound x)).num.toNat + 1

/-- The diagonal reindex: depth `=` argument index `= 2M + 4(j+1)·K`. -/
@[irreducible] def RexpReal_R (x : Real) (j : Nat) : Nat := 2 * xBound x + 4 * (j + 1) * RexpReal_K x

/-- The `j`-th diagonal rational approximant `S_{x_{R j}}(R j)`. -/
def RexpReal_seq (x : Real) (j : Nat) : Q := expSum (x.seq (RexpReal_R x j)) (RexpReal_R x j)

-- `maxHeartbeats` raised: this single proof assembles the truncation + Lipschitz bounds with several
-- ℚ-cross-multiplication discharges; the reindex defs are `irreducible` (so unification never unfolds
-- their heavy bodies), but the bound-chaining itself is long. No `sorry`/`native_decide`; axiom-clean.
set_option maxHeartbeats 1000000 in
/-- **The diagonal regularity (one side)**: for `j ≤ k`, the gap is `≤ 1/(j+1)`. -/
theorem RexpReal_diag_le (x : Real) {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (RexpReal_seq x j) (RexpReal_seq x k))) (Qbound j) := by
  have hM : 0 < xBound x := xBound_pos x
  have hK1 : npow (xBound x) (2 * xBound x + 1) ≤ RexpReal_K x := by unfold RexpReal_K; omega
  have hK2 : (expM_U (xBound x) (2 * xBound x)).num.toNat ≤ RexpReal_K x := by unfold RexpReal_K; omega
  have hRle : RexpReal_R x j ≤ RexpReal_R x k := by
    unfold RexpReal_R
    have hmul : 4 * (j + 1) * RexpReal_K x ≤ 4 * (k + 1) * RexpReal_K x :=
      Nat.mul_le_mul (Nat.mul_le_mul (Nat.le_refl 4) (Nat.succ_le_succ hjk)) (Nat.le_refl _)
    omega
  have h2M : 2 * xBound x ≤ RexpReal_R x j := by unfold RexpReal_R; omega
  -- midpoint B = expSum (x_{Rk}) (R j)
  have htri := Qabs_sub_triangle (a := RexpReal_seq x j)
    (b := expSum (x.seq (RexpReal_R x k)) (RexpReal_R x j)) (c := RexpReal_seq x k)
    (expSum_den_pos (x.den_pos _) _) (expSum_den_pos (x.den_pos _) _) (expSum_den_pos (x.den_pos _) _)
  -- Lipschitz part:  |S_{x_{Rj}}(Rj) − S_{x_{Rk}}(Rj)| ≤ 1/(2(j+1))
  have hLip : Qle (Qabs (Qsub (RexpReal_seq x j) (expSum (x.seq (RexpReal_R x k)) (RexpReal_R x j))))
      (⟨1, 2 * (j + 1)⟩ : Q) := by
    have hLS := expSum_Lip_le (x.den_pos (RexpReal_R x j)) (x.den_pos (RexpReal_R x k))
      (canon_bound x (RexpReal_R x j)) (canon_bound x (RexpReal_R x k)) (RexpReal_R x j)
    have hCle : Qle (LipS (xBound x) (RexpReal_R x j))
        ⟨((expM_U (xBound x) (2 * xBound x)).num.toNat : Int), 1⟩ :=
      Qle_trans (expM_U_den_pos _ _) (LipS_le_U (xBound x) (RexpReal_R x j))
        (Qle_toNat (expM_U_num_nonneg _ _) (expM_U_den_pos _ _))
    have hDnn : 0 ≤ (Qabs (Qsub (x.seq (RexpReal_R x j)) (x.seq (RexpReal_R x k)))).num :=
      Qabs_num_nonneg _
    -- D ≤ 2/(Rj+1)
    have hDbound : Qle (Qabs (Qsub (x.seq (RexpReal_R x j)) (x.seq (RexpReal_R x k))))
        ⟨2, RexpReal_R x j + 1⟩ := by
      have hxreg := x.reg (RexpReal_R x j) (RexpReal_R x k)
      have hanti : Qle (Qbound (RexpReal_R x k)) (Qbound (RexpReal_R x j)) := by
        show (1 : Int) * ((RexpReal_R x j + 1 : Nat) : Int) ≤ 1 * ((RexpReal_R x k + 1 : Nat) : Int)
        have : RexpReal_R x j + 1 ≤ RexpReal_R x k + 1 := by omega
        rw [Int.one_mul, Int.one_mul]; exact_mod_cast this
      have hsum : Qeq (add (Qbound (RexpReal_R x j)) (Qbound (RexpReal_R x j))) ⟨2, RexpReal_R x j + 1⟩ := by
        simp only [Qeq, add, Qbound]; push_cast; ring_uor
      exact Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) hxreg
        (Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
          (Qadd_le_add (Qle_refl _) hanti) (Qeq_le hsum))
    -- assemble:  Lip ≤ (LipS)·D ≤ ⟨Cnat,1⟩·D ≤ ⟨Cnat,1⟩·⟨2,Rj+1⟩ ≤ 1/(2(j+1))
    refine Qle_trans (Qmul_den_pos (LipS_den_pos _ _) (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos _)))) hLS ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (x.den_pos _))))
      (Qmul_le_mul_right hDnn hCle) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos _))
      (Qmul_le_mul_left (Int.ofNat_nonneg _) hDbound) ?_
    -- ⟨Cnat,1⟩ · ⟨2,Rj+1⟩ ≤ ⟨1, 2(j+1)⟩
    show ((expM_U (xBound x) (2 * xBound x)).num.toNat : Int) * 2 * (2 * (j + 1) : Nat)
        ≤ 1 * ((1 * (RexpReal_R x j + 1) : Nat) : Int)
    have harith : (expM_U (xBound x) (2 * xBound x)).num.toNat * 2 * (2 * (j + 1))
        ≤ 1 * (1 * (RexpReal_R x j + 1)) := by
      have hstep : 4 * (j + 1) * (expM_U (xBound x) (2 * xBound x)).num.toNat
          ≤ 4 * (j + 1) * RexpReal_K x := Nat.mul_le_mul (Nat.le_refl _) hK2
      have he : (expM_U (xBound x) (2 * xBound x)).num.toNat * 2 * (2 * (j + 1))
          = 4 * (j + 1) * (expM_U (xBound x) (2 * xBound x)).num.toNat := by
        have hI : (((expM_U (xBound x) (2 * xBound x)).num.toNat * 2 * (2 * (j + 1)) : Nat) : Int)
            = ((4 * (j + 1) * (expM_U (xBound x) (2 * xBound x)).num.toNat : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast hI
      rw [he]; unfold RexpReal_R; omega
    exact_mod_cast harith
  -- truncation part:  |S_{x_{Rk}}(Rj) − S_{x_{Rk}}(Rk)| ≤ 1/(2(j+1))
  have hTr : Qle (Qabs (Qsub (expSum (x.seq (RexpReal_R x k)) (RexpReal_R x j)) (RexpReal_seq x k)))
      (⟨1, 2 * (j + 1)⟩ : Q) := by
    have hTB := expSum_trunc_bound (x.den_pos (RexpReal_R x k)) (canon_bound x (RexpReal_R x k))
      (a := RexpReal_R x j) (Nat.le_trans h2M (Nat.le_add_right _ 2)) hRle
    rw [Qabs_Qsub_comm]
    refine Qle_trans (fct_pos (RexpReal_R x j + 1)) hTB ?_
    -- ⟨2·M^{Rj+1}, (Rj+1)!⟩ ≤ ⟨1, 2(j+1)⟩
    show (2 * npow (xBound x) (RexpReal_R x j + 1) : Int) * (2 * (j + 1) : Nat)
        ≤ 1 * ((fct (RexpReal_R x j + 1) : Nat) : Int)
    have hd : 2 * xBound x + 1 + 4 * (j + 1) * RexpReal_K x = RexpReal_R x j + 1 := by unfold RexpReal_R; omega
    have htr := trunc_reindex (xBound x) (2 * (j + 1)) (4 * (j + 1) * RexpReal_K x) hM
      (by have : 2 * (2 * (j + 1)) * npow (xBound x) (2 * xBound x + 1)
            ≤ 4 * (j + 1) * RexpReal_K x := by
            have h4 : 4 * (j + 1) * npow (xBound x) (2 * xBound x + 1) ≤ 4 * (j + 1) * RexpReal_K x :=
              Nat.mul_le_mul (Nat.le_refl _) hK1
            have he : 2 * (2 * (j + 1)) * npow (xBound x) (2 * xBound x + 1)
                = 4 * (j + 1) * npow (xBound x) (2 * xBound x + 1) := by
              have hI : ((2 * (2 * (j + 1)) * npow (xBound x) (2 * xBound x + 1) : Nat) : Int)
                  = ((4 * (j + 1) * npow (xBound x) (2 * xBound x + 1) : Nat) : Int) := by
                push_cast; ring_uor
              exact_mod_cast hI
            rw [he]; exact h4
          omega)
    rw [hd] at htr
    -- htr : 2 * M^{Rj+1} * (2(j+1)) ≤ (Rj+1)!
    have : (2 * npow (xBound x) (RexpReal_R x j + 1)) * (2 * (j + 1)) ≤ fct (RexpReal_R x j + 1) := htr
    rw [Int.one_mul]; exact_mod_cast this
  -- combine:  ≤ 1/(2(j+1)) + 1/(2(j+1)) ≈ 1/(j+1)
  have hfin : Qeq (add (⟨1, 2 * (j + 1)⟩ : Q) ⟨1, 2 * (j + 1)⟩) (Qbound j) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  exact Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (expSum_den_pos (x.den_pos _) _) (expSum_den_pos (x.den_pos _) _)))
      (Qabs_den_pos (Qsub_den_pos (expSum_den_pos (x.den_pos _) _) (expSum_den_pos (x.den_pos _) _))))
    htri (Qle_trans (add_den_pos (by show 0 < 2 * (j + 1); omega) (by show 0 < 2 * (j + 1); omega))
      (Qadd_le_add hLip hTr) (Qeq_le hfin))

/-- The diagonal sequence is Bishop-regular. -/
theorem RexpReal_regular (x : Real) : IsRegular (RexpReal_seq x) := by
  intro j k
  rcases Nat.le_total j k with h | h
  · exact Qle_trans (Qbound_den_pos j) (RexpReal_diag_le x h) (Qle_self_add (by show (0:Int) ≤ 1; decide))
  · have hswap := RexpReal_diag_le x h
    rw [Qabs_Qsub_comm] at hswap
    exact Qle_trans (Qbound_den_pos k) hswap (Qle_add_self (by show (0:Int) ≤ 1; decide))

/-- **`exp` on ℝ**: the everywhere-defined real exponential, as the diagonal of rational partial sums. -/
def RexpReal (x : Real) : Real :=
  ⟨RexpReal_seq x, RexpReal_regular x,
    fun j => expSum_den_pos (x.den_pos (RexpReal_R x j)) (RexpReal_R x j)⟩

end UOR.Bridge.F1Square.Analysis
