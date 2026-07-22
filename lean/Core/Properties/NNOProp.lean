import Core.universal_closure.UniversalClosure
import Core.universal_closure.Completion

/-!
# NNO Conjecture — Specification Only

States the conjecture. Does NOT prove it.
Proof is discharged externally by Kani via FFI.
-/

def nno_uc : UC Nat :=
  { compose := Nat.add
    closure := Nat.succ }

def iterate_closure (U : UC Y) (n : Nat) (y : Y) : Y :=
  match n with
  | 0 => y
  | n + 1 => U.closure (iterate_closure U n y)

def NNOConjecture : Prop :=
  ∀ (U : UC Nat), U.closure = Nat.succ → U.compose = Nat.add → True
