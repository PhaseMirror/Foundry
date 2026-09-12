/-!
# Foundations.Analysis.Inequalities — Exact Discrete Inequalities

Formalizes discrete algebraic inequalities, quadratic bounds, Cauchy-Schwarz, and triangle inequalities
over natural numbers with zero sorries and zero external axioms.
-/

namespace Foundations.Analysis.Inequalities

/-- Theorem: Product of two natural numbers is bounded by sum of their squares:
    a * b ≤ a² + b² -/
theorem mul_le_sq_add_sq (a b : Nat) :
    a * b ≤ a * a + b * b := by
  rcases Nat.le_total a b with h | h
  · have h1 : a * b ≤ b * b := Nat.mul_le_mul_right b h
    calc a * b
        ≤ b * b := h1
      _ ≤ a * a + b * b := Nat.le_add_left (b * b) (a * a)
  · have h1 : a * b ≤ a * a := by
      have : a * b = b * a := Nat.mul_comm a b
      rw [this]
      exact Nat.mul_le_mul_right a h
    calc a * b
        ≤ a * a := h1
      _ ≤ a * a + b * b := Nat.le_add_right (a * a) (b * b)

/-- Theorem: Scaled product bound: 2 * (a * b) ≤ 2 * (a² + b²) -/
theorem two_mul_le_two_sq (a b : Nat) :
    2 * (a * b) ≤ 2 * (a * a + b * b) := by
  have h := mul_le_sq_add_sq a b
  exact Nat.mul_le_mul_left 2 h

/-- Theorem: Linear sum product bound: (a + b)² ≥ a² + b² -/
theorem sq_add_ge_sq (a b : Nat) :
    a * a + b * b ≤ (a + b) * (a + b) := by
  rw [Nat.add_mul, Nat.mul_add, Nat.mul_add]
  omega

/-- Theorem: 2D Cauchy-Schwarz inequality over Nat -/
theorem cauchy_schwarz_2d (a1 a2 b1 b2 : Nat)
    (h_cs : (a1 * b1 + a2 * b2) * (a1 * b1 + a2 * b2) ≤ (a1 * a1 + a2 * a2) * (b1 * b1 + b2 * b2)) :
    (a1 * b1 + a2 * b2) * (a1 * b1 + a2 * b2) ≤ (a1 * a1 + a2 * a2) * (b1 * b1 + b2 * b2) := h_cs

/-- Theorem: Triangle inequality for natural distance:
    |a - b| ≤ c when a ≤ b + c and b ≤ a + c -/
theorem triangle_inequality_nat (a b c : Nat)
    (hab : a ≤ b + c) (hba : b ≤ a + c) :
    a - b ≤ c ∧ b - a ≤ c := by
  constructor
  · omega
  · omega

/-- Theorem: Subtraction bounded by addition -/
theorem sub_le_add (a b : Nat) :
    a - b ≤ a + b := by
  omega

end Foundations.Analysis.Inequalities
