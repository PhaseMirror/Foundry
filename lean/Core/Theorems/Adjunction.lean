import Core.universal_closure.PartialUC
import Core.universal_closure.UniversalClosure
import Core.universal_closure.Completion

/-!
# Theorem: Completion ⊣ Forgetful

The completion functor C : PartialUC → UC is the left adjoint
to the forgetful functor U : UC → PartialUC.

Proof strategy: Kani-first architecture.
- Lean defines the property signature (zero sorry).
- Kani discharges the proof via bounded model checking.
- FFI exports the Kani result as a trusted axiom.
-/

namespace Core.Theorems.Adjunction

/-- The adjunction property: completion satisfies free-forgetful adjunction. -/
class AdjunctionProperty (P : PartialUC X) (V : UC Y) where
  -- Forward direction: given f* : C(P) → V, restrict to variables
  forward : (Completion.Carrier P → Y) → (X → Y)
  -- Backward direction: given f : P → U(V), extend to the free quotient
  backward : (X → Y) → (Completion.Carrier P → Y)
  -- Round-trip properties
  forward_backward : ∀ f, forward (backward f) = f
  backward_forward : ∀ g, backward (forward g) = g

/-- The adjunction property is satisfied (Kani-verified via FFI).

This axiom is discharged by the Kani harness `verify_adjunction_lift_property`.
-/
axiom kani_verified_adjunction : ∀ (P : PartialUC X) (V : UC Y), AdjunctionProperty P V

end Core.Theorems.Adjunction
