/-!
# Core compatibility shims (Lean core v4.33 drift)

Small helpers removed or renamed in recent Lean core releases, restored here so
the displaced F1-square bricks compile against stock core (no Mathlib).
Also provides the historical `npow` natural-power family consumed across the
restored analysis layer.
-/

/-- Historical alias: positive bases have positive powers (pre-`one_le_pow` name). -/
theorem Nat.pos_pow_of_pos (k : Nat) {n : Nat} (h : 0 < n) : 0 < n ^ k :=
  Nat.one_le_pow k n h

/-- Historical alias: `natAbs` of a numeral-coercion is the coercion itself. -/
theorem Int.natAbs_ofNat {n : Nat} : (n : Int).natAbs = n := rfl

/-- Historical natural-power family (unreduced, `b ^ k`). -/
def npow (b k : Nat) : Nat := b ^ k

theorem npow_zero (b : Nat) : npow b 0 = 1 := rfl

theorem npow_succ (b n : Nat) : npow b (n + 1) = b * npow b n := by
  show b ^ (n + 1) = b * b ^ n
  rw [Nat.pow_succ, Nat.mul_comm]

theorem npow_pos {b : Nat} (hb : 0 < b) (k : Nat) : 0 < npow b k := by
  show (0:Nat) < b ^ k
  have h1 := Nat.one_le_pow k b hb
  omega

theorem npow_one (b : Nat) : npow b 1 = b := by
  show b ^ 1 = b
  rw [Nat.pow_one]

theorem npow_one_left (n : Nat) : npow 1 n = 1 := by
  show (1 : Nat) ^ n = 1
  exact Nat.one_pow n

theorem npow_two (b : Nat) : npow b 2 = b * b := by
  rw [show ((2 : Nat) = 1 + 1) from rfl, npow_succ, npow_one]

theorem npow_mono {i a b : Nat} (hi : 0 < i) (h : a ≤ b) : npow i a ≤ npow i b :=
  Nat.pow_le_pow_right hi h
