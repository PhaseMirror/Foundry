/-
F1 square — `ExactBoundedReal`: a constructive real viewed as a stream of certified rational
enclosures (the v0.10.0 carrier for ζ and λₙ "as exact-bounded objects").

A Bishop constructive real `x` already *is* exact-bounded: its `n`-th approximant `xₙ` is a rational,
and regularity guarantees the true value lies within `1/(n+1)` of it — so `x` is enclosed by the
rational interval `[xₙ − 1/(n+1), xₙ + 1/(n+1)]`, of width `2/(n+1) → 0`. This module makes that
enclosure view explicit: `ExactBoundedReal := Real`, with rational lower/upper bounds `lowerB`/`upperB`
and the width identity, plus the regularity certificate exposed as `certificate`. No new mathematics —
it names the interface that `ζ` and `λₙ` inhabit.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.Real

namespace UOR.Bridge.F1Square.Analysis

/-- An **exact-bounded real**: a constructive real, presented as a stream of certified rational
    enclosures. (Definitionally a `Real`; the name records the role.) -/
abbrev ExactBoundedReal := Real

/-- The rational lower bound at precision `n`: `xₙ − 1/(n+1)`. -/
def lowerB (x : ExactBoundedReal) (n : Nat) : Q := Qsub (x.seq n) (Qbound n)

/-- The rational upper bound at precision `n`: `xₙ + 1/(n+1)`. -/
def upperB (x : ExactBoundedReal) (n : Nat) : Q := add (x.seq n) (Qbound n)

/-- The enclosure has **exact width `2/(n+1)`** — so the precision is explicit and `→ 0`. -/
theorem enclosure_width (x : ExactBoundedReal) (n : Nat) :
    Qeq (Qsub (upperB x n) (lowerB x n)) ⟨2, n + 1⟩ := by
  simp only [upperB, lowerB, Qsub, add, neg, Qbound, Qeq]; push_cast; ring_uor

/-- The lower bound never exceeds the upper bound (the enclosure is a genuine interval). -/
theorem lowerB_le_upperB (x : ExactBoundedReal) (n : Nat) : Qle (lowerB x n) (upperB x n) := by
  simp only [lowerB, upperB, Qsub, add, neg, Qbound, Qle]
  have h1 : (x.seq n).num * ((n : Int) + 1) + (-1) * ((x.seq n).den : Int)
      ≤ (x.seq n).num * ((n : Int) + 1) + 1 * ((x.seq n).den : Int) := by
    have hd : (0 : Int) ≤ ((x.seq n).den : Int) := Int.ofNat_nonneg _
    omega
  have h2 : (0 : Int) ≤ ((x.seq n).den : Int) * ((n : Int) + 1) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (by omega)
  have key := Int.mul_le_mul_of_nonneg_right h1 h2
  push_cast
  exact key

/-- The **exactness certificate**: the regularity of the underlying sequence — approximants at
    precisions `m, n` agree within `1/(m+1) + 1/(n+1)`. This is what makes the enclosures shrink. -/
theorem certificate (x : ExactBoundedReal) : IsRegular x.seq := x.reg

end UOR.Bridge.F1Square.Analysis
