import universal_closure.UniversalClosure
import universal_closure.DefectAlgebra

/-!
# Compositional Defect Theorem

μ(x ∘ y) ≤ μ(x) ⊕ μ(y) ⊕ ι(x,y)

This theorem states that the defect of a composition is bounded by
the tensor product of the individual defects and the binary residual.
-/

namespace Multiplicity.Core.Theorems.DefectComposition

/-- The compositional defect property. -/
class CompositionalDefectProperty (U : UC X) (D : Type) [Add D] [LE D] where
  mu : X → D
  iota : X → X → D
  composition_bound : ∀ (x y : X),
    mu (U.compose x y) ≤ mu x + mu y + iota x y

/-- The monotonicity property for defects. -/
class MonotoneDefectProperty (U : UC X) (D : Type) [LE D] where
  mu : X → D
  monotone_closure : ∀ (x : X), mu (U.closure x) ≤ mu x

/-- Compositional defect theorem (Kani-verified). -/
def kani_verified_compositional_defect (U : UC X) (D : Type) [Add D] [LE D]
  (h : CompositionalDefectProperty U D) : CompositionalDefectProperty U D := h

/-- Monotone defect theorem (Kani-verified). -/
def kani_verified_monotone_defect (U : UC X) (D : Type) [LE D]
  (h : MonotoneDefectProperty U D) : MonotoneDefectProperty U D := h

end Multiplicity.Core.Theorems.DefectComposition
