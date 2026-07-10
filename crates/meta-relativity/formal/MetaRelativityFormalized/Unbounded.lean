import MetaRelativityFormalized.Axioms

namespace MetaRelativity

/-- Trait to check if an operator is sectorial with angle phi. -/
class SectorialCheck (H : Type) where
  is_sectorial : H → ℝ → Prop

/-- Check Kato–Rellich relative form-boundedness: ||K|| < bound * ||A0|| -/
def is_form_bounded (k_norm : ℝ) (a0_norm : ℝ) (bound : ℝ) : Prop :=
  k_norm < bound * a0_norm

end MetaRelativity
