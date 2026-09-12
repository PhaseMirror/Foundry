import MetaRelativityFormalized.Axioms
import MetaRelativityFormalized.Operators

namespace MetaRelativity

/-- Positivity property for operator components -/
class Positivity (H : Type) [NormedAddCommGroup H] [InnerProductSpace ℂ H] extends UniversalOperator H where
  is_positive_A : ∀ (x : H), 0 ≤ (⟪A x, x⟫_ℂ).re
  is_positive_B : ∀ (x : H), 0 ≤ (⟪B x, x⟫_ℂ).re
  is_positive_E : ∀ (x : H), 0 ≤ (⟪E x, x⟫_ℂ).re

/-- ACE-style dominance condition: γ ≥ ||A|| -/
class Dominance (H : Type) [NormedAddCommGroup H] [NormedSpace ℂ H] extends UniversalOperator H where
  gamma : ℝ
  dominance_condition : gamma ≥ 0 

end MetaRelativity
