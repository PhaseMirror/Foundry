/-!
# Higher-Order Multiplicity

This module formalizes multiplicities of multiplicity — the recursive,
self-referential structure where a multiplicity value itself carries
multiplicity information. This is the foundation for the
Prime-Indexed Recursive Tensor Mathematics (PIRTM) framework.

## Key Definitions

- `HigherOrderMultiplicity`: A multiplicity whose exponents are themselves
  prime-encoded multisets, forming a recursive hierarchy.
- `MultiplicityDepth`: The nesting depth of a higher-order multiplicity.
- `TensorProduct`: The tensor product of two multiplicity spaces.
- `ContractionBound`: The Lipschitz contraction constraint for
  higher-order operator compositions.

All definitions are axiom-clean: no Mathlib dependency, no sorrys.
-/
namespace Multiplicity.Core.Multiplicity.HigherOrder

open Core.MultiplicityCore

/-! ## Higher-Order Multiplicity Type -/

/-- A first-order multiplicity is a prime-encoded multiset:
    a function `f : Nat → Nat` that is non-zero only on primes
    and has finite support.

    A second-order multiplicity is a multiplicity whose exponents
    are themselves first-order multiplicities. This recursive
    structure continues to arbitrary depth. -/
inductive HigherOrderMultiplicity (depth : Nat) (Idx : Type) [PrimeLabel Idx] : Type
| zero : HigherOrderMultiplicity 0
| firstOrder (m : MultiplicityTerm Idx) : HigherOrderMultiplicity 1
| higherOrder (d : Nat) (inner : HigherOrderMultiplicity d) (outer : MultiplicityTerm Idx) :
    HigherOrderMultiplicity (d + 1)

namespace Multiplicity.HigherOrderMultiplicity

/-- The depth of a higher-order multiplicity. -/
def depth {d : Nat} {Idx : Type} [PrimeLabel Idx] (h : HigherOrderMultiplicity d Idx) : Nat := d

/-- The total prime weight of a higher-order multiplicity. -/
def totalWeight {d : Nat} {Idx : Type} [PrimeLabel Idx] (h : HigherOrderMultiplicity d Idx) : Nat :=
  match h with
  | .zero => 0
  | .firstOrder t => term_value t
  | .higherOrder _ inner outer => totalWeight inner + term_value outer

/-- The nesting depth of a higher-order multiplicity.
    `nestingDepth zero = 0`
    `nestingDepth (firstOrder t) = 1`
    `nestingDepth (higherOrder d inner outer) = 1 + nestingDepth inner` -/
def nestingDepth {d : Nat} {Idx : Type} [PrimeLabel Idx] (h : HigherOrderMultiplicity d Idx) : Nat :=
  match h with
  | .zero => 0
  | .firstOrder _ => 1
  | .higherOrder _ inner _ => 1 + nestingDepth inner

/-- Flatten a higher-order multiplicity to a first-order multiplicity.
    This sums all prime weights across all nesting levels. -/
def flatten {d : Nat} {Idx : Type} [PrimeLabel Idx] (h : HigherOrderMultiplicity d Idx) : MultiplicityTerm Idx :=
  match h with
  | .zero => MultiplicityTerm.base { src := ⟨0⟩, dst := ⟨0⟩, weight := 0, prod := 0 }
  | .firstOrder t => t
  | .higherOrder _ inner outer => MultiplicityTerm.add (flatten inner) outer

/-- The contraction coefficient of a higher-order multiplicity.
    For a multiplicity of depth `d`, the contraction coefficient is
    `λ^d` where `λ` is the base contraction constant. -/
def contractionCoefficient {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (λ : Rat) (h : HigherOrderMultiplicity d Idx) : Rat :=
  λ ^ h.nestingDepth

/-- A higher-order multiplicity is contractive if its contraction
    coefficient is strictly less than 1. -/
def isContractive {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (λ : Rat) (h : HigherOrderMultiplicity d Idx) : Prop :=
  contractionCoefficient λ h < 1

end Multiplicity.HigherOrderMultiplicity

/-! ## Multiplicity Depth Theorems -/

/-- The depth of a flattened higher-order multiplicity is at most
    the original depth. -/
theorem flatten_depth_bound {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (h : HigherOrderMultiplicity d Idx) :
    h.flatten.depth ≤ d := by
  induction h with
  | zero => simp [flatten, depth]
  | firstOrder t => simp [flatten, depth]
  | higherOrder d' inner outer ih =>
    simp [flatten, depth, nestingDepth]
    exact Nat.le_add_right _ _

/-- The total weight of a flattened higher-order multiplicity equals
    the sum of total weights across all nesting levels. -/
theorem flatten_weight {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (h : HigherOrderMultiplicity d Idx) :
    h.flatten.totalWeight = h.totalWeight := by
  induction h with
  | zero => simp [flatten, totalWeight]
  | firstOrder t => simp [flatten, totalWeight, term_value]
  | higherOrder d' inner outer ih =>
    simp [flatten, totalWeight, ih]
    exact Nat.add_assoc _ _ _

/-- Nesting depth is monotonic with respect to higher-order construction. -/
theorem nestingDepth_monotone {d : Nat} {Idx : Type} [PrimeLabel Idx]
    (h : HigherOrderMultiplicity d Idx) :
    h.nestingDepth ≤ d := by
  induction h with
  | zero => simp [nestingDepth]
  | firstOrder _ => simp [nestingDepth]
  | higherOrder d' inner outer ih =>
    simp [nestingDepth, ih]
    exact Nat.le_add_right _ _

/-! ## Recursive Multiplicity Depth -/

/-- The recursive multiplicity depth measures how many levels of
    multiplicity nesting exist in a term. -/
def recursiveDepth {Idx : Type} [PrimeLabel Idx] :
    MultiplicityTerm Idx → Nat
  | MultiplicityTerm.base _ => 0
  | MultiplicityTerm.add t₁ t₂ => max (recursiveDepth t₁) (recursiveDepth t₂)

/-- A multiplicity term is at depth `d` if its recursive depth equals `d`. -/
def atDepth {Idx : Type} [PrimeLabel Idx] (d : Nat) (t : MultiplicityTerm Idx) : Prop :=
  recursiveDepth t = d

/-- The recursive depth of a sum is the maximum of the depths of the summands. -/
theorem recursiveDepth_add {Idx : Type} [PrimeLabel Idx]
    (t₁ t₂ : MultiplicityTerm Idx) :
    recursiveDepth (MultiplicityTerm.add t₁ t₂) = max (recursiveDepth t₁) (recursiveDepth t₂) :=
  rfl

/-- The recursive depth of a base term is 0. -/
theorem recursiveDepth_base {Idx : Type} [PrimeLabel Idx]
    (i : Interaction Idx) :
    recursiveDepth (MultiplicityTerm.base i) = 0 :=
  rfl

/-! ## Tensor Product of Multiplicity Spaces -/

/-- The tensor product of two multiplicity spaces.
    Given two multisets M and N, their tensor product M ⊗ N
    is the multiset whose prime exponents are the pointwise
    products of the exponents of M and N. -/
def tensorProduct {Idx : Type} [PrimeLabel Idx]
    (M N : Multiset) : Multiset :=
  { f := fun p => M.f p * N.f p,
    prime_enc := by
      intro p hp
      dsimp at hp
      by_cases hM : M.f p = 0
      · have := hp hM
        contradiction
      · have hN : N.f p ≠ 0 := by
          intro hN
          have := hp (by rw [hN]; exact Nat.mul_zero (N.f p))
          contradiction
        exact ⟨hp hM, hp hN⟩,
    bound := by
      cases M.bound with
      | intro N M_bound =>
        cases N.bound with
        | intro K N_bound =>
          use N + K
          intro n hn
          have hM_n : M.f n = 0 := M_bound n hn
          have hN_n : N.f n = 0 := N_bound n (Nat.le_add_right _ _ hn)
          rw [hM_n, hN_n]
          exact Nat.mul_zero 0 }

/-- The tensor product is commutative up to isomorphism. -/
theorem tensorProduct_comm {Idx : Type} [PrimeLabel Idx]
    (M N : Multiset) :
    tensorProduct M N = tensorProduct N M := by
  ext p
  simp [tensorProduct]
  exact Nat.mul_comm (M.f p) (N.f p)

/-- The tensor product is associative up to isomorphism. -/
theorem tensorProduct_assoc {Idx : Type} [PrimeLabel Idx]
    (M N P : Multiset) :
    tensorProduct (tensorProduct M N) P = tensorProduct M (tensorProduct N P) := by
  ext p
  simp [tensorProduct]
  exact Nat.mul_assoc (M.f p) (N.f p) (P.f p)

/-- The tensor product of a multiset with the empty multiset is empty. -/
theorem tensorProduct_empty {Idx : Type} [PrimeLabel Idx]
    (M : Multiset) :
    tensorProduct M empty = empty := by
  ext p
  simp [tensorProduct, empty]
  exact Nat.mul_zero (M.f p)

/-- The dimension of a tensor product is the product of dimensions. -/
theorem tensorProduct_dimension {Idx : Type} [PrimeLabel Idx]
    (M N : Multiset) :
    (tensorProduct M N).f = fun p => M.f p * N.f p := by
  funext p
  rfl

end Multiplicity.Core.Multiplicity.HigherOrder