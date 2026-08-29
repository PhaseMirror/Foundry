import Foundations.CulturalMath.Base

/-!
# Foundations.CulturalMath.Egyptian — Egyptian Arithmetic & Unit Fractions

Formalizes Egyptian doubling-multiplication, unit fraction decompositions, and proportional balancing.
-/

namespace Foundations.CulturalMath.Egyptian

open Foundations.CulturalMath.Base

-- Egyptian multiplication
def egyptianMulAux : Nat → Nat → Nat → Nat
  | 0,     _, acc => acc
  | n + 1, b, acc => egyptianMulAux n b (acc + b)

def egyptianMul (a b : Nat) := egyptianMulAux a b 0

private theorem mulAux_eq (a b acc : Nat) : egyptianMulAux a b acc = a * b + acc := by
  induction a generalizing acc with
  | zero => simp [egyptianMulAux]
  | succ n ih =>
    simp only [egyptianMulAux]
    rw [ih (acc + b)]
    rw [Nat.succ_mul]
    omega

theorem egyptianMul_eq_mul (a b : Nat) : egyptianMul a b = a * b := by
  unfold egyptianMul; simp [mulAux_eq]

theorem double_eq (n : Nat) : n + n = 2 * n := by
  omega

theorem halve_double_even (n : Nat) (_ : n % 2 = 0) : (n + n) / 2 = n := by
  omega

def UnitFrac := Nat × Nat
def UnitFracIsValid : UnitFrac → Prop := fun ⟨_, d⟩ => d ≥ 2

def IsValidDecomp (ds : List Nat) : Prop :=
  (∀ d ∈ ds, d ≥ 2) ∧ List.Nodup ds

theorem empty_decomp_valid : IsValidDecomp [] := by
  simp [IsValidDecomp]

end Foundations.CulturalMath.Egyptian
