import Foundations.MetaRelativity.Core

/-!
# Foundations.MetaRelativity.Invariants — Multiplicity Functor & Spectral Invariants

Formalizes the Multiplicity Functor accumulating prime power factors.
-/

namespace Foundations.MetaRelativity

def multiplicity (e : Nat → Nat) : Nat → Nat
  | 0 => 1
  | n + 1 => multiplicity e n * (n + 2) ^ e (n + 2)

theorem multiplicity_zero (e : Nat → Nat) : multiplicity e 0 = 1 := rfl

theorem multiplicity_ge_one : ∀ (e : Nat → Nat) (n : Nat), multiplicity e n ≥ 1
  | _, 0 => by simp [multiplicity]
  | e, n + 1 => by
    simp only [multiplicity]
    have ih := multiplicity_ge_one e n
    have h_base : (n + 2) ^ e (n + 2) ≥ 1 :=
      Nat.one_le_pow (e (n + 2)) (n + 2) (by omega)
    have : multiplicity e n * (n + 2) ^ e (n + 2) ≥ 1 * 1 :=
      Nat.mul_le_mul ih h_base
    omega

theorem multiplicity_all_zero : ∀ n, multiplicity (fun _ => 0) n = 1
  | 0 => rfl
  | n + 1 => by
    simp only [multiplicity, Nat.pow_zero, Nat.mul_one]
    exact multiplicity_all_zero n

end Foundations.MetaRelativity
