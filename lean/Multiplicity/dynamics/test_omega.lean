theorem test (x k : Nat) (hk : k < 10000) (h : x * 10000 ≤ k * x) : x = 0 := by
  cases x with
  | zero => rfl
  | succ x' =>
    rw [Nat.mul_comm] at h
    have h_pos : 0 < x' + 1 := Nat.zero_lt_succ x'
    have hk_lt : k * (x' + 1) < 10000 * (x' + 1) := Nat.mul_lt_mul_of_pos_right hk h_pos
    omega
