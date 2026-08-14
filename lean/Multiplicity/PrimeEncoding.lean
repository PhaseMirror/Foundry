import Std
import Multiplicity.Semantics.Multiplicity.Core

namespace Multiplicity.Semantics

namespace Multiplicity

namespace Multiplicity.PrimeEncoding

def PrimeSignature : Type := List Core.Prime

def primeSignature (n : Nat) : PrimeSignature :=
  Core.primeFactors n

def signatureProduct (s : PrimeSignature) : Nat :=
  s.foldl (fun acc p => acc * p) 1

theorem signatureProduct_nonneg (s : PrimeSignature) :
    0 ≤ signatureProduct s := by omega

theorem signatureProduct_one : signatureProduct [] = 1 := by rfl

end Multiplicity.PrimeEncoding

end Multiplicity

end Multiplicity.Semantics
