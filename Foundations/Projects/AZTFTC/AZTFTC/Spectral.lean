import Init
import AZTFTC.Core
import AZTFTC.Operators
import AZTFTC.Boundary
import AZTFTC.GeoPotential
import AZTFTC.Hilbert

/-! # AZ-TFTC — Spectral Properties

Spectrum, prime-resonant stabilization, Q enhancement.
-/

namespace AZTFTC.Spectral

open AZTFTC
open AZTFTC.Operators
open AZTFTC.Boundary
open AZTFTC.GeoPotential
open AZTFTC.Hilbert

/-- Dominant eigenvalue. -/
def dominantEigenvalue (op : DiscreteOperator) (v0 : List Float) (iters : Nat) : Float :=
  powerIter op v0 iters

/-- Is mode prime-resonant? -/
def isPrimeResonant (omega_n omega_0 : Float) (primes : List Nat) (tol : Float) : Bool :=
  primes.any (fun p => Float.abs (omega_n - omega_0 * Float.log (Float.ofNat p)) < tol)

/-- Prime-overlap S_{n,p}. -/
def primeOverlap (psi uGrid : List Float) (p : Nat) (sigma : Float) : Float :=
  innerProd psi (List.zipWith (fun u psi_i => logGaussian sigma (u - Float.log (Float.ofNat p)) * psi_i) uGrid psi)

/-- Q enhancement. -/
def qEnhancement (S : Float) (kappa : Float) : Float := 1.0 + kappa * S

/-- Example spectrum (tiny system). -/
def exampleSpectrum : List Float :=
  let N := 5
  let M := 10
  let r := 1
  let primes := firstNPrimes N
  let op := buildAZHamiltonian N M r 0.2 0.05 0.01 1.0 1e12
  let v0 := normalize (List.replicate (hilbertDim N M r) 1.0)
  (List.range 3).map (fun _ => dominantEigenvalue op v0 10)

end AZTFTC.Spectral
