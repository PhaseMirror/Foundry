import Foundations.PeanoN.Nat
import Foundations.PeanoN.Order
import Foundations.PeanoN.Div

/-!
# Foundations: PeanoN (from-scratch core) Tests

Exercises the self-contained reconstruction of `ℕ` from Peano's axioms
(`Foundations.PeanoN.*`). Every assertion below is a theorem — no mathlib,
no `sorry`.
-/

namespace Foundations.PeanoN.Tests

open Foundations.PeanoN

-- Peano axioms
theorem test_p1 (n : Nat) : Nat.zero ≠ Nat.succ n := Nat.zero_ne_succ n
theorem test_p2 {m n : Nat} (h : Nat.succ m = Nat.succ n) : m = n := Nat.succ_inj h
theorem test_induction {P : Nat → Prop} (h0 : P Nat.zero)
    (hS : ∀ n, P n → P (Nat.succ n)) : ∀ n, P n := Nat.induction_law P h0 hS

-- Arithmetic laws
theorem test_add_comm (m n : Nat) : Nat.add m n = Nat.add n m := Nat.add_comm m n
theorem test_add_assoc (m n k : Nat) : Nat.add (Nat.add m n) k = Nat.add m (Nat.add n k) :=
  Nat.add_assoc m n k
theorem test_mul_comm (m n : Nat) : Nat.mul m n = Nat.mul n m := Nat.mul_comm m n
theorem test_mul_assoc (m n k : Nat) : Nat.mul (Nat.mul m n) k = Nat.mul m (Nat.mul n k) :=
  Nat.mul_assoc m n k
theorem test_mul_add (m a b : Nat) : Nat.mul m (Nat.add a b) = Nat.add (Nat.mul m a) (Nat.mul m b) :=
  Nat.mul_add m a b

-- Order
theorem test_le_total (m n : Nat) : Nat.Le m n ∨ Nat.Le n m := Nat.le_total m n
theorem test_le_antisymm {m n : Nat} (h1 : Nat.Le m n) (h2 : Nat.Le n m) : m = n :=
  Nat.le_antisymm h1 h2
theorem test_well_ordering {P : Nat → Prop} (hex : ∃ n, P n) :
    ∃ m, P m ∧ ∀ n, P n → Nat.Le m n := Nat.well_ordering hex
theorem test_trichotomy (m n : Nat) : Nat.Lt m n ∨ m = n ∨ Nat.Lt n m := Nat.trichotomy m n

-- Subtraction
theorem test_sub_add (a b : Nat) : Nat.sub (Nat.add a b) a = b := Nat.sub_add a b
theorem test_sub_le (a b : Nat) : Nat.Le (Nat.sub a b) a := Nat.sub_le a b

-- Division and modulo
theorem test_div_mod (a b : Nat) (hb : b ≠ Nat.zero) :
    a = Nat.add (Nat.mul b (Nat.div a b)) (Nat.mod a b) := Nat.div_mod a b hb
theorem test_mod_lt (a b : Nat) (hb : b ≠ Nat.zero) : Nat.Lt (Nat.mod a b) b := Nat.mod_lt a b hb

-- Divisibility
theorem test_dvd_refl (a : Nat) : Nat.dvd a a := Nat.dvd_refl a
theorem test_one_dvd (a : Nat) : Nat.dvd Nat.one a := Nat.one_dvd a
theorem test_dvd_zero (a : Nat) : Nat.dvd a Nat.zero := Nat.dvd_zero a
theorem test_dvd_mul_right (a b : Nat) : Nat.dvd a (Nat.mul a b) := Nat.dvd_mul_right a b

end Foundations.PeanoN.Tests
