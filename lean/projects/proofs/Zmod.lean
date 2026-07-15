import Kernel

/-!
# Zmod — modular arithmetic primitives

Formalizes the ZMOD modular-arithmetic invariants: residues stay in `[0, m)` and
addition respects the modulus. No `Mathlib`, no `sorry`.
-/
namespace Zmod

open proofs.Kernel

/-- Residue of `a` modulo `m` (requires `m > 0`). -/
def mod (a m : Nat) (h : 0 < m) : Nat := a % m

/-- The residue is strictly below the modulus. -/
theorem mod_bounds (a m : Nat) (h : 0 < m) : mod a m h < m := Nat.mod_lt a h

/-- Addition commutes with reduction modulo `m`. -/
theorem mod_add (a b m : Nat) (h : 0 < m) :
    (mod a m h + mod b m h) % m = mod (a + b) m h := by
  simp [mod]
  exact Nat.mod_add_mod a b m

/-- Modulus-1 arithmetic is trivial. -/
theorem mod_one (a : Nat) : mod a 1 (by decide) = 0 := by simp [mod]

end Zmod
