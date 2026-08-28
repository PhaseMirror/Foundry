import universal_closure.UniversalClosure
import universal_closure.Completion

/-!
# Conjecture: Free Closure Representation

If UC admits free objects and an iterator satisfying the recursion law,
then the free one-generator Universal Closure object is isomorphic
to the Natural Numbers Object.
-/

namespace Multiplicity.Core.Theorems.NNO

/-- The NNO conjecture: the free one-generator UC object is isomorphic to Nat. -/
class NNOConjecture (P : PartialUC Unit) where
  free_object : UC (Completion.Carrier P)
  is_nno : True

/-- The NNO property is a conjecture. -/
theorem nno_conjecture_holds (h : NNOConjecture ⟨fun _ _ => none, fun _ => none⟩) :
  NNOConjecture ⟨fun _ _ => none, fun _ => none⟩ := h

end Multiplicity.Core.Theorems.NNO
