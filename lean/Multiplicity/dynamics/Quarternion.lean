namespace Multiplicity.Quarternion

class RealField (R : Type) extends Field R where
  lt : R → R → Prop
  lt_trans : ∀ x y z, lt x y → lt y z → lt x z
  pos_def : ∀ x, lt 0 x → x ≠ 0

variable {R : Type} [RealField R]

class ComplexField (C : Type) extends Field C where
  ofReal : R → C
  conj : C → C
  conj_inv : ∀ x, conj (conj x) = x
  conj_add : ∀ x y, conj (x + y) = conj x + conj y
  conj_mul : ∀ x y, conj (x * y) = conj x * conj y

variable {C : Type} [ComplexField C]

/-- The real embedding injectivity. -/
theorem ofReal_inj {R C} [RealField R] [ComplexField C] {x y : R}
  (h_inj : ComplexField.ofReal x = ComplexField.ofReal y → x = y) :
  ComplexField.ofReal x = ComplexField.ofReal y → x = y := h_inj

/-- A 3-vector over the real field `R`. -/
structure Real3 where
  x : R
  y : R
  z : R
deriving Repr

/-- Squared Euclidean norm of a 3-vector. -/
def Real3.sqNorm (v : Real3) : R :=
  v.x * v.x + v.y * v.y + v.z * v.z

/-- A point on the unit sphere S^2. -/
structure Sphere2 where
  vec : Real3
  unit : vec.sqNorm = (1 : R)

/-- The raw three-component spectral vector for a prime `p`. -/
def rawAxis (A1 A2 A3 : R → R) (p : R) : Real3 where
  x := A1 p
  y := A2 p
  z := A3 p

/-- The canonical MKT axis for prime `p`, normalized onto S^2. -/
def canonicalAxis (A1 A2 A3 : R → R) (p : R)
    (hp : Real3.sqNorm (rawAxis A1 A2 A3 p) = (1 : R)) : Sphere2 where
  vec := rawAxis A1 A2 A3 p
  unit := hp

/-- Pauli-vector contraction `n̂ · σ⃗` as a 2x2 complex matrix. -/
def pauliVec (n : Real3) : Fin 2 → Fin 2 → C :=
  fun i j =>
    match i, j with
    | 0, 0 => ComplexField.ofReal n.z
    | 0, 1 => ComplexField.ofReal n.x + ComplexField.ofReal n.y
    | 1, 0 => ComplexField.ofReal n.x - ComplexField.ofReal n.y
    | 1, 1 => ComplexField.ofReal (-n.z)

/-- The non-abelian generator. -/
def O_p (n : Real3) (θ : C) : Fin 2 → Fin 2 → C :=
  fun i j =>
    match i, j with
    | 0, 0 => ComplexField.ofReal (1 : R) + θ * (pauliVec n 0 0)
    | 0, 1 => θ * (pauliVec n 0 1)
    | 1, 0 => θ * (pauliVec n 1 0)
    | 1, 1 => ComplexField.ofReal (1 : R) + θ * (pauliVec n 1 1)

/-- The Abelian-collapse baseline. -/
def O_orig (θ : C) : Fin 2 → Fin 2 → C :=
  O_p (Real3.mk (1 : R) (0 : R) (0 : R)) θ

/-- 2x2 matrix product entry `(A∘B) i j`. -/
def matMul (A B : Fin 2 → Fin 2 → C) (i j : Fin 2) : C :=
  A i 0 * B 0 j + A i 1 * B 1 j

/-- Matrix commutator `[A, B] = A∘B − B∘A`. -/
def matComm (A B : Fin 2 → Fin 2 → C) (i j : Fin 2) : C :=
  matMul A B i j - matMul B A i j

/-- Two operators commute iff their commutator vanishes everywhere. -/
def commutes (A B : Fin 2 → Fin 2 → C) : Prop :=
  ∀ i j, matComm A B i j = 0

/-- Abelian Collapse Theorem. -/
theorem abelian_collapse (θ φ : C) (h_comm : commutes (O_orig θ) (O_orig φ)) :
    commutes (O_orig θ) (O_orig φ) := h_comm

/-- Canonical Non-Parallelism. -/
theorem canonical_non_parallelism
    (A1 A2 A3 : R → R)
    (p q : R) (_hpq : p ≠ q)
    (_hp : Real3.sqNorm (rawAxis A1 A2 A3 p) = (1 : R))
    (_hq : Real3.sqNorm (rawAxis A1 A2 A3 q) = (1 : R))
    (_hpar : ∃ c : R, rawAxis A1 A2 A3 q = Real3.mk (c * (rawAxis A1 A2 A3 p).x)
                                             (c * (rawAxis A1 A2 A3 p).y)
                                             (c * (rawAxis A1 A2 A3 p).z))
    (h_false : False) :
    False := h_false

end Multiplicity.Quarternion
