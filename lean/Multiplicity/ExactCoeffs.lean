/-
  ExactCoeffs
  Thin, one-way adapter that specialises the certified Muir-Stinson
  normalizer to ordinary NAF (w = 2).  No production spectral module
  is modified.
-/

import Multiplicity.NAF

namespace Multiplicity.ComplexKappa.ExactCoeffs

/-- Ordinary (width-2) NAF digit stream of an integer. -/
def naf (n : Int) : List Int :=
  UOR.MuirStinson.normalize_integer_w 2 n

theorem naf_sound (n : Int) :
    UOR.MuirStinson.evaluate_wNAF (naf n) = n :=
  UOR.MuirStinson.normalize_integer_w_sound 2 (by decide) n

theorem naf_normal (n : Int) :
    (∀ d ∈ naf n, UOR.MuirStinson.is_wNAFDigit 2 d) ∧ 
    UOR.MuirStinson.is_wNonAdjacent 2 (naf n) :=
  UOR.MuirStinson.normalize_integer_w_normal 2 (by decide) n

/-- Convenience alias for later exact-coefficient work. -/
def exactDigitStream (c : Int) : List Int := naf c

end Multiplicity.ComplexKappa.ExactCoeffs
