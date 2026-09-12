/-!
# Universal Closure Calculator (UCC) Core Types
Formalized without Mathlib.
-/

namespace Automorphic.UCC

class UniversalClosure (X : Type) where
  compose : X → X → X
  closure : X → X
  defect : X → Rat
  invariant : X → X
  associatorDefect : X → X → X → Rat

class ClosureLaw (X : Type) [UniversalClosure X] where
  closure_idem : ∀ x : X, UniversalClosure.closure (UniversalClosure.closure x) = UniversalClosure.closure x

class DefectLaw (X : Type) [UniversalClosure X] where
  defect_nonneg : ∀ x : X, UniversalClosure.defect x ≥ 0

end Automorphic.UCC
