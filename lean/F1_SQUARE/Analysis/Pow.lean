/-
F1 square — real powers `xⁿ` on constructive ℝ (part of the v0.12.0 multiplicative substrate).

Every series transcendental to come — `exp`, `cos`, `sin` — is `Σ (real power)·(rational)`, so it needs
genuine real powers. These are the iterated real multiplication `Rmul`, with the congruence (powers
respect `≈`) that the setoid quotient requires.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.ROrder

namespace UOR.Bridge.F1Square.Analysis

/-- Real powers `xⁿ`, the iterated real multiplication. -/
def Rpow (x : Real) : Nat → Real
  | 0 => one
  | (n + 1) => Rmul x (Rpow x n)

theorem Rpow_zero (x : Real) : Rpow x 0 = one := rfl

theorem Rpow_succ (x : Real) (n : Nat) : Rpow x (n + 1) = Rmul x (Rpow x n) := rfl

/-- `x¹ ≈ x`. -/
theorem Rpow_one (x : Real) : Req (Rpow x 1) x := by
  show Req (Rmul x (Rpow x 0)) x
  -- Rmul x one ≈ x
  exact Rmul_one x

/-- Powers respect Bishop equality (so `Rpow` is well-defined on the `≈`-setoid). -/
theorem Rpow_congr {x y : Real} (h : Req x y) : ∀ n, Req (Rpow x n) (Rpow y n)
  | 0 => Req_refl one
  | (n + 1) => Rmul_congr h (Rpow_congr h n)

end UOR.Bridge.F1Square.Analysis
