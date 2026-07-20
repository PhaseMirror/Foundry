import META_RELATIVITY.Core

/-!
# META_RELATIVITY Spectral Invariants

Multiplicity functor and related spectral properties.
All definitions use `Nat`. Zero axioms, zero sorry.
-/

namespace META_RELATIVITY

/-! ## Multiplicity Functor -/

/-- The Multiplicity Functor: M(e, bound) iteratively accumulates
    `(p+2)^{e(p+2)}` for p = 0, ..., bound-1. -/
def multiplicity (e : Nat → Nat) : Nat → Nat
  | 0 => 1
  | n + 1 => multiplicity e n * (n + 2) ^ e (n + 2)

/-- M(e, 0) = 1 (empty product). -/
theorem multiplicity_zero (e : Nat → Nat) : multiplicity e 0 = 1 := rfl

/-- Multiplicity result is always ≥ 1. -/
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

/-- M with all-zero exponents is 1. -/
theorem multiplicity_all_zero : ∀ n, multiplicity (fun _ => 0) n = 1
  | 0 => rfl
  | n + 1 => by
    simp only [multiplicity, Nat.pow_zero, Nat.mul_one]
    exact multiplicity_all_zero n

end META_RELATIVITY
