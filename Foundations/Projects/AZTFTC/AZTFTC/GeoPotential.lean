import Init
import AZTFTC.Core

/-! # AZ-TFTC — Geometric Potentials

Φ_σ(x) and V_geo(x).
-/

namespace AZTFTC.GeoPotential

open AZTFTC

/-- π constant. -/
def PI : Float := 3.141592653589793

/-- Log-Gaussian mollifier. -/
def logGaussian (sigma : Float) (v : Float) : Float :=
  let norm := 1.0 / (Float.sqrt (2.0 * PI) * sigma)
  norm * Float.exp (-(v * v) / (2.0 * sigma * sigma))

/-- Potency field Φ_σ. -/
def phiSigma (primes : List Nat) (alpha : List Float) (sigma : Float) (uGrid : List Float) : List Float :=
  List.map (fun uj =>
    (List.zip primes alpha).foldl (fun acc (p, a) =>
      let v := uj - Float.log (Float.ofNat p)
      acc + a * logGaussian sigma v) 0.0) uGrid

/-- Geometry potential V_geo = g Φ_σ + η Φ_σ R. -/
def vGeo (Phi : List Float) (g eta : Float) (R : List Float) : List Float :=
  List.zipWith (fun phi r => g * phi + eta * phi * r) Phi R

/-- Default alpha_p = p^{-0.5}. -/
def defaultAlpha (primes : List Nat) : List Float :=
  primes.map (fun p => Float.pow (Float.ofNat p) (-0.5))

/-- Log-coordinate grid. -/
def buildUGrid (uMin uMax : Float) (M : Nat) : List Float :=
  let du := (uMax - uMin) / Float.ofNat (M - 1)
  (List.range M).map (fun j => uMin + Float.ofNat j * du)

/-- Example Φ_σ (small system for runtime). -/
def examplePhiSigma : List Float :=
  let primes := firstNPrimes 5
  let alpha := defaultAlpha primes
  let uGrid := buildUGrid (-3.0) 7.0 10
  phiSigma primes alpha 0.2 uGrid

/-- Example V_geo (small system for runtime). -/
def exampleVGeo : List Float :=
  let Phi := examplePhiSigma
  let R := List.replicate Phi.length 0.1
  vGeo Phi (defaultG.toFloat / 100.0) (defaultEta.toFloat / 100.0) R

end AZTFTC.GeoPotential
