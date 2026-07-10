/-
F1 square — the **Euler–Mascheroni constant γ via the convergence-accelerated harmonic route**, whose
approximants have small denominators so that `Pos λ₁` is kernel-certifiable.

Standard definition, realized in *telescoped* form (so no log-additivity lemma is needed):

  γ = Σ_{i≥1} cᵢ,   cᵢ = 1/i − log((i+1)/i) = 1/i − 2·artanh(1/(2i+1)),   0 ≤ cᵢ ≤ 1/(i(i+1)).

Each consecutive-ratio log has a *small* artanh argument `1/(2i+1)` (fast geometric convergence),
unlike `log(n+1)` directly (argument `→ 1`). The series is built as a single rational diagonal (à la
`Rpi`, `gammaSeq`), reusing the artanh partial sum `artSum` (Log.lean); its termwise bracket
`0 ≤ cᵢ ≤ 1/(i(i+1))` rests on the two analytic facts `t ≤ artanh t ≤ t/(1−t²)`, mechanized here as
rational bounds on `artSum`.

This file builds the analytic foundation (the `artSum` bounds). The diagonal, its regularity, the
γ-lower bracket, and `Pos λ₁` follow. Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Log
import F1Square.Analysis.Euler

namespace UOR.Bridge.F1Square.Analysis

/-! ### Rational lower bound: `artSum t N ≥ t` (the first series term, for `t ≥ 0`) -/

/-- Each artanh term is non-negative for a non-negative base. -/
theorem artTerm_num_nonneg {t : Q} (ht0 : 0 ≤ t.num) (n : Nat) : 0 ≤ (artTerm t n).num := by
  show 0 ≤ (mul (qpow t (2 * n + 1)) ⟨1, 2 * n + 1⟩).num
  simp only [mul]
  have := qpow_nonneg ht0 (2 * n + 1)
  omega

/-- The artanh partial sums are monotone (one step), for a non-negative base. -/
theorem artSum_step {t : Q} (ht0 : 0 ≤ t.num) (_htd : 0 < t.den) (N : Nat) :
    Qle (artSum t N) (artSum t (N + 1)) := by
  show Qle (artSum t N) (add (artSum t N) (artTerm t (N + 1)))
  exact Qle_self_add (artTerm_num_nonneg ht0 (N + 1))

/-- The artanh partial sums are monotone, for a non-negative base. -/
theorem artSum_mono {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den) {a b : Nat} (hab : a ≤ b) :
    Qle (artSum t a) (artSum t b) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (artSum_den_pos htd _) ih (artSum_step ht0 htd _)

/-- The first partial sum is the base: `artSum t 0 ≈ t`. -/
theorem artSum_zero_eq (t : Q) : Qeq (artSum t 0) t := by
  show Qeq (mul (qpow t (2 * 0 + 1)) ⟨1, 2 * 0 + 1⟩) t
  have hq : qpow t 1 = mul t (qpow t 0) := qpow_succ t 0
  show Qeq (mul (qpow t 1) ⟨1, 1⟩) t
  rw [hq]
  simp only [Qeq, mul, qpow]; push_cast; ring_uor

/-- **`artSum t N ≥ t`** for a non-negative base — the artanh lower bound at the rational level. -/
theorem artSum_ge_arg {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den) (N : Nat) :
    Qle t (artSum t N) :=
  Qle_trans (artSum_den_pos htd 0) (Qeq_le (Qeq_symm (artSum_zero_eq t)))
    (artSum_mono ht0 htd (Nat.zero_le N))

/-! ### Rational geometric upper bound: `artSum t N · (1−t²) ≤ t` -/

/-- Each artanh term is `≤` the geometric term (since `1/(2n+1) ≤ 1`). -/
theorem artTerm_le_geoTerm {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den) (n : Nat) :
    Qle (artTerm t n) (geoTerm t n) := by
  show Qle (mul (qpow t (2 * n + 1)) ⟨1, 2 * n + 1⟩) (qpow t (2 * n + 1))
  have h1 : Qle (⟨1, 2 * n + 1⟩ : Q) ⟨1, 1⟩ := by
    show (1 : Int) * ((1 : Nat) : Int) ≤ 1 * ((2 * n + 1 : Nat) : Int); push_cast; omega
  have h2 : Qle (mul (qpow t (2 * n + 1)) ⟨1, 2 * n + 1⟩) (mul (qpow t (2 * n + 1)) ⟨1, 1⟩) :=
    Qmul_le_mul_left (qpow_nonneg ht0 _) h1
  have h3 : Qeq (mul (qpow t (2 * n + 1)) ⟨1, 1⟩) (qpow t (2 * n + 1)) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  exact Qle_trans (Qmul_den_pos (qpow_den_pos htd _) Nat.one_pos) h2 (Qeq_le h3)

/-- The artanh partial sum is `≤` the geometric partial sum. -/
theorem artSum_le_geoSum {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den) :
    ∀ N, Qle (artSum t N) (geoSum t N)
  | 0 => artTerm_le_geoTerm ht0 htd 0
  | (N + 1) => by
      show Qle (add (artSum t N) (artTerm t (N + 1))) (add (geoSum t N) (geoTerm t (N + 1)))
      exact Qadd_le_add (artSum_le_geoSum ht0 htd N) (artTerm_le_geoTerm ht0 htd (N + 1))

/-- Cleared geometric closed bound: `geoSum t N · (1−t²) ≤ t` (drop the non-negative `t^{2N+3}`). -/
theorem geoSum_cleared_le {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den) (N : Nat) :
    Qle (mul (geoSum t N) (Qsub ⟨1, 1⟩ (mul t t))) t := by
  have hU := geoU_eq htd N
  exact Qle_trans (add_den_pos (Qmul_den_pos (geoSum_den_pos htd N)
      (Qsub_den_pos Nat.one_pos (Nat.mul_pos htd htd))) (qpow_den_pos htd _))
    (Qle_self_add (qpow_nonneg ht0 _)) (Qeq_le hU)

/-- **The cleared artanh geometric upper bound**: `artSum t N · (1−t²) ≤ t`. -/
theorem artSum_le_geo {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den)
    (hWnn : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul t t)).num) (N : Nat) :
    Qle (mul (artSum t N) (Qsub ⟨1, 1⟩ (mul t t))) t := by
  have h1 : Qle (mul (artSum t N) (Qsub ⟨1, 1⟩ (mul t t)))
      (mul (geoSum t N) (Qsub ⟨1, 1⟩ (mul t t))) :=
    Qmul_le_mul_right hWnn (artSum_le_geoSum ht0 htd N)
  exact Qle_trans (Qmul_den_pos (geoSum_den_pos htd N)
    (Qsub_den_pos Nat.one_pos (Nat.mul_pos htd htd))) h1 (geoSum_cleared_le ht0 htd N)

/-! ### Step 2: the γ-term bracket `0 ≤ 1/(n+1) − 2·artSum(1/(2n+3),T) ≤ 1/((n+1)(n+2))` -/

/-- `2·artSum ≥ 1/(n+2)` (from `artSum ≥` its argument `1/(2n+3)`). -/
theorem two_artSum_ge (n T : Nat) :
    Qle (⟨1, n + 2⟩ : Q) (mul (⟨2, 1⟩ : Q) (artSum ⟨1, 2 * n + 3⟩ T)) := by
  have htd : 0 < (⟨1, 2 * n + 3⟩ : Q).den := by show 0 < 2 * n + 3; omega
  have ht0 : (0 : Int) ≤ (⟨1, 2 * n + 3⟩ : Q).num := by show (0 : Int) ≤ 1; decide
  have h1 : Qle (⟨1, 2 * n + 3⟩ : Q) (artSum ⟨1, 2 * n + 3⟩ T) := artSum_ge_arg ht0 htd T
  have h2 := Qmul_le_mul_left (show (0 : Int) ≤ (⟨2, 1⟩ : Q).num by decide) h1
  refine Qle_trans (Qmul_den_pos (by decide) htd) ?_ h2
  simp only [Qle, mul]; push_cast; omega

/-- `2·artSum ≤ 1/(n+1)` (from the geometric bound `artSum·(1−t²) ≤ t`, then cancel `1−t²`). -/
theorem two_artSum_le (n T : Nat) :
    Qle (mul (⟨2, 1⟩ : Q) (artSum ⟨1, 2 * n + 3⟩ T)) (⟨1, n + 1⟩ : Q) := by
  have htd : 0 < (⟨1, 2 * n + 3⟩ : Q).den := by show 0 < 2 * n + 3; omega
  have ht0 : (0 : Int) ≤ (⟨1, 2 * n + 3⟩ : Q).num := by show (0 : Int) ≤ 1; decide
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)).num := by
    show 0 < (add (⟨1, 1⟩ : Q) (neg (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩))).num
    simp only [add, neg, mul]
    have h9 : ((9 : Nat) : Int) ≤ (((2 * n + 3) * (2 * n + 3) : Nat) : Int) := by
      exact_mod_cast Nat.mul_le_mul (show 3 ≤ 2 * n + 3 by omega) (show 3 ≤ 2 * n + 3 by omega)
    push_cast at h9 ⊢; omega
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)).den :=
    Qsub_den_pos Nat.one_pos (Qmul_den_pos htd htd)
  refine Qmul_le_cancel_right hWn hWd ?_
  have hge := artSum_le_geo (t := ⟨1, 2 * n + 3⟩) ht0 htd (Int.le_of_lt hWn) T
  have hassoc : Qeq
      (mul (mul (⟨2, 1⟩ : Q) (artSum ⟨1, 2 * n + 3⟩ T))
        (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))
      (mul (⟨2, 1⟩ : Q)
        (mul (artSum ⟨1, 2 * n + 3⟩ T) (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))) := by
    simp only [Qeq, mul, Qsub, add, neg]; push_cast; ring_uor
  have hLHS : Qle
      (mul (mul (⟨2, 1⟩ : Q) (artSum ⟨1, 2 * n + 3⟩ T))
        (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))
      (mul (⟨2, 1⟩ : Q) ⟨1, 2 * n + 3⟩) :=
    Qle_trans (Qmul_den_pos (by decide) (Qmul_den_pos (artSum_den_pos htd T) hWd))
      (Qeq_le hassoc) (Qmul_le_mul_left (by decide) hge)
  refine Qle_trans (Qmul_den_pos (by decide) htd) hLHS ?_
  have hmono : (2 * (n : Int) + 3) ≤ 2 * (n + 2) := by omega
  have hnn : (0 : Int) ≤ 2 * ((n : Int) + 1) * (2 * n + 3) :=
    Int.mul_nonneg (Int.mul_nonneg (by omega) (by omega)) (by omega)
  have hstep := Int.mul_le_mul_of_nonneg_left hmono hnn
  have hkey : (2 : Int) * ((n : Int) + 1) * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3))
      ≤ ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) - 1) * (2 * (n : Int) + 3) := by
    calc (2 : Int) * ((n : Int) + 1) * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3))
        = (2 * ((n : Int) + 1) * (2 * (n : Int) + 3)) * (2 * (n : Int) + 3) := by ring_uor
      _ ≤ (2 * ((n : Int) + 1) * (2 * (n : Int) + 3)) * (2 * ((n : Int) + 2)) := hstep
      _ = ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) - 1) * (2 * (n : Int) + 3) := by ring_uor
  have hcmp_int : 2 * (((n : Int) + 1) * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3)))
      ≤ ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1) * (2 * (n : Int) + 3) := by
    have hid : ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1) * (2 * (n : Int) + 3)
        - 2 * (((n : Int) + 1) * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3)))
        = 2 * ((n : Int) + 1) * (2 * (n : Int) + 3) := by ring_uor
    have hpos : (0 : Int) ≤ 2 * ((n : Int) + 1) * (2 * (n : Int) + 3) :=
      Int.mul_nonneg (Int.mul_nonneg (by omega) (by omega)) (by omega)
    omega
  show Qle (mul (⟨2, 1⟩ : Q) ⟨1, 2 * n + 3⟩)
    (mul (⟨1, n + 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))
  simp only [Qle, mul, Qsub, add, neg]
  push_cast
  simp only [Int.one_mul]
  exact hcmp_int

/-- The `n`-th γ-term approximant `cApprox(n,T) = 1/(n+1) − 2·artSum(1/(2n+3),T)` (harmonic index
    `i = n+1`). Bracketed in `[0, 1/((n+1)(n+2))]` **uniformly in the artanh depth `T`**. -/
def cApprox (n T : Nat) : Q := Qsub ⟨1, n + 1⟩ (mul ⟨2, 1⟩ (artSum ⟨1, 2 * n + 3⟩ T))

theorem cApprox_den_pos (n T : Nat) : 0 < (cApprox n T).den :=
  Qsub_den_pos (by show 0 < n + 1; omega)
    (Qmul_den_pos (by decide) (artSum_den_pos (by show 0 < 2 * n + 3; omega) T))

theorem cApprox_num_nonneg (n T : Nat) : 0 ≤ (cApprox n T).num :=
  num_nonneg_of_Qzero_le (Qsub_nonneg_of_le (two_artSum_le n T))

theorem cApprox_ub (n T : Nat) : Qle (cApprox n T) (⟨1, (n + 1) * (n + 2)⟩ : Q) := by
  have hneg : Qle (neg (mul (⟨2, 1⟩ : Q) (artSum ⟨1, 2 * n + 3⟩ T))) (neg ⟨1, n + 2⟩) :=
    Qneg_le_neg (two_artSum_ge n T)
  have hstep : Qle (cApprox n T) (Qsub (⟨1, n + 1⟩ : Q) ⟨1, n + 2⟩) := by
    show Qle (add (⟨1, n + 1⟩ : Q) (neg (mul ⟨2, 1⟩ (artSum ⟨1, 2 * n + 3⟩ T))))
      (add ⟨1, n + 1⟩ (neg ⟨1, n + 2⟩))
    exact Qadd_le_add (Qle_refl _) hneg
  have heq : Qeq (Qsub (⟨1, n + 1⟩ : Q) ⟨1, n + 2⟩) (⟨1, (n + 1) * (n + 2)⟩ : Q) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  exact Qle_trans (Qsub_den_pos (by show 0 < n + 1; omega) (by show 0 < n + 2; omega)) hstep
    (Qeq_le heq)

/-! ### Step 3a: the plain partial sum and its telescoping truncation tail -/

/-- The plain partial sum `Σ_{i=0}^{M-1} f i`. -/
def Ssum (f : Nat → Q) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (M + 1) => add (Ssum f M) (f M)

theorem Ssum_den_pos {f : Nat → Q} (hf : ∀ i, 0 < (f i).den) : ∀ M, 0 < (Ssum f M).den
  | 0 => Nat.one_pos
  | (M + 1) => add_den_pos (Ssum_den_pos hf M) (hf M)

/-- **Telescoping truncation tail**: for `0 ≤ f i ≤ 1/((i+1)(i+2))`, the gap from `Mj` to `Mk`
    (`Mj ≤ Mk`) is `≤ 1/(Mj+1) − 1/(Mk+1)`. -/
theorem Ssum_tail_le {f : Nat → Q} (hf : ∀ i, 0 < (f i).den)
    (hfb : ∀ i, Qle (f i) (⟨1, (i + 1) * (i + 2)⟩ : Q)) (Mj : Nat) :
    ∀ {Mk}, Mj ≤ Mk →
      Qle (Qsub (Ssum f Mk) (Ssum f Mj)) (Qsub (⟨1, Mj + 1⟩ : Q) ⟨1, Mk + 1⟩) := by
  intro Mk hjk
  induction hjk with
  | refl =>
    have h0 : (Qsub (Ssum f Mj) (Ssum f Mj)).num = 0 := Qsub_self_num _
    have h1 : (Qsub (⟨1, Mj + 1⟩ : Q) ⟨1, Mj + 1⟩).num = 0 := Qsub_self_num _
    show Qle (Qsub (Ssum f Mj) (Ssum f Mj)) (Qsub (⟨1, Mj + 1⟩ : Q) ⟨1, Mj + 1⟩)
    unfold Qle; rw [h0, h1]; omega
  | @step K hK ih =>
    have hKpos : 0 < (K + 1) * (K + 2) := Nat.mul_pos (by omega) (by omega)
    have hrew : Qeq (Qsub (Ssum f (K + 1)) (Ssum f Mj))
        (add (Qsub (Ssum f K) (Ssum f Mj)) (f K)) :=
      Qsub_add_right (Ssum f K) (f K) (Ssum f Mj)
    have hstep : Qle (add (Qsub (Ssum f K) (Ssum f Mj)) (f K))
        (add (Qsub (⟨1, Mj + 1⟩ : Q) ⟨1, K + 1⟩) ⟨1, (K + 1) * (K + 2)⟩) :=
      Qadd_le_add ih (hfb K)
    have heq : Qeq (add (Qsub (⟨1, Mj + 1⟩ : Q) ⟨1, K + 1⟩) ⟨1, (K + 1) * (K + 2)⟩)
        (Qsub (⟨1, Mj + 1⟩ : Q) ⟨1, K + 2⟩) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    refine Qle_trans (add_den_pos (Qsub_den_pos (by show 0 < Mj + 1; omega) (by show 0 < K + 1; omega))
        hKpos)
      (Qle_congr_left (add_den_pos (Qsub_den_pos (Ssum_den_pos hf K) (Ssum_den_pos hf Mj)) (hf K))
        (Qeq_symm hrew) hstep) (Qeq_le heq)

/-! ### Step 3b: the per-term ζ-depth difference bound -/

/-- Powers are monotone in the base. -/
theorem npow_base_mono {a b : Nat} (h : a ≤ b) : ∀ m, npow a m ≤ npow b m
  | 0 => Nat.le_refl 1
  | (m + 1) => by
      show a * npow a m ≤ b * npow b m
      exact Nat.mul_le_mul h (npow_base_mono h m)

/-- `i^{a+b} = i^a · i^b`. -/
theorem npow_add (i a : Nat) : ∀ b, npow i (a + b) = npow i a * npow i b
  | 0 => by show npow i a = npow i a * 1; rw [Nat.mul_one]
  | (b + 1) => by
      show npow i (a + b + 1) = npow i a * npow i (b + 1)
      rw [npow_succ, npow_add i a b, npow_succ]
      simp only [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]

/-- `(1/d)^m = 1/dᵐ`. -/
theorem qpow_one_den (d : Nat) : ∀ m, qpow (⟨1, d⟩ : Q) m = ⟨1, npow d m⟩
  | 0 => rfl
  | (m + 1) => by rw [qpow_succ, qpow_one_den d m, npow_succ]; rfl

/-- **Per-term depth bound**: deepening the artanh approximant from `Tj` to `Tk` moves the γ-term by
    at most `1/3^{2Tj+1}` (uniformly in `n`). -/
theorem cApprox_depth_diff (n : Nat) {Tj Tk : Nat} (hT : Tj ≤ Tk) :
    Qle (Qabs (Qsub (cApprox n Tj) (cApprox n Tk))) (⟨1, npow 3 (2 * Tj + 1)⟩ : Q) := by
  have htd : 0 < (⟨1, 2 * n + 3⟩ : Q).den := by show 0 < 2 * n + 3; omega
  have ht0 : (0 : Int) ≤ (⟨1, 2 * n + 3⟩ : Q).num := by show (0 : Int) ≤ 1; decide
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)).num := by
    show 0 < (add (⟨1, 1⟩ : Q) (neg (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩))).num
    simp only [add, neg, mul]
    have h9 : ((9 : Nat) : Int) ≤ (((2 * n + 3) * (2 * n + 3) : Nat) : Int) := by
      exact_mod_cast Nat.mul_le_mul (show 3 ≤ 2 * n + 3 by omega) (show 3 ≤ 2 * n + 3 by omega)
    push_cast at h9 ⊢; omega
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)).den :=
    Qsub_den_pos Nat.one_pos (Qmul_den_pos htd htd)
  -- the ⟨1,n+1⟩ cancels: cApprox-diff = 2·(artSum Tk − artSum Tj)
  have heq : Qeq (Qsub (cApprox n Tj) (cApprox n Tk))
      (mul ⟨2, 1⟩ (Qsub (artSum ⟨1, 2 * n + 3⟩ Tk) (artSum ⟨1, 2 * n + 3⟩ Tj))) := by
    simp only [cApprox, Qeq, Qsub, mul, add, neg]; push_cast
    generalize (artSum ⟨1, 2 * n + 3⟩ Tj).num = aj; generalize ((artSum ⟨1, 2 * n + 3⟩ Tj).den : Int) = bj
    generalize (artSum ⟨1, 2 * n + 3⟩ Tk).num = ak; generalize ((artSum ⟨1, 2 * n + 3⟩ Tk).den : Int) = bk
    ring_uor
  have habs : Qeq (Qabs (Qsub (cApprox n Tj) (cApprox n Tk)))
      (mul ⟨2, 1⟩ (Qabs (Qsub (artSum ⟨1, 2 * n + 3⟩ Tk) (artSum ⟨1, 2 * n + 3⟩ Tj)))) := by
    have h := Qabs_Qeq heq; rw [Qabs_mul] at h; exact h
  refine Qle_congr_left (Qmul_den_pos (by decide) (Qabs_den_pos (Qsub_den_pos
      (artSum_den_pos htd Tk) (artSum_den_pos htd Tj)))) (Qeq_symm habs) ?_
  -- cancel W
  refine Qmul_le_cancel_right hWn hWd ?_
  have htrunc := artSum_trunc (t := ⟨1, 2 * n + 3⟩) (ρ := ⟨1, 2 * n + 3⟩) htd ht0 htd
    (Qle_refl _) (Int.le_of_lt hWn) hT
  -- htrunc : |artSum Tk − artSum Tj|·W ≤ qpow ⟨1,2n+3⟩ (2Tj+3)
  have hassoc : Qeq
      (mul (mul (⟨2, 1⟩ : Q) (Qabs (Qsub (artSum ⟨1, 2 * n + 3⟩ Tk) (artSum ⟨1, 2 * n + 3⟩ Tj))))
        (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))
      (mul (⟨2, 1⟩ : Q)
        (mul (Qabs (Qsub (artSum ⟨1, 2 * n + 3⟩ Tk) (artSum ⟨1, 2 * n + 3⟩ Tj)))
          (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))) := by
    simp only [Qeq, mul, Qsub, add, neg]; push_cast; ring_uor
  have hLHS : Qle
      (mul (mul (⟨2, 1⟩ : Q) (Qabs (Qsub (artSum ⟨1, 2 * n + 3⟩ Tk) (artSum ⟨1, 2 * n + 3⟩ Tj))))
        (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))
      (mul (⟨2, 1⟩ : Q) (qpow ⟨1, 2 * n + 3⟩ (2 * Tj + 3))) :=
    Qle_trans (Qmul_den_pos (by decide) (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos
        (artSum_den_pos htd Tk) (artSum_den_pos htd Tj))) hWd)) (Qeq_le hassoc)
      (Qmul_le_mul_left (by decide) htrunc)
  refine Qle_trans (Qmul_den_pos (by decide) (qpow_den_pos htd (2 * Tj + 3))) hLHS ?_
  -- final power comparison: 2·(1/(2n+3)^{2Tj+3}) ≤ (1/3^{2Tj+1})·W
  rw [qpow_one_den, show 2 * Tj + 3 = (2 * Tj + 1) + 2 from by omega, npow_add, npow_two]
  show Qle (mul (⟨2, 1⟩ : Q) ⟨1, npow (2 * n + 3) (2 * Tj + 1) * ((2 * n + 3) * (2 * n + 3))⟩)
    (mul (⟨1, npow 3 (2 * Tj + 1)⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * n + 3⟩ ⟨1, 2 * n + 3⟩)))
  have hmonoI : ((npow 3 (2 * Tj + 1) : Nat) : Int) ≤ ((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int) := by
    exact_mod_cast npow_base_mono (show 3 ≤ 2 * n + 3 by omega) (2 * Tj + 1)
  have hAnn : (0 : Int) ≤ ((npow 3 (2 * Tj + 1) : Nat) : Int) := by exact_mod_cast Nat.zero_le _
  have hBnn : (0 : Int) ≤ ((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int) := by exact_mod_cast Nat.zero_le _
  have hm8 : (8 : Int) ≤ (2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1 := by
    have h := Int.mul_le_mul (show (3 : Int) ≤ 2 * (n : Int) + 3 by omega)
      (show (3 : Int) ≤ 2 * (n : Int) + 3 by omega) (by omega) (by omega)
    omega
  have hmm : (0 : Int) ≤ (2 * (n : Int) + 3) * (2 * (n : Int) + 3) :=
    Int.mul_nonneg (by omega) (by omega)
  have hge : 2 * ((npow 3 (2 * Tj + 1) : Nat) : Int)
      ≤ ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1) * ((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int) :=
    calc 2 * ((npow 3 (2 * Tj + 1) : Nat) : Int)
        ≤ 8 * ((npow 3 (2 * Tj + 1) : Nat) : Int) := Int.mul_le_mul_of_nonneg_right (by omega) hAnn
      _ ≤ 8 * ((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int) :=
          Int.mul_le_mul_of_nonneg_left hmonoI (by omega)
      _ ≤ ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1) * ((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int) :=
          Int.mul_le_mul_of_nonneg_right hm8 hBnn
  simp only [Qle, mul, Qsub, add, neg]
  push_cast
  simp only [Int.one_mul]
  calc 2 * (((npow 3 (2 * Tj + 1) : Nat) : Int)
          * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3)))
      = (2 * ((npow 3 (2 * Tj + 1) : Nat) : Int))
          * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3)) := by ring_uor
    _ ≤ (((2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1) * ((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int))
          * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3)) := Int.mul_le_mul_of_nonneg_right hge hmm
    _ = ((2 * (n : Int) + 3) * (2 * (n : Int) + 3) + -1)
          * (((npow (2 * n + 3) (2 * Tj + 1) : Nat) : Int) * ((2 * (n : Int) + 3) * (2 * (n : Int) + 3))) := by
        ring_uor

/-! ### Step 3c: the γ diagonal and its regularity -/

/-- The plain partial sums are monotone (non-negative terms). -/
theorem Ssum_le {f : Nat → Q} (hf0 : ∀ i, 0 ≤ (f i).num) (hfd : ∀ i, 0 < (f i).den)
    {a b : Nat} (hab : a ≤ b) : Qle (Ssum f a) (Ssum f b) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (Ssum_den_pos hfd _) ih (Qle_self_add (hf0 _))

/-- Exponential dominates the polynomial: `8(j+1)² ≤ 3^{2j+3}`. -/
theorem pow_dom : ∀ j, 8 * ((j + 1) * (j + 1)) ≤ npow 3 (2 * j + 3)
  | 0 => by decide
  | (j + 1) => by
      have ih := pow_dom j
      have hpow : npow 3 (2 * (j + 1) + 3) = npow 3 (2 * j + 3) * 9 := by
        rw [show 2 * (j + 1) + 3 = (2 * j + 3) + 2 from by omega, npow_add,
          show npow 3 2 = 9 from by decide]
      have hsqe : (3 * (j + 1)) * (3 * (j + 1)) = 9 * ((j + 1) * (j + 1)) := by
        have h : (((3 * (j + 1)) * (3 * (j + 1)) : Nat) : Int) = ((9 * ((j + 1) * (j + 1)) : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast h
      have hsq : (j + 1 + 1) * (j + 1 + 1) ≤ 9 * ((j + 1) * (j + 1)) := by
        have h3 : j + 1 + 1 ≤ 3 * (j + 1) := by omega
        calc (j + 1 + 1) * (j + 1 + 1) ≤ (3 * (j + 1)) * (3 * (j + 1)) := Nat.mul_le_mul h3 h3
          _ = 9 * ((j + 1) * (j + 1)) := hsqe
      rw [hpow]
      calc 8 * ((j + 1 + 1) * (j + 1 + 1)) ≤ 8 * (9 * ((j + 1) * (j + 1))) :=
            Nat.mul_le_mul (Nat.le_refl 8) hsq
        _ = 9 * (8 * ((j + 1) * (j + 1))) := by omega
        _ ≤ 9 * npow 3 (2 * j + 3) := Nat.mul_le_mul (Nat.le_refl 9) ih
        _ = npow 3 (2 * j + 3) * 9 := Nat.mul_comm _ _


/-- **Term-wise difference of two plain sums**: if each term differs by `≤ 1/e`, the length-`M` sums
    differ by `≤ M/e`. -/
theorem Ssum_depth_diff {f g : Nat → Q} (e : Nat) (he : 0 < e) (hfd : ∀ i, 0 < (f i).den)
    (hgd : ∀ i, 0 < (g i).den) (hdiff : ∀ i, Qle (Qabs (Qsub (f i) (g i))) (⟨1, e⟩ : Q)) :
    ∀ M, Qle (Qabs (Qsub (Ssum f M) (Ssum g M))) (⟨(M : Int), e⟩ : Q)
  | 0 => by
      show Qle (Qabs (Qsub (⟨0, 1⟩ : Q) ⟨0, 1⟩)) (⟨(0 : Int), e⟩ : Q)
      have hx : (Qabs (Qsub (⟨0, 1⟩ : Q) ⟨0, 1⟩)).num = 0 := by decide
      unfold Qle; rw [hx]; simp
  | (M + 1) => by
      show Qle (Qabs (Qsub (add (Ssum f M) (f M)) (add (Ssum g M) (g M))))
        (⟨((M + 1 : Nat) : Int), e⟩ : Q)
      have hreg : Qeq (Qsub (add (Ssum f M) (f M)) (add (Ssum g M) (g M)))
          (add (Qsub (Ssum f M) (Ssum g M)) (Qsub (f M) (g M))) := by
        simp only [Qeq, Qsub, add, neg]; push_cast
        generalize (Ssum f M).num = a1; generalize ((Ssum f M).den : Int) = b1
        generalize (f M).num = a2; generalize ((f M).den : Int) = b2
        generalize (Ssum g M).num = a3; generalize ((Ssum g M).den : Int) = b3
        generalize (g M).num = a4; generalize ((g M).den : Int) = b4
        ring_uor
      have hsum : Qeq (add (⟨(M : Int), e⟩ : Q) ⟨1, e⟩) (⟨((M + 1 : Nat) : Int), e⟩ : Q) := by
        simp only [Qeq, add]; push_cast
        generalize ((e : Nat) : Int) = E; generalize ((M : Nat) : Int) = Mc
        ring_uor
      have key : Qle (Qabs (Qsub (add (Ssum f M) (f M)) (add (Ssum g M) (g M))))
          (add (Qabs (Qsub (Ssum f M) (Ssum g M))) (Qabs (Qsub (f M) (g M)))) :=
        Qle_congr_left (Qabs_den_pos (add_den_pos
          (Qsub_den_pos (Ssum_den_pos hfd M) (Ssum_den_pos hgd M)) (Qsub_den_pos (hfd M) (hgd M))))
          (Qeq_symm (Qabs_Qeq hreg)) (Qabs_add_le _ _)
      refine Qle_trans (add_den_pos
          (Qabs_den_pos (Qsub_den_pos (Ssum_den_pos hfd M) (Ssum_den_pos hgd M)))
          (Qabs_den_pos (Qsub_den_pos (hfd M) (hgd M)))) key ?_
      exact Qle_trans (add_den_pos (show 0 < (⟨(M : Int), e⟩ : Q).den from he)
          (show 0 < (⟨1, e⟩ : Q).den from he))
        (Qadd_le_add (Ssum_depth_diff e he hfd hgd hdiff M) (hdiff M)) (Qeq_le hsum)

/-- Number of telescoping terms at diagonal depth `j`. -/
def gammaHN (j : Nat) : Nat := 2 * (j + 1)

/-- The `j`-th rational approximant of γ: the `2(j+1)`-term sum of the depth-`(j+1)`
    artanh-telescoping terms `cApprox`. -/
def gammaHseq (j : Nat) : Q := Ssum (fun i => cApprox i (j + 1)) (gammaHN j)

theorem gammaHseq_den_pos (j : Nat) : 0 < (gammaHseq j).den :=
  Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) (gammaHN j)

theorem gammaHseq_reg_le {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (gammaHseq j) (gammaHseq k))) (Qbound j) := by
  have hNmono : gammaHN j ≤ gammaHN k := by unfold gammaHN; omega
  have htri := Qabs_sub_triangle
    (a := Ssum (fun i => cApprox i (j + 1)) (gammaHN j))
    (b := Ssum (fun i => cApprox i (k + 1)) (gammaHN j))
    (c := Ssum (fun i => cApprox i (k + 1)) (gammaHN k))
    (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) _)
    (Ssum_den_pos (fun i => cApprox_den_pos i (k + 1)) _)
    (Ssum_den_pos (fun i => cApprox_den_pos i (k + 1)) _)
  have hA : Qle (Qabs (Qsub (Ssum (fun i => cApprox i (j + 1)) (gammaHN j))
      (Ssum (fun i => cApprox i (k + 1)) (gammaHN j)))) (⟨(gammaHN j : Int), npow 3 (2 * j + 3)⟩ : Q) :=
    Ssum_depth_diff (npow 3 (2 * j + 3)) (npow_pos (by omega) _)
      (fun i => cApprox_den_pos i (j + 1)) (fun i => cApprox_den_pos i (k + 1))
      (fun i => cApprox_depth_diff i (show j + 1 ≤ k + 1 by omega)) (gammaHN j)
  have hAbnd : Qle (⟨(gammaHN j : Int), npow 3 (2 * j + 3)⟩ : Q) (⟨1, 2 * j + 2⟩ : Q) := by
    refine Qfrac_le (a := 2 * j + 1) ?_
    show gammaHN j * (2 * j + 1 + 1) ≤ npow 3 (2 * j + 3)
    have hpd := pow_dom j
    have h4 : gammaHN j * (2 * j + 1 + 1) = 4 * ((j + 1) * (j + 1)) := by
      have h : ((gammaHN j * (2 * j + 1 + 1) : Nat) : Int) = ((4 * ((j + 1) * (j + 1)) : Nat) : Int) := by
        unfold gammaHN; push_cast; ring_uor
      exact_mod_cast h
    rw [h4]; omega
  have hBnn : 0 ≤ (Qsub (Ssum (fun i => cApprox i (k + 1)) (gammaHN k))
      (Ssum (fun i => cApprox i (k + 1)) (gammaHN j))).num :=
    num_nonneg_of_Qzero_le (Qsub_nonneg_of_le (Ssum_le (fun i => cApprox_num_nonneg i (k + 1))
      (fun i => cApprox_den_pos i (k + 1)) hNmono))
  have hB : Qle (Qabs (Qsub (Ssum (fun i => cApprox i (k + 1)) (gammaHN j))
      (Ssum (fun i => cApprox i (k + 1)) (gammaHN k))))
      (Qsub (⟨1, gammaHN j + 1⟩ : Q) ⟨1, gammaHN k + 1⟩) := by
    rw [Qabs_Qsub_comm]
    exact Qabs_le_of_nonneg hBnn (Ssum_tail_le (fun i => cApprox_den_pos i (k + 1))
      (fun i => cApprox_ub i (k + 1)) (gammaHN j) hNmono)
  have hBbnd : Qle (Qsub (⟨1, gammaHN j + 1⟩ : Q) ⟨1, gammaHN k + 1⟩) (⟨1, 2 * j + 2⟩ : Q) := by
    refine Qle_trans (show 0 < (⟨1, gammaHN j + 1⟩ : Q).den by show 0 < gammaHN j + 1; omega)
      (Qsub_le_self (by show (0 : Int) ≤ 1; decide)) ?_
    show (1 : Int) * ((2 * j + 2 : Nat) : Int) ≤ 1 * ((gammaHN j + 1 : Nat) : Int)
    unfold gammaHN; push_cast; omega
  have hsum : Qeq (add (⟨1, 2 * j + 2⟩ : Q) ⟨1, 2 * j + 2⟩) (Qbound j) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  refine Qle_trans (add_den_pos
      (Qabs_den_pos (Qsub_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i (j + 1)) _)
        (Ssum_den_pos (fun i => cApprox_den_pos i (k + 1)) _)))
      (Qabs_den_pos (Qsub_den_pos (Ssum_den_pos (fun i => cApprox_den_pos i (k + 1)) _)
        (Ssum_den_pos (fun i => cApprox_den_pos i (k + 1)) _)))) htri ?_
  refine Qle_trans (add_den_pos (by show 0 < 2 * j + 2; omega) (by show 0 < 2 * j + 2; omega))
    (Qadd_le_add (Qle_trans (by show 0 < npow 3 (2 * j + 3); exact npow_pos (by omega) _) hA hAbnd)
      (Qle_trans (Qsub_den_pos (by show 0 < gammaHN j + 1; omega) (by show 0 < gammaHN k + 1; omega))
        hB hBbnd))
    (Qeq_le hsum)

theorem gammaHseq_regular : IsRegular gammaHseq := by
  intro m n
  rcases Nat.le_total m n with h | h
  · exact Qle_trans (Qbound_den_pos m) (gammaHseq_reg_le h)
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · rw [Qabs_Qsub_comm]
    exact Qle_trans (Qbound_den_pos n) (gammaHseq_reg_le h)
      (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **The Euler–Mascheroni constant γ**, accelerated route: `γ = Σ (1/i − log((i+1)/i))`, a
    constructive real with small-denominator approximants (so `Pos λ₁` is kernel-certifiable). -/
def Rgamma_h : Real := ⟨gammaHseq, gammaHseq_regular, gammaHseq_den_pos⟩

/-! ### Step 4: the γ lower bracket `Rle (ofQ γ_lo) Rgamma_h` -/

/-- From `|a − b| ≤ e` extract the lower bound `a − e ≤ b`. -/
theorem Qabs_lower {a b e : Q} (had : 0 < a.den) (hbd : 0 < b.den) (hed : 0 < e.den)
    (h : Qle (Qabs (Qsub a b)) e) : Qle (Qsub a e) b := by
  have h1 : Qle (Qsub a b) e :=
    Qle_trans (Qabs_den_pos (Qsub_den_pos had hbd)) (Qle_self_Qabs _) h
  have hc1 : Qeq (add (Qsub a b) b) a := by
    simp only [Qeq, Qsub, add, neg]; push_cast
    generalize a.num = an; generalize ((a.den : Nat) : Int) = ad
    generalize b.num = bn; generalize ((b.den : Nat) : Int) = bd
    ring_uor
  have h3 : Qle a (add e b) :=
    Qle_congr_left (add_den_pos (Qsub_den_pos had hbd) hbd) hc1 (Qadd_le_add h1 (Qle_refl b))
  have h4 : Qle (Qsub a e) (Qsub (add e b) e) := Qsub_le_sub h3
  have hc2 : Qeq (Qsub (add e b) e) b := by
    simp only [Qeq, Qsub, add, neg]; push_cast
    generalize e.num = en; generalize ((e.den : Nat) : Int) = ed
    generalize b.num = bn; generalize ((b.den : Nat) : Int) = bd
    ring_uor
  exact Qle_congr_right (Qsub_den_pos (add_den_pos hed hbd) hed) hc2 h4

/-- The fixed-depth-3 uniform lower bound term `clow i = cApprox(i,3) − 1/3⁷`. -/
def clow (i : Nat) : Q := Qsub (cApprox i 3) ⟨1, npow 3 7⟩

/-- `clow i ≤ cApprox(i, n+1)` for `n+1 ≥ 3` (uniform in the depth). -/
theorem clow_le_cApprox (i n : Nat) (hn : 3 ≤ n + 1) : Qle (clow i) (cApprox i (n + 1)) :=
  Qabs_lower (cApprox_den_pos i 3) (cApprox_den_pos i (n + 1))
    (by show 0 < npow 3 7; exact npow_pos (by omega) _) (cApprox_depth_diff i hn)

/-- Plain sums are monotone in the summand. -/
theorem Ssum_le_of_le {f g : Nat → Q} (h : ∀ i, Qle (f i) (g i)) :
    ∀ M, Qle (Ssum f M) (Ssum g M)
  | 0 => Qle_refl _
  | (M + 1) => Qadd_le_add (Ssum_le_of_le h M) (h M)

theorem clow_den_pos (i : Nat) : 0 < (clow i).den :=
  Qsub_den_pos (cApprox_den_pos i 3) (by show 0 < npow 3 7; exact npow_pos (by omega) _)

/-- The first `min(2(n+1),20)` `clow`-terms lower-bound `gammaHseq n` (for `n ≥ 2`, so depth `≥ 3`). -/
theorem gammaHseq_ge_clow {n : Nat} (hn : 2 ≤ n) :
    Qle (Ssum clow (min (2 * (n + 1)) 20)) (gammaHseq n) := by
  have h2 : Qle (Ssum clow (min (2 * (n + 1)) 20))
      (Ssum (fun i => cApprox i (n + 1)) (min (2 * (n + 1)) 20)) :=
    Ssum_le_of_le (fun i => clow_le_cApprox i n (by omega)) (min (2 * (n + 1)) 20)
  have h1 : Qle (Ssum (fun i => cApprox i (n + 1)) (min (2 * (n + 1)) 20)) (gammaHseq n) :=
    Ssum_le (fun i => cApprox_num_nonneg i (n + 1)) (fun i => cApprox_den_pos i (n + 1))
      (by show min (2 * (n + 1)) 20 ≤ gammaHN n; unfold gammaHN; exact Nat.min_le_left _ _)
  exact Qle_trans (Ssum_den_pos (fun i => cApprox_den_pos i (n + 1)) _) h2 h1

theorem gammaHseq_nonneg (n : Nat) : Qle (⟨0, 1⟩ : Q) (gammaHseq n) :=
  Ssum_le (fun i => cApprox_num_nonneg i (n + 1)) (fun i => cApprox_den_pos i (n + 1)) (Nat.zero_le _)

/-- **The γ lower bracket**: `Rgamma_h ≥ 54/100` (`γ ≈ 0.5772`). The shallow `Ssum clow 20 ≥ 0.54`
    certificate plus the uniform lower bound `gammaHseq n ≥ Ssum clow (min(2(n+1),20))`. -/
theorem Rgamma_h_lower : Rle (ofQ (⟨54, 100⟩ : Q) (by decide)) Rgamma_h := by
  intro n
  show Qle (⟨54, 100⟩ : Q) (add (gammaHseq n) ⟨2, n + 1⟩)
  match n with
  | 0 =>
    exact Qle_trans (add_den_pos (by decide) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add ⟨0, 1⟩ ⟨2, 0 + 1⟩))
      (Qadd_le_add (gammaHseq_nonneg 0) (Qle_refl _))
  | 1 =>
    exact Qle_trans (add_den_pos (by decide) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add ⟨0, 1⟩ ⟨2, 1 + 1⟩))
      (Qadd_le_add (gammaHseq_nonneg 1) (Qle_refl _))
  | 2 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (2 + 1)) 20)) ⟨2, 2 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | 3 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (3 + 1)) 20)) ⟨2, 3 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | 4 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (4 + 1)) 20)) ⟨2, 4 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | 5 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (5 + 1)) 20)) ⟨2, 5 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | 6 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (6 + 1)) 20)) ⟨2, 6 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | 7 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (7 + 1)) 20)) ⟨2, 7 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | 8 =>
    exact Qle_trans (add_den_pos (Ssum_den_pos clow_den_pos _) (by decide))
      (by decide : Qle (⟨54, 100⟩ : Q) (add (Ssum clow (min (2 * (8 + 1)) 20)) ⟨2, 8 + 1⟩))
      (Qadd_le_add (gammaHseq_ge_clow (by omega)) (Qle_refl _))
  | (m + 9) =>
    have hmin : min (2 * ((m + 9) + 1)) 20 = 20 := Nat.min_eq_right (by omega)
    have hge := gammaHseq_ge_clow (show 2 ≤ m + 9 by omega)
    rw [hmin] at hge
    have hg : Qle (⟨54, 100⟩ : Q) (gammaHseq (m + 9)) :=
      Qle_trans (Ssum_den_pos clow_den_pos 20) (by decide : Qle (⟨54, 100⟩ : Q) (Ssum clow 20)) hge
    exact Qle_trans (gammaHseq_den_pos (m + 9)) hg (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-! ### Step 5 foundation: the artanh series upper bound -/

/-- `a − b ≤ c → a ≤ b + c`. -/
theorem Qle_add_of_Qsub_le {a b c : Q} (had : 0 < a.den) (hbd : 0 < b.den) (hcd : 0 < c.den)
    (h : Qle (Qsub a b) c) : Qle a (add b c) := by
  have hcancel : Qeq (add (Qsub a b) b) a := by
    simp only [Qeq, Qsub, add, neg]; push_cast
    generalize a.num = an; generalize ((a.den : Nat) : Int) = ad
    generalize b.num = bn; generalize ((b.den : Nat) : Int) = bd
    ring_uor
  have h3 : Qle a (add c b) :=
    Qle_congr_left (add_den_pos (Qsub_den_pos had hbd) hbd) hcancel (Qadd_le_add h (Qle_refl b))
  have hcomm : Qeq (add c b) (add b c) := by
    simp only [Qeq, add]; push_cast
    generalize c.num = cn; generalize ((c.den : Nat) : Int) = cd
    generalize b.num = bn; generalize ((b.den : Nat) : Int) = bd
    ring_uor
  exact Qle_congr_right (add_den_pos hcd hbd) hcomm h3

/-- **The artanh series upper bound (cleared)**: for every length `M`,
    `artSum t M · (1−t²) ≤ artSum t T · (1−t²) + t^{2T+3}` — the partial sum never exceeds the
    depth-`T` value plus its geometric tail. -/
theorem artSum_upper_cleared {t : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den)
    (hWnn : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul t t)).num) (T M : Nat) :
    Qle (mul (artSum t M) (Qsub ⟨1, 1⟩ (mul t t)))
      (add (mul (artSum t T) (Qsub ⟨1, 1⟩ (mul t t))) (qpow t (2 * T + 3))) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul t t)).den :=
    Qsub_den_pos Nat.one_pos (Qmul_den_pos htd htd)
  rcases Nat.le_total T M with h | h
  · have htr := artSum_trunc htd ht0 htd (Qeq_le (Qabs_of_nonneg ht0)) hWnn h
    have hstep : Qle (mul (Qsub (artSum t M) (artSum t T)) (Qsub ⟨1, 1⟩ (mul t t)))
        (qpow t (2 * T + 3)) :=
      Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (artSum_den_pos htd M)
          (artSum_den_pos htd T))) hWd)
        (Qmul_le_mul_right hWnn (Qle_self_Qabs _)) htr
    have h2 : Qle (Qsub (mul (artSum t M) (Qsub ⟨1, 1⟩ (mul t t)))
        (mul (artSum t T) (Qsub ⟨1, 1⟩ (mul t t)))) (qpow t (2 * T + 3)) :=
      Qle_congr_left (Qmul_den_pos (Qsub_den_pos (artSum_den_pos htd M) (artSum_den_pos htd T)) hWd)
        (Qmul_sub_right _ _ _) hstep
    exact Qle_add_of_Qsub_le (Qmul_den_pos (artSum_den_pos htd M) hWd)
      (Qmul_den_pos (artSum_den_pos htd T) hWd) (qpow_den_pos htd _) h2
  · exact Qle_trans (Qmul_den_pos (artSum_den_pos htd T) hWd)
      (Qmul_le_mul_right hWnn (artSum_mono ht0 htd h)) (Qle_self_add (qpow_nonneg ht0 _))

/-- Upper bound for a constant-scaled real: if every approximant of `y` is `≤ c`, then
    `k·y ≤ k·c` (for `k ≥ 0`). -/
theorem Rmul_ofQ_le {k c : Q} (hk : 0 ≤ k.num) (hkd : 0 < k.den) (hcd : 0 < c.den)
    {y : Real} (hc : ∀ m, Qle (y.seq m) c) :
    Rle (Rmul (ofQ k hkd) y) (ofQ (mul k c) (Qmul_den_pos hkd hcd)) := by
  intro n
  show Qle (mul ((ofQ k hkd).seq (Ridx (ofQ k hkd) y n)) (y.seq (Ridx (ofQ k hkd) y n)))
    (add (mul k c) ⟨2, n + 1⟩)
  exact Qle_trans (Qmul_den_pos hkd hcd)
    (Qmul_le_mul_left hk (hc (Ridx (ofQ k hkd) y n)))
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **Uniform upper bound on the artanh partial sums**: `artSum t M ≤ artSum t T + tail` for all `M`,
    given a `tail` with `tail·(1−t²) = t^{2T+3}` (the geometric tail in cleared form). -/
theorem artSum_le_value {t tail : Q} (ht0 : 0 ≤ t.num) (htd : 0 < t.den) (htaild : 0 < tail.den)
    (hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul t t)).num) (T : Nat)
    (htail : Qeq (mul tail (Qsub ⟨1, 1⟩ (mul t t))) (qpow t (2 * T + 3))) (M : Nat) :
    Qle (artSum t M) (add (artSum t T) tail) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul t t)).den :=
    Qsub_den_pos Nat.one_pos (Qmul_den_pos htd htd)
  refine Qmul_le_cancel_right hWn hWd ?_
  refine Qle_trans (add_den_pos (Qmul_den_pos (artSum_den_pos htd T) hWd) (qpow_den_pos htd _))
    (artSum_upper_cleared ht0 htd (Int.le_of_lt hWn) T M) ?_
  refine Qeq_le (Qeq_symm (Qeq_trans
    (add_den_pos (Qmul_den_pos (artSum_den_pos htd T) hWd) (Qmul_den_pos htaild hWd))
    (Qmul_add_right (artSum t T) tail (Qsub ⟨1, 1⟩ (mul t t)))
    (Qadd_congr (Qeq_refl _) htail)))

/-! ### Step 5: the log4π upper bound -/

/-- The geometric-tail identity for base `1/3`: `(1/(8·3^{2T+1}))·(1−1/9) = (1/3)^{2T+3}`. -/
theorem log_tail_eq (T : Nat) :
    Qeq (mul (⟨1, 8 * npow 3 (2 * T + 1)⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨1, 3⟩ ⟨1, 3⟩)))
      (qpow (⟨1, 3⟩ : Q) (2 * T + 3)) := by
  rw [qpow_one_den]
  have hnp : npow 3 (2 * T + 3) = npow 3 (2 * T + 1) * 9 := by
    rw [show 2 * T + 3 = (2 * T + 1) + 2 from by omega, npow_add, show npow 3 2 = 9 from by decide]
  rw [hnp]
  generalize npow 3 (2 * T + 1) = N
  simp only [Qeq, mul, Qsub, add, neg]
  push_cast
  omega

/-- **log 2 = 2·artanh(1/3)**, built directly from the artanh of the rational `1/3` (exposing the
    structure for the upper bound), bypassing `RlogPos`'s witness nesting. Same value as `Rlog2`. -/
def Rlog2c : Real :=
  Rmul (ofQ ⟨2, 1⟩ (by decide))
    (Rartanh (ofQ ⟨1, 3⟩ (by decide)) ⟨1, 3⟩ (by decide) (by decide) (by decide)
      (fun n => Qle_refl ⟨1, 3⟩))

/-- **Upper bound for log 2**: `Rlog2c ≤ 2·(artSum(1/3,8) + 1/(8·3¹⁷))` (`≈ 0.6931`). -/
theorem Rlog2c_le :
    Rle Rlog2c (ofQ (mul ⟨2, 1⟩ (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩))
      (Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 8)
        (by show 0 < 8 * npow 3 (2 * 8 + 1); exact Nat.mul_pos (by decide) (npow_pos (by decide) _))))) := by
  apply Rmul_ofQ_le (by decide) (by decide)
    (add_den_pos (artSum_den_pos (by decide) 8) (by show 0 < 8 * npow 3 (2 * 8 + 1); exact Nat.mul_pos (by decide) (npow_pos (by decide) _)))
  intro m
  show Qle (artSum ((ofQ ⟨1, 3⟩ (by decide)).seq (Rartanh_R ⟨1, 3⟩ m)) (Rartanh_R ⟨1, 3⟩ m))
    (add (artSum ⟨1, 3⟩ 8) ⟨1, 8 * npow 3 (2 * 8 + 1)⟩)
  exact artSum_le_value (by decide) (by decide)
    (by show 0 < 8 * npow 3 (2 * 8 + 1); exact Nat.mul_pos (by decide) (npow_pos (by decide) _))
    (by show 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨1, 3⟩ ⟨1, 3⟩)).num; decide) 8 (log_tail_eq 8)
    (Rartanh_R ⟨1, 3⟩ m)

-- ===========================================================================
-- A **generic tight upper bound for `2·artanh(1/(2p+1))`** — the small-argument artanh that equals
-- the consecutive-log difference `log(p+1) − log p` (the `γ₁`-numeric input). Mirrors `Rlog2c_le`
-- but at the variable base `1/(2p+1)`, with the geometric tail in closed form. Because the argument
-- `1/(2p+1)` is *small* (unlike the direct `log k = 2·artanh((k−1)/(k+1))`, whose argument → 1), the
-- artanh series converges fast and a shallow depth `T` already gives a tight rational bound.
-- ===========================================================================

/-- The cleared `Int` polynomial identity behind `deltaTail_eq` — stated over genuine `Int` variables
    (so `ring_uor` sees clean atoms, not `Nat.cast`s), namely `(2P+1)² − 1 = 4P(P+1)` scaled by the
    common `N·(2P+1)²` factor. -/
private theorem deltaTail_int (P N : Int) :
    1 * (1 * ((2 * P + 1) * (2 * P + 1)) + -1) * (N * ((2 * P + 1) * (2 * P + 1)))
      = 1 * (N * (4 * P * (P + 1)) * (1 * ((2 * P + 1) * (2 * P + 1)))) := by ring_uor

/-- The geometric-tail identity for base `1/(2p+1)`: using `(2p+1)² − 1 = 4p(p+1)` (no `Nat` subtraction),
    `(1 / ((2p+1)^{2T+1}·4p(p+1)))·(1 − 1/(2p+1)²) = (1/(2p+1))^{2T+3}`. -/
theorem deltaTail_eq (p T : Nat) :
    Qeq (mul (⟨1, npow (2 * p + 1) (2 * T + 1) * (4 * p * (p + 1))⟩ : Q)
          (Qsub ⟨1, 1⟩ (mul ⟨1, 2 * p + 1⟩ ⟨1, 2 * p + 1⟩)))
        (qpow (⟨1, 2 * p + 1⟩ : Q) (2 * T + 3)) := by
  rw [qpow_one_den]
  have hnp : npow (2 * p + 1) (2 * T + 3)
      = npow (2 * p + 1) (2 * T + 1) * ((2 * p + 1) * (2 * p + 1)) := by
    rw [show 2 * T + 3 = (2 * T + 1) + 2 from by omega, npow_add]
    congr 1
    show npow (2 * p + 1) 2 = (2 * p + 1) * (2 * p + 1)
    simp only [npow_succ, npow, Nat.mul_one]
  rw [hnp]
  generalize npow (2 * p + 1) (2 * T + 1) = N
  simp only [Qeq, mul, Qsub, add, neg]
  push_cast
  exact deltaTail_int p N

/-- Each artanh term is monotone in the base. -/
theorem artTerm_base_mono {a b : Q} (ha0 : 0 ≤ a.num) (had : 0 < a.den) (hbd : 0 < b.den)
    (hab : Qle a b) (n : Nat) : Qle (artTerm a n) (artTerm b n) := by
  show Qle (mul (qpow a (2 * n + 1)) ⟨1, 2 * n + 1⟩) (mul (qpow b (2 * n + 1)) ⟨1, 2 * n + 1⟩)
  exact Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide) (qpow_base_mono had hbd ha0 hab (2 * n + 1))

/-- The artanh partial sums are monotone in the base (for non-negative bases). -/
theorem artSum_base_mono {a b : Q} (ha0 : 0 ≤ a.num) (had : 0 < a.den) (hbd : 0 < b.den)
    (hab : Qle a b) : ∀ N, Qle (artSum a N) (artSum b N)
  | 0 => artTerm_base_mono ha0 had hbd hab 0
  | (N + 1) =>
      Qadd_le_add (artSum_base_mono ha0 had hbd hab N) (artTerm_base_mono ha0 had hbd hab (N + 1))

/-! ### Step 5b: pointwise bounds on the π approximants (for `log π`'s modulus) -/

/-- `6/5 ≤ Rpi.seq n` pointwise (the Machin lower bracket, without the regularity slack). -/
theorem Rpi_seq_lb (n : Nat) :
    Qle (Qsub (mul ⟨16, 1⟩ ⟨1, 8⟩) (mul ⟨4, 1⟩ ⟨1, 5⟩)) (Rpi_seq n) := by
  have hcondA : Qle (qpow (⟨1, 2⟩ : Q) 5)
      (mul (Qsub (arctanSum ⟨1, 5⟩ 1) ⟨1, 8⟩) (Qsub ⟨1, 1⟩ (mul ⟨1, 2⟩ ⟨1, 2⟩))) := by decide
  have hcondB : Qle (qpow (⟨1, 2⟩ : Q) 3)
      (mul (Qsub (⟨1, 5⟩ : Q) (arctanSum ⟨1, 239⟩ 0)) (Qsub ⟨1, 1⟩ (mul ⟨1, 2⟩ ⟨1, 2⟩))) := by decide
  have hL5 : Qle (⟨1, 8⟩ : Q) (arctanSum ⟨1, 5⟩ (Rpi_g n)) :=
    arctanSum_diag_ge ⟨1, 5⟩ (by decide) (ρ := ⟨1, 2⟩) (L := ⟨1, 8⟩) (by decide) (by decide)
      (by decide) (by decide) (by decide) hcondA (20 * n + 19)
  have hU239 : Qle (arctanSum ⟨1, 239⟩ (Rpi_g n)) (⟨1, 5⟩ : Q) :=
    arctanSum_diag_le ⟨1, 239⟩ (by decide) (ρ := ⟨1, 2⟩) (U := ⟨1, 5⟩) (by decide) (by decide)
      (by decide) (by decide) (by decide) hcondB (20 * n + 19)
  exact Qsub_le_2 (Qmul_le_mul_left (by decide) hL5) (Qmul_le_mul_left (by decide) hU239)

/-! ### Step 5c: a *tight* π upper bound via the alternating arctan truncation -/

/-- One-sided arctan truncation (upper): the deep diagonal is `≤` a shallow partial sum plus a tail.
    Using `ρ = t` (the tightest valid radius) makes the shallow sum small-denominator. -/
theorem arctanSum_deep_le {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) {tail : Q} (htaild : 0 < tail.den)
    (hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num) {a b : Nat} (hab : a ≤ b)
    (htail : Qle (qpow ρ (2 * a + 3)) (mul tail (Qsub ⟨1, 1⟩ (mul ρ ρ)))) :
    Qle (arctanSum t b) (add (arctanSum t a) tail) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos hρd hρd)
  have htrunc := arctanSum_trunc htd hρ0 hρd htρ (Int.le_of_lt hWn) hab
  have hdiff : Qle (Qabs (Qsub (arctanSum t b) (arctanSum t a))) tail :=
    Qmul_le_cancel_right hWn hWd
      (Qle_trans (qpow_den_pos hρd _) htrunc htail)
  have hsub : Qle (Qsub (arctanSum t b) (arctanSum t a)) tail :=
    Qle_trans (Qabs_den_pos (Qsub_den_pos (arctanSum_den_pos htd b) (arctanSum_den_pos htd a)))
      (Qle_self_Qabs _) hdiff
  exact Qle_add_of_Qsub_le (arctanSum_den_pos htd b) (arctanSum_den_pos htd a) htaild hsub

/-- One-sided arctan truncation (lower): the deep diagonal is `≥` a shallow partial sum minus a tail. -/
theorem arctanSum_deep_ge {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) {tail : Q} (htaild : 0 < tail.den)
    (hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num) {a b : Nat} (hab : a ≤ b)
    (htail : Qle (qpow ρ (2 * a + 3)) (mul tail (Qsub ⟨1, 1⟩ (mul ρ ρ)))) :
    Qle (Qsub (arctanSum t a) tail) (arctanSum t b) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos hρd hρd)
  have htrunc := arctanSum_trunc htd hρ0 hρd htρ (Int.le_of_lt hWn) hab
  have hdiff : Qle (Qabs (Qsub (arctanSum t b) (arctanSum t a))) tail :=
    Qmul_le_cancel_right hWn hWd
      (Qle_trans (qpow_den_pos hρd _) htrunc htail)
  have hdiff' : Qle (Qabs (Qsub (arctanSum t a) (arctanSum t b))) tail := by
    rw [Qabs_Qsub_comm]; exact hdiff
  exact Qabs_lower (arctanSum_den_pos htd a) (arctanSum_den_pos htd b) htaild hdiff'

/-- **`Rpi.seq n ≤ 3.142` pointwise** — a tight Machin upper bracket from shallow arctan partial sums
    (`16·arctanSum(1/5,3) − 4·arctanSum(1/239,1)` plus `ρ = t` geometric tails). -/
theorem Rpi_seq_ub_tight (n : Nat) : Qle (Rpi_seq n) (⟨3142, 1000⟩ : Q) := by
  have hg : Rpi_g n = 12 * (20 * n + 20) := by unfold Rpi_g Rartanh_R; rfl
  have hge3 : 3 ≤ Rpi_g n := by rw [hg]; omega
  have hge1 : 1 ≤ Rpi_g n := by rw [hg]; omega
  have h5 : Qle (arctanSum ⟨1, 5⟩ (Rpi_g n)) (add (arctanSum ⟨1, 5⟩ 3) ⟨1, 1000000⟩) :=
    arctanSum_deep_le (ρ := ⟨1, 5⟩) (by decide) (by decide) (by decide) (by decide) (by decide)
      (by decide) hge3 (by decide)
  have h239 : Qle (Qsub (arctanSum ⟨1, 239⟩ 1) ⟨1, 1000000⟩) (arctanSum ⟨1, 239⟩ (Rpi_g n)) :=
    arctanSum_deep_ge (ρ := ⟨1, 239⟩) (by decide) (by decide) (by decide) (by decide) (by decide)
      (by decide) hge1 (by decide)
  exact Qle_trans
    (Qsub_den_pos (Qmul_den_pos (by decide) (add_den_pos (arctanSum_den_pos (by decide) 3) (by decide)))
      (Qmul_den_pos (by decide) (Qsub_den_pos (arctanSum_den_pos (by decide) 1) (by decide))))
    (Qsub_le_2 (Qmul_le_mul_left (by decide) h5) (Qmul_le_mul_left (by decide) h239))
    (by decide)

/-! ### Step 5d: `log π` as `Rlog Rpi`, with a tight upper bound -/

/-- `6/5 ≤ Rpi.seq n` (the Machin lower bracket in clean `⟨6,5⟩` form). -/
theorem Rpi_seq_ge (n : Nat) : Qle (⟨6, 5⟩ : Q) (Rpi_seq n) :=
  Qle_trans (Qsub_den_pos (Qmul_den_pos (by decide) (by decide)) (Qmul_den_pos (by decide) (by decide)))
    (by decide : Qle (⟨6, 5⟩ : Q) (Qsub (mul ⟨16, 1⟩ ⟨1, 8⟩) (mul ⟨4, 1⟩ ⟨1, 5⟩)))
    (Rpi_seq_lb n)

/-- Every π approximant has positive numerator. -/
theorem Rpi_seq_num_pos (n : Nat) : 0 < (Rpi_seq n).num := by
  have hge' : (6 : Int) * ((Rpi_seq n).den : Int) ≤ (Rpi_seq n).num * 5 := Rpi_seq_ge n
  have hd' : (0 : Int) < ((Rpi_seq n).den : Int) := by exact_mod_cast Rpi_seq_den_pos n
  omega

/-- The t-map of a rational `≥ 1` has non-negative numerator. -/
theorem tmap_num_nonneg {q : Q} (hq : Qle (⟨1, 1⟩ : Q) q) : 0 ≤ (tmap q).num := by
  have hq' : (1 : Int) * (q.den : Int) ≤ q.num * 1 := hq
  have hd : (0 : Int) ≤ (q.den : Int) := Int.ofNat_nonneg _
  have heq : (tmap q).num = (q.num - (q.den : Int)) * (q.den : Int) := by
    simp only [tmap, mul, Qsub, add, neg, Qinv]; push_cast; ring_uor
  rw [heq]; exact Int.mul_nonneg (by omega) hd

/-- The reindexed `(π−1)/(π+1)` diagonal has positive denominators. -/
theorem RpiTmap_den (n : Nat) : 0 < (Rlog_seq Rpi n).den := by
  refine Qmul_den_pos (Qsub_den_pos (Rpi.den_pos _) Nat.one_pos) (Qinv_den_pos ?_)
  have h : 0 < (Rpi.seq (Rlog_R n)).num := Rpi_seq_num_pos (Rlog_R n)
  have h2 : (0 : Int) ≤ ((Rpi.seq (Rlog_R n)).den : Int) := Int.ofNat_nonneg _
  show 0 < (Rpi.seq (Rlog_R n)).num * 1 + 1 * ((Rpi.seq (Rlog_R n)).den : Int)
  omega

/-- **`(π−1)/(π+1)` as a constructive real** — the argument of `log π = 2·artanh((π−1)/(π+1))`. -/
def RpiTmap : Real := ⟨Rlog_seq Rpi, Rlog_regular Rpi Rpi_seq_num_pos, RpiTmap_den⟩

/-- Every approximant of `(π−1)/(π+1)` is `≤ 15/29 = tmap(22/7)` in absolute value (since `π ≤ 22/7`). -/
theorem RpiTmap_abs_le (n : Nat) : Qle (Qabs (RpiTmap.seq n)) (⟨15, 29⟩ : Q) := by
  have hqM : Qle (Rpi.seq (Rlog_R n)) (⟨22, 7⟩ : Q) :=
    Qle_trans (by decide) (Rpi_seq_ub_tight (Rlog_R n)) (by decide : Qle (⟨3142, 1000⟩ : Q) ⟨22, 7⟩)
  have hq1 : 0 < (add (Rpi.seq (Rlog_R n)) ⟨1, 1⟩).num := by
    have h : 0 < (Rpi.seq (Rlog_R n)).num := Rpi_seq_num_pos (Rlog_R n)
    have h2 : (0 : Int) ≤ ((Rpi.seq (Rlog_R n)).den : Int) := Int.ofNat_nonneg _
    show 0 < (Rpi.seq (Rlog_R n)).num * 1 + 1 * ((Rpi.seq (Rlog_R n)).den : Int); omega
  have hqMge : Qle (⟨1, 1⟩ : Q) (mul (Rpi.seq (Rlog_R n)) ⟨22, 7⟩) :=
    Qle_trans (Qmul_den_pos (by decide) (by decide))
      (by decide : Qle (⟨1, 1⟩ : Q) (mul ⟨6, 5⟩ ⟨22, 7⟩))
      (Qmul_le_mul_right (by decide) (Rpi_seq_ge (Rlog_R n)))
  exact Qle_trans (by decide : 0 < (tmap (⟨22, 7⟩ : Q)).den)
    (tmap_abs_le (Rpi.den_pos (Rlog_R n)) (by decide) hq1 (by decide) hqM hqMge)
    (by decide : Qle (tmap (⟨22, 7⟩ : Q)) ⟨15, 29⟩)

/-- Every approximant of `(π−1)/(π+1)` is non-negative (since `π ≥ 1`). -/
theorem RpiTmap_nonneg (n : Nat) : 0 ≤ (RpiTmap.seq n).num :=
  tmap_num_nonneg (Qle_trans (by decide) (by decide : Qle (⟨1, 1⟩ : Q) ⟨6, 5⟩) (Rpi_seq_ge (Rlog_R n)))

/-- **`log π`** = `2·artanh((π−1)/(π+1))`, with radius `15/29`. -/
def Rlogπc : Real :=
  Rmul (ofQ ⟨2, 1⟩ (by decide))
    (Rartanh RpiTmap ⟨15, 29⟩ (by decide) (by decide) (by decide) RpiTmap_abs_le)

/-- The artanh truncation tail for base `15/29`, depth `T = 6`: `tail·(1−(15/29)²) = (15/29)^15`. -/
theorem tailπ_eq :
    Qeq (mul (⟨npow 15 15, npow 29 13 * 616⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨15, 29⟩ ⟨15, 29⟩)))
      (qpow ⟨15, 29⟩ 15) := by decide

/-- **`log π ≤ 2·(artSum(15/29,6) + tail) ≈ 1.1453`** — kernel-certified upper bound. The varying
    artanh argument `(π−1)/(π+1)` is dominated by the constant `15/29` (base-monotonicity), then the
    constant series is truncated at depth 6 with an explicit geometric tail. -/
theorem Rlogπc_le :
    Rle Rlogπc (ofQ (mul ⟨2, 1⟩ (add (artSum ⟨15, 29⟩ 6) ⟨npow 15 15, npow 29 13 * 616⟩))
      (Qmul_den_pos (by decide) (add_den_pos (artSum_den_pos (by decide) 6) (by decide)))) := by
  unfold Rlogπc
  apply Rmul_ofQ_le (by decide) (by decide)
    (add_den_pos (artSum_den_pos (by decide) 6) (by decide))
  intro m
  show Qle (artSum (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m)) (Rartanh_R ⟨15, 29⟩ m))
    (add (artSum ⟨15, 29⟩ 6) ⟨npow 15 15, npow 29 13 * 616⟩)
  exact Qle_trans (artSum_den_pos (by decide) (Rartanh_R ⟨15, 29⟩ m))
    (artSum_base_mono (RpiTmap_nonneg _) (RpiTmap.den_pos _) (by decide)
      (Qle_trans (Qabs_den_pos (RpiTmap.den_pos _)) (Qle_self_Qabs _) (RpiTmap_abs_le _))
      (Rartanh_R ⟨15, 29⟩ m))
    (artSum_le_value (by decide) (by decide) (by decide) (by decide) 6 tailπ_eq (Rartanh_R ⟨15, 29⟩ m))

/-! ### Step 6: ℝ-order bridges (monotonicity of `+`, `−`, and halving) and `Pos λ₁` -/

/-- Halving a non-negative rational is `≤` the rational. -/
theorem Qmul_half_le {e : Q} (he : 0 ≤ e.num) : Qle (mul ⟨1, 2⟩ e) e := by
  have hp : 0 ≤ e.num * (e.den : Int) := Int.mul_nonneg he (Int.ofNat_nonneg _)
  show (1 * e.num) * ((e.den : Nat) : Int) ≤ e.num * ((2 * e.den : Nat) : Int)
  have h1 : (1 * e.num) * ((e.den : Nat) : Int) = e.num * (e.den : Int) := by push_cast; ring_uor
  have h2 : e.num * ((2 * e.den : Nat) : Int) = 2 * (e.num * (e.den : Int)) := by push_cast; ring_uor
  rw [h1, h2]; omega

/-- Halving contracts the `Qabs` of a difference: `|½a − ½b| ≤ |a − b|`. -/
theorem Qabs_half_le {a b : Q} (had : 0 < a.den) (hbd : 0 < b.den) :
    Qle (Qabs (Qsub (mul ⟨1, 2⟩ a) (mul ⟨1, 2⟩ b))) (Qabs (Qsub a b)) := by
  have hd : Qeq (Qsub (mul ⟨1, 2⟩ a) (mul ⟨1, 2⟩ b)) (mul ⟨1, 2⟩ (Qsub a b)) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  have hae : Qeq (Qabs (Qsub (mul ⟨1, 2⟩ a) (mul ⟨1, 2⟩ b)))
      (mul ⟨1, 2⟩ (Qabs (Qsub a b))) := by
    have h1 := Qabs_Qeq hd
    have h2 : Qabs (mul ⟨1, 2⟩ (Qsub a b)) = mul ⟨1, 2⟩ (Qabs (Qsub a b)) := by rw [Qabs_mul]; rfl
    rw [h2] at h1; exact h1
  refine Qle_trans (Qmul_den_pos (by decide) (Qabs_den_pos (Qsub_den_pos had hbd)))
    (Qeq_le hae) (Qmul_half_le ?_)
  show (0 : Int) ≤ ((Qsub a b).num.natAbs : Int); exact Int.ofNat_nonneg _

/-- Antitonicity of real negation. -/
theorem Rneg_le {x y : Real} (hxy : Rle x y) : Rle (Rneg y) (Rneg x) := by
  intro n
  show Qle (neg (y.seq n)) (add (neg (x.seq n)) ⟨2, n + 1⟩)
  refine Qle_trans
    (add_den_pos (neg_den_pos (add_den_pos (y.den_pos n) (Nat.succ_pos _))) (Nat.succ_pos _))
    (Qeq_le ?_) (Qadd_le_add (Qneg_le_neg (hxy n)) (Qle_refl (⟨2, n + 1⟩ : Q)))
  show Qeq (neg (y.seq n)) (add (neg (add (y.seq n) ⟨2, n + 1⟩)) ⟨2, n + 1⟩)
  simp only [Qeq, neg, add]; push_cast; ring_uor

/-- **Halving** a constructive real, with no reindexing (`½ ≤ 1`, so regularity is preserved). -/
def Rhalf (x : Real) : Real where
  seq := fun n => mul ⟨1, 2⟩ (x.seq n)
  reg := by
    intro j k
    exact Qle_trans (Qabs_den_pos (Qsub_den_pos (x.den_pos j) (x.den_pos k)))
      (Qabs_half_le (x.den_pos j) (x.den_pos k)) (x.reg j k)
  den_pos := fun n => Qmul_den_pos (by decide) (x.den_pos n)

/-- A lower bound survives halving. -/
theorem Rhalf_ge {c : Q} (hcd : 0 < c.den) {x : Real} (h : Rle (ofQ c hcd) x) :
    Rle (ofQ (mul ⟨1, 2⟩ c) (Qmul_den_pos (by decide) hcd)) (Rhalf x) := by
  intro n
  show Qle (mul ⟨1, 2⟩ c) (add (mul ⟨1, 2⟩ (x.seq n)) ⟨2, n + 1⟩)
  have hQeq : Qeq (mul ⟨1, 2⟩ (add (x.seq n) ⟨2, n + 1⟩)) (add (mul ⟨1, 2⟩ (x.seq n)) ⟨1, n + 1⟩) := by
    simp only [Qeq, mul, add]; push_cast; ring_uor
  have hbound : Qle (⟨1, n + 1⟩ : Q) ⟨2, n + 1⟩ := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 2 * ((n + 1 : Nat) : Int)
    have : (0 : Int) ≤ ((n + 1 : Nat) : Int) := Int.ofNat_nonneg _; omega
  have hmid : Qle (mul ⟨1, 2⟩ (add (x.seq n) ⟨2, n + 1⟩)) (add (mul ⟨1, 2⟩ (x.seq n)) ⟨2, n + 1⟩) :=
    Qle_trans (add_den_pos (Qmul_den_pos (by decide) (x.den_pos n)) (Nat.succ_pos n))
      (Qeq_le hQeq) (Qadd_le_add (Qle_refl _) hbound)
  exact Qle_trans (Qmul_den_pos (by decide) (add_den_pos (x.den_pos n) (Nat.succ_pos n)))
    (Qmul_le_mul_left (by decide) (h n)) hmid

/-- `ofQ (p+q) ≤ (ofQ p) + (ofQ q)` (the constant sequences coincide). -/
theorem Rle_ofQ_add_Radd {p q : Q} (hp : 0 < p.den) (hq : 0 < q.den) :
    Rle (ofQ (add p q) (add_den_pos hp hq)) (Radd (ofQ p hp) (ofQ q hq)) :=
  fun _ => Qle_self_add (by show (0 : Int) ≤ 2; decide)

/-- `(ofQ p) + (ofQ q) ≤ ofQ (p+q)` (the constant sequences coincide). -/
theorem Radd_Rle_ofQ_add {p q : Q} (hp : 0 < p.den) (hq : 0 < q.den) :
    Rle (Radd (ofQ p hp) (ofQ q hq)) (ofQ (add p q) (add_den_pos hp hq)) :=
  fun _ => Qle_self_add (by show (0 : Int) ≤ 2; decide)

/-- A real bounded above by `ofQ d` has its negation bounded below by `ofQ (−d)`. -/
theorem Rneg_ofQ_le {d : Q} (hbd : 0 < d.den) {B : Real} (hB : Rle B (ofQ d hbd)) :
    Rle (ofQ (neg d) (neg_den_pos hbd)) (Rneg B) := Rneg_le hB

end UOR.Bridge.F1Square.Analysis
