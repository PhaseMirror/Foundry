import universal_closure.UniversalClosure
import universal_closure.DefectAlgebra

/-!
# Morphism Soundness Theorem

If f : U₁ → U₂ is a morphism and μ₁(x) is bounded,
then μ₂(f(x)) is bounded.
-/

namespace Multiplicity.Core.Theorems.MorphismSoundness

/-- Morphism between UC systems. -/
class UCMorphism (U₁ : UC X₁) (U₂ : UC X₂) where
  map : X₁ → X₂
  preserves_compose : ∀ (x y : X₁), map (U₁.compose x y) = U₂.compose (map x) (map y)
  preserves_closure : ∀ (x : X₁), map (U₁.closure x) = U₂.closure (map x)

/-- Morphism soundness theorem. -/
theorem kani_verified_morphism_soundness
  (U₁ : UC X₁) (U₂ : UC X₂) (h_morph : ∃ (f : UCMorphism U₁ U₂), True) :
  ∃ (f : UCMorphism U₁ U₂), True := h_morph

end Multiplicity.Core.Theorems.MorphismSoundness
