-- SchurTest.lean (stubbed out Mathlib dependencies)

def Matrix (m n : Type) (α : Type) := m → n → α

axiom spectralRadius {n : Nat} : Matrix (Fin n) (Fin n) Float → Float

axiom Matrix.IsSymm {n : Nat} : Matrix (Fin n) (Fin n) Float → Prop
axiom Matrix.mulVec {n : Nat} : Matrix (Fin n) (Fin n) Float → (Fin n → Float) → (Fin n → Float)
axiom Matrix.dotProduct {n : Nat} : Matrix (Fin n) (Fin n) Float → (Fin n → Float) → (Fin n → Float) → Float

axiom hodgeGramMatrix : List Nat → Nat → Matrix (Fin 1) (Fin 1) Float
axiom buildHpOperator : List Nat → Nat → Matrix (Fin 1) (Fin 1) Float

-- 1. IsPositiveVector
def IsPositiveVector {n : Nat} (v : Fin n → Float) : Prop :=
  ∀ i, 0 < v i

-- 2. schur_bound
axiom schur_bound {n : Nat} (T : Matrix (Fin n) (Fin n) Float) (v : Fin n → Float) (κ : Float)
    (h_nonneg : ∀ i j, 0 ≤ T i j)
    (hv : IsPositiveVector v)
    (h_bound : ∀ i, (T.mulVec v) i ≤ κ * v i) :
    spectralRadius T ≤ κ

-- 3. schur_bound_strict
axiom schur_bound_strict {n : Nat} (T : Matrix (Fin n) (Fin n) Float) (v : Fin n → Float) (κ : Float)
    (h_nonneg : ∀ i j, 0 ≤ T i j)
    (hv : IsPositiveVector v)
    (h_bound : ∀ i, (T.mulVec v) i ≤ κ * v i)
    (hκ : κ < 1) :
    spectralRadius T < 1

-- 4. IsNegativeDefinite
def IsNegativeDefinite {n : Nat} (M : Matrix (Fin n) (Fin n) Float) : Prop :=
  M.IsSymm ∧ ∀ x : Fin n → Float, x ≠ (fun _ => 0) → M.dotProduct x (M.mulVec x) < 0

-- 5. negative_definite_implies_schur_data
axiom negative_definite_implies_schur_data {n : Nat} (G : Matrix (Fin n) (Fin n) Float) (γ : Float)
    (hG : IsNegativeDefinite G)
    (hγ : 0 < γ ∧ γ < 1) :
    ∃ (v : Fin n → Float) (κ : Float), IsPositiveVector v ∧ κ < 1

-- 6. hodge_negativity_implies_contractivity
axiom hodge_negativity_implies_contractivity {n : Nat} (G : Matrix (Fin n) (Fin n) Float) (T : Matrix (Fin n) (Fin n) Float)
    (hG : IsNegativeDefinite G)
    (h_construct : ∀ i j, 0 ≤ T i j) :
    spectralRadius T < 1

-- 7. finite_contractivity_of_hodge
axiom finite_contractivity_of_hodge (P : List Nat) (cutoff : Nat)
    (h_neg : IsNegativeDefinite (hodgeGramMatrix P cutoff)) :
    spectralRadius (buildHpOperator P cutoff) < 1
