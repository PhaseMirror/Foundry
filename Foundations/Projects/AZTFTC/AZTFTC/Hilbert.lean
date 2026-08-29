import Init
import AZTFTC.Core

/-! # AZ-TFTC — Discrete Hilbert Space

Discrete approximation of H = ℓ²(P) ⊗ L²(ℝᵈ) ⊗ ℂʳ.
-/

namespace AZTFTC.Hilbert

open AZTFTC

/-- Basis vector. -/
structure BasisVector where
  primeIdx : Nat
  spatialIdx : Nat
  colorIdx : Nat
  deriving Repr, DecidableEq

/-- Dimension of truncated space. -/
def hilbertDim (N M r : Nat) : Nat := N * M * r

/-- Discrete inner product. -/
def innerProd (v w : List Float) : Float :=
  (List.zip v w).foldl (fun acc (a, b) => acc + a * b) 0.0

/-- Norm squared. -/
def normSq (v : List Float) : Float := innerProd v v

/-- Normalize vector. -/
def normalize (v : List Float) : List Float :=
  let n := Float.sqrt (normSq v)
  v.map (fun x => x / n)

/-- Zero vector. -/
def zeroVec (d : Nat) : List Float := List.replicate d 0.0

/-- Standard basis vector. -/
def basisVec (d i : Nat) : List Float :=
  (List.range d).map (fun j => if j = i then 1.0 else 0.0)

end AZTFTC.Hilbert
