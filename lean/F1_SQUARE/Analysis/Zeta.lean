/-
F1 square — the Riemann zeta function `ζ(s)` at integer arguments `s ≥ 2`, as a genuine
**exact-bounded constructive real** (the v0.10.0 ζ object).

In the convergent regime `Re(s) > 1`, `ζ(s) = Σ_{i≥1} 1/iˢ` is a series of *rationals* with a rigorous,
explicitly computable rational tail bound — so its partial sums form a regular sequence of rationals,
i.e. a `Real`, with certified enclosures (`Analysis.ExactBounded`). For integer `s ≥ 2` we build it
here directly. The tail bound is the telescoping observation that `U(N) := S(N) + 1/(N+1)` is
**decreasing**: the added term `1/(N+2)ˢ ≤ 1/((N+1)(N+2)) = 1/(N+1) − 1/(N+2)` (since
`(N+1)(N+2) ≤ (N+2)² ≤ (N+2)ˢ`), giving `S(b) − S(a) ≤ 1/(a+1)` for `a ≤ b` — and that bound is
already the Bishop regularity modulus, so no reindex is needed.

**Honest scope.** This is `ζ` in the half-plane `Re(s) > 1` at integer points — where ζ has **no
zeros** and RH does **not** live. The analytic continuation to the critical strip `0 < Re(s) < 1`
(where the nontrivial zeros and RH are) is **not** built here; nor is `ζ` at complex `s`. This brick
makes `ζ(s≥2)` a certified-computable object (the kind the λₙ / explicit-formula layer will consume),
not a route to RH.

Natural powers `iˢ` are built from scratch (core has no `Nat.pow`-with-our-API of the shape we need).
Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.Exp
import F1Square.Analysis.ExactBounded

namespace UOR.Bridge.F1Square.Analysis

/-- Natural powers `iᵏ`, from scratch. -/
def npow (i : Nat) : Nat → Nat
  | 0 => 1
  | (k + 1) => i * npow i k

theorem npow_succ (i k : Nat) : npow i (k + 1) = i * npow i k := rfl

/-- Powers of a positive base are positive. -/
theorem npow_pos {i : Nat} (hi : 0 < i) : ∀ k, 0 < npow i k
  | 0 => Nat.one_pos
  | (k + 1) => Nat.mul_pos hi (npow_pos hi k)

/-- `i² = i · i`. -/
theorem npow_two (i : Nat) : npow i 2 = i * i := by
  show i * (i * 1) = i * i; rw [Nat.mul_one]

/-- `1ᵏ = 1`. -/
theorem npow_one : ∀ k, npow 1 k = 1
  | 0 => rfl
  | (k + 1) => by show 1 * npow 1 k = 1; rw [npow_one k]

/-- Powers are monotone in the exponent for a positive base. -/
theorem npow_mono {i : Nat} (hi : 0 < i) {a b : Nat} (hab : a ≤ b) : npow i a ≤ npow i b := by
  induction hab with
  | refl => exact Nat.le_refl _
  | @step k _ ih =>
      have h : npow i k ≤ i * npow i k := Nat.le_mul_of_pos_left (npow i k) hi
      exact Nat.le_trans ih h

/-- The partial sums `S(N) = Σ_{i=1}^{N+1} 1/iˢ` of `ζ(s)`. -/
def zetaSum (s : Nat) : Nat → Q
  | 0 => ⟨1, npow 1 s⟩
  | (N + 1) => add (zetaSum s N) ⟨1, npow (N + 2) s⟩

theorem zetaSum_den_pos (s : Nat) : ∀ N, 0 < (zetaSum s N).den
  | 0 => npow_pos (by omega) s
  | (N + 1) => add_den_pos (zetaSum_den_pos s N) (npow_pos (by omega) s)

/-- The partial sums are monotone (one step). -/
theorem zetaSum_step (s N : Nat) : Qle (zetaSum s N) (zetaSum s (N + 1)) := by
  show Qle (zetaSum s N) (add (zetaSum s N) ⟨1, npow (N + 2) s⟩)
  exact Qle_self_add (by show (0 : Int) ≤ 1; decide)

/-- The partial sums are monotone. -/
theorem zetaSum_le (s : Nat) {a b : Nat} (hab : a ≤ b) : Qle (zetaSum s a) (zetaSum s b) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (zetaSum_den_pos s _) ih (zetaSum_step s _)

/-- **The tail-bound step**: `1/(N+2)ˢ + 1/(N+2) ≤ 1/(N+1)` for `s ≥ 2` — the heart of the rigorous
    bound. It rests on `(N+1)(N+2) ≤ (N+2)² ≤ (N+2)ˢ`. -/
theorem zeta_step_le (s : Nat) (hs : 2 ≤ s) (N : Nat) :
    Qle (add (⟨1, npow (N + 2) s⟩ : Q) ⟨1, N + 2⟩) ⟨1, N + 1⟩ := by
  have hcmp : (N + 1) * (N + 2) ≤ npow (N + 2) s := by
    have hsq : npow (N + 2) 2 ≤ npow (N + 2) s := npow_mono (by omega) hs
    rw [npow_two] at hsq
    have hle : (N + 1) * (N + 2) ≤ (N + 2) * (N + 2) := Nat.mul_le_mul_right (N + 2) (by omega)
    exact Nat.le_trans hle hsq
  have h1 : Qle (⟨1, npow (N + 2) s⟩ : Q) ⟨1, (N + 1) * (N + 2)⟩ := by
    show (1 : Int) * (((N + 1) * (N + 2) : Nat) : Int) ≤ (1 : Int) * ((npow (N + 2) s : Nat) : Int)
    exact Int.mul_le_mul_of_nonneg_left (by exact_mod_cast hcmp) (by decide)
  refine Qle_trans
    (add_den_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos (N + 1))) (Nat.succ_pos (N + 1)))
    (Qadd_le_add h1 (Qle_refl _))
    (Qeq_le ?_)
  simp only [Qeq, add]; push_cast; ring_uor

/-- The telescoping upper sequence `U(N) := S(N) + 1/(N+1)`. -/
def zetaU (s N : Nat) : Q := add (zetaSum s N) ⟨1, N + 1⟩

theorem zetaU_den_pos (s N : Nat) : 0 < (zetaU s N).den :=
  add_den_pos (zetaSum_den_pos s N) (Nat.succ_pos N)

/-- `U` is decreasing (one step). -/
theorem zetaU_step (s : Nat) (hs : 2 ≤ s) (N : Nat) : Qle (zetaU s (N + 1)) (zetaU s N) := by
  have hassoc : Qeq (zetaU s (N + 1))
      (add (zetaSum s N) (add (⟨1, npow (N + 2) s⟩ : Q) ⟨1, N + 2⟩)) := by
    simp only [zetaU, zetaSum, Qeq, add]; push_cast; ring_uor
  have hp : 0 < npow (N + 2) s := npow_pos (by omega) s
  have hden : 0 < (add (zetaSum s N) (add (⟨1, npow (N + 2) s⟩ : Q) ⟨1, N + 2⟩)).den :=
    add_den_pos (zetaSum_den_pos s N) (add_den_pos hp (Nat.succ_pos _))
  refine Qle_congr_left hden (Qeq_symm hassoc) ?_
  exact Qadd_le_add (Qle_refl (zetaSum s N)) (zeta_step_le s hs N)

/-- `U` is decreasing. -/
theorem zetaU_le (s : Nat) (hs : 2 ≤ s) {a b : Nat} (hab : a ≤ b) : Qle (zetaU s b) (zetaU s a) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (zetaU_den_pos s _) (zetaU_step s hs _) ih

/-- **The rigorous error bound**: for `a ≤ b`, the partial-sum gap `S(b) − S(a) ≤ 1/(a+1)`. This is
    the exact, computable certificate that the partial sums converge to `ζ(s)`. -/
theorem zetadiff_bound (s : Nat) (hs : 2 ≤ s) {a b : Nat} (hab : a ≤ b) :
    Qle (Qsub (zetaSum s b) (zetaSum s a)) ⟨1, a + 1⟩ := by
  have hb : Qle (zetaSum s b) (add (zetaSum s a) ⟨1, a + 1⟩) :=
    Qle_trans (zetaU_den_pos s b) (Qle_self_add (by show (0 : Int) ≤ 1; decide)) (zetaU_le s hs hab)
  have hsub := Qsub_le_sub (z := zetaSum s a) hb
  refine Qle_trans
    (Qsub_den_pos (add_den_pos (zetaSum_den_pos s a) (Nat.succ_pos a)) (zetaSum_den_pos s a)) hsub ?_
  exact Qeq_le (Qsub_add_cancel (zetaSum s a) ⟨1, a + 1⟩)

/-- The gap as an absolute value (the gap is non-negative). -/
theorem zetaabs_bound (s : Nat) (hs : 2 ≤ s) {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (zetaSum s b) (zetaSum s a))) ⟨1, a + 1⟩ := by
  have hnn : 0 ≤ (Qsub (zetaSum s b) (zetaSum s a)).num := by
    have h := zetaSum_le s hab
    unfold Qle at h
    show 0 ≤ (zetaSum s b).num * ((zetaSum s a).den : Int)
      + (-(zetaSum s a).num) * ((zetaSum s b).den : Int)
    rw [Int.neg_mul]; omega
  exact Qabs_le_of_nonneg hnn (zetadiff_bound s hs hab)

/-- The partial sums are a regular sequence (so they define a constructive real): the gap bound
    `1/(min+1)` is already `≤ 1/(m+1) + 1/(n+1)`, so no reindex is needed. -/
theorem zetaSeq_regular (s : Nat) (hs : 2 ≤ s) : IsRegular (zetaSum s) := by
  intro m n
  rcases Nat.le_total m n with hmn | hnm
  · refine Qle_trans (Qbound_den_pos m) ?_ (Qle_self_add (by show (0 : Int) ≤ 1; decide))
    rw [Qabs_Qsub_comm]
    exact zetaabs_bound s hs hmn
  · refine Qle_trans (Qbound_den_pos n) ?_ (Qle_add_self (by show (0 : Int) ≤ 1; decide))
    exact zetaabs_bound s hs hnm

/-- **`ζ(s)` for integer `s ≥ 2`** as an exact-bounded constructive real: the value of `Σ_{i≥1} 1/iˢ`,
    with the rigorous rational error bound `zetadiff_bound` as its precision certificate. -/
def zeta (s : Nat) (hs : 2 ≤ s) : ExactBoundedReal :=
  ⟨zetaSum s, zetaSeq_regular s hs, zetaSum_den_pos s⟩

theorem zeta_seq (s : Nat) (hs : 2 ≤ s) (n : Nat) : (zeta s hs).seq n = zetaSum s n := rfl

/-- `ζ(s) > 0` (witnessed at index 1: its approximant `1 + 1/2ˢ` exceeds `1/2`). -/
theorem zeta_pos (s : Nat) (hs : 2 ≤ s) : Pos (zeta s hs) := by
  refine ⟨1, ?_⟩
  show Qlt ⟨1, 2⟩ (add (⟨1, npow 1 s⟩ : Q) ⟨1, npow 2 s⟩)
  unfold Qlt add
  have h1 : npow 1 s = 1 := npow_one s
  rw [h1]; push_cast; omega

end UOR.Bridge.F1Square.Analysis
