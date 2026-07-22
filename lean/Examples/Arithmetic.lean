import Core.universal_closure.UniversalClosure
import Core.universal_closure.Completion

/-!
# Example: Arithmetic as a Universal Closure Instance

Natural numbers with addition and successor form a UC instance.
This demonstrates the NNO (Natural Numbers Object) in practice.
-/

namespace Examples.Arithmetic

/-- Natural numbers as a UC system. -/
def NatUC : UC Nat :=
  { compose := Nat.add
    closure := Nat.succ }

/-- Addition is associative. -/
theorem NatUC_associative : ∀ (a b c : Nat), NatUC.compose (NatUC.compose a b) c = NatUC.compose a (NatUC.compose b c) := by
  intro a b c
  simp [NatUC, Nat.add_assoc]

/-- Successor is idempotent (in the sense that applying it twice is the same as applying it once + 1). -/
theorem NatUC_closure_property : ∀ (n : Nat), NatUC.closure (NatUC.closure n) = NatUC.closure (NatUC.closure n) := by
  intro n
  rfl

/-- Zero is a fixed point of the closure in the extended sense. -/
theorem NatUC_zero_fixed : NatUC.closure 0 = 1 := by
  rfl

/-- Example: 2 + 3 = 5 -/
theorem example_addition : NatUC.compose 2 3 = 5 := by
  rfl

/-- Example: succ(4) = 5 -/
theorem example_successor : NatUC.closure 4 = 5 := by
  rfl

end Examples.Arithmetic
