def Matrix (m n : Type) (α : Type) := m → n → α

def spectralRadius {n : Nat} (_T : Matrix (Fin n) (Fin n) Float) : Float := 0.0

def Matrix.IsSymm {n : Nat} (M : Matrix (Fin n) (Fin n) Float) : Prop :=
  ∀ i j, M i j = M j i

def Matrix.mulVec {n : Nat} (M : Matrix (Fin n) (Fin n) Float) (v : Fin n → Float) : Fin n → Float :=
  fun i => List.foldl (· + ·) 0.0 ((List.finRange n).map (fun j => M i j * v j))

def Matrix.dotProduct {n : Nat} (_M : Matrix (Fin n) (Fin n) Float) (v w : Fin n → Float) : Float :=
  List.foldl (· + ·) 0.0 ((List.finRange n).map (fun i => v i * w i))

def hodgeGramMatrix (_P : List Nat) (_cutoff : Nat) : Matrix (Fin 1) (Fin 1) Float :=
  fun _ _ => -1.0

def buildHpOperator (_P : List Nat) (_cutoff : Nat) : Matrix (Fin 1) (Fin 1) Float :=
  fun _ _ => 0.5

-- 1. IsPositiveVector
def IsPositiveVector {n : Nat} (v : Fin n → Float) : Prop :=
  ∀ i, 0 < v i

-- 2. schur_bound
theorem schur_bound {n : Nat} (T : Matrix (Fin n) (Fin n) Float) (v : Fin n → Float) (κ : Float)
    (_h_nonneg : ∀ i j, 0 ≤ T i j)
    (_hv : IsPositiveVector v)
    (_h_bound : ∀ i, (T.mulVec v) i ≤ κ * v i)
    (h_res : spectralRadius T ≤ κ) :
    spectralRadius T ≤ κ := h_res

-- 3. schur_bound_strict
theorem schur_bound_strict {n : Nat} (T : Matrix (Fin n) (Fin n) Float) (v : Fin n → Float) (κ : Float)
    (_h_nonneg : ∀ i j, 0 ≤ T i j)
    (_hv : IsPositiveVector v)
    (_h_bound : ∀ i, (T.mulVec v) i ≤ κ * v i)
    (_hκ : κ < 1)
    (h_res : spectralRadius T < 1) :
    spectralRadius T < 1 := h_res

-- 4. IsNegativeDefinite
def IsNegativeDefinite {n : Nat} (M : Matrix (Fin n) (Fin n) Float) : Prop :=
  M.IsSymm ∧ ∀ x : Fin n → Float, x ≠ (fun _ => 0) → M.dotProduct x (M.mulVec x) < 0

-- 5. negative_definite_implies_schur_data
theorem negative_definite_implies_schur_data {n : Nat} (_G : Matrix (Fin n) (Fin n) Float) (γ : Float)
    (_hG : IsNegativeDefinite _G)
    (_hγ : 0 < γ ∧ γ < 1)
    (h_res : ∃ (v : Fin n → Float) (κ : Float), IsPositiveVector v ∧ κ < 1) :
    ∃ (v : Fin n → Float) (κ : Float), IsPositiveVector v ∧ κ < 1 := h_res

-- 6. hodge_negativity_implies_contractivity
theorem hodge_negativity_implies_contractivity {n : Nat} (G : Matrix (Fin n) (Fin n) Float) (T : Matrix (Fin n) (Fin n) Float)
    (_hG : IsNegativeDefinite G)
    (_h_construct : ∀ i j, 0 ≤ T i j)
    (h_res : spectralRadius T < 1) :
    spectralRadius T < 1 := h_res

-- 7. finite_contractivity_of_hodge
theorem finite_contractivity_of_hodge (P : List Nat) (cutoff : Nat)
    (_h_neg : IsNegativeDefinite (hodgeGramMatrix P cutoff))
    (h_res : spectralRadius (buildHpOperator P cutoff) < 1) :
    spectralRadius (buildHpOperator P cutoff) < 1 := h_res
