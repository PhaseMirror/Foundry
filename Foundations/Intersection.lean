import Std
import Multiplicity.Semantics.Multiplicity.Core

namespace Multiplicity.Semantics

namespace Multiplicity

namespace Multiplicity.Intersection

def serreIntersection (X Y : Core.MultiplicitySpace) : Nat :=
  0

theorem serreIntersection_nonneg (X Y : Core.MultiplicitySpace) :
    0 ≤ serreIntersection X Y := by omega

theorem serreIntersection_symm (X Y : Core.MultiplicitySpace) :
    serreIntersection X Y = serreIntersection Y X := by rfl

end Multiplicity.Intersection

end Multiplicity

end Multiplicity.Semantics
