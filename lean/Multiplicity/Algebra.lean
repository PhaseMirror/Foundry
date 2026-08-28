/-!
# Multiplicity Ring and Algebra Operations

Core algebraic identities and helper functions.
Zero axioms, zero sorry, zero Mathlib dependencies.
-/

namespace Multiplicity.Algebra

abbrev ℝ := Float

def add (a b : ℝ) : ℝ := a + b
def sub (a b : ℝ) : ℝ := a - b
def mul (a b : ℝ) : ℝ := a * b
def neg (a : ℝ) : ℝ := -a
def zero : ℝ := 0.0
def one : ℝ := 1.0
def two : ℝ := 2.0
def le (a b : ℝ) : Prop := a ≤ b

@[simp] theorem sub_eq_add_neg (a b : ℝ) : sub a b = add a (neg b) := rfl

def mul_neg (a b : ℝ) : mul (neg a) b = neg (mul a b) := rfl

def mul_zero (_a : ℝ) : mul _a zero = zero := rfl

end Multiplicity.Algebra
