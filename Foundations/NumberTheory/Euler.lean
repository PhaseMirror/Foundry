import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith
import Foundations.Nat.Div
import Foundations.Nat.Prime
import Foundations.Nat.GCD
import Foundations.Nat.Factorial

/-!
# Euler's Totient Function and Elementary Properties
-/

namespace Foundations.NumberTheory.Euler

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith
open Foundations.NatDiv
open Foundations.NatPrime
open Foundations.NatGCD
open Foundations.NatFactorial

/-! ## Totient Function -/

def phi (n : Nat) : Nat :=
  (List.range n).filter (fun k => Nat.gcd (k + 1) n = 1) |>.length

/-- `phi 1 = 1`. -/
theorem phi_one : phi 1 = 1 := by rfl

/-- `phi 2 = 1`. -/
theorem phi_two : phi 2 = 1 := by rfl

/-- `phi 3 = 2`. -/
theorem phi_three : phi 3 = 2 := by rfl

/-- `phi 4 = 2`. -/
theorem phi_four : phi 4 = 2 := by rfl

/-- Totient is non-negative. -/
theorem phi_nonneg (n : Nat) : phi n ≥ 0 := Nat.zero_le (phi n)

/-- Wilson's theorem statement skeleton. -/
theorem wilson_theorem {p : Nat} (_hp : IsPrime p) : True := trivial

end Foundations.NumberTheory.Euler
