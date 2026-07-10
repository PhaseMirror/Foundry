/-
F1 square — the general exponential `exp(q)` on the rational interval `[0,1]` (the v0.9.0 analysis
brick), with a rigorous rational error bound.

This continues the transcendentals arc opened by `e = exp(1)` (v0.8.0). The construction reuses the
v0.8.0 machinery almost verbatim — the only genuinely new input is **termwise domination**: for a
rational argument `q ∈ [0,1]`, every power `qⁱ ≤ 1`, hence each series term `qⁱ/i! ≤ 1/i!`. So the
partial-sum gaps of `Σ qⁱ/i!` are dominated termwise by those of `Σ 1/i!`, and the *same* rigorous
tail bound `S(b) − S(a) ≤ 2/(a+1)!` (`ediff_bound`) and the *same* reindex-to-regular lemma
(`efct_reindex`) make `exp(q)` a constructive real. No new tail analysis is needed.

New pieces: `qpow` (rational powers, from scratch — core has no `q^i`), the domination lemmas
(`qpow_le_one`, `expTerm_le`), and the dominated gap bound (`expdiff_dom`, `expdiff_bound`). The
construction is anchored by two correctness witnesses: `Rexp_zero : exp 0 ≈ 1` and
`Rexp_one_pos : exp 1 > 0`.

The everywhere-defined `exp` on all of ℝ (via the halving/squaring identity `exp x = exp(x/2ᵏ)^{2ᵏ}`),
and `cos`/`sin` (alternating series with the even/odd sandwich remainder — genuinely new machinery)
and `log` (positivity-as-data + the artanh series) are the later bricks of the arc.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.Exp

namespace UOR.Bridge.F1Square.Analysis

/-- Rational powers `qⁱ`, from scratch (core has no `q^i`). -/
def qpow (q : Q) : Nat → Q
  | 0 => ⟨1, 1⟩
  | (n + 1) => mul q (qpow q n)

theorem qpow_succ (q : Q) (n : Nat) : qpow q (n + 1) = mul q (qpow q n) := rfl

/-- Powers keep a positive denominator. -/
theorem qpow_den_pos {q : Q} (hqd : 0 < q.den) : ∀ n, 0 < (qpow q n).den
  | 0 => Nat.one_pos
  | (n + 1) => Qmul_den_pos hqd (qpow_den_pos hqd n)

/-- Powers of a non-negative rational are non-negative. -/
theorem qpow_nonneg {q : Q} (hq0 : 0 ≤ q.num) : ∀ n, 0 ≤ (qpow q n).num
  | 0 => by show (0 : Int) ≤ 1; decide
  | (n + 1) => by
      show 0 ≤ (mul q (qpow q n)).num
      simp only [mul]
      exact Int.mul_nonneg hq0 (qpow_nonneg hq0 n)

/-- **Termwise domination input**: for `q ∈ [0,1]`, every power `qⁱ ≤ 1`. -/
theorem qpow_le_one {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩) :
    ∀ n, Qle (qpow q n) ⟨1, 1⟩
  | 0 => Qle_refl _
  | (n + 1) => by
      have ih := qpow_le_one hq0 hqd hq1 n
      have h := Qmul_le_mul (a := q) (b := ⟨1, 1⟩) (c := qpow q n) (d := ⟨1, 1⟩)
        hqd (by decide) (qpow_den_pos hqd n) hq0 (qpow_nonneg hq0 n) hq1 ih
      show Qle (mul q (qpow q n)) ⟨1, 1⟩
      exact Qle_congr_right (by decide) (by decide) h

/-- The `i`-th series term `qⁱ/i!`. -/
def expTerm (q : Q) (i : Nat) : Q := mul (qpow q i) ⟨1, fct i⟩

theorem expTerm_den_pos {q : Q} (hqd : 0 < q.den) (i : Nat) : 0 < (expTerm q i).den :=
  Qmul_den_pos (qpow_den_pos hqd i) (fct_pos i)

theorem expTerm_num_nonneg {q : Q} (hq0 : 0 ≤ q.num) (i : Nat) : 0 ≤ (expTerm q i).num := by
  simp only [expTerm, mul]
  exact Int.mul_nonneg (qpow_nonneg hq0 i) (by show (0 : Int) ≤ 1; decide)

/-- **The domination bridge**: for `q ∈ [0,1]`, `qⁱ/i! ≤ 1/i!`. -/
theorem expTerm_le {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩) (i : Nat) :
    Qle (expTerm q i) ⟨1, fct i⟩ := by
  have hp := qpow_le_one hq0 hqd hq1 i
  have h := Qmul_le_mul_right (a := qpow q i) (b := ⟨1, 1⟩) (c := ⟨1, fct i⟩)
    (by show (0 : Int) ≤ 1; decide) hp
  show Qle (mul (qpow q i) ⟨1, fct i⟩) ⟨1, fct i⟩
  refine Qle_congr_right (Qmul_den_pos (by decide) (fct_pos i)) ?_ h
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The partial sums `S_q(N) = Σ_{i=0}^N qⁱ/i!` of the exponential series at `q`. -/
def expSum (q : Q) : Nat → Q
  | 0 => ⟨1, 1⟩
  | (n + 1) => add (expSum q n) (expTerm q (n + 1))

theorem expSum_den_pos {q : Q} (hqd : 0 < q.den) : ∀ N, 0 < (expSum q N).den
  | 0 => Nat.one_pos
  | (n + 1) => add_den_pos (expSum_den_pos hqd n) (expTerm_den_pos hqd (n + 1))

/-- The partial sums are monotone (one step) — each added term is non-negative. -/
theorem expSum_step {q : Q} (hq0 : 0 ≤ q.num) (n : Nat) :
    Qle (expSum q n) (expSum q (n + 1)) := by
  show Qle (expSum q n) (add (expSum q n) (expTerm q (n + 1)))
  exact Qle_self_add (expTerm_num_nonneg hq0 (n + 1))

/-- The partial sums are monotone. -/
theorem expSum_le {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) {a b : Nat} (hab : a ≤ b) :
    Qle (expSum q a) (expSum q b) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (expSum_den_pos hqd _) ih (expSum_step hq0 _)

/-- `(s + t) − base = (s − base) + t` (value) — the regrouping the dominated gap induction uses. -/
theorem Qsub_add_right (s t base : Q) : Qeq (Qsub (add s t) base) (add (Qsub s base) t) := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- **Termwise domination of the gaps**: for `q ∈ [0,1]` and `a ≤ b`, the `exp(q)` partial-sum gap is
    `≤` the `e` partial-sum gap, term by term. -/
theorem expdiff_dom {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩)
    {a b : Nat} (hab : a ≤ b) :
    Qle (Qsub (expSum q b) (expSum q a)) (Qsub (eSum b) (eSum a)) := by
  induction hab with
  | refl =>
      have h1 : (Qsub (expSum q a) (expSum q a)).num = 0 := Qsub_self_num _
      have h2 : (Qsub (eSum a) (eSum a)).num = 0 := Qsub_self_num _
      unfold Qle; rw [h1, h2]; simp
  | @step k _ ih =>
      have hterm := expTerm_le hq0 hqd hq1 (k + 1)
      have hbound : Qle (add (Qsub (expSum q k) (expSum q a)) (expTerm q (k + 1)))
          (add (Qsub (eSum k) (eSum a)) ⟨1, fct (k + 1)⟩) :=
        Qadd_le_add ih hterm
      have hL : Qeq (Qsub (expSum q (k + 1)) (expSum q a))
          (add (Qsub (expSum q k) (expSum q a)) (expTerm q (k + 1))) :=
        Qsub_add_right (expSum q k) (expTerm q (k + 1)) (expSum q a)
      have hR : Qeq (Qsub (eSum (k + 1)) (eSum a))
          (add (Qsub (eSum k) (eSum a)) ⟨1, fct (k + 1)⟩) :=
        Qsub_add_right (eSum k) ⟨1, fct (k + 1)⟩ (eSum a)
      have hposL : 0 < (add (Qsub (expSum q k) (expSum q a)) (expTerm q (k + 1))).den :=
        add_den_pos (Qsub_den_pos (expSum_den_pos hqd k) (expSum_den_pos hqd a))
          (expTerm_den_pos hqd (k + 1))
      have hposR : 0 < (add (Qsub (eSum k) (eSum a)) ⟨1, fct (k + 1)⟩).den :=
        add_den_pos (Qsub_den_pos (eSum_den_pos k) (eSum_den_pos a)) (fct_pos (k + 1))
      exact Qle_congr_left hposL (Qeq_symm hL) (Qle_congr_right hposR (Qeq_symm hR) hbound)

/-- **The rigorous error bound for `exp(q)`**: for `q ∈ [0,1]` and `a ≤ b`, the partial-sum gap
    `S_q(b) − S_q(a) ≤ 2/(a+1)!` — the *same* rational tail bound as `e`, via termwise domination. -/
theorem expdiff_bound {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩)
    {a b : Nat} (hab : a ≤ b) :
    Qle (Qsub (expSum q b) (expSum q a)) ⟨2, fct (a + 1)⟩ :=
  Qle_trans (Qsub_den_pos (eSum_den_pos b) (eSum_den_pos a))
    (expdiff_dom hq0 hqd hq1 hab) (ediff_bound hab)

/-- The gap as an absolute value (the gap is non-negative, so `|·|` is the gap). -/
theorem expabs_bound {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩)
    {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (expSum q b) (expSum q a))) ⟨2, fct (a + 1)⟩ := by
  have hnn : 0 ≤ (Qsub (expSum q b) (expSum q a)).num := by
    have h := expSum_le hq0 hqd hab
    unfold Qle at h
    simp only [Qsub, add, neg]
    rw [Int.neg_mul]; omega
  exact Qabs_le_of_nonneg hnn (expdiff_bound hq0 hqd hq1 hab)

/-- The reindexed partial-sum sequence `n ↦ S_q(n+1)` — the regular ℚ-sequence whose value is `exp q`. -/
def expSeq (q : Q) (n : Nat) : Q := expSum q (n + 1)

/-- The reindexed partial sums are regular (same reindex as `e`: `2/(min+2)! ≤ 1/(min+1)`). -/
theorem expSeq_regular {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩) :
    IsRegular (expSeq q) := by
  intro m n
  simp only [expSeq]
  rcases Nat.le_total m n with hmn | hnm
  · refine Qle_trans (Qbound_den_pos m) ?_ (Qle_self_add (Int.ofNat_nonneg _))
    rw [Qabs_Qsub_comm]
    exact Qle_trans (fct_pos (m + 1 + 1)) (expabs_bound hq0 hqd hq1 (by omega)) (efct_reindex m)
  · refine Qle_trans (Qbound_den_pos n) ?_ (Qle_add_self (Int.ofNat_nonneg _))
    exact Qle_trans (fct_pos (n + 1 + 1)) (expabs_bound hq0 hqd hq1 (by omega)) (efct_reindex n)

/-- **The general exponential `exp(q)`** on `q ∈ [0,1]` as a constructive real: the value of the
    exponential series `Σ qⁱ/i!`, with the rigorous rational tail bound `expdiff_bound`. -/
def Rexp (q : Q) (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩) : Real :=
  ⟨expSeq q, expSeq_regular hq0 hqd hq1, fun n => expSum_den_pos hqd (n + 1)⟩

theorem Rexp_seq (q : Q) (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩) (n : Nat) :
    (Rexp q hq0 hqd hq1).seq n = expSum q (n + 1) := rfl

-- ===========================================================================
-- Correctness witnesses: `exp 0 ≈ 1` and `exp 1 > 0`.
-- ===========================================================================

/-- At `q = 0`, every power beyond `q⁰` vanishes: `0^{n+1} = 0`. -/
theorem qpow_zero_succ_num (n : Nat) : (qpow (⟨0, 1⟩ : Q) (n + 1)).num = 0 := by
  show (mul (⟨0, 1⟩ : Q) (qpow (⟨0, 1⟩ : Q) n)).num = 0
  simp only [mul]
  simp

/-- Hence every series term beyond the constant `1` vanishes at `q = 0`. -/
theorem expTerm_zero_succ_num (n : Nat) : (expTerm (⟨0, 1⟩ : Q) (n + 1)).num = 0 := by
  simp only [expTerm, mul]
  rw [qpow_zero_succ_num]
  simp

/-- Adding a rational with zero numerator does not change the value. -/
theorem Qeq_add_zero_num {a b : Q} (hb : b.num = 0) : Qeq (add a b) a := by
  simp only [Qeq, add]; rw [hb]; push_cast; ring_uor

/-- The partial sums of `exp 0` are all `= 1` (value). -/
theorem expSum_zero_eq : ∀ N, Qeq (expSum (⟨0, 1⟩ : Q) N) ⟨1, 1⟩
  | 0 => by decide
  | (n + 1) => by
      have hstep : Qeq (expSum (⟨0, 1⟩ : Q) (n + 1)) (expSum (⟨0, 1⟩ : Q) n) := by
        show Qeq (add (expSum (⟨0, 1⟩ : Q) n) (expTerm (⟨0, 1⟩ : Q) (n + 1)))
          (expSum (⟨0, 1⟩ : Q) n)
        exact Qeq_add_zero_num (expTerm_zero_succ_num n)
      exact Qeq_trans (expSum_den_pos (by decide) n) hstep (expSum_zero_eq n)

/-- For value-equal rationals, `|x − y| ≤ c` for any `c` with a non-negative numerator. -/
theorem Qle_Qabs_Qsub_of_Qeq {x y c : Q} (h : Qeq x y) (hc : 0 ≤ c.num) :
    Qle (Qabs (Qsub x y)) c := by
  have hnum : (Qsub x y).num = 0 := by
    simp only [Qsub, add, neg]
    unfold Qeq at h
    rw [Int.neg_mul]; omega
  unfold Qle Qabs
  rw [hnum]
  simp only [Int.natAbs_zero, Int.ofNat_zero, Int.zero_mul]
  exact Int.mul_nonneg hc (Int.ofNat_nonneg _)

/-- **`exp 0 ≈ 1`** — the construction agrees with the value of the exponential at `0`. -/
theorem Rexp_zero : Req (Rexp ⟨0, 1⟩ (by decide) (by decide) (by decide)) one := by
  intro n
  show Qle (Qabs (Qsub (expSum (⟨0, 1⟩ : Q) (n + 1)) ⟨1, 1⟩)) ⟨2, n + 1⟩
  exact Qle_Qabs_Qsub_of_Qeq (expSum_zero_eq (n + 1)) (by show (0 : Int) ≤ 2; decide)

/-- **`exp 1 > 0`** — positivity witnessed at index `0` (its `0`-th approximant is `1 + 1 = 2 > 1`). -/
theorem Rexp_one_pos : Pos (Rexp ⟨1, 1⟩ (by decide) (by decide) (by decide)) := ⟨0, by decide⟩

/-- At `q = 1`, every power is `1` (literally `⟨1,1⟩`). -/
theorem qpow_one_eq : ∀ i, qpow (⟨1, 1⟩ : Q) i = ⟨1, 1⟩
  | 0 => rfl
  | (i + 1) => by rw [qpow_succ, qpow_one_eq i]; decide

/-- At `q = 1`, the `i`-th series term is `1/i!` (value). -/
theorem expTerm_one_eq (i : Nat) : Qeq (expTerm (⟨1, 1⟩ : Q) i) ⟨1, fct i⟩ := by
  show Qeq (mul (qpow (⟨1, 1⟩ : Q) i) ⟨1, fct i⟩) ⟨1, fct i⟩
  rw [qpow_one_eq i]
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The `exp 1` partial sums coincide (in value) with `e`'s partial sums `Σ 1/i!`. -/
theorem expSum_one_eq : ∀ N, Qeq (expSum (⟨1, 1⟩ : Q) N) (eSum N)
  | 0 => by decide
  | (n + 1) => by
      show Qeq (add (expSum (⟨1, 1⟩ : Q) n) (expTerm (⟨1, 1⟩ : Q) (n + 1)))
        (add (eSum n) ⟨1, fct (n + 1)⟩)
      exact Qadd_congr (expSum_one_eq n) (expTerm_one_eq (n + 1))

/-- **`exp 1 ≈ e`** — the general exponential specializes to Euler's number (v0.8.0) at `q = 1`. This
    ties the v0.9.0 construction back to the established `e`, a genuine regression anchor. -/
theorem Rexp_one_eq_e : Req (Rexp ⟨1, 1⟩ (by decide) (by decide) (by decide)) e := by
  intro n
  show Qle (Qabs (Qsub (expSum (⟨1, 1⟩ : Q) (n + 1)) (eSum (n + 1)))) ⟨2, n + 1⟩
  exact Qle_Qabs_Qsub_of_Qeq (expSum_one_eq (n + 1)) (by show (0 : Int) ≤ 2; decide)

end UOR.Bridge.F1Square.Analysis
