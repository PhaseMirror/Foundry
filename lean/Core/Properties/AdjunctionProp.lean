import Core.universal_closure.Completion

/-!
# Adjunction Property — Specification Only

States what must be true. Does NOT prove it.
Proof is discharged externally by Kani via FFI.
-/

open Completion

def AdjunctionProperty {X : Type} (P : PartialUC X) : Prop :=
  ∀ {Y : Type} (V : UC Y) (f : X → Y)
    (h_comp : ∀ x y z, P.compose_p x y = some z → V.compose (f x) (f y) = f z)
    (h_close : ∀ x y, P.closure_p x = some y → V.closure (f x) = f y),
    ∃ (g : Carrier P → Y),
      (∀ x, g (var_embed P x) = f x) ∧
      (∀ a b, g (compose_q P a b) = V.compose (g a) (g b)) ∧
      (∀ a, g (closure_q P a) = V.closure (g a))
