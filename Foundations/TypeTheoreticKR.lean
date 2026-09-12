/-! TypeTheoreticKR.lean - Multiplicity Type-Theoretic Knowledge Representation -/

namespace MultiplicityKR

/-- 
  A Projector Π extracts invariant and event content at a given level.
  It is defined as an idempotent endomorphism on a space X.
-/
structure Projector (X : Type) where
  map : X → X
  idemp : map ∘ map = map

/-- 
  A Rotation Operator R acting on the same space X.
-/
structure Rotation (X : Type) where
  map : X → X

/--
  Definition (Axiomatic constraint): Projector-Rotation invariance at the same level.
  Π_ℓ ∘ R^(ℓ) = Π_ℓ
-/
def projector_rotation_invariant {X : Type} (Pi : Projector X) (R : Rotation X) : Prop :=
  Pi.map ∘ R.map = Pi.map

/--
  Theorem: If a rotation is invariant under a projector, applying the rotation
  multiple times (e.g., twice) preserves this invariance.
-/
theorem double_rotation_invariant {X : Type} (Pi : Projector X) (R : Rotation X)
  (h : projector_rotation_invariant Pi R) :
  Pi.map ∘ (R.map ∘ R.map) = Pi.map := by
  unfold projector_rotation_invariant at h
  have h1 : Pi.map ∘ (R.map ∘ R.map) = (Pi.map ∘ R.map) ∘ R.map := rfl
  rw [h1, h, h]

end MultiplicityKR
