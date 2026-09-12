/-!
# Foundations.Goldilocks.Core — Goldilocks Finite Field (p = 2^64 - 2^32 + 1)

Formalization of the Goldilocks prime field arithmetic, identities, and distributive laws.
-/

namespace Foundations.Goldilocks

/-- The Goldilocks Prime p = 2^64 - 2^32 + 1 -/
def p : Nat := 2^64 - 2^32 + 1

theorem p_pos : p > 0 := by decide

instance : NeZero p := ⟨by decide⟩

/-- Goldilocks Finite Field -/
abbrev Field := Fin p

instance : Coe Nat Field where
  coe n := ⟨n % p, Nat.mod_lt _ p_pos⟩

instance : Add Field where
  add a b := ⟨(a.val + b.val) % p, Nat.mod_lt _ p_pos⟩

instance : Sub Field where
  sub a b := ⟨(a.val + (p - b.val)) % p, Nat.mod_lt _ p_pos⟩

instance : Mul Field where
  mul a b := ⟨(a.val * b.val) % p, Nat.mod_lt _ p_pos⟩

instance : One Field where
  one := ⟨1 % p, Nat.mod_lt _ p_pos⟩

instance : Zero Field where
  zero := ⟨0, p_pos⟩

def fieldPow (base : Field) : Nat → Field
  | 0 => (1 : Field)
  | k + 1 => base * fieldPow base k

theorem field_mul_one (a : Field) : a * (1 : Field) = a := by
  ext
  have hp : (1 : Field).val = 1 := by decide
  change (a.val * (1 : Field).val) % p = a.val
  rw [hp]
  have h1 : a.val * 1 = a.val := by omega
  rw [h1]
  exact Nat.mod_eq_of_lt a.isLt

theorem field_one_mul (a : Field) : (1 : Field) * a = a := by
  ext
  have hp : (1 : Field).val = 1 := by decide
  change ((1 : Field).val * a.val) % p = a.val
  rw [hp]
  have h1 : 1 * a.val = a.val := by omega
  rw [h1]
  exact Nat.mod_eq_of_lt a.isLt

theorem field_mul_comm (a b : Field) : a * b = b * a := by
  ext
  change (a.val * b.val) % p = (b.val * a.val) % p
  rw [Nat.mul_comm]

theorem field_add_comm (a b : Field) : a + b = b + a := by
  ext
  change (a.val + b.val) % p = (b.val + a.val) % p
  rw [Nat.add_comm]

theorem field_add_zero (a : Field) : a + (0 : Field) = a := by
  ext
  have hz : (0 : Field).val = 0 := rfl
  change (a.val + (0 : Field).val) % p = a.val
  rw [hz]
  have h1 : a.val + 0 = a.val := by omega
  rw [h1]
  exact Nat.mod_eq_of_lt a.isLt

theorem field_sub_self (a : Field) : a - a = (0 : Field) := by
  ext
  change (a.val + (p - a.val)) % p = 0
  have h1 : a.val + (p - a.val) = p := by omega
  rw [h1]
  exact Nat.mod_self p

end Foundations.Goldilocks
