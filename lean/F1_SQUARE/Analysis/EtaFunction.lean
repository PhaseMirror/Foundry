/-
F1 square — the **Dirichlet eta function** `η(s) = Σ_{n≥1} (−1)^{n−1} n⁻ˢ` and the route it gives to `ζ`
on the **critical strip** (the v0.16.0 "(B) analytic continuation" goal, the integration-free path).

The Dirichlet series `ζ(s) = Σ n⁻ˢ` converges only for `Re s > 1`; Euler–Maclaurin continues it but its
remainder is an integral (no constructive integration in the library). The eta function gives the same
continuation *without integration*: the alternating series `η(s) = Σ (−1)^{n−1} n⁻ˢ` converges for
`Re s > 0` by **Abel summation** (a discrete identity), since the partial sums of `(−1)^{n−1}` are
bounded by `1` and `n⁻ˢ → 0` with bounded variation `Σ |n⁻ˢ − (n+1)⁻ˢ| < ∞` (the key estimate, from
the consecutive-log gap and a complex exp-difference bound — *no integral*). Then on `0 < Re s < 1`,

    ζ(s) = η(s) / (1 − 2^{1−s})        (`1 − 2^{1−s} ≠ 0` there),

via the complex reciprocal `Cinv` (built in `ComplexInv`). This module builds the **partial sums**
`czEtaSum`; the variation bound (convergence) and the `η → ζ` division build on top.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.EulerMaclaurin

namespace UOR.Bridge.F1Square.Analysis

/-- The `n`-th **signed** eta term `(−1)^{n−1} n⁻ˢ` (for `n = m+1`, the sign is `(−1)^m`). -/
def czEtaTerm (s : Complex) (m : Nat) : Complex :=
  if m % 2 = 0 then cpowNeg s (m + 1) else Cneg (cpowNeg s (m + 1))

/-- **The eta partial sum** `Σ_{n=1}^{M} (−1)^{n−1} n⁻ˢ` (the head of `η(s)`). -/
def czEtaSum (s : Complex) : Nat → Complex
  | 0 => Czero
  | (m + 1) => Cadd (czEtaSum s m) (czEtaTerm s m)

theorem czEtaSum_zero (s : Complex) : czEtaSum s 0 = Czero := rfl

theorem czEtaSum_succ (s : Complex) (m : Nat) :
    czEtaSum s (m + 1) = Cadd (czEtaSum s m) (czEtaTerm s m) := rfl

/-- The even-index signed term is `+n⁻ˢ`. -/
theorem czEtaTerm_even (s : Complex) (m : Nat) (h : m % 2 = 0) :
    czEtaTerm s m = cpowNeg s (m + 1) := by simp only [czEtaTerm, if_pos h]

/-- The odd-index signed term is `−n⁻ˢ`. -/
theorem czEtaTerm_odd (s : Complex) (m : Nat) (h : m % 2 = 1) :
    czEtaTerm s m = Cneg (cpowNeg s (m + 1)) := by
  simp only [czEtaTerm, if_neg (by omega : ¬ m % 2 = 0)]

end UOR.Bridge.F1Square.Analysis
