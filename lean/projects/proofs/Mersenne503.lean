import Kernel

set_option maxRecDepth 2000000
set_option exponentiation.threshold 2000

/-!
# Mersenne 503 — certified properties of `M₅₀₃ = 2⁵⁰³ − 1`

Formalizes the elementary number-theoretic invariants of the Mersenne number
`M₅₀₃` claimed in `docs/`. All proofs are concrete computations (`decide`) or
elementary `Nat` reasoning — no `Mathlib`, no `sorry`.
-/
namespace Mersenne503

open proofs.Kernel

/-- The specific Mersenne number `M₅₀₃ = 2⁵⁰³ − 1`. -/
def M503 : Nat := mersenne 503

/-- `M₅₀₃` is positive. -/
theorem M503_pos : 0 < M503 := by
  unfold M503 mersenne
  apply mersenne_pos 503
  decide

/-- `M₅₀₃` is odd. -/
theorem M503_odd : M503 % 2 = 1 := by decide

/-- `2⁵⁰³ ≡ 1 (mod M₅₀₃)`. -/
theorem two_pow_503_mod_M503 : 2^503 % M503 = 1 := by decide

/-- `M₅₀₃` is not divisible by 3. -/
theorem M503_not_div_3 : M503 % 3 ≠ 0 := by decide

/-- `M₅₀₃` has at least `2⁵⁰²` as a lower bound on magnitude. -/
theorem M503_large : 2^502 < M503 := by decide

end Mersenne503
