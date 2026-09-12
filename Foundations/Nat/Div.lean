import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.NatDiv

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith

/-! ## Basic Properties -/

/-- Divisibility is reflexive. -/
theorem dvd_refl (a : Nat) : a ∣ a := Nat.dvd_refl a

/-- Divisibility is transitive. -/
theorem dvd_trans {a b c : Nat} (hab : a ∣ b) (hbc : b ∣ c) : a ∣ c :=
  Nat.dvd_trans hab hbc

/-- `0 ∣ a` iff `a = 0`. -/
theorem zero_dvd {a : Nat} : (0 : Nat) ∣ a ↔ a = 0 := Nat.zero_dvd

/-- `a ∣ 0` for any `a`. -/
theorem dvd_zero (a : Nat) : a ∣ 0 := Nat.dvd_zero a

/-- `1 ∣ a` for any `a`. -/
theorem one_dvd (a : Nat) : (1 : Nat) ∣ a := Nat.one_dvd a

/-- Divisibility is antisymmetric (for natural numbers). -/
theorem dvd_antisymm {m n : Nat} (hm : m ∣ n) (hn : n ∣ m) : m = n :=
  Nat.dvd_antisymm hm hn

/-! ## Divisibility and Arithmetic -/

/-- `a ∣ a * b`. -/
theorem dvd_mul_right (a b : Nat) : a ∣ a * b := Nat.dvd_mul_right a b

/-- `a ∣ b * a`. -/
theorem dvd_mul_left (a b : Nat) : a ∣ b * a := Nat.dvd_mul_left a b

/-- If `a ∣ b` and `a ∣ c` then `a ∣ b + c`. -/
theorem dvd_add {a b c : Nat} (hab : a ∣ b) (hac : a ∣ c) : a ∣ b + c :=
  Nat.dvd_add hab hac

/-- If `a ∣ b` and `a ∣ c` then `a ∣ b - c`. -/
theorem dvd_sub {a b c : Nat} (hab : a ∣ b) (hac : a ∣ c) : a ∣ b - c :=
  Nat.dvd_sub hab hac

/-! ## Divisibility and Modulo -/

/-- `a ∣ b` iff `b % a = 0`. -/
theorem dvd_iff_mod_eq_zero {a b : Nat} : a ∣ b ↔ b % a = 0 :=
  Nat.dvd_iff_mod_eq_zero

/-- Divisibility implies the quotient divides. -/
theorem div_dvd_of_dvd {n m : Nat} (h : n ∣ m) : m / n ∣ m :=
  Nat.div_dvd_of_dvd h

end Foundations.NatDiv
