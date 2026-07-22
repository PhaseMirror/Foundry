/-
F1 square — constructive **square root** of a non-negative rational, by interval bisection.

The general `√` is a named program blocker (the `RexpReal ∘ RlogPos` inverse is absent, so the
`RrpowPos x ⟨1,2⟩` route cannot prove `(√x)² = x`). Bisection sidesteps it entirely: starting from
`[0, q+1]` (which brackets `√q` since `0² ≤ q ≤ (q+1)²`), repeatedly halving the bracket around the
decidable test `m² ≤ q` gives rational lower endpoints `lo_n ↑ √q` with geometric error
`hi_n − lo_n = (q+1)/2^n`. The increments `lo_{n+1} − lo_n ∈ [0, (q+1)/2^{n+1}]` sit under the digamma
envelope `K/((n+1)n)` (`K = q+1`, since `(n+1)n ≤ 2^{n+1}`), so `genSum_RReg` makes the partial sums
regular — exactly the theta/integral UOR pattern. This file builds the Q-level bisection and its
invariants; `SqrtReal.lean` assembles the constructive real `Rsqrt q` and proves `(Rsqrt q)² = q`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.DyadicIntegral

namespace UOR.Bridge.F1Square.Analysis

/-- `¬(a ≤ b) ⟹ b ≤ a` for rationals (the `Int` order is total). -/
theorem Qle_of_not_le {a b : Q} (h : ¬ Qle a b) : Qle b a := by
  unfold Qle at *; omega

/-- `(a+b)/2 ≤ b` when `a ≤ b`. -/
theorem Qavg_le_right {a b : Q} (hbd : 0 < b.den) (h : Qle a b) :
    Qle (mul (add a b) (⟨1, 2⟩ : Q)) b := by
  refine Qle_trans (Qmul_den_pos (add_den_pos hbd hbd) (by decide))
    (Qmul_le_mul_right (show (0 : Int) ≤ 1 by decide) (Qadd_le_add h (Qle_refl b))) ?_
  exact Qeq_le (by simp only [Qeq, mul, add]; push_cast; ring_uor)

/-- `a ≤ (a+b)/2` when `a ≤ b`. -/
theorem Qavg_ge_left {a b : Q} (had : 0 < a.den) (h : Qle a b) :
    Qle a (mul (add a b) (⟨1, 2⟩ : Q)) := by
  refine Qle_trans (Qmul_den_pos (add_den_pos had had) (by decide))
    (Qeq_le (by simp only [Qeq, mul, add]; push_cast; ring_uor : Qeq a (mul (add a a) (⟨1, 2⟩ : Q))))
    (Qmul_le_mul_right (show (0 : Int) ≤ 1 by decide) (Qadd_le_add (Qle_refl a) h))

/-- The bisection step: from the bracket `(lo, hi)`, test the midpoint `m = (lo+hi)/2` and keep the
    half that still brackets `√q`. -/
def sqrtBisect (q : Q) : Nat → Q × Q
  | 0 => (⟨0, 1⟩, add q (⟨1, 1⟩ : Q))
  | (n + 1) =>
    let p := sqrtBisect q n
    let m := mul (add p.1 p.2) (⟨1, 2⟩ : Q)
    if Qle (mul m m) q then (m, p.2) else (p.1, m)

/-- The lower bracket endpoint after `n` bisections (`↑ √q`). -/
def sqLo (q : Q) (n : Nat) : Q := (sqrtBisect q n).1
/-- The upper bracket endpoint after `n` bisections (`↓ √q`). -/
def sqHi (q : Q) (n : Nat) : Q := (sqrtBisect q n).2

/-- The bracket endpoints have positive denominators (so `Qeq`/`Qle` transit through them). -/
theorem sqrtBisect_den_pos (q : Q) (hqd : 0 < q.den) (n : Nat) :
    0 < (sqLo q n).den ∧ 0 < (sqHi q n).den := by
  induction n with
  | zero =>
    refine ⟨?_, ?_⟩ <;> simp only [sqLo, sqHi, sqrtBisect]
    · exact Nat.one_pos
    · exact add_den_pos hqd (by decide)
  | succ n ih =>
    obtain ⟨hl, hh⟩ := ih
    have hmd : 0 < (mul (add (sqLo q n) (sqHi q n)) (⟨1, 2⟩ : Q)).den :=
      Qmul_den_pos (add_den_pos hl hh) (by decide)
    simp only [sqLo, sqHi, sqrtBisect]
    split
    · exact ⟨hmd, hh⟩
    · exact ⟨hl, hmd⟩

/-- **The bracket width is `(q+1)/2^n`** (geometric contraction, branch-independent). -/
theorem sqrtBisect_width (q : Q) (hqd : 0 < q.den) (n : Nat) :
    Qeq (Qsub (sqHi q n) (sqLo q n)) (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 2 ^ n⟩ : Q)) := by
  induction n with
  | zero => simp only [sqHi, sqLo, sqrtBisect, Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  | succ n ih =>
    obtain ⟨hl, hh⟩ := sqrtBisect_den_pos q hqd n
    have hstep : Qeq (Qsub (sqHi q (n + 1)) (sqLo q (n + 1)))
        (mul (Qsub (sqHi q n) (sqLo q n)) (⟨1, 2⟩ : Q)) := by
      simp only [sqHi, sqLo, sqrtBisect]
      split <;> (simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor)
    refine Qeq_trans (Qmul_den_pos (Qsub_den_pos hh hl) (by decide)) hstep ?_
    refine Qeq_trans
      (Qmul_den_pos (Qmul_den_pos (add_den_pos hqd (by decide)) Nat.one_le_two_pow) (by decide))
      (Qmul_congr ih (Qeq_refl _)) ?_
    rw [Nat.pow_succ]
    simp only [Qeq, mul]; push_cast; ring_uor

/-- **The bisection invariants**: `lo² ≤ q ≤ hi²`, `lo ≤ hi`, `0 ≤ lo` — maintained at every step. -/
theorem sqrtBisect_inv (q : Q) (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) (n : Nat) :
    Qle (mul (sqLo q n) (sqLo q n)) q ∧ Qle q (mul (sqHi q n) (sqHi q n))
       ∧ Qle (sqLo q n) (sqHi q n) ∧ Qle (⟨0, 1⟩ : Q) (sqLo q n) := by
  induction n with
  | zero =>
    have hqn : 0 ≤ q.num := by have := hq; simp only [Qle] at this; simpa using this
    refine ⟨?_, ?_, ?_, ?_⟩
    · simpa only [sqLo, sqrtBisect, mul] using hq
    · show Qle q (mul (sqHi q 0) (sqHi q 0))
      simp only [sqHi, sqrtBisect]
      have hrn : 0 ≤ (add q (⟨1, 1⟩ : Q)).num := by simp only [add]; push_cast; omega
      have hqr : Qle q (add q (⟨1, 1⟩ : Q)) := Qle_self_add (by decide)
      have h1r : Qle (⟨1, 1⟩ : Q) (add q (⟨1, 1⟩ : Q)) := Qle_add_self hqn
      have hrr : Qle (add q (⟨1, 1⟩ : Q)) (mul (add q (⟨1, 1⟩ : Q)) (add q (⟨1, 1⟩ : Q))) :=
        Qle_trans (Qmul_den_pos (add_den_pos hqd (by decide)) (by decide))
          (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor :
            Qeq (add q (⟨1, 1⟩ : Q)) (mul (add q (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q))))
          (Qmul_le_mul_left hrn h1r)
      exact Qle_trans (add_den_pos hqd (by decide)) hqr hrr
    · have := hqn; have := hqd
      simp only [sqLo, sqHi, sqrtBisect, Qle, add]; push_cast; omega
    · exact Qle_refl _
  | succ n ih =>
    obtain ⟨hlo, hhi, hle, hpos⟩ := ih
    obtain ⟨hl, hh⟩ := sqrtBisect_den_pos q hqd n
    simp only [sqLo, sqHi, sqrtBisect]
    split
    · rename_i hc
      exact ⟨hc, hhi, Qavg_le_right hh hle, Qle_trans hl hpos (Qavg_ge_left hl hle)⟩
    · rename_i hc
      exact ⟨hlo, Qle_of_not_le hc, Qavg_ge_left hl hle, hpos⟩

end UOR.Bridge.F1Square.Analysis
