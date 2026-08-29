namespace MathFormalization

/-- A very simple ring structure over Nat (addition, multiplication). -/
structure Ring where
  carrier : Type
  zero : carrier
  one : carrier
  add : carrier → carrier → carrier
  mul : carrier → carrier → carrier
  add_comm : ∀ a b, add a b = add b a
  add_assoc : ∀ a b c, add (add a b) c = add a (add b c)
  mul_comm : ∀ a b, mul a b = mul b a
  mul_assoc : ∀ a b c, mul (mul a b) c = mul a (mul b c)
  left_distrib : ∀ a b c, mul a (add b c) = add (mul a b) (mul a c)
  right_distrib : ∀ a b c, mul (add a b) c = add (mul a c) (mul b c)
  zero_mul : ∀ a, mul zero a = zero
  mul_zero : ∀ a, mul a zero = zero
  one_mul : ∀ a, mul one a = a
  mul_one : ∀ a, mul a one = a

/-- Instance of the trivial ring on Nat. -/
instance : Ring where
  carrier := Nat
  zero := Nat.zero
  one := Nat.succ Nat.zero
  add := Nat.add
  mul := Nat.mul
  add_comm := Nat.rec (fun b => by simp [Nat.add]) (fun a ih b => by simp [Nat.add, ih, Nat.succ_add])
  add_assoc := sorry  -- placeholder for longer proof
  mul_comm := sorry
  mul_assoc := sorry
  left_distrib := sorry
  right_distrib := sorry
  zero_mul := by intro a; simp [Nat.mul]
  mul_zero := by intro a; simp [Nat.mul]
  one_mul := by intro a; simp [Nat.mul]
  mul_one := by intro a; simp [Nat.mul]

end MathFormalization
