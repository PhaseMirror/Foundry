import Automorphic.UCC

/-!
# Banach Contraction for Universal Closure Composition
Formalized without Mathlib.
-/

namespace Automorphic.UCC.Banach

open Automorphic.UCC

variable {X : Type} [UniversalClosure X]

def defectMetric (x y : X) : Rat :=
  UniversalClosure.defect x + UniversalClosure.defect y

theorem defectMetric_symm (x y : X) : defectMetric x y = defectMetric y x := by
  dsimp [defectMetric]
  exact Rat.add_comm (UniversalClosure.defect x) (UniversalClosure.defect y)

end Automorphic.UCC.Banach
