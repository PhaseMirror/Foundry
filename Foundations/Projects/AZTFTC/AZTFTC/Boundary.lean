import Init
import AZTFTC.Core
import AZTFTC.Operators
import AZTFTC.GeoPotential
import AZTFTC.Hilbert

/-! # AZ-TFTC — Fractal Boundary Conditions

Dirichlet teeth at log-prime positions.
-/

namespace AZTFTC.Boundary

open AZTFTC
open AZTFTC.Operators
open AZTFTC.GeoPotential
open AZTFTC.Hilbert

/-- Log-prime grid index. -/
def logPrimeIndex (p : Nat) (uMin du : Float) : Nat :=
  ((Float.log (Float.ofNat p) - uMin) / du).floor.toUInt64.toNat

/-- Is this a tooth? -/
def isTooth (primes : List Nat) (j : Nat) (uMin du : Float) : Bool :=
  primes.any (fun p => logPrimeIndex p uMin du = j)

/-- Apply fractal teeth. -/
def applyFractalTeeth (op : DiscreteOperator) (penalty : Float) : DiscreteOperator :=
  let N := op.N
  let M := op.M
  let r := op.r
  let primes := firstNPrimes N
  let uMin := -3.0
  let du := (7.0 - (-3.0)) / Float.ofNat M
  let dim := hilbertDim N M r
  let mat := (List.range dim).map (fun i =>
    let _pIdx := i / (M * r)
    let sIdx := (i % (M * r)) / r
    if isTooth (primes.take N) sIdx uMin du then
      let zeroRow := List.replicate dim 0.0
      setList zeroRow i penalty
    else
      if i < op.mat.length then op.mat[i]! else List.replicate dim 0.0)
  {
    N := N, M := M, r := r, mat := mat
  }

/-- Full 1D AZ Hamiltonian with teeth. -/
def buildAZHamiltonian (N M r : Nat) (sigma g eta c2 penalty : Float) : DiscreteOperator :=
  let primes := firstNPrimes N
  let Phi := examplePhiSigma
  let R := List.replicate Phi.length 0.1
  let Vgeo := vGeo Phi g eta R
  let op := buildHAZ N M r primes sigma g eta c2 Vgeo
  applyFractalTeeth op penalty

end AZTFTC.Boundary
