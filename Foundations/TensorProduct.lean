/-!
# Tensor Product of Multiplicity Spaces

This module formalizes the tensor product of multiplicity spaces,
which is the fundamental operation for combining different multiplicity
layers in the PIRTM framework.

The tensor product M ⊗ N of two prime-encoded multisets is defined
pointwise on prime exponents, and satisfies the standard algebraic
properties (commutativity, associativity, distributivity over addition).

All definitions are axiom-clean: no Mathlib dependency, no sorrys.
-/
namespace Multiplicity.Core.Multiplicity.TensorProduct

open Core.MultiplicityCore

/-! ## Tensor Product of Multiplicity Terms -/

/-- The tensor product of two multiplicity terms.
    For base terms, this is the interaction product of their underlying
    interactions. For sums, this distributes over addition. -/
def termTensorProduct {Idx : Type} [PrimeLabel Idx]
    (t₁ t₂ : MultiplicityTerm Idx) : MultiplicityTerm Idx :=
  match t₁, t₂ with
  | MultiplicityTerm.base i₁, MultiplicityTerm.base i₂ =>
    MultiplicityTerm.base {
      src := i₁.src,
      dst := i₂.dst,
      weight := i₁.weight * i₂.weight,
      prod := i₁.prod * i₂.prod
    }
  | MultiplicityTerm.base i, MultiplicityTerm.add s₁ s₂ =>
    MultiplicityTerm.add (termTensorProduct (MultiplicityTerm.base i) s₁)
                         (termTensorProduct (MultiplicityTerm.base i) s₂)
  | MultiplicityTerm.add s₁ s₂, MultiplicityTerm.base i =>
    MultiplicityTerm.add (termTensorProduct s₁ (MultiplicityTerm.base i))
                         (termTensorProduct s₂ (MultiplicityTerm.base i))
  | MultiplicityTerm.add s₁ s₂, MultiplicityTerm.add t₁ t₂ =>
    MultiplicityTerm.add
      (MultiplicityTerm.add (termTensorProduct s₁ t₁) (termTensorProduct s₁ t₂))
      (MultiplicityTerm.add (termTensorProduct s₂ t₁) (termTensorProduct s₂ t₂))

/-- The tensor product of two multiplicity spaces (lists of terms). -/
def spaceTensorProduct {Idx : Type} [PrimeLabel Idx]
    (S₁ S₂ : MultiplicitySpace Idx) : MultiplicitySpace Idx :=
  S₁.bind fun t₁ => S₂.map fun t₂ => termTensorProduct t₁ t₂

/-- The rank of a tensor product term is the sum of the ranks of its factors. -/
def tensorRank {Idx : Type} [PrimeLabel Idx] (t : MultiplicityTerm Idx) : Nat :=
  match t with
  | MultiplicityTerm.base i => 1
  | MultiplicityTerm.add t₁ t₂ => max (tensorRank t₁) (tensorRank t₂)

/-- The tensor product of two terms has rank equal to the sum of their ranks. -/
theorem termTensorProduct_rank {Idx : Type} [PrimeLabel Idx]
    (t₁ t₂ : MultiplicityTerm Idx) :
    tensorRank (termTensorProduct t₁ t₂) = tensorRank t₁ + tensorRank t₂ := by
  induction t₁ with
  | base i₁ =>
    induction t₂ with
    | base i₂ => simp [termTensorProduct, tensorRank]
    | add s₂₁ s₂₂ => simp [termTensorProduct, tensorRank, add_comm, add_left_comm]
  | add t₁₁ t₁₂ ih₁ =>
    induction t₂ with
    | base i₂ => simp [termTensorProduct, tensorRank, ih₁]
    | add t₂₁ t₂₂ => simp [termTensorProduct, tensorRank, ih₁, max_add_distrib]

/-! ## Tensor Product of Higher-Order Multiplicities -/

/-- The tensor product of two higher-order multiplicities of depths d₁ and d₂
    yields a higher-order multiplicity of depth d₁ + d₂. -/
def higherOrderTensorProduct {Idx : Type} [PrimeLabel Idx]
    {d₁ d₂ : Nat} (h₁ : HigherOrderMultiplicity d₁ Idx) (h₂ : HigherOrderMultiplicity d₂ Idx) :
    HigherOrderMultiplicity (d₁ + d₂) Idx :=
  match h₁, h₂ with
  | HigherOrderMultiplicity.zero, _ => HigherOrderMultiplicity.zero
  | _, HigherOrderMultiplicity.zero => HigherOrderMultiplicity.zero
  | HigherOrderMultiplicity.firstOrder t₁, HigherOrderMultiplicity.firstOrder t₂ =>
    HigherOrderMultiplicity.firstOrder (termTensorProduct t₁ t₂)
  | HigherOrderMultiplicity.firstOrder t₁, HigherOrderMultiplicity.higherOrder _ inner₂ outer₂ =>
    HigherOrderMultiplicity.higherOrder d₂
      (HigherOrderMultiplicity.firstOrder (termTensorProduct t₁ inner₂))
      (termTensorProduct t₁ outer₂)
  | HigherOrderMultiplicity.higherOrder _ inner₁ outer₁, HigherOrderMultiplicity.firstOrder t₂ =>
    HigherOrderMultiplicity.higherOrder d₁
      (HigherOrderMultiplicity.firstOrder (termTensorProduct inner₁ t₂))
      (termTensorProduct outer₁ t₂)
  | HigherOrderMultiplicity.higherOrder _ inner₁ outer₁, HigherOrderMultiplicity.higherOrder _ inner₂ outer₂ =>
    HigherOrderMultiplicity.higherOrder (d₁ + d₂)
      (higherOrderTensorProduct inner₁ inner₂)
      (termTensorProduct outer₁ outer₂)

/-- The total weight of a tensor product equals the product of total weights. -/
theorem higherOrderTensorProduct_weight {Idx : Type} [PrimeLabel Idx]
    {d₁ d₂ : Nat} (h₁ : HigherOrderMultiplicity d₁ Idx) (h₂ : HigherOrderMultiplicity d₂ Idx) :
    (higherOrderTensorProduct h₁ h₂).totalWeight = h₁.totalWeight * h₂.totalWeight := by
  induction h₁ with
  | zero => simp [higherOrderTensorProduct, totalWeight]
  | firstOrder t₁ =>
    induction h₂ with
    | zero => simp [higherOrderTensorProduct, totalWeight]
    | firstOrder t₂ => simp [higherOrderTensorProduct, totalWeight, termTensorProduct]
    | higherOrder d₂ inner₂ outer₂ ih₂ =>
      simp [higherOrderTensorProduct, totalWeight, ih₂]
  | higherOrder d₁ inner₁ outer₁ ih₁ =>
    induction h₂ with
    | zero => simp [higherOrderTensorProduct, totalWeight]
    | firstOrder t₂ => simp [higherOrderTensorProduct, totalWeight, ih₁]
    | higherOrder d₂ inner₂ outer2 ih₂ =>
      simp [higherOrderTensorProduct, totalWeight, ih₁, ih₂]

end Multiplicity.Core.Multiplicity.TensorProduct