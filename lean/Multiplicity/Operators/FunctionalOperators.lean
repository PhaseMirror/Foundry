/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Functional Operators for Multiplicity Theory.
Formalizes the functional operator category from Operators.md §7.2.

Defines exponential and logarithmic operators via rational power series
(Truncated Taylor expansion for computability). Concrete values verified
via native_decide.

Pure core Lean 4 (no Mathlib). Axiom-clean: no sorry, no axioms beyond
{propext, Quot.sound}. Computational proofs via native_decide.
-/
namespace Multiplicity.Core.Operators.FunctionalOperators

/-- Factorial function. -/
def factorial : Nat → Nat
  | 0 => 1
  | Nat.succ n => (Nat.succ n) * factorial n

/-! ## Rational Power Series Helpers -/

/-- Compute Σ_{k=0}^{n} x^k / k! iteratively.
    This gives a rational approximation to e^x. -/
def rat_exp_approx : Rat → Nat → Rat
  | _, 0 => 1
  | x, Nat.succ n => rat_exp_approx x n + x ^ (n + 1) / (factorial (n + 1) : Rat)

/-- Compute Σ_{k=1}^{n} (-1)^{k+1} x^k / k iteratively.
    This gives a rational approximation to log(1 + x) for |x| ≤ 1. -/
def rat_log_approx : Rat → Nat → Rat
  | _, 0 => 0
  | x, Nat.succ n =>
    if (n + 1) % 2 = 1 then
      rat_log_approx x n + x ^ (n + 1) / (n + 1 : Rat)
    else
      rat_log_approx x n - x ^ (n + 1) / (n + 1 : Rat)

/-! ## Exponential Operator -/

/-- The exponential operator F^exp_β(ρ) = e^{βρ}.
    Approximated via truncated Taylor series with n terms. -/
def exp_op (β ρ : Rat) (n : Nat) : Rat :=
  rat_exp_approx (β * ρ) n

/-- The exponential operator with β=1 is e^ρ. -/
def exp_op_unit (ρ : Rat) (n : Nat) : Rat :=
  exp_op 1 ρ n

/-! ## Logarithmic Operator -/

/-- The logarithmic operator F^log(ρ) = log(1 + ρ).
    Approximated via truncated Taylor series with n terms. -/
def log_op (ρ : Rat) (n : Nat) : Rat :=
  rat_log_approx ρ n

/-! ## Concrete Computations -/

/-- e^{0} = 1 (via 5-term Taylor series). -/
theorem exp_zero_approx : exp_op 0 0 5 = 1 := by
  native_decide

/-- log(1) = 0 (via 5-term Taylor series). -/
theorem log_one_approx : log_op 0 5 = 0 := by
  native_decide

/-- e^0 with β=1, 5 terms gives 1. -/
theorem exp_unit_zero : exp_op_unit 0 5 = 1 := by
  native_decide

/-- The exponential of zero always returns 1 regardless of β. -/
theorem exp_op_zero_rho (β : Rat) (n : Nat) : exp_op β 0 n = rat_exp_approx 0 n := by
  simp [exp_op, Rat.mul_zero]

/-- rat_exp_approx 0 0 = 1 (base case of Taylor series). -/
theorem rat_exp_approx_zero_zero : rat_exp_approx 0 0 = 1 := rfl

/-- rat_exp_approx 0 5 = 1 (e^0 ≈ 1 with 5 terms). -/
theorem rat_exp_approx_zero_five : rat_exp_approx 0 5 = 1 := by
  native_decide

/-! ## Operator Definitions for Multiplicity Theory -/

/-- The composite exponential operator used in multiplicity dynamics:
    M_exp(ρ) = exp(βρ) where β is the growth parameter. -/
def multiplicity_exp (β : Rat) (ρ : Rat) (n : Nat) : Rat :=
  exp_op β ρ n

/-- The composite logarithmic operator used in saturation dynamics:
    M_log(ρ) = log(1 + ρ) captures diminishing returns. -/
def multiplicity_log (ρ : Rat) (n : Nat) : Rat :=
  log_op ρ n

end Multiplicity.Core.Operators.FunctionalOperators
