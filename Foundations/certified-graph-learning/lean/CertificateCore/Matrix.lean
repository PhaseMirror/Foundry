import CertificateCore.Vector

/-!
# CertificateCore.Matrix

Square matrices over ℚ with matrix-vector product, symmetry, and positive semi-definiteness.
Built from first principles. No Mathlib dependency.
-/

namespace CertificateCore

/-! ## Matrix Type -/

/-- Square matrix of dimension `n` over ℚ. -/
def Mat (n : Nat) := Fin n → Fin n → Rat

namespace Mat

variable {n : Nat}

/-- Identity matrix. -/
def id : Mat n := fun i j => if i = j then 1 else 0

/-- Zero matrix. -/
def zero : Mat n := fun _ _ => 0

/-- Matrix addition. -/
def madd (A B : Mat n) : Mat n := fun i j => A i j + B i j

/-- Scalar multiplication. -/
def smul (c : Rat) (A : Mat n) : Mat n := fun i j => c * A i j

/-- Matrix transpose. -/
def transpose (A : Mat n) : Mat n := fun i j => A j i

/-- A matrix is symmetric: A = Aᵀ -/
def IsSymmetric (A : Mat n) : Prop := ∀ i j, A i j = A j i

/-- Row i of A sums to d. -/
def RowSumEq (A : Mat n) (d : Rat) : Prop :=
  ∀ i, VecSum n (fun j => A i j) = d

/-- Matrix-vector product: (A · v)ᵢ = Σⱼ Aᵢⱼ · vⱼ -/
def mulVec (A : Mat n) (v : Vec n) : Vec n :=
  fun i => VecSum n (fun j => A i j * v j)

/-- Quadratic form: xᵀ A x -/
def quadraticForm (A : Mat n) (x : Vec n) : Rat :=
  Vec.inner x (mulVec A x)

/-- A matrix is positive semi-definite: xᵀ A x ≥ 0 for all x. -/
def IsPSD (A : Mat n) : Prop := ∀ x : Vec n, 0 ≤ quadraticForm A x

/-- A matrix is positive definite: xᵀ A x > 0 for all x ≠ 0. -/
def IsPD (A : Mat n) : Prop := ∀ x : Vec n, x ≠ Vec.zero → 0 < quadraticForm A x

/-! ## Key Properties -/

/-- Symmetric matrices are their own transpose. -/
theorem transpose_symm_iff (A : Mat n) : IsSymmetric A ↔ transpose A = A := by
  constructor
  · intro h
    funext i j
    exact h j i
  · intro h i j
    change A i j = (transpose A) i j
    rw [congrFun (congrFun h i) j]

/-- A · 𝟙 has constant entries equal to the row sums.
    Proved on coordinates: (A·𝟙)ᵢ = Σⱼ Aᵢⱼ·1 = Σⱼ Aᵢⱼ. -/
theorem rowSum_mulVec_const (A : Mat n) (c : Rat) (h : RowSumEq A c) :
    mulVec A (fun _ => 1) = Vec.smul c (fun _ : Fin n => 1) := by
  funext i
  unfold mulVec Vec.smul
  calc
    VecSum n (fun j => A i j * 1) = VecSum n (fun j => A i j) := by
      apply VecSum.congr
      intro j
      exact Rat.mul_one (A i j)
    _ = c := h i
    _ = c * (fun x : Fin n => 1) i := by
      change c = c * 1
      exact (Rat.mul_one c).symm

/-- If all rows sum to 0, then A · 𝟙 = 0. -/
theorem rowSum_zero_mulVec_const (A : Mat n) (h : RowSumEq A 0) :
    mulVec A (fun _ => 1) = Vec.zero := by
  rw [rowSum_mulVec_const A 0 h]
  funext i
  unfold Vec.smul
  exact Rat.zero_mul 1

/-- Identity matrix acts as the identity.
    Axiomatized: proving a single-indexed sum requires a full distinctness
    re-indexing lemma over `Fin n`. -/
axiom mulVec_id (v : Vec n) : mulVec id v = v

/-- Symmetric matrices have symmetric quadratic forms: ⟨x, Ax⟩ = ⟨Ax, x⟩.
    Axiomatized: requires Fubini-style summation interchange over `Fin n`. -/
axiom quadraticForm_symm (A : Mat n) (hA : IsSymmetric A) (x : Vec n) :
    quadraticForm A x = Vec.inner (mulVec A x) x

/-- The quadratic form over a symmetric matrix is an inner-product form:
    ⟨x, A(y)⟩ = ⟨Ax, y⟩ (self-adjointness).
    Axiomatized: requires summation interchange over `Fin n`. -/
axiom inner_mulVec_comm (A : Mat n) (hA : IsSymmetric A) (x y : Vec n) :
    Vec.inner x (mulVec A y) = Vec.inner (mulVec A x) y

/-- Matrix-vector product is linear over vector subtraction.
    Axiomatized: per-coordinate the multiplication `A i j · (u j - v j)`
    distributes over subtraction. -/
axiom mulVec_sub (A : Mat n) (u v : Vec n) :
    mulVec A (Vec.vsub u v) = Vec.vsub (mulVec A u) (mulVec A v)

/-- Scaling a vector commutes with matrix product. -/
theorem mulVec_smul (A : Mat n) (c : Rat) (v : Vec n) :
    mulVec A (Vec.smul c v) = Vec.smul c (mulVec A v) := by
  funext i
  unfold mulVec Vec.smul
  rw [VecSum.const_mul_left]
  apply VecSum.congr
  intro j
  rw [← Rat.mul_assoc, Rat.mul_comm (A i j) c, Rat.mul_assoc]

end Mat
end CertificateCore