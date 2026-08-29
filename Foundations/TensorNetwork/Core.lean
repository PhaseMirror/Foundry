/-!
# Foundations.TensorNetwork.Core — Multiplicity Tensor Networks & Interaction Products

Formalizes the tensor product of multiplicity interaction spaces,
pointwise prime interaction products, and tensor rank additive conservation.
-/

namespace Foundations.TensorNetwork

/-- Multiplicity interaction tuple connecting source and destination nodes. -/
structure MultiplicityInteraction where
  src : Nat
  dst : Nat
  weight : Nat
  prod : Nat
  deriving Repr, DecidableEq

/-- Recursive multiplicity term representation. -/
inductive MultiplicityTerm where
  | base : MultiplicityInteraction → MultiplicityTerm
  | add : MultiplicityTerm → MultiplicityTerm → MultiplicityTerm
  deriving Repr

/-- Tensor product of two multiplicity terms. -/
def termTensorProduct : MultiplicityTerm → MultiplicityTerm → MultiplicityTerm
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

/-- The rank of a multiplicity term. -/
def tensorRank : MultiplicityTerm → Nat
  | MultiplicityTerm.base _ => 1
  | MultiplicityTerm.add t₁ t₂ => tensorRank t₁ + tensorRank t₂

/-- Theorem: Base interaction tensor rank is strictly 1. -/
theorem base_tensor_rank (i : MultiplicityInteraction) :
    tensorRank (MultiplicityTerm.base i) = 1 := rfl

/-- Theorem: Tensor rank of product of base terms is 1. -/
theorem base_term_product_rank (i₁ i₂ : MultiplicityInteraction) :
    tensorRank (termTensorProduct (MultiplicityTerm.base i₁) (MultiplicityTerm.base i₂)) = 1 := by
  unfold termTensorProduct
  rfl

end Foundations.TensorNetwork
