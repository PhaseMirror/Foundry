import Init
import GodelianTruth.Core
import GodelianTruth.Gamma
import GodelianTruth.Contraction
import GodelianTruth.Godel
import GodelianTruth.PrimeSieved
import GodelianTruth.LawfulSchedules
import GodelianTruth.Conservative

/-! # Godelian Truth Examples

Concrete instantiations of core types and theorems.
-/

namespace GodelianTruth.Examples

open GodelianTruth
open GodelianTruth.Gamma
open GodelianTruth.Contraction
open GodelianTruth.PrimeSieved

/-- Example: zero valuation. -/
def exZeroV : Valuation := zeroValuation

/-- Example: half valuation. -/
def exHalfV : Valuation := halfValuation

/-- Example: Γ applied to zero valuation. -/
def exGammaZero : Valuation := Gamma exZeroV

/-- Example: T_λ applied to zero valuation. -/
def exTLambdaZero : Valuation := TLambda exZeroV lambda alpha defaultBias

/-- Example: prime list up to 20. -/
def exPrimes20 : List Nat := primesUpTo 20

/-- Example: π(100). -/
def exPi100 : Nat := pi 100

/-- Example: prime-sieved iteration from zero. -/
def exPrimeIter0 : Valuation := primeSievedIterate exZeroV lambda alpha defaultBias 0
def exPrimeIter1 : Valuation := primeSievedIterate exZeroV lambda alpha defaultBias 1
def exPrimeIter2 : Valuation := primeSievedIterate exZeroV lambda alpha defaultBias 2
def exPrimeIter3 : Valuation := primeSievedIterate exZeroV lambda alpha defaultBias 3

/-- Example: contraction factor. -/
def exContract : Nat := contractionFactor

end GodelianTruth.Examples
