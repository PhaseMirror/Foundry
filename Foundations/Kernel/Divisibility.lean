/-!
# Foundations.Kernel.Divisibility — Elementary Divisibility Laws on Nat

Core divisibility laws on `Nat`, used by primes, gcd/lcm and factorization.
All facts are re-derived from `Nat`'s core arithmetic.
-/

namespace Foundations.Kernel

/-- Divisibility is reflexive. -/
theorem dvd_refl (a : Nat) : a ∣ a := Nat.dvd_refl a

/-- Divisibility is transitive. -/
theorem dvd_trans {a b c : Nat} (hab : a ∣ b) (hbc : b ∣ c) : a ∣ c :=
  Nat.dvd_trans hab hbc

/-- A number divides itself times another. -/
theorem dvd_mul_right (a b : Nat) : a ∣ a * b := Nat.dvd_mul_right a b

/-- Divisibility is closed under multiplying by a factor. -/
theorem dvd_mul_of_dvd_left {a b c : Nat} (h : a ∣ b) : a ∣ b * c :=
  Nat.dvd_trans h (Nat.dvd_mul_right b c)

/-- Divisibility is closed under left multiplication. -/
theorem mul_dvd_mul_left {a b c : Nat} (h : a ∣ b) : c * a ∣ c * b :=
  Nat.mul_dvd_mul_left c h

/-- Divisibility is antisymmetric. -/
theorem dvd_antisymm {m n : Nat} (hmn : m ∣ n) (hnm : n ∣ m) : m = n :=
  Nat.dvd_antisymm hmn hnm

/-- Dividing a number by a divisor yields another divisor. -/
theorem div_dvd_of_dvd {n m : Nat} (h : n ∣ m) : m / n ∣ m :=
  Nat.div_dvd_of_dvd h

/-- Divisibility agrees with a zero remainder. -/
theorem dvd_iff_mod_eq_zero {m n : Nat} : m ∣ n ↔ n % m = 0 :=
  Nat.dvd_iff_mod_eq_zero

/-- A zero remainder is a divisibility witness. -/
theorem dvd_of_mod_eq_zero {m n : Nat} (h : n % m = 0) : m ∣ n :=
  Nat.dvd_iff_mod_eq_zero.2 h

/-- A positive divisor is at most the dividend. -/
theorem le_of_dvd {m n : Nat} (h : 0 < n) (hm : m ∣ n) : m ≤ n :=
  Nat.le_of_dvd h hm

/-- Divisor of a quotient: `a ∣ b / c` iff `c * a ∣ b`. -/
theorem div_dvd_iff_mul_dvd {a b c : Nat} (hbc : c ∣ b) : a ∣ b / c ↔ c * a ∣ b :=
  Nat.dvd_div_iff_mul_dvd hbc

/-- Divisibility is closed under addition. -/
theorem dvd_add {a b c : Nat} (h₁ : a ∣ b) (h₂ : a ∣ c) : a ∣ b + c :=
  Nat.dvd_add h₁ h₂

/-- Divisibility is closed under subtraction. -/
theorem dvd_sub {k m n : Nat} (h₁ : k ∣ m) (h₂ : k ∣ n) : k ∣ m - n :=
  Nat.dvd_sub h₁ h₂

/-- If `k * m ∣ k * n` for a positive `k`, then `m ∣ n`. -/
theorem dvd_of_mul_dvd_mul_left {k m n : Nat} (kpos : 0 < k) (h : k * m ∣ k * n) :
    m ∣ n :=
  Nat.dvd_of_mul_dvd_mul_left kpos h

/-- Cancellation of common divisors by division. -/
theorem div_dvd_of_dvd_left {a b : Nat} (h : a ∣ b) : b / a ∣ b :=
  Nat.div_dvd_of_dvd h

end Foundations.Kernel
