import MetaRelativityFormalized.Axioms

namespace MetaRelativity

/-- The Universal Operator stack: U = A + B + E -/
class UniversalOperator (H : Type) [Add H] where
  A : H → H -- Prime Block
  B : H → H -- Time-Sieve Block
  E : H → H -- Internal Block
  U (x : H) := A x + B x + E x

/-- Boundedness property of the Universal Operator stack -/
class BoundedOperator (H : Type) [NormedAddCommGroup H] [NormedSpace ℂ H] extends UniversalOperator H where
  is_bounded_A : ∃ (c_A : ℝ), ∀ (x : H), ‖A x‖ ≤ c_A * ‖x‖
  is_bounded_B : ∃ (c_B : ℝ), ∀ (x : H), ‖B x‖ ≤ c_B * ‖x‖
  is_bounded_E : ∃ (c_E : ℝ), ∀ (x : H), ‖E x‖ ≤ c_E * ‖x‖

/-- Self-adjoint property of the Universal Operator stack -/
class SelfAdjointOperatorStack (H : Type) [NormedAddCommGroup H] [InnerProductSpace ℂ H] extends UniversalOperator H where
  is_self_adjoint_A : ∀ x y : H, ⟪A x, y⟫_ℂ = ⟪x, A y⟫_ℂ
  is_self_adjoint_B : ∀ x y : H, ⟪B x, y⟫_ℂ = ⟪x, B y⟫_ℂ
  is_self_adjoint_E : ∀ x y : H, ⟪E x, y⟫_ℂ = ⟪x, E y⟫_ℂ

end MetaRelativity
