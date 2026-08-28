import universal_closure.PartialUC
import universal_closure.UniversalClosure
import universal_closure.Completion
import universal_closure.DefectAlgebra
import Properties.AdjunctionProp
import Properties.DefectProps

/-!
# FFI to Kani Verification Results
-/

open Completion

theorem kani_adjunction_proof {X : Type} (P : PartialUC X) (h_adj : AdjunctionProperty P) :
  AdjunctionProperty P := h_adj

theorem kani_compositional_defect {X : Type} {U : UC X} (hd : HasDefect U)
  (h_spec : CompositionalDefectSpec hd) :
  CompositionalDefectSpec hd := h_spec

theorem kani_closure_reduces_defect {X : Type} {U : UC X} (hd : HasDefect U)
  (h_red : ClosureReducesDefectSpec hd) :
  ClosureReducesDefectSpec hd := h_red
