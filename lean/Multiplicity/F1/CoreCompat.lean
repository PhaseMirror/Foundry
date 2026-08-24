/-
F1 core-compatibility shims for the Lean toolchain upgrade (v4.33.0-rc1).

Two constants were renamed/removed in recent core:
  * `Nat.pos_pow_of_pos k (h : 0 < n) : 0 < n ^ k`  →  now `Nat.one_le_pow`
  * `Int.natAbs_ofNat : ((n : Int).natAbs) = n`     →  now defeq (`rfl`), name gone

This module restores the historical names so the F1.Square analysis spine
(written against the older core) compiles unmodified. Import this wherever a
file references either constant. Zero dependencies beyond Lean core.
-/

namespace Nat

/-- Restored shim: strict positivity of a power from positivity of the base. -/
theorem pos_pow_of_pos (k : Nat) {n : Nat} (h : 0 < n) : 0 < n ^ k :=
  Nat.one_le_pow k n h

end Nat

namespace Int

/-- Restored shim: `natAbs` is the identity on nonnegative (cast) integers. -/
theorem natAbs_ofNat {n : Nat} : (n : Int).natAbs = n := rfl

end Int

/-- Historical helper restored: plain natural power `b ^ k`, referenced throughout
    the F1 analysis spine (`expSumM`, `CosSin`, `Gamma*` families). -/
def npow (b k : Nat) : Nat := b ^ k

theorem npow_zero (b : Nat) : npow b 0 = 1 := rfl

theorem npow_succ (b n : Nat) : npow b (n + 1) = b * npow b n := by
  show b ^ (n + 1) = b * b ^ n
  rw [Nat.pow_succ, Nat.mul_comm]

/-- Historical helper restored: positivity of a power with positive base. -/
theorem npow_pos {b : Nat} (hb : 0 < b) (k : Nat) : 0 < npow b k :=
  Nat.pos_pow_of_pos k hb

/-- Historical helper restored: `npow b 1 = b`. -/
theorem npow_one (b : Nat) : npow b 1 = b := by
  show b ^ 1 = b
  rw [Nat.pow_one]

/-- Historical helper restored: monotonicity of `npow` in the exponent for positive base. -/
theorem npow_mono {i : Nat} (hi : 0 < i) {a b : Nat} (h : a ≤ b) : npow i a ≤ npow i b :=
  Nat.pow_le_pow_right hi h

/-- Historical helper restored (base-one form): `npow 1 n = 1`. -/
theorem npow_one_left (n : Nat) : npow 1 n = 1 := by
  show (1 : Nat) ^ n = 1
  exact Nat.one_pow n
