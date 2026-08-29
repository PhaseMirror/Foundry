import Std
import Foundations.Semantics.Multiplicity.Core

namespace Multiplicity.Semantics

namespace Multiplicity

namespace Multiplicity.JMultiplicity

def jMultiplicity (I : Core.MultiplicitySpace) (R : Nat) : Nat :=
  0

theorem jMultiplicity_nonneg (I : Core.MultiplicitySpace) (R : Nat) :
    0 ≤ jMultiplicity I R := by omega

theorem jMultiplicity_le_dim (I : Core.MultiplicitySpace) (R : Nat) :
    jMultiplicity I R ≤ I.dimension := by
  simp [jMultiplicity]

end Multiplicity.JMultiplicity

end Multiplicity

end Multiplicity.Semantics
