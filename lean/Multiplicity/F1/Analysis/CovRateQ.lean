/-
F1 square — **the rate-arithmetic core for the covariance null family** (`CovRateQ.lean`): two
elementary rational inequalities that turn a "fast enough approximation" into a `C₀/(k+1)` bound.

- `Qmul_recip_le` — a nonneg rational `a` scaled by `1/(idx+1)` is `≤ 1/D` once `idx` clears
  `a·D`: if `a.num·D < idx+1` then `a·(1/(idx+1)) ≤ 1/D`. This is what lets a *rational index
  schedule* `idx(k)` (chosen from the magnitude of the covComb coefficient) drive the
  continuity-gap coefficient-times-approximation-rate term below `1/(k+1)`.
- `Qmul_four_le` — a nonneg rational `P` times the fixed `4/(k+1)` weight is `≤ ⌈4P⌉/(k+1)`:
  `P·(4/(k+1)) ≤ (4·⌈P⌉)/(k+1)`, the `idx`-independent tail term of the covComb bound.

WHY. The real-scale dilation covariance's continuity gap (`covComb_scale_split`) is
`Sⁿ⁺¹·((φ.L+head)·|c−c'| + 4/(k+1)) + Bφ·(n+1)Sⁿ·|c−c'|`. With `head` collapsed to a rational
(`genSum_ofQ`) and `|c−c'| ≤ 1/(idx+1)` for a fast approximant, these two inequalities bound the
whole thing by `C₀/(k+1)` — the null-family shape the Archimedean squeeze needs to discharge
`hbound` and make the covariance unconditional.

HONEST SCOPE. Two rational inequalities — no reals, no analysis, no transform, no crux.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.QOrder

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **A nonneg rational scaled by `1/(idx+1)` is `≤ 1/D` once `idx` clears `a·D`.** If
    `a.num·D < idx+1` (and `a ≥ 0`), then `a·(1/(idx+1)) ≤ 1/D`. -/
theorem Qmul_recip_le (a : Q) (D idx : Nat) (ha : 0 ≤ a.num) (had : 0 < a.den)
    (hidx : a.num.toNat * D < idx + 1) :
    Qle (mul a (⟨1, idx + 1⟩ : Q)) (⟨1, D⟩ : Q) := by
  simp only [Qle, mul]
  push_cast
  -- goal: (a.num * 1) * D ≤ 1 * (a.den * (idx+1))
  have htoNat : (a.num.toNat : Int) = a.num := Int.toNat_of_nonneg ha
  have hden1 : (1 : Int) ≤ (a.den : Int) := by exact_mod_cast had
  have hidxZ : a.num * (D : Int) < ((idx : Int) + 1) := by
    have h : ((a.num.toNat * D : Nat) : Int) < ((idx + 1 : Nat) : Int) := by exact_mod_cast hidx
    push_cast at h
    rw [htoNat] at h
    exact h
  have hmul : ((idx : Int) + 1) ≤ (a.den : Int) * ((idx : Int) + 1) := by
    calc ((idx : Int) + 1) = 1 * ((idx : Int) + 1) := (Int.one_mul _).symm
      _ ≤ (a.den : Int) * ((idx : Int) + 1) := Int.mul_le_mul_of_nonneg_right hden1 (by omega)
  calc a.num * 1 * (D : Int) = a.num * (D : Int) := by ring_uor
    _ ≤ (idx : Int) + 1 := Int.le_of_lt hidxZ
    _ ≤ (a.den : Int) * ((idx : Int) + 1) := hmul
    _ = 1 * ((a.den : Int) * ((idx : Int) + 1)) := (Int.one_mul _).symm

/-- **A nonneg rational times the fixed `4/(k+1)` weight is `≤ ⌈4P⌉/(k+1)`.**
    `P·(4/(k+1)) ≤ (4·P.num.toNat)/(k+1)`. -/
theorem Qmul_four_le (P : Q) (k1 : Nat) (hP : 0 ≤ P.num) (hPd : 0 < P.den) :
    Qle (mul P (⟨4, k1⟩ : Q)) (⟨4 * (P.num.toNat : Int), k1⟩ : Q) := by
  simp only [Qle, mul]
  push_cast
  -- goal: (P.num * 4) * k1 ≤ (4 * P.num.toNat) * (P.den * k1)
  have htoNat : (P.num.toNat : Int) = P.num := Int.toNat_of_nonneg hP
  rw [htoNat]
  have hden1 : (1 : Int) ≤ (P.den : Int) := by exact_mod_cast hPd
  have hX : (0 : Int) ≤ P.num * 4 * (k1 : Int) :=
    Int.mul_nonneg (Int.mul_nonneg hP (by omega)) (by omega)
  calc P.num * 4 * (k1 : Int) = P.num * 4 * (k1 : Int) * 1 := (Int.mul_one _).symm
    _ ≤ P.num * 4 * (k1 : Int) * (P.den : Int) := Int.mul_le_mul_of_nonneg_left hden1 hX
    _ = 4 * P.num * ((P.den : Int) * (k1 : Int)) := by ring_uor

end Multiplicity.UOR.Bridge.F1Square.Analysis
