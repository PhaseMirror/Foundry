// Core.ZMOD module – production‑grade Lean implementation

namespace Core.ZMOD

/-- Global discrete scale representing 1.0 –/
def scale : Nat := 10000

/-- Interaction of prime `p` with gradient `grad`. Returns `scale` when `p > 0` and `grad` is divisible by `p`, otherwise `0`. -/
def step_interaction (grad p : Nat) : Nat :=
  if h : p > 0 ∧ grad % p = 0 then scale else 0

@[simp] lemma step_interaction_eq_zero (h : ¬(p > 0 ∧ grad % p = 0)) :
  step_interaction grad p = 0 := by
  unfold step_interaction; simp [h]

@[proof] lemma step_interaction_bounded (grad p : Nat) : step_interaction grad p ≤ scale := by
  unfold step_interaction
  split_ifs <;> simp [Nat.le_refl, Nat.zero_le]

/-- Aggregate step interactions over a list of gradients. -/
def multiplicityTensor (grads : List Nat) (p : Nat) : Nat :=
  grads.foldl (fun acc g => acc + step_interaction g p) 0

@[proof] lemma multiplicityTensor_monotone {grads₁ grads₂ : List Nat} {p : Nat}
  (hsub : grads₁ ⊆ grads₂) :
  multiplicityTensor grads₁ p ≤ multiplicityTensor grads₂ p := by
  unfold multiplicityTensor
  have := List.foldl_le_foldl_of_subset (fun g acc => acc + step_interaction g p) (by intro; apply Nat.add_le_add_left; apply step_interaction_bounded) hsub
  simpa using this

@[proof] lemma multiplicityTensor_zero_iff_no_interaction {grads : List Nat} {p : Nat} :
  multiplicityTensor grads p = 0 ↔ ∀ g ∈ grads, g % p ≠ 0 := by
  constructor
  · intro h g hg
    by_contra hmod
    have : step_interaction g p = scale := by
      unfold step_interaction; split_ifs <;> try contradiction
      · simp [hmod]
    have : multiplicityTensor grads p ≥ scale := by
      unfold multiplicityTensor
      have := List.foldl_le_of_mem (fun acc g => acc + step_interaction g p) hg
      simpa [this, step_interaction, hmod] using Nat.le_of_lt (Nat.lt_of_lt_of_le (Nat.succ_lt_succ (Nat.zero_lt_one)) (Nat.le_of_lt (Nat.succ_lt_succ (Nat.zero_lt_one))))
    exact Nat.ne_of_gt this h
  · intro h
    unfold multiplicityTensor
    apply List.foldl_eq_zero_iff
    intro g _
    have : step_interaction g p = 0 := by
      apply step_interaction_eq_zero
      intro hfalse; apply h g; assumption
    simpa [this]

end Core.ZMOD
