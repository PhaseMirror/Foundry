import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.NatFactorial

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith

def factorial : Nat → Nat
  | 0     => 1
  | n + 1 => (n + 1) * factorial n

@[simp] theorem factorial_zero : factorial 0 = 1 := rfl

theorem factorial_succ (n : Nat) : factorial (n + 1) = (n + 1) * factorial n := by
  simp [factorial]

theorem factorial_pos : ∀ n, 1 ≤ factorial n
  | 0     => Nat.le_refl 1
  | n + 1 => by
    rw [factorial]
    have ih := factorial_pos n
    apply Nat.le_trans ih
    apply Nat.le_mul_of_pos_left
    omega

theorem le_factorial : ∀ n, 1 ≤ n → n ≤ factorial n
  | 0, h => by omega
  | 1, _ => by simp [factorial]
  | n + 2, _ => by
    rw [factorial]
    apply Nat.le_mul_of_pos_right
    have hp := factorial_pos (n + 1)
    omega

private theorem factorial_dvd_succ (m : Nat) : factorial m ∣ factorial (m + 1) := by
  rw [factorial_succ]
  exact Nat.dvd_mul_left (factorial m) (m + 1)

theorem factorial_dvd : ∀ {n m : Nat}, n ≤ m → factorial n ∣ factorial m := by
  intro n m h
  induction m with
  | zero =>
    have : n = 0 := by omega
    subst this
    exact Nat.dvd_refl (factorial 0)
  | succ m ih =>
    cases Nat.eq_or_lt_of_le h with
    | inl heq =>
      subst heq
      exact Nat.dvd_refl _
    | inr hlt =>
      have hnm := Nat.le_of_lt_succ hlt
      exact Nat.dvd_trans (ih hnm) (factorial_dvd_succ m)

end Foundations.NatFactorial
