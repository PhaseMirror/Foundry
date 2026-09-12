/-!
# Foundations.Operators.Functional — Rational Power Series & Functional Multiplicity Operators

Formalizes truncated Taylor power series for rational exponential and logarithmic operators,
growth dynamics functions, and exact evaluators.
-/

namespace Foundations.Operators.Functional

/-- Factorial function. -/
def factorial : Nat → Nat
  | 0 => 1
  | Nat.succ n => (Nat.succ n) * factorial n

/-- Truncated Taylor approximation of $e^x = \sum_{k=0}^n x^k / k!$. -/
def rat_exp_approx : Rat → Nat → Rat
  | _, 0 => 1
  | x, Nat.succ n => rat_exp_approx x n + x ^ (n + 1) / (factorial (n + 1) : Rat)

/-- Truncated Taylor approximation of $\ln(1+x) = \sum_{k=1}^n (-1)^{k+1} x^k / k$. -/
def rat_log_approx : Rat → Nat → Rat
  | _, 0 => 0
  | x, Nat.succ n =>
    if (n + 1) % 2 = 1 then
      rat_log_approx x n + x ^ (n + 1) / (n + 1 : Rat)
    else
      rat_log_approx x n - x ^ (n + 1) / (n + 1 : Rat)

/-- Exponential operator $F^{\exp}_\beta(\rho) = e^{\beta \rho}$. -/
def exp_op (β ρ : Rat) (n : Nat) : Rat :=
  rat_exp_approx (β * ρ) n

/-- Unit exponential operator $e^\rho$. -/
def exp_op_unit (ρ : Rat) (n : Nat) : Rat :=
  exp_op 1 ρ n

/-- Logarithmic operator $F^{\log}(\rho) = \ln(1 + \rho)$. -/
def log_op (ρ : Rat) (n : Nat) : Rat :=
  rat_log_approx ρ n

/-- Theorem: $e^0 = 1$ via 5-term Taylor approximation. -/
theorem exp_zero_approx : exp_op 0 0 5 = 1 := by
  native_decide

/-- Theorem: $\ln(1) = 0$ via 5-term Taylor approximation. -/
theorem log_one_approx : log_op 0 5 = 0 := by
  native_decide

/-- Theorem: Unit exponential at zero gives 1. -/
theorem exp_unit_zero : exp_op_unit 0 5 = 1 := by
  native_decide

/-- Theorem: Zero density always yields base Taylor approximation. -/
theorem exp_op_zero_rho (β : Rat) (n : Nat) : exp_op β 0 n = rat_exp_approx 0 n := by
  simp [exp_op, Rat.mul_zero]

/-- Composite exponential operator $M_{\exp}(\rho)$. -/
def multiplicity_exp (β : Rat) (ρ : Rat) (n : Nat) : Rat :=
  exp_op β ρ n

/-- Composite logarithmic operator $M_{\log}(\rho)$. -/
def multiplicity_log (ρ : Rat) (n : Nat) : Rat :=
  log_op ρ n

end Foundations.Operators.Functional
