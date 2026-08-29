namespace Foundations.Peano

/-! ## Peano Axioms (stated as propositions about `Nat`) -/

/-- P1: Zero is not the successor of any number. -/
theorem peano_zero_ne_succ (n : Nat) : Nat.zero ≠ Nat.succ n := by
  intro h
  exact Nat.noConfusion h

/-- P2: Injectivity of successor. -/
theorem peano_succ_inj {m n : Nat} (h : Nat.succ m = Nat.succ n) : m = n :=
  Nat.succ_inj.mp h

/-- P3: Zero is the additive identity (left). -/
theorem peano_zero_add (n : Nat) : Nat.zero + n = n := Nat.zero_add n

/-- P3: Zero is the additive identity (right). -/
theorem peano_add_zero (n : Nat) : n + Nat.zero = n := Nat.add_zero n

/-- P4: Successor addition (left). -/
theorem peano_succ_add (m n : Nat) : Nat.succ m + n = Nat.succ (m + n) :=
  Nat.succ_add m n

/-! ## Addition: Commutativity and Associativity -/

/-- Addition is commutative. -/
theorem peano_add_comm (m n : Nat) : m + n = n + m := Nat.add_comm m n

/-- Addition is associative. -/
theorem peano_add_assoc (m n k : Nat) : (m + n) + k = m + (n + k) :=
  Nat.add_assoc m n k

/-! ## Multiplication -/

/-- Multiplication: zero left. -/
theorem peano_mul_zero (n : Nat) : Nat.zero * n = Nat.zero :=
  Nat.zero_mul n

/-- Multiplication: zero right. -/
theorem peano_mul_zero' (n : Nat) : n * Nat.zero = Nat.zero :=
  Nat.mul_zero n

/-- Multiplication: successor. -/
theorem peano_mul_succ (m n : Nat) : m * Nat.succ n = m * n + m :=
  Nat.mul_succ m n

/-- Multiplication: successor left. -/
theorem peano_succ_mul (m n : Nat) : Nat.succ m * n = m * n + n :=
  Nat.succ_mul m n

/-- Multiplication is commutative. -/
theorem peano_mul_comm (m n : Nat) : m * n = n * m := Nat.mul_comm m n

/-- Multiplication is associative. -/
theorem peano_mul_assoc (m n k : Nat) : (m * n) * k = m * (n * k) :=
  Nat.mul_assoc m n k

/-! ## Distributivity -/

/-- Left distributivity. -/
theorem peano_mul_add (m n k : Nat) : m * (n + k) = m * n + m * k :=
  Nat.mul_add m n k

/-- Right distributivity. -/
theorem peano_add_mul (m n k : Nat) : (m + n) * k = m * k + n * k :=
  Nat.add_mul m n k

/-! ## Power -/

/-- Power: base case. -/
theorem peano_pow_zero (m : Nat) : m ^ (0 : Nat) = 1 :=
  Nat.pow_zero m

/-- Power: successor. -/
theorem peano_pow_succ (m n : Nat) : m ^ Nat.succ n = m ^ n * m :=
  Nat.pow_succ m n

/-! ## One and Two -/

/-- One is the multiplicative identity (left). -/
theorem peano_one_mul (n : Nat) : 1 * n = n :=
  Nat.one_mul n

/-- One is the multiplicative identity (right). -/
theorem peano_mul_one (n : Nat) : n * 1 = n :=
  Nat.mul_one n

/-! ## Subtraction -/

/-- `a - a = 0`. -/
theorem peano_sub_self (a : Nat) : a - a = 0 := Nat.sub_self a

/-- `a - 0 = a`. -/
theorem peano_sub_zero (a : Nat) : a - 0 = a := Nat.sub_zero a

/-! ## Order -/

/-- `a ≤ a`. -/
theorem peano_le_refl (a : Nat) : a ≤ a := Nat.le_refl a

/-- `a ≤ b → a ≤ b + c`. -/
theorem peano_le_add_right {a b : Nat} (h : a ≤ b) (c : Nat) : a ≤ b + c :=
  Nat.le_add_right_of_le h

/-- `a + b ≤ a + c → b ≤ c`. -/
theorem peano_add_le_cancel {a b c : Nat} (h : a + b ≤ a + c) : b ≤ c :=
  Nat.add_le_add_iff_left.mp h

/-! ## Division and Modulo -/

/-- `a % b < b` for positive `b`. -/
theorem peano_mod_lt (a b : Nat) (h : 0 < b) : a % b < b :=
  Nat.mod_lt a h

/-- `a = a / b * b + a % b`. -/
theorem peano_div_mod (a b : Nat) : a = a / b * b + a % b := by
  have h := Nat.div_add_mod a b
  rw [Nat.mul_comm b (a / b)] at h
  exact h.symm

/-! ## Absolute Value / Max -/

/-- `max a b ≥ a`. -/
theorem peano_le_max_left (a b : Nat) : a ≤ Nat.max a b :=
  Nat.le_max_left a b

/-- `max a b ≥ b`. -/
theorem peano_le_max_right (a b : Nat) : b ≤ Nat.max a b :=
  Nat.le_max_right a b

end Foundations.Peano
