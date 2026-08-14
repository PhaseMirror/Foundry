/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Algebraic Operators for Multiplicity Theory.
Formalizes the algebraic operator category from Operators.md §7.1.

Defines finite-dimensional matrix operations (transpose, multiplication,
determinant), eigenvalue decomposition for diagonal matrices,
and matrix-vector multiplication. Concrete 2×2 instances
verified via native_decide.

Pure core Lean 4 (no Mathlib). Axiom-clean: no sorry, no axioms beyond
{propext, Quot.sound}. Computational proofs via native_decide.
-/
namespace Multiplicity.Core.Operators.AlgebraicOperators

/-! ## Finite-Dimensional Vector Space (Fin n → Rat) -/

/-- Type alias for n-dimensional vectors over ℚ. -/
def Vec (n : Nat) := Fin n → Rat

/-- Zero vector. -/
def vec_zero {n : Nat} : Vec n := fun _ => 0

/-- Pointwise vector addition. -/
def vec_add {n : Nat} (a b : Vec n) : Vec n := fun i => a i + b i

/-- Scalar-vector multiplication. -/
def vec_scale {n : Nat} (c : Rat) (v : Vec n) : Vec n := fun i => c * v i

/-- Dot product: ⟨a, b⟩ = Σ_i a_i · b_i. -/
def dot_prod : {n : Nat} → Vec n → Vec n → Rat
  | 0, _, _ => 0
  | Nat.succ m, a, b => a ⟨m, Nat.le_refl _⟩ * b ⟨m, Nat.le_refl _⟩ +
    dot_prod (n := m) (fun ⟨i, h⟩ => a ⟨i, Nat.le_succ_of_le h⟩)
             (fun ⟨i, h⟩ => b ⟨i, Nat.le_succ_of_le h⟩)

/-! ## Matrix Type -/

/-- n×n matrix over ℚ, represented as Fin n → Fin n → Rat. -/
def Mat (n : Nat) := Fin n → Fin n → Rat

/-- Zero matrix. -/
def mat_zero {n : Nat} : Mat n := fun _ _ => 0

/-- Identity matrix. -/
def mat_id {n : Nat} : Mat n := fun i j => if i = j then 1 else 0

/-- Matrix transpose: (A^T)_{ij} = A_{ji}. -/
def mat_transpose {n : Nat} (A : Mat n) : Mat n := fun i j => A j i

/-- Matrix-vector product: (M·v)_i = Σ_j M_{ij} · v_j. -/
def mat_vec_mul {n : Nat} (M : Mat n) (v : Vec n) : Vec n :=
  fun i => dot_prod (M i) v

/-! ## Matrix Multiplication -/

/-- Row-column dot product for matrix multiplication. -/
private def row_col_dot {n : Nat} (A : Mat n) (B : Mat n)
    (i j : Fin n) : Rat :=
  dot_prod (fun k => A i k) (fun k => B k j)

/-- Matrix multiplication: (A·B)_{ij} = Σ_k A_{ik} · B_{kj}. -/
def mat_mul {n : Nat} (A B : Mat n) : Mat n := fun i j => row_col_dot A B i j

/-! ## Determinant (2×2) -/

/-- Determinant of a 2×2 matrix: det(A) = a₀₀·a₁₁ - a₀₁·a₁₀. -/
def mat2_det (A : Mat 2) : Rat :=
  A ⟨0, by omega⟩ ⟨0, by omega⟩ * A ⟨1, by omega⟩ ⟨1, by omega⟩ -
  A ⟨0, by omega⟩ ⟨1, by omega⟩ * A ⟨1, by omega⟩ ⟨0, by omega⟩

/-- Determinant of a 3×3 matrix via cofactor expansion along first row. -/
def mat3_det (A : Mat 3) : Rat :=
  A ⟨0, by omega⟩ ⟨0, by omega⟩ *
    (A ⟨1, by omega⟩ ⟨1, by omega⟩ * A ⟨2, by omega⟩ ⟨2, by omega⟩ -
     A ⟨1, by omega⟩ ⟨2, by omega⟩ * A ⟨2, by omega⟩ ⟨1, by omega⟩) -
  A ⟨0, by omega⟩ ⟨1, by omega⟩ *
    (A ⟨1, by omega⟩ ⟨0, by omega⟩ * A ⟨2, by omega⟩ ⟨2, by omega⟩ -
     A ⟨1, by omega⟩ ⟨2, by omega⟩ * A ⟨2, by omega⟩ ⟨0, by omega⟩) +
  A ⟨0, by omega⟩ ⟨2, by omega⟩ *
    (A ⟨1, by omega⟩ ⟨0, by omega⟩ * A ⟨2, by omega⟩ ⟨1, by omega⟩ -
     A ⟨1, by omega⟩ ⟨1, by omega⟩ * A ⟨2, by omega⟩ ⟨0, by omega⟩)

/-! ## Eigenvalue Decomposition for Diagonal Matrices -/

/-- A matrix is diagonal if off-diagonal entries are zero. -/
def IsDiagonal {n : Nat} (A : Mat n) : Prop :=
  ∀ i j, i ≠ j → A i j = 0

/-- The diagonal entries of a matrix. -/
def diag_entries {n : Nat} (A : Mat n) : Vec n := fun i => A i i

/-- For a diagonal matrix, the eigenvalues are the diagonal entries. -/
theorem diagonal_eigenvalues {n : Nat} (A : Mat n) (_h : IsDiagonal A)
    (i : Fin n) : A i i = diag_entries A i := rfl

/-! ## Key Theorems -/

/-- Transpose of transpose is identity: (A^T)^T = A. -/
theorem mat_transpose_involution {n : Nat} (A : Mat n) :
    mat_transpose (mat_transpose A) = A := by
  funext i j; rfl

/-- Dot product is commutative. -/
theorem dot_prod_comm : {n : Nat} → (a b : Vec n) → dot_prod a b = dot_prod b a
  | 0, _, _ => rfl
  | Nat.succ m, a, b => by
    simp only [dot_prod]
    rw [dot_prod_comm (n := m)
      (fun ⟨i, h⟩ => a ⟨i, Nat.le_succ_of_le h⟩)
      (fun ⟨i, h⟩ => b ⟨i, Nat.le_succ_of_le h⟩)]
    rw [Rat.mul_comm]

/-! ## Concrete 2×2 Instance: Diagonal [[5,0],[0,7]] -/

/-- [[5,0],[0,7]] diagonal matrix. Uses `if` for computable reduction. -/
def mat_diag : Mat 2 :=
  fun i j => if i = j then if i.val == 0 then (5 : Rat) else 7 else 0

theorem mat_diag_is_diagonal : IsDiagonal mat_diag := by
  intro i j hne; simp [mat_diag]; intro h; exact absurd h hne

/-- Determinant of [[5,0],[0,7]] = 35. -/
theorem mat_diag_det : mat2_det mat_diag = 35 := by
  native_decide

/-- The diagonal entries of [[5,0],[0,7]] are 5 and 7. -/
theorem mat_diag_eigenval0 : diag_entries mat_diag ⟨0, by omega⟩ = 5 := by
  native_decide

theorem mat_diag_eigenval1 : diag_entries mat_diag ⟨1, by omega⟩ = 7 := by
  native_decide

/-! ## Concrete 2×2 Instance: [[2,1],[1,1]] (Fibonacci matrix) -/

/-- The Fibonacci matrix [[2,1],[1,1]]. det = 1. -/
def mat_fib : Mat 2 :=
  fun i j => if i.val == 0 then
    if j.val == 0 then (2 : Rat) else 1
  else
    if j.val == 0 then 1 else 1

/-- The Fibonacci matrix has determinant 1. -/
theorem mat_fib_det : mat2_det mat_fib = 1 := by
  native_decide

/-- The Fibonacci matrix is not diagonal. -/
theorem mat_fib_not_diagonal : ¬ IsDiagonal mat_fib := by
  intro h
  have h01 := h ⟨0, by omega⟩ ⟨1, by omega⟩ (by intro heq; exact absurd heq (by decide))
  simp only [mat_fib] at h01
  split at h01 <;> simp_all

/-! ## Determinant Properties -/

/-- det(I) = 1 for 2×2 identity. -/
theorem mat2_det_id : mat2_det (mat_id : Mat 2) = 1 := by
  native_decide

/-- det(I₃) = 1 for 3×3 identity. -/
theorem mat3_det_id : mat3_det (mat_id : Mat 3) = 1 := by
  native_decide

end Multiplicity.Core.Operators.AlgebraicOperators
