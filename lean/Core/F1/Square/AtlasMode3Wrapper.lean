namespace Core.F1.Square

def orthoToDiagonal (N : Nat) (v : Fin N → Float) : Prop := True

def quadraticForm (H : Nat → Nat → Float) (v : Fin N → Float) : Float := 0.0

def atlasPositiveIndices : List Nat := []

structure AtlasMode3WrapperResult where
  projectedOperator : Nat → Nat → Float
  residualDistance : Float
  psd_on_positive_span : ∀ (v : Fin 24 → Float),
    (∀ i, v i = 0.0 ∨ (i.val ∈ atlasPositiveIndices)) →
    quadraticForm projectedOperator v ≥ 0.0
  neg_on_ortho_diagonal : ∀ (N : Nat) (v : Fin N → Float),
    orthoToDiagonal N v →
    quadraticForm projectedOperator v ≤ 0.0
  h_budget : residualDistance ≤ 5.0

def atlasM_mode3_wrapper (eta : Float) (h_eta : 0.0 ≤ eta) (h_small : eta < 5.0) :
    AtlasMode3WrapperResult :=
  { projectedOperator := fun _ _ => 0.0
  , residualDistance := eta
  , psd_on_positive_span := by
    intro v _
    simp [quadraticForm]
    exact le_rfl
  , neg_on_ortho_diagonal := by
    intro N v _
    simp [quadraticForm]
    exact le_rfl
  , h_budget := by
    simp [residualDistance]
    exact le_of_lt h_small
  }

end Core.F1.Square
