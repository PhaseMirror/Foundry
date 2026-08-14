import Multiplicity.F1.ConstructiveAnalysis.Finset
import Multiplicity.F1.Analysis.ExplicitFormula -- for IsPrime

open Finset
open Classical

namespace Multiplicity.GaussMultiplicity

/-!
  # Gauss Multiplicity Principle

  This module formalizes the conceptual leap from Euler's prime composition
  to Gauss's relational network of primes, as defined in ADR-0005.

  We model the transition from intrinsic factorization multiplicity to
  contextual/relational multiplicity via the Legendre symbol and the
  prime interaction matrix.
-/

/-- The Legendre symbol (p / q).
    Returns 1 if p is a quadratic residue mod q (and p ≢ 0 mod q),
    -1 if p is a quadratic non-residue mod q,
    and 0 if q divides p. -/
def legendre (p q : ℕ) : ℤ :=
  if p % q = 0 then 0
  else if ∃ x, (x * x) % q = p % q then 1
  else -1

/-- Relational Multiplicity: M_+(p; X)
    The number of primes q ≤ X such that p is a quadratic residue mod q. -/
noncomputable def M_plus (p X : ℕ) : ℕ :=
  ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = 1)).card

/-- Relational Multiplicity: M_-(p; X)
    The number of primes q ≤ X such that p is a quadratic non-residue mod q. -/
noncomputable def M_minus (p X : ℕ) : ℕ :=
  ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = -1)).card

/-- Relational Multiplicity Imbalance: Δ(p; X) = M_+(p; X) - M_-(p; X) -/
noncomputable def delta (p X : ℕ) : ℤ :=
  (M_plus p X : ℤ) - (M_minus p X : ℤ)

/-- The prime interaction matrix up to bound N.
    Encoded as a function from pairs of numbers to their Legendre symbol.
    By restricting to primes, this forms the matrix R_N from the ADR. -/
def interaction_matrix (N : ℕ) (i j : ℕ) : ℤ :=
  if ExplicitFormula.IsPrime i ∧ ExplicitFormula.IsPrime j ∧ i ≤ N ∧ j ≤ N then
    legendre i j
  else
    0

/-- Law of Quadratic Reciprocity (as an axiom for the relational network).
    For distinct odd primes p and q, (p/q)(q/p) = (-1)^((p-1)/2 * (q-1)/2).
    This establishes the structural symmetry of the interaction matrix. -/
axiom quadratic_reciprocity (p q : ℕ) (hp : ExplicitFormula.IsPrime p) (hq : ExplicitFormula.IsPrime q)
    (hodd_p : p > 2) (hodd_q : q > 2) (hne : p ≠ q) :
    legendre p q * legendre q p = if ((p - 1) / 2) % 2 = 1 ∧ ((q - 1) / 2) % 2 = 1 then -1 else 1

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

/-- Representation Multiplicity: R_Q(n).
    Mathematically, this is the cardinality of the set of integer solutions (x, y)
    such that eval_form Q x y = n. We introduce it as an opaque function to
    complete the contextual profile triad (Factor, Residue, Representation). -/
axiom R_Q (Q : BinaryQuadraticForm) (n : ℤ) : ℕ

/-! ## Structural Theorems on Relational Multiplicity -/

/-- The Interaction Matrix is symmetric (or anti-symmetric) for odd primes,
    directly reflecting the relational structure given by Quadratic Reciprocity. -/
theorem interaction_matrix_symmetry (N : ℕ) (i j : ℕ)
    (hi : ExplicitFormula.IsPrime i) (hj : ExplicitFormula.IsPrime j)
    (hodd_i : i > 2) (hodd_j : j > 2) (hne : i ≠ j)
    (h_le_i : i ≤ N) (h_le_j : j ≤ N) :
    interaction_matrix N i j * interaction_matrix N j i =
      if ((i - 1) / 2) % 2 = 1 ∧ ((j - 1) / 2) % 2 = 1 then -1 else 1 := by
  -- Unfold the definition of interaction_matrix
  have h_ij : interaction_matrix N i j = legendre i j := by
    dsimp [interaction_matrix]
    rw [if_pos ⟨hi, hj, h_le_i, h_le_j⟩]
  have h_ji : interaction_matrix N j i = legendre j i := by
    dsimp [interaction_matrix]
    rw [if_pos ⟨hj, hi, h_le_j, h_le_i⟩]
  rw [h_ij, h_ji]
  exact quadratic_reciprocity i j hi hj hodd_i hodd_j hne

/-- Trivial bound on relational multiplicity components: M_+(p; X) and M_-(p; X)
    are strictly bounded by the number of elements in the range up to X. -/
theorem M_plus_le_X (p X : ℕ) : M_plus p X ≤ X + 1 := by
  dsimp [M_plus]
  -- The cardinality of a filtered Finset is bounded by the cardinality of the original Finset.
  have h_card : ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = 1)).card ≤ (range (X + 1)).card :=
    Finset.card_filter_le _ _
  rwa [Finset.card_range] at h_card

theorem M_minus_le_X (p X : ℕ) : M_minus p X ≤ X + 1 := by
  dsimp [M_minus]
  have h_card : ((range (X + 1)).filter (λ q => ExplicitFormula.IsPrime q ∧ legendre p q = -1)).card ≤ (range (X + 1)).card :=
    Finset.card_filter_le _ _
  rwa [Finset.card_range] at h_card

/-- The absolute imbalance |Δ(p; X)| is bounded by X + 1.
    Since Δ = M_+ - M_-, and M_+, M_- are disjoint subsets of primes ≤ X,
    their sum is at most the total number of primes ≤ X, which is ≤ X + 1. -/
theorem delta_abs_bound (p X : ℕ) : |delta p X| ≤ (X + 1 : ℤ) := by
  dsimp [delta]
  have h_plus := M_plus_le_X p X
  have h_minus := M_minus_le_X p X
  omega

end Multiplicity.GaussMultiplicity
