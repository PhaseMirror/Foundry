/-!
# PhaseMirror Observatory
Core Discrete Structures - Sedona Spine Compliant
-/

namespace PhaseMirror

/-- Discrete Exact Rational -/
structure ExactRat where
  num : Int
  den : Nat
  h_den : den > 0

/-- Core State for PhaseMirror -/
structure State (dim : Nat) where
  resonance : ExactRat
  multiplicity_gain : Int
  fuel_bound : Nat

end PhaseMirror
