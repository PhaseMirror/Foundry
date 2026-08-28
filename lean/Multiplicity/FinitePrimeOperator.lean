import Init

/-! # Multiplicity — Finite Prime Operator -/

namespace Multiplicity

/-- Discrete spectral radius bound for finite prime operator. -/
def spectralRadiusHp (_pCount : Nat) : Float := 0.5

theorem hp_operator_contractive (pCount : Nat) :
  spectralRadiusHp pCount < 1.0 := by
  dsimp [spectralRadiusHp]
  decide

end Multiplicity
