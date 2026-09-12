import Init
import AZTFTC.Core
import AZTFTC.Hilbert
import AZTFTC.Lawful
import AZTFTC.Operators
import AZTFTC.GeoPotential
import AZTFTC.Boundary
import AZTFTC.Spectral
import AZTFTC.Casimir

/-! # AZ-TFTC — Examples

Concrete instantiations.
-/

namespace AZTFTC.Examples

open AZTFTC
open AZTFTC.Operators
open AZTFTC.GeoPotential
open AZTFTC.Boundary
open AZTFTC.Spectral
open AZTFTC.Casimir
open AZTFTC.Hilbert

/-- Example: first 10 primes. -/
def exPrimes10 : List Nat := firstNPrimes 10

/-- Example: π(50) = 15. -/
def exPi50 : Nat := pi 50

/-- Example: zero vector. -/
def exZeroVec : List Float := zeroVec 5

/-- Example: basis vector. -/
def exBasisVec : List Float := basisVec 5 2

/-- Example: Φ_σ with tiny system. -/
def examplePhiSigma : List Float :=
  let primes := firstNPrimes 5
  let alpha := defaultAlpha primes
  let uGrid := buildUGrid (-3.0) 7.0 10
  phiSigma primes alpha 0.2 uGrid

/-- Example: V_geo with tiny system. -/
def exVGeoSmall : List Float :=
  let Phi := examplePhiSigma
  let R := List.replicate Phi.length 0.1
  vGeo Phi 0.05 0.01 R

/-- Example: tiny AZ Hamiltonian. -/
def exSmallOp : DiscreteOperator :=
  buildAZHamiltonian 5 10 1 0.2 0.05 0.01 1.0 1e12

/-- Example: dominant eigenvalue. -/
def exDominantEval : Float :=
  let op := exSmallOp
  let v0 := normalize (List.replicate (hilbertDim 5 10 1) 1.0)
  dominantEigenvalue op v0 10

/-- Example: Casimir deviation with tiny system. -/
def exDeltaTiny : Float :=
  deltaCasimir 500.0 5 10 1 0.2 0.05 0.01 1.0 1e12 1.0

/-- Example: curvature shift with tiny system. -/
def exampleCurvShift : Float :=
  let N := 5
  let M := 10
  let r := 1
  let Phi := examplePhiSigma
  let R := List.replicate Phi.length 0.1
  let PhiR := List.zipWith (fun phi r => phi * r) Phi R
  let psi := normalize (List.replicate (hilbertDim N M r) (1.0 / Float.sqrt (Float.ofNat (hilbertDim N M r))))
  curvatureShift psi PhiR 0.01

end AZTFTC.Examples
