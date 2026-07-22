import Core.Spec.PartialUC
import Core.Spec.UniversalClosure
import Core.Spec.Completion

/-!
# Instantiation Examples

Demonstrates the spec on concrete types.
No proofs — Kani verifies the properties.
-/

def nat_partial : PartialUC Nat :=
  { compose_p := fun x y => some (x + y)
    closure_p := fun x => some (Nat.succ x) }

def nat_uc : UC Nat :=
  { compose := Nat.add
    closure := Nat.succ }

def nat_to_partial : nat_uc.toPartialUC = nat_partial := rfl
