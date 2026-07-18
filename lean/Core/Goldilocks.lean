namespace Core.Goldilocks

/-- The Goldilocks Prime p = 2^64 - 2^32 + 1 -/
def p : Nat := 2^64 - 2^32 + 1

instance : NeZero p := ⟨by decide⟩

/-- Goldilocks Finite Field -/
abbrev Field := Fin p

instance : Coe Nat Field where
  coe n := ⟨n % p, Nat.mod_lt _ (by decide)⟩

instance : Add Field where
  add a b := ⟨(a.val + b.val) % p, Nat.mod_lt _ (by decide)⟩

instance : Sub Field where
  sub a b := ⟨(a.val + (p - b.val)) % p, Nat.mod_lt _ (by decide)⟩

instance : Mul Field where
  mul a b := ⟨(a.val * b.val) % p, Nat.mod_lt _ (by decide)⟩

instance : One Field where
  one := ⟨1 % p, Nat.mod_lt _ (by decide)⟩

instance : Zero Field where
  zero := ⟨0, Nat.mod_lt _ (by decide)⟩

def Field.pow (base : Field) : Nat → Field
  | 0 => (1 : Field)
  | k + 1 => base * Field.pow base k

@[simp] theorem field_mul_one (a : Field) : a * (1 : Field) = a := by
  apply Fin.ext
  simp [Mul.mul, One.one, Nat.mod_mul_left_mod]

@[simp] theorem field_one_mul (a : Field) : (1 : Field) * a = a := by
  apply Fin.ext
  simp [Mul.mul, One.one, Nat.mod_mul_left_mod]

@[simp] theorem field_mul_comm (a b : Field) : a * b = b * a := by
  apply Fin.ext
  simp [Mul.mul, Nat.mul_comm]

@[simp] theorem field_mul_assoc (a b c : Field) : (a * b) * c = a * (b * c) := by
  apply Fin.ext
  simp [Mul.mul, Nat.mul_assoc]

@[simp] theorem field_distrib (a b c : Field) : a * (b + c) = a * b + a * c := by
  apply Fin.ext
  simp [Mul.mul, Add.add, Nat.mod_mul_left_mod, Nat.mul_add, Nat.add_mod_mod, Nat.mul_mod]

@[simp] theorem field_add_comm (a b : Field) : a + b = b + a := by
  apply Fin.ext
  simp [Add.add, Nat.add_comm]

@[simp] theorem field_add_assoc (a b c : Field) : (a + b) + c = a + (b + c) := by
  apply Fin.ext
  simp [Add.add, Nat.add_assoc]

@[simp] theorem field_add_zero (a : Field) : a + (0 : Field) = a := by
  apply Fin.ext
  simp [Add.add, Zero.zero, Nat.add_mod_mod]

@[simp] theorem field_sub_self (a : Field) : a - a = (0 : Field) := by
  apply Fin.ext
  simp [Sub.sub]

@[simp] theorem pow_add (a : Field) (m n : Nat) : a ^ (m + n) = a ^ m * a ^ n := by
  induction n with
  | zero =>
      simp [Nat.add_zero]
  | succ n ih =>
      simp [Nat.add_succ, ih, Nat.succ_eq_add_one, mul_assoc]

@[simp] theorem pow_mul (a : Field) (m n : Nat) : (a ^ m) ^ n = a ^ (m * n) := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      simp [Nat.succ_mul, ih, mul_assoc]

end Core.Goldilocks
