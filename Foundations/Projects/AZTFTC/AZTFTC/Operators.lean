import Init
import AZTFTC.Core
import AZTFTC.Hilbert
import AZTFTC.Lawful
import AZTFTC.GeoPotential

/-! # AZ-TFTC — Operators

Universal operator U, H_ZM, H_AZ.
-/

namespace AZTFTC.Operators

open AZTFTC
open AZTFTC.Hilbert
open AZTFTC.Lawful
open AZTFTC.GeoPotential

/-- Discrete operator. -/
structure DiscreteOperator where
  N : Nat
  M : Nat
  r : Nat
  mat : List (List Float)
  deriving Repr

/-- Zero matrix. -/
def zeroMat (d : Nat) : List (List Float) := List.replicate d (List.replicate d 0.0)

/-- Set list element safely. -/
def setList {α : Type} (l : List α) (i : Nat) (v : α) : List α :=
  l.take i ++ v :: l.drop (i + 1)

/-- Set matrix entry safely. -/
def setMat (mat : List (List Float)) (i j : Nat) (v : Float) : List (List Float) :=
  mat.mapIdx (fun idx row =>
    if idx = i then setList row j v else row)

/-- Build universal operator U = A + B + E. -/
def buildU (N M r : Nat) (primes : List Nat) : DiscreteOperator :=
  let dim := hilbertDim N M r
  let aWeights := (primes.take N).map (fun p => Float.log (Float.ofNat p))
  let mat0 := zeroMat dim
  let mat1 := (List.range dim).foldl (fun mat i =>
    let w := if i < aWeights.length then aWeights[i]! else 1.0
    let mat := setMat mat i i (w + 1.0)
    let mat := if i > 0 then setMat mat i (i-1) 0.1 else mat
    let mat := if i < dim - 1 then setMat mat i (i+1) 0.1 else mat
    mat) mat0
  {
    N := N, M := M, r := r, mat := mat1
  }

/-- H_ZM = U. -/
def buildHZM (N M r : Nat) (primes : List Nat) : DiscreteOperator := buildU N M r primes

/-- H_AZ = -c² ∇² + V_geo. -/
def buildHAZ (N M r : Nat) (_primes : List Nat)
  (_sigma _g _eta c2 : Float) (Vgeo : List Float) : DiscreteOperator :=
  let dim := hilbertDim N M r
  let du := (700.0 - (-300.0)) / Float.ofNat M
  let diagVal := 2.0 * c2 / (du * du)
  let offVal := -c2 / (du * du)
  let mat0 := zeroMat dim
  let mat1 := (List.range dim).foldl (fun mat j =>
    let rowVal := if j < Vgeo.length then diagVal + Vgeo[j]! else diagVal
    let mat := setMat mat j j rowVal
    let mat := if j > 0 then setMat mat j (j-1) offVal else mat
    let mat := if j < dim - 1 then setMat mat j (j+1) offVal else mat
    mat) mat0
  {
    N := N, M := M, r := r, mat := mat1
  }

/-- Apply operator to vector. -/
def applyOp (op : DiscreteOperator) (v : List Float) : List Float :=
  op.mat.map (fun row => innerProd v row)

/-- Power iteration. -/
def powerIter (op : DiscreteOperator) (v0 : List Float) (iters : Nat) : Float :=
  let rec aux (v : List Float) (i : Nat) (acc : Float) : Float :=
    if i >= iters then acc
    else
      let w := applyOp op v
      let nw := normalize w
      let rho := innerProd v w / innerProd v v
      aux nw (i + 1) rho
  aux v0 0 0.0

end AZTFTC.Operators
