import Init
import AZTFTC.Core
import AZTFTC.Operators
import AZTFTC.Boundary
import AZTFTC.Spectral
import AZTFTC.Hilbert
import AZTFTC.GeoPotential

/-! # AZ-TFTC — Casimir Predictions

Casimir-force deviations and curvature-weighted shifts.
-/

namespace AZTFTC.Casimir

open AZTFTC
open AZTFTC.Operators
open AZTFTC.Boundary
open AZTFTC.Spectral
open AZTFTC.Hilbert
open AZTFTC.GeoPotential

/-- π constant. -/
def PI : Float := 3.141592653589793

/-- Standard 1D Casimir force proxy. -/
def casimirStd (L_nm : Float) : Float :=
  let L := L_nm * 1e-9
  (-(PI * PI * 1.0) / (24.0 * L * L))

/-- Zero-point energy. -/
def zpe (omegas : List Float) (hbar : Float) : Float :=
  0.5 * hbar * (omegas.foldl (fun acc w => acc + w) 0.0)

/-- AZ Casimir force. -/
def casimirAZ (omegas : List Float) (L_nm : Float) (hbar : Float) : Float :=
  let E := zpe omegas hbar
  let dL := 1e-9
  (-(E - zpe omegas hbar) / dL)

/-- Relative deviation δ(L). -/
def deltaCasimir (L_nm : Float) (N M r : Nat) (sigma g eta c2 penalty hbar : Float) : Float :=
  let primes := firstNPrimes N
  let op := buildAZHamiltonian N M r sigma g eta c2 penalty
  let v0 := normalize (List.replicate (hilbertDim N M r) 1.0)
  let eigs := (List.range M).map (fun _ => dominantEigenvalue op v0 20)
  let omegas := eigs.map (fun e => if e > 0 then Float.sqrt e else 0.0)
  let f_az := casimirAZ omegas L_nm hbar
  let f_std := casimirStd L_nm
  (f_az - f_std) / f_std

/-- Example: δ(500 nm) with tiny system. -/
def exampleDelta500nm : Float :=
  deltaCasimir 500.0 5 10 1 0.2 0.05 0.01 1.0 1e12 1.0

/-- Curvature shift δω_n ≈ η ⟨ψ_n| Φ_σ R |ψ_n⟩. -/
def curvatureShift (psi PhiR : List Float) (eta : Float) : Float :=
  eta * innerProd psi PhiR

/-- Example curvature shift with tiny system. -/
def exampleCurvatureShift : Float :=
  let N := 5
  let M := 10
  let r := 1
  let Phi := examplePhiSigma
  let R := List.replicate Phi.length 0.1
  let PhiR := List.zipWith (fun phi r => phi * r) Phi R
  let psi := normalize (List.replicate (hilbertDim N M r) (1.0 / Float.sqrt (Float.ofNat (hilbertDim N M r))))
  curvatureShift psi PhiR 0.01

end AZTFTC.Casimir
