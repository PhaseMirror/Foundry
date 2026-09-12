def two_pow_pos (n : Nat) : 0 < 2 ^ n := by
  induction n with
  | zero => decide
  | succ n ih =>
    rw [Nat.pow_succ]
    omega

def one_le_two_pow (n : Nat) : 1 ≤ 2 ^ n := by
  induction n with
  | zero => decide
  | succ n ih =>
    rw [Nat.pow_succ]
    omega
