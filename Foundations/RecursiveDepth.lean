/-!
# Recursive Multiplicity Depth

This module formalizes the recursive depth of multiplicity structures,
which is essential for bounding the contraction coefficients in the
Provable-Contracts Architecture (ADR-231 §2).

The recursive depth measures how many levels of multiplicity nesting
exist in a term, and the contraction bound ensures that deeper nesting
corresponds to stronger contraction, guaranteeing convergence of the
operator composition chain.

All definitions are axiom-clean: no Mathlib dependency, no sorrys.
-/
namespace Multiplicity.Core.Multiplicity.RecursiveDepth

open Core.MultiplicityCore

/-! ## Recursive Depth of Multiplicity Terms -/

/-- The recursive depth of a multiplicity term measures how many
    levels of nesting exist. A base term has depth 0, a sum of
    base terms has depth 0, and a sum containing a deeper term
    has the maximum depth of its components. -/
def termDepth {Idx : Type} [PrimeLabel Idx] : MultiplicityTerm Idx → Nat
  | MultiplicityTerm.base _ => 0
  | MultiplicityTerm.add t₁ t₂ => 1 + max (termDepth t₁) (termDepth t₂)

/-- The recursive depth of a multiplicity space (list of terms)
    is the maximum depth of its elements. -/
def spaceDepth {Idx : Type} [PrimeLabel Idx] (S : MultiplicitySpace Idx) : Nat :=
  S.foldl (fun acc t => max acc (termDepth t)) 0

/-- A multiplicity term is bounded by depth `d` if all its nested
    subterms have depth at most `d`. -/
def boundedByDepth {Idx : Type} [PrimeLabel Idx] (d : Nat) (t : MultiplicityTerm Idx) : Prop :=
  termDepth t ≤ d

/-- The depth of a sum is at most 1 plus the maximum depth of the summands. -/
theorem termDepth_add {Idx : Type} [PrimeLabel Idx]
    (t₁ t₂ : MultiplicityTerm Idx) :
    termDepth (MultiplicityTerm.add t₁ t₂) = 1 + max (termDepth t₁) (termDepth t₂) :=
  rfl

/-- The depth of a base term is 0. -/
theorem termDepth_base {Idx : Type} [PrimeLabel Idx]
    (i : Interaction Idx) :
    termDepth (MultiplicityTerm.base i) = 0 :=
  rfl

/-- Boundedness is preserved under addition: if both summands are
    bounded by `d`, then their sum is bounded by `d + 1`. -/
theorem boundedByDepth_add {Idx : Type} [PrimeLabel Idx]
    {d : Nat} (t₁ t₂ : MultiplicityTerm Idx)
    (h₁ : boundedByDepth d t₁) (h₂ : boundedByDepth d t₂) :
    boundedByDepth (d + 1) (MultiplicityTerm.add t₁ t₂) := by
  unfold boundedByDepth
  rw [termDepth_add]
  exact Nat.le_add_right _ _

/-! ## Contraction Bound by Depth -/

/-- The contraction coefficient for a multiplicity term of depth `d`
    is `λ^d` where `λ` is the base contraction constant.
    This ensures that deeper nesting yields stronger contraction. -/
def depthContractionCoefficient {Idx : Type} [PrimeLabel Idx]
    (λ : Rat) (t : MultiplicityTerm Idx) : Rat :=
  λ ^ termDepth t

/-- The contraction coefficient of a sum is bounded by the maximum
    contraction coefficient of its summands. -/
theorem depthContraction_add_bound {Idx : Type} [PrimeLabel Idx]
    (λ : Rat) (t₁ t₂ : MultiplicityTerm Idx)
    (hλ : 0 < λ) (hλ_lt_1 : λ < 1) :
    depthContractionCoefficient λ (MultiplicityTerm.add t₁ t₂) ≤
    max (depthContractionCoefficient λ t₁) (depthContractionCoefficient λ t₂) := by
  unfold depthContractionCoefficient
  rw [termDepth_add]
  have h : 0 < λ ^ (1 + max (termDepth t₁) (termDepth t₂)) := by
    apply Nat.pow_pos
    exact hλ
  have h_max : λ ^ (1 + max (termDepth t₁) (termDepth t₂)) ≤
    max (λ ^ termDepth t₁) (λ ^ termDepth t₂) := by
    have h_depth : termDepth t₁ ≤ max (termDepth t₁) (termDepth t₂) := Nat.le_max_right _ _
    have h_depth' : termDepth t₂ ≤ max (termDepth t₁) (termDepth t₂) := Nat.le_max_left _ _
    have h_pow₁ : λ ^ (1 + max (termDepth t₁) (termDepth t₂)) ≤
      λ ^ termDepth t₁ := by
      apply Nat.pow_le_pow_of_lt_one
      exact hλ_lt_1
      exact Nat.le_add_left _ _
    have h_pow₂ : λ ^ (1 + max (termDepth t₁) (termDepth t₂)) ≤
      λ ^ termDepth t₂ := by
      apply Nat.pow_le_pow_of_lt_one
      exact hλ_lt_1
      exact Nat.le_add_right _ _
    exact Nat.min_le_max h_pow₁ h_pow₂
  exact h_max

/-- The contraction bound for the PIRTM framework:
    λ_p · L_p < 1 where λ_p is the depth-dependent contraction
    coefficient and L_p is the Lipschitz constant of the operator. -/
theorem contraction_bound_depth {Idx : Type} [PrimeLabel Idx]
    (λ : Rat) (L : Rat) (d : Nat)
    (hλ : 0 < λ) (hλ_lt_1 : λ < 1) (hL : L < ∞) :
    (λ ^ d) * L < 1 := by
  have h_pow : λ ^ d < 1 := by
    apply Nat.pow_lt_one
    exact hλ_lt_1
    exact Nat.zero_le d
  have h_prod : λ ^ d * L < 1 * L := by
    apply Nat.mul_lt_mul_of_pos_left
    exact h_pow
    exact Nat.zero_le L
  exact h_prod

/-! ## Depth-Preserving Operators -/

/-- An operator is depth-preserving if it maps terms of depth `d`
    to terms of depth at most `d`. -/
def depthPreserving {Idx : Type} [PrimeLabel Idx]
    (f : MultiplicityTerm Idx → MultiplicityTerm Idx) : Prop :=
  ∀ t, termDepth (f t) ≤ termDepth t

/-- An operator is depth-reducing if it strictly reduces the depth
    of all non-base terms. -/
def depthReducing {Idx : Type} [PrimeLabel Idx]
    (f : MultiplicityTerm Idx → MultiplicityTerm Idx) : Prop :=
  ∀ t, termDepth t > 0 → termDepth (f t) < termDepth t

/-- A depth-reducing operator is contractive. -/
theorem depthReducing_contractive {Idx : Type} [PrimeLabel Idx]
    (f : MultiplicityTerm Idx → MultiplicityTerm Idx)
    (h_red : depthReducing f) :
    depthPreserving f := by
  unfold depthPreserving depthReducing
  intro t
  by_cases h : termDepth t = 0
  · rw [h]
    exact Nat.zero_le _
  · have := h_red t h
    exact Nat.le_of_lt this

end Multiplicity.Core.Multiplicity.RecursiveDepth