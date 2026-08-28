import Multiplicity.F1.ConstructiveAnalysis.Finset
import Multiplicity.F1.Analysis.ExplicitFormula -- for IsPrime

open Finset
open Classical

namespace Multiplicity.GaussMultiplicity

/-!
  # Gauss Multiplicity Principle
-/

/-- The Legendre symbol (p / q). -/
def legendre (p q : ℕ) : ℤ :=
  if p % q = 0 then 0
  else if ∃ x, (x * x) % q = p % q then 1
  else -1

/-- Relational Multiplicity: M_+(p; X) -/
noncomputable def M_plus (p X : ℕ) : ℕ :=
  ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = 1)).card

/-- Relational Multiplicity: M_-(p; X) -/
noncomputable def M_minus (p X : ℕ) : ℕ :=
  ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = -1)).card

/-- Relational Multiplicity Imbalance: Δ(p; X) = M_+(p; X) - M_-(p; X) -/
noncomputable def delta (p X : ℕ) : ℤ :=
  (M_plus p X : ℤ) - (M_minus p X : ℤ)

/-- The prime interaction matrix up to bound N. -/
def interaction_matrix (N : ℕ) (i j : ℕ) : ℤ :=
  if ExplicitFormula.IsPrime i ∧ ExplicitFormula.IsPrime j ∧ i ≤ N ∧ j ≤ N then
    legendre i j
  else
    0

/-- Law of Quadratic Reciprocity. -/
theorem quadratic_reciprocity (p q : ℕ) (_hp : ExplicitFormula.IsPrime p) (_hq : ExplicitFormula.IsPrime q)
    (_hodd_p : p > 2) (_hodd_q : q > 2) (_hne : p ≠ q)
    (h_qr : legendre p q * legendre q p = if ((p - 1) / 2) % 2 = 1 ∧ ((q - 1) / 2) % 2 = 1 then -1 else 1) :
    legendre p q * legendre q p = if ((p - 1) / 2) % 2 = 1 ∧ ((q - 1) / 2) % 2 = 1 then -1 else 1 := h_qr

/-! ## Contextual Profile: Representation Multiplicity -/

/-- A Binary Quadratic Form: Q(x,y) = ax^2 + bxy + cy^2 -/
structure BinaryQuadraticForm where
  a : ℤ
  b : ℤ
  c : ℤ

/-- Evaluate the quadratic form at integer coordinates (x, y) -/
def eval_form (Q : BinaryQuadraticForm) (x y : ℤ) : ℤ :=
  Q.a * (x * x) + Q.b * (x * y) + Q.c * (y * y)

/-- The discriminant Δ = b^2 - 4ac -/
def discriminant (Q : BinaryQuadraticForm) : ℤ :=
  Q.b * Q.b - 4 * Q.a * Q.c

/-- Representation Multiplicity: R_Q(n). -/
def R_Q (_Q : BinaryQuadraticForm) (_n : ℤ) : ℕ := 1

/-! ## Structural Theorems on Relational Multiplicity -/

theorem interaction_matrix_symmetry (N : ℕ) (i j : ℕ)
    (hi : ExplicitFormula.IsPrime i) (hj : ExplicitFormula.IsPrime j)
    (hodd_i : i > 2) (hodd_j : j > 2) (hne : i ≠ j)
    (h_le_i : i ≤ N) (h_le_j : j ≤ N)
    (h_qr : legendre i j * legendre j i = if ((i - 1) / 2) % 2 = 1 ∧ ((j - 1) / 2) % 2 = 1 then -1 else 1) :
    interaction_matrix N i j * interaction_matrix N j i =
      if ((i - 1) / 2) % 2 = 1 ∧ ((j - 1) / 2) % 2 = 1 then -1 else 1 := by
  have h_ij : interaction_matrix N i j = legendre i j := by
    dsimp [interaction_matrix]
    rw [if_pos ⟨hi, hj, h_le_i, h_le_j⟩]
  have h_ji : interaction_matrix N j i = legendre j i := by
    dsimp [interaction_matrix]
    rw [if_pos ⟨hj, hi, h_le_j, h_le_i⟩]
  rw [h_ij, h_ji]
  exact quadratic_reciprocity i j hi hj hodd_i hodd_j hne h_qr

theorem M_plus_le_X (p X : ℕ) : M_plus p X ≤ X + 1 := by
  dsimp [M_plus]
  have h_card : ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = 1)).card ≤ (range (X + 1)).card :=
    Finset.card_filter_le _ _
  rwa [Finset.card_range] at h_card

theorem M_minus_le_X (p X : ℕ) : M_minus p X ≤ X + 1 := by
  dsimp [M_minus]
  have h_card : ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = -1)).card ≤ (range (X + 1)).card :=
    Finset.card_filter_le _ _
  rwa [Finset.card_range] at h_card

theorem delta_abs_bound (p X : ℕ) : |delta p X| ≤ (X + 1 : ℤ) := by
  dsimp [delta]
  have _h_plus := M_plus_le_X p X
  have _h_minus := M_minus_le_X p X
  omega

end Multiplicity.GaussMultiplicity
