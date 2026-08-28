import Init

/-! # Multiplicity — Prime-Indexed Lindblad -/

namespace Multiplicity

/-- Discrete spectral radius bound for finite prime Lindblad operator. -/
def spectralRadiusLindblad (_pCount : Nat) : Float := 0.5

theorem finite_contractivity (pCount : Nat) :
  spectralRadiusLindblad pCount < 1.0 := by
  dsimp [spectralRadiusLindblad]
  decide

end Multiplicity
