import Init
import HCQA.Core

/-! # HCQA — Qudit-Classical Feedback Interface (QCFI)

Formalizes the QCFI: bidirectional communication channel between classical
optimizer and quantum hardware, implementing adaptive subspace allocation
and measurement scheduling.
-/

namespace HCQA.QCFI

open HCQA.Core

/-- QCFI configuration state. -/
structure QCFIState where
  variance : Float
  partition : SubspacePartition
  t2Times : List Float
  shotCount : Nat
  deriving Repr

/-- Reallocation mode. -/
inductive ReallocMode where
  | errorBuffering
  | compression
  | maintain
  deriving Repr

/-- Maximum of a list of floats. -/
def listMax (xs : List Float) : Float :=
  match xs with
  | [] => 0.0
  | x :: xs' => xs'.foldl (fun acc y => if y > acc then y else acc) x

/-- Minimum of a list of floats. -/
def listMin (xs : List Float) : Float :=
  match xs with
  | [] => 0.0
  | x :: xs' => xs'.foldl (fun acc y => if y < acc then y else acc) x

/-- Adaptive subspace allocation algorithm. -/
def adaptiveAlloc (state : QCFIState) (threshold : Float) : QCFIState × ReallocMode :=
  if state.variance > 0.01 ∧ listMax state.t2Times < threshold then
    let newPartition := { state.partition with compDim := state.partition.compDim - 1, synDim := state.partition.synDim + 1 }
    ({ state with partition := newPartition, shotCount := 10000 }, ReallocMode.errorBuffering)
  else if state.variance <= 0.001 ∧ listMin state.t2Times > 2 * threshold then
    let newPartition := { state.partition with compDim := state.partition.compDim + 1, synDim := state.partition.synDim - 1 }
    ({ state with partition := newPartition, shotCount := 1000 }, ReallocMode.compression)
  else (state, ReallocMode.maintain)

/-- Verified QCFI properties. -/
theorem alloc_preserves_total_dim (state : QCFIState) (threshold : Float) :
  let (newState, _) := adaptiveAlloc state threshold
  newState.partition.totalDim = state.partition.totalDim := by
  dsimp [adaptiveAlloc]
  split
  · rfl
  · split
    · rfl
    · rfl

end HCQA.QCFI
