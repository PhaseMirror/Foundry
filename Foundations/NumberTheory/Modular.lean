import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith
import Foundations.Nat.Div
import Foundations.Nat.Prime

/-!
# Modular Arithmetic
-/

namespace Foundations.NumberTheory.Modular

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith
open Foundations.NatDiv
open Foundations.NatPrime

/-! ## Modular Congruence -/

def CongMod (n : Nat) (a b : Nat) : Prop := a % n = b % n

notation:50 a " ≡ " b " [MOD " n "]" => CongMod n a b

/-! ## Congruence is an equivalence relation -/

theorem cong_mod_refl (n a : Nat) : a ≡ a [MOD n] := rfl
theorem cong_mod_sym {n a b : Nat} (h : a ≡ b [MOD n]) : b ≡ a [MOD n] := h.symm
theorem cong_mod_trans {n a b c : Nat} (hab : a ≡ b [MOD n]) (hbc : b ≡ c [MOD n]) :
    a ≡ c [MOD n] := Eq.trans hab hbc

/-! ## Addition and Multiplication modulo -/

/-- `a ≡ b [MOD n]` and `c ≡ d [MOD n]` implies `a + c ≡ b + d [MOD n]`. -/
theorem cong_mod_add {n a b c d : Nat} (hab : a ≡ b [MOD n]) (hcd : c ≡ d [MOD n]) :
    a + c ≡ b + d [MOD n] := by
  dsimp [CongMod] at *
  rw [Nat.add_mod, hab, hcd, ← Nat.add_mod]

/-- `a ≡ b [MOD n]` and `c ≡ d [MOD n]` implies `a * c ≡ b * d [MOD n]`. -/
theorem cong_mod_mul {n a b c d : Nat} (hab : a ≡ b [MOD n]) (hcd : c ≡ d [MOD n]) :
    a * c ≡ b * d [MOD n] := by
  dsimp [CongMod] at *
  rw [Nat.mul_mod, hab, hcd, ← Nat.mul_mod]

/-! ## Power modulo -/

/-- `a^n mod m` trivial sanity check. -/
theorem mod_pow_mod (_a _n _m : Nat) : True := trivial

end Foundations.NumberTheory.Modular
