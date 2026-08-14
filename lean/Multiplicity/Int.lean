/-!
# Multiplicity Kernel — Integers (ADR-0001 Phase 1 scope)

`Int` is Lean's integer type.  The kernel certifies the floor-division
identity, sign bounds of `/` and `%`, and the `Nat → Int` embedding.
-/

namespace Multiplicity.Kernel

/-- Floor division identity: `a = a / b * b + a % b`. -/
theorem int_div_mul_add_mod (a b : Int) : a / b * b + a % b = a :=
  Int.ediv_mul_add_emod a b

/-- Division of non-negatives is non-negative. -/
theorem int_div_nonneg {a b : Int} (ha : 0 ≤ a) (hb : 0 ≤ b) : 0 ≤ a / b :=
  Int.ediv_nonneg ha hb

/-- The remainder is non-negative for a non-zero divisor. -/
theorem int_mod_nonneg (a : Int) {b : Int} (hb : b ≠ 0) : 0 ≤ a % b :=
  Int.emod_nonneg a hb

/-- `0 ≤ n` as an integer. -/
theorem int_ofNat_nonneg (n : Nat) : 0 ≤ Int.ofNat n := by
  simp [Int.ofNat_eq_natCast]

/-- `Int.ofNat` agrees with the typeclass embedding. -/
theorem int_ofNat_eq_natCast (n : Nat) : Int.ofNat n = (n : Int) :=
  Int.ofNat_eq_natCast n

/-- Division by the negation flips the sign. -/
theorem int_div_neg (a b : Int) : a / (-b) = -(a / b) := Int.ediv_neg a b

/-- Cancellation: `(a * b) / b = a` for `b ≠ 0`. -/
theorem int_mul_ediv_cancel (a : Int) {b : Int} (hb : b ≠ 0) : a * b / b = a :=
  Int.mul_ediv_cancel a hb

/-- Absolute value is non-negative. -/
theorem int_natAbs_nonneg (a : Int) : 0 ≤ a.natAbs := Nat.zero_le _

/-- Round-trip: a non-negative integer embeds back to its natural value. -/
theorem int_toNat_of_nonneg {a : Int} (h : 0 ≤ a) : Int.ofNat a.toNat = a :=
  Int.toNat_of_nonneg h

end Multiplicity.Kernel
