import Foundations.FPES.Core
import Foundations.FPES.Proofs

/-!
# FPES FFI — Lean 4 side (ADR-0029 §4)

Exported C ABI symbols callable from Rust via FFI.  The flat API takes
primitive arrays and builds `HypothesisSpace` internally.
-/

set_option compiler.ignoreBorrowAnnotation true

namespace FPES.FFI

open FPES

/-- Build a `List Path` from parallel id/class arrays. -/
def mkPaths (pathIds pathCls : Array UInt32) : List Path :=
  Id.run do
    let n := pathIds.size
    let mut ps : List Path := []
    for i in [:n] do
      ps := ps ++ [{ id := pathIds[i]!.toNat, cls := pathCls[i]!.toNat }]
    return ps

/-- Build a `List EquivalenceClass` from an id array. -/
def mkClasses (clsIds : Array UInt32) : List EquivalenceClass :=
  Id.run do
    let n := clsIds.size
    let mut cs : List EquivalenceClass := []
    for i in [:n] do
      cs := cs ++ [{ id := clsIds[i]!.toNat }]
    return cs

/-- `fpes_check_paths`: check `Viable` on a space given as flat arrays.
    Returns `true` iff `NoDupClasses ∧ Registered ∧ ClassesNonempty`.
    Symbol: `fpes_check_paths_ffi` on the Rust side. -/
@[export fpes_check_paths_ffi]
def fpesCheckPaths
    (pathIds : Array UInt32)
    (pathCls : Array UInt32)
    (clsIds  : Array UInt32)
    : Bool :=
  let H : HypothesisSpace :=
    { paths := mkPaths pathIds pathCls, classes := mkClasses clsIds }
  decide (Viable H)

/-- `fpes_multiplicity_count`: return the multiplicity of class `classId`.
    Symbol: `fpes_multiplicity_count_ffi`. -/
@[export fpes_multiplicity_count_ffi]
def fpesMultiplicityCount
    (pathIds  : Array UInt32)
    (pathCls  : Array UInt32)
    (classId  : UInt32)
    : UInt32 :=
  let paths := mkPaths pathIds pathCls
  let c : EquivalenceClass := { id := classId.toNat }
  (countInClass paths c).toUInt32

/-- `fpes_representatives_count`: return the number of representatives after
    contraction.  Symbol: `fpes_representatives_count_ffi`. -/
@[export fpes_representatives_count_ffi]
def fpesRepresentativesCount
    (pathIds  : Array UInt32)
    (pathCls  : Array UInt32)
    (clsIds   : Array UInt32)
    : UInt32 :=
  let H : HypothesisSpace :=
    { paths := mkPaths pathIds pathCls, classes := mkClasses clsIds }
  (representatives H).length.toUInt32

/-- Handle-based viability check (placeholder for lean_rs integration). -/
@[export fpes_check_paths]
def fpesCheckPathsOpaque (_h : UInt64) : Bool := true

end FPES.FFI
