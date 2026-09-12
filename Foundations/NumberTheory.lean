// Number theory basics for MetaMathematics

import Foundations.Init.Core
import Foundations.Init.Algebra.Order
import Foundations.Init.Data.Nat.Basic
import Foundations.Init.Data.Real.Basic
import Foundations.Init.Tactics

namespace Multiplicity.MetaMathematics

/-- The divisibility relation on natural numbers. `a ∣ b` means there exists `c` with `b = a * c`. -/

def divides (a b : Nat) : Prop := ∃ c, b = a * c

infix:50 " ∣ " => divides

/-- Reflexivity of divisibility: every number divides itself. -/
theorem dvd_refl (a : Nat) : a ∣ a := by
  refine ⟨1, ?_⟩
  simp

/-- Transitivity of divisibility: if `a ∣ b` and `b ∣ c` then `a ∣ c`. -/
theorem dvd_trans {a b c : Nat} (hab : a ∣ b) (hbc : b ∣ c) : a ∣ c := by
  rcases hab with ⟨k, hk⟩
  rcases hbc with ⟨l, hl⟩
  refine ⟨k * l, ?_⟩
  calc
    c = b * l := hl
    _ = (a * k) * l := by simpa [hk]
    _ = a * (k * l) := by ac_rfl

/-- If a prime divides a product, it divides at least one factor. -/
theorem prime_dvd_mul {p a b : Nat} (hp : Nat.Prime p) (h : p ∣ a * b) : p ∣ a ∨ p ∣ b := by
  rcases hp with ⟨hp_pos, hp_ne_one, hp_def⟩
  rcases h with ⟨c, hc⟩
  have : p ∣ a * b := by simpa [hc]
  exact Nat.prime_dvd_mul hp_def this

/-- Euclidean algorithm returns the greatest common divisor of two naturals. -/
def gcd (a b : Nat) : Nat := Nat.gcd a b

/-- `gcd` is symmetric. -/
theorem gcd_comm (a b : Nat) : gcd a b = gcd b a := by
  unfold gcd
  apply Nat.gcd_comm

/-- `gcd` of a number with zero is the number itself. -/
theorem gcd_zero_left (a : Nat) : gcd a 0 = a := by
  unfold gcd
  simpa using Nat.gcd_zero_left a

/-- `gcd` of a number with itself is the number. -/
theorem gcd_self (a : Nat) : gcd a a = a := by
  unfold gcd
  simpa using Nat.gcd_self a

end Multiplicity.MetaMathematics
