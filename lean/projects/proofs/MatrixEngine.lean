import Kernel

/-!
# MatrixEngine — prime-indexed encoding & identity neutrality

Formalizes two Matrix Prime Compute Engine invariants:
1. Encoding by a fixed prime is injective (no two values collide).
2. The discrete identity matrix is left-neutral on its diagonal entries.

No `Mathlib`, no `sorry`.
-/
namespace MatrixEngine

open proofs.Kernel

/-- Encode `v` under prime `p` as `p * v`. -/
def primeEncode (p v : Nat) : Nat := p * v

/-- Encoding by a non-zero scalar is injective (no collisions). -/
theorem prime_encode_injective (p v w : Nat) (hnz : p ≠ 0) (h : primeEncode p v = primeEncode p w) :
    v = w := Nat.mul_left_cancel hnz h

/-- A 2×2 matrix over `Nat`. -/
def M22 := Matrix 2 2 Nat

/-- The identity matrix is left-neutral on diagonal entries. -/
theorem id_left_diag (A : M22) (i : Fin 2) : Matrix.id 2 i i * A i i = A i i := by
  simp [Matrix.id]

/-- The identity matrix is right-neutral on diagonal entries. -/
theorem id_right_diag (A : M22) (i : Fin 2) : A i i * Matrix.id 2 i i = A i i := by
  simp [Matrix.id]

end MatrixEngine
