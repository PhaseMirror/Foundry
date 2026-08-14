/-- PrimeIndex module without Mathlib -/

namespace Multiplicity.MetaMathematics

-- A simple primality predicate (naïve definition)
structure PrimeIndex where
  n : Nat
  isPrime : Bool -- true iff n is prime (naïve)

-- Weight function for a given exponent α

def weight (α : Real) (p : PrimeIndex) : Real :=
  (p.n.toReal) ^ α

-- Positivity of weight for any prime (assuming α is real and p.n > 1)

theorem weight_pos (α : Real) (p : PrimeIndex) (hpos : (p.n : Real) > 0) :
  0 < weight α p :=
by
  -- Since (p.n : Real) > 0 and real power of a positive base is positive
  have : (p.n.toReal) ^ α > 0 := by
    have hp : 0 < p.n.toReal := hpos
    exact Real.rpow_pos_of_pos hp α
  exact this

end Multiplicity.MetaMathematics

