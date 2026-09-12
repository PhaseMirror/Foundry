/-!
# Foundations.ZMOD.Core — Discrete Scale Multiplicity Interaction Tensor

Formalizes interaction of prime indices with discrete gradient components and
monotonicity bounds on the aggregated multiplicity tensor.
-/

namespace Foundations.ZMOD

/-- Global discrete scale representing 1.0 -/
def scale : Nat := 10000

/-- Interaction of prime `p` with gradient `grad`. Returns `scale` when `p > 0` and `grad % p = 0`, otherwise `0`. -/
def stepInteraction (grad p : Nat) : Nat :=
  if p > 0 ∧ grad % p = 0 then scale else 0

/-- Lemma: Step interaction is zero when divisibility fails or p = 0. -/
theorem step_interaction_eq_zero (grad p : Nat) (h : ¬(p > 0 ∧ grad % p = 0)) :
    stepInteraction grad p = 0 := by
  dsimp [stepInteraction]
  rw [if_neg h]

/-- Lemma: Step interaction is strictly bounded by the discrete scale. -/
theorem step_interaction_bounded (grad p : Nat) : stepInteraction grad p ≤ scale := by
  dsimp [stepInteraction]
  split
  · exact Nat.le_refl scale
  · exact Nat.zero_le scale

/-- Aggregate step interactions over a list of gradients. -/
def multiplicityTensor (grads : List Nat) (p : Nat) : Nat :=
  grads.foldl (fun acc g => acc + stepInteraction g p) 0

/-- Theorem: Empty list yields zero tensor. -/
theorem multiplicity_tensor_nil (p : Nat) : multiplicityTensor [] p = 0 := rfl

/-- Helper lemma for accumulator shifting in foldl. -/
theorem foldl_add_step (l : List Nat) (init : Nat) (p : Nat) :
    List.foldl (fun acc g => acc + stepInteraction g p) init l = init + List.foldl (fun acc g => acc + stepInteraction g p) 0 l := by
  induction l generalizing init with
  | nil => rfl
  | cons x xs ih =>
    dsimp
    rw [ih (init + stepInteraction x p)]
    rw [ih (0 + stepInteraction x p)]
    omega

/-- Theorem: Single element evaluation -/
theorem multiplicity_tensor_singleton (g p : Nat) :
    multiplicityTensor [g] p = stepInteraction g p := by
  dsimp [multiplicityTensor]
  omega

/-- Theorem: Appending gradient lists sums their multiplicity tensor contributions. -/
theorem multiplicity_tensor_append (grads₁ grads₂ : List Nat) (p : Nat) :
    multiplicityTensor (grads₁ ++ grads₂) p = multiplicityTensor grads₁ p + multiplicityTensor grads₂ p := by
  dsimp [multiplicityTensor]
  rw [List.foldl_append]
  exact foldl_add_step grads₂ (List.foldl (fun acc g => acc + stepInteraction g p) 0 grads₁) p

end Foundations.ZMOD
