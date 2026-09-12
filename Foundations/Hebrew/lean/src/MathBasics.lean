namespace MathFormalization

/-- The natural numbers, defined inductively. -/
inductive Nat where
  | zero : Nat
  | succ : Nat → Nat

deriving Repr, Inhabited

/-- Addition on Nat defined by recursion. -/
protected def Nat.add : Nat → Nat → Nat
  | .zero, n => n
  | .succ m, n => Nat.succ (Nat.add m n)

instance : Add Nat := ⟨Nat.add⟩

/-- Multiplication on Nat defined by recursion. -/
protected def Nat.mul : Nat → Nat → Nat
  | .zero, _ => .zero
  | .succ m, n => n + Nat.mul m n

instance : Mul Nat := ⟨Nat.mul⟩

/-- Prove addition is commutative (by recursion). -/
theorem add_comm : ∀ a b : Nat, a + b = b + a :=
  Nat.rec (fun b => by
    -- base case a = zero
    simp [Nat.add]
  ) (fun a ih b => by
    -- inductive step a = succ a'
    simp [Nat.add, ih, Nat.succ_add]
  )

end MathFormalization
