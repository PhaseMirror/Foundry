import Core.universal_closure.PartialUC

/-!
# Total Universal Closure System — Formal Spec

Pure definition. No proofs. No sorry. No Mathlib.
Kani verifies the implementation satisfies this spec.
-/

structure UC (X : Type) where
  compose : X → X → X
  closure : X → X

class IdempotentClosure (U : UC X) : Prop where
  idempotent : ∀ x, U.closure (U.closure x) = U.closure x

class AssociativeCompose (U : UC X) : Prop where
  associative : ∀ x y z, U.compose (U.compose x y) z = U.compose x (U.compose y z)

def toPartialUC (U : UC X) : PartialUC X :=
  { compose_p := fun x y => some (U.compose x y)
    closure_p := fun x => some (U.closure x) }
