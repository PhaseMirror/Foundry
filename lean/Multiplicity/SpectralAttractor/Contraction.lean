/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Multiplicity.SpectralAttractor.Tags
import Multiplicity.SpectralAttractor.Basic
import Multiplicity.SpectralAttractor.Matrices

/-!
# Spectral contraction

Decay lemmas for the locked rate sequence `rateSq n = c n * c n` of
ADR-0034-F1 §5: `0 ≤ rateSq n < 1` for every mode, hence iterated
weights decay geometrically.

Scope note (honest): the carrier classes carry order and ring laws but
no metric/Banach structure, so "contraction" here means the algebraic
core — pointwise rate bounds and their iterates — which is what the
atlas estimates consume.
-/

namespace ComplexKappa.SpectralAttractor

/-- Squared spectral weight of mode `n`. -/
@[adr] def rateSq {R} [so : SpectralOrderedCarrier R] [se : SpectralExpCarrier R]
    (n : ZeroMode) : R := c n * c n

/-- `0 ≤ rateSq n`. -/
@[proof] theorem rateSq_nonneg {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    so.carLe czero (rateSq n) :=
  (so.mul_pos (c n) (c n) (c_pos n) (c_pos n)).1

/-- `rateSq n ≤ 1`: from `c n ≤ 1` and `0 ≤ c n`, monotonicity gives
`c n * c n ≤ c n`, and `c n ≤ 1`. -/
@[proof] theorem rateSq_le_carOne {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) : so.carLe (rateSq n) so.carOne := by
  have hs := so.mul_le_mul_right_of_nonneg (c n) so.carOne (c n)
    (c_lt_one n).1 (c_pos n).1
  rw [so.carOne_mul] at hs
  show so.carLe (rateSq n) so.carOne
  exact so.le_trans _ _ _ hs (c_lt_one n).1

/-- Strict decay pair: `0 ≤ rateSq n` and `¬ (1 ≤ rateSq n)`.

If `1 ≤ rateSq n` then, since `rateSq n = c n * c n ≤ c n`, also
`1 ≤ c n`, contradicting the strict mode bound. -/
@[proof] theorem rateSq_lt_carOne {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    so.carLe czero (rateSq n) ∧ ¬ so.carLe so.carOne (rateSq n) := by
  refine ⟨rateSq_nonneg n, fun h => ?_⟩
  have hs := so.mul_le_mul_right_of_nonneg (c n) so.carOne (c n)
    (c_lt_one n).1 (c_pos n).1
  rw [so.carOne_mul] at hs
  exact absurd (so.le_trans _ _ _ h hs) (c_lt_one n).2

/-! ## Metric layer — iterated rates toward the attractor

The carrier carries no metric structure (see the scope note above), so the
iteration layer is expressed in the only faithful algebraic form: the
*squaring orbit* of the one-step rate,
`rateSqPow n 0 = rateSq n`, `rateSqPow n (k+1) = rateSqPow n k ^ 2`.
Squaring is chosen deliberately: the carrier's sign discipline proves
`sq_nonneg` unconditionally, so the entire orbit is simultaneously
nonnegative, bounded by the unit, and antitone — the discrete contraction
gauge the atlas estimates consume. Strictness at odd depths is deferred to
the analytic obligations of the atlas module. -/

/-- Squaring orbit of the one-step squared spectral weight of mode `n`
(`rateSqPow n 0 = rateSq n`, `rateSqPow n (k+1) = rateSqPow n k ^ 2`). -/
@[adr] def rateSqPow {R} [so : SpectralOrderedCarrier R] [se : SpectralExpCarrier R]
    (n : ZeroMode) : Nat → R
  | 0 => rateSq n
  | Nat.succ k => rateSqPow n k * rateSqPow n k

/-- Orbit membership gauge: every iterate satisfies
`0 ≤ rateSqPow n k ≤ 1`. One induction carries both halves; the step uses
`sq_nonneg` for the floor and right-multiplication of the ceiling by the
now-known-nonnegative iterate. -/
@[proof] theorem rateSqPow_mem {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    ∀ k : Nat, so.carLe czero (rateSqPow n k) ∧
      so.carLe (rateSqPow n k) so.carOne := by
  intro k
  induction k with
  | zero =>
    exact ⟨rateSq_nonneg (R := R) n, rateSq_le_carOne (R := R) n⟩
  | succ k ih =>
    refine ⟨so.sq_nonneg _, ?_⟩
    show so.carLe (rateSqPow n k * rateSqPow n k) so.carOne
    have hs := so.mul_le_mul_right_of_nonneg (rateSqPow n k) so.carOne
      (rateSqPow n k) ih.2 ih.1
    rw [so.carOne_mul] at hs
    exact so.le_trans _ _ _ hs ih.2

/-- **Attractor bound**: every iterate stays below the unit. -/
@[proof] theorem rateSqPow_le_carOne {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    ∀ k : Nat, so.carLe (rateSqPow n k) so.carOne :=
  fun k => (rateSqPow_mem n k).2

/-- The orbit is antitone: each squaring never increases the iterate. -/
@[proof] theorem rateSqPow_antitone {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) (k : Nat) :
    so.carLe (rateSqPow n (Nat.succ k)) (rateSqPow n k) :=
  (rateSqPow_mem n k).1 |> fun h => by
    show so.carLe (rateSqPow n k * rateSqPow n k) (rateSqPow n k)
    have hs := so.mul_le_mul_right_of_nonneg (rateSqPow n k) so.carOne
      (rateSqPow n k) (rateSqPow_le_carOne n k) h
    rw [so.carOne_mul] at hs
    exact hs

/-- Chain lemma: appending `d` further contractions never increases the
iterate — `rateSqPow n (a + d) ≤ rateSqPow n a`. Induction on `d`, pasting
the antitone step onto the induction hypothesis through `le_trans`. -/
private theorem rateSqPow_le_of_add {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    ∀ d a : Nat, so.carLe (rateSqPow n (a + d)) (rateSqPow n a) := by
  intro d
  induction d with
  | zero =>
    intro a
    rw [Nat.add_zero]
    exact so.le_refl _
  | succ d ih =>
    intro a
    rw [Nat.add_succ]
    exact so.le_trans _ _ _ (rateSqPow_antitone n (a + d)) (ih a)

/-- Convergence gauge: for every positive depth the iterate is dominated by
the one-step rate — the orbit collapses onto the `rateSq n`-neighborhood of
the attractor after a single step and never leaves it. -/
@[proof] theorem rateSqPow_le_rateSq {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    ∀ k : Nat, 0 < k → so.carLe (rateSqPow n k) (rateSq (R := R) n) := by
  intro k hk
  match k with
  | 0 => exact absurd hk (by omega)
  | Nat.succ m =>
    have hchain := rateSqPow_le_of_add (R := R) n m 1
    have hsucc : 1 + m = Nat.succ m := by omega
    rw [hsucc] at hchain
    show so.carLe (rateSqPow n (Nat.succ m)) (rateSq (R := R) n)
    have hstep : so.carLe (rateSqPow n 1) (rateSq (R := R) n) := by
      show so.carLe (rateSq n * rateSq n) (rateSq n)
      have hs2 := so.mul_le_mul_right_of_nonneg (rateSq n) so.carOne (rateSq n)
        (rateSq_le_carOne (R := R) n) (rateSq_nonneg (R := R) n)
      rw [so.carOne_mul] at hs2
      exact hs2
    exact so.le_trans _ _ _ hchain hstep

end ComplexKappa.SpectralAttractor
