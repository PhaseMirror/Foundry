import CulturalMath.Base

namespace CulturalMath.Egyptian

-- Egyptian multiplication
def egyptianMulAux : Nat → Nat → Nat → Nat
  | 0,     _, acc => acc
  | n + 1, b, acc => egyptianMulAux n b (acc + b)

def egyptianMul (a b : Nat) := egyptianMulAux a b 0

-- Core lemma
private theorem mulAux_eq (a b acc : Nat) : egyptianMulAux a b acc = a * b + acc := by
  induction a generalizing acc with
  | zero => simp [egyptianMulAux]
  | succ n ih =>
    simp only [egyptianMulAux]
    have := ih (acc + b)
    have h2 : (n + 1) * b = n * b + b := by rw [Nat.add_mul, Nat.one_mul]
    omega

theorem egyptianMul_eq_mul (a b : Nat) : egyptianMul a b = a * b := by
  unfold egyptianMul; simp [mulAux_eq]

-- Proportional reasoning
def proportional (a b c d : Nat) : Prop := a * d = b * c

theorem proportional_refl (a b : Nat) : proportional a b a b :=
  (Nat.mul_comm b a).symm

theorem proportional_symm {a b c d : Nat} (h : proportional a b c d) :
    proportional c d a b := by
  unfold proportional at h ⊢; rw [Nat.mul_comm c b, Nat.mul_comm d a]; exact h.symm

-- n + n = 2 * n
theorem double_eq (n : Nat) : n + n = 2 * n := by rw [show 2 = 1 + 1 from rfl, Nat.add_mul, Nat.one_mul]

-- Halving even numbers
theorem halve_double_even (n : Nat) (_ : n % 2 = 0) : (n + n) / 2 = n := by
  rw [double_eq, Nat.mul_div_cancel_left n (by omega : 2 > 0)]

-- Unit fractions
def UnitFrac := Nat × Nat
def UnitFracIsValid : UnitFrac → Prop := fun ⟨_, d⟩ => d ≥ 2

-- Egyptian decomposition validity
def IsValidDecomp (ds : List Nat) : Prop :=
  (∀ d ∈ ds, d ≥ 2) ∧ List.Nodup ds

theorem empty_decomp_valid : IsValidDecomp [] := by simp [IsValidDecomp]

end CulturalMath.Egyptian
