import Core.universal_closure.PartialUC
import Core.universal_closure.UniversalClosure
import Core.universal_closure.Completion

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
