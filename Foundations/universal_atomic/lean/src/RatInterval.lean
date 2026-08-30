import Init.Data.Rat.Basic

namespace Multiplicity.Core

/-- Exact rational interval representation for bounded numerical checks. -/
structure RatInterval where
  lower : Rat
  upper : Rat
  h_valid : lower ≤ upper

/-- Checks if a rational value falls strictly within the given interval. -/
def RatInterval.contains (i : RatInterval) (x : Rat) : Bool :=
  i.lower ≤ x ∧ x ≤ i.upper

end Multiplicity.Core
