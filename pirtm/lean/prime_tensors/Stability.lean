/-!
# Prime Tensors: Stability

Formal specification of stability conditions for prime-indexed
transition operators under the Sedona Spine governance substrate.

Self-contained in Lean 4 Core (Mathlib-Free).
-/

namespace prime_tensors.Stability

/-! ## Spectral Stability -/

/-- Iterate a function n times. -/
def iterate {α : Type} (f : α → α) (n : Nat) (x : α) : α :=
  match n with
  | 0 => x
  | n + 1 => iterate f n (f x)

/-- A transition operator is spectrally stable if its repeated application
    does not increase the cardinality of the prime index set. -/
def SpectralStable (op : List Nat → List Nat) (n : Nat) : Prop :=
  ∀ s, (iterate op n s).length ≤ s.length

/-- Any length-non-increasing operator is spectrally stable. -/
theorem spectral_stable_of_length_non_increasing
    (f : List Nat → List Nat)
    (h : ∀ s, (f s).length ≤ s.length)
    (n : Nat) (s : List Nat) :
    (iterate f n s).length ≤ s.length := by
  induction n generalizing s with
  | zero => simp [iterate]
  | succ n ih =>
      simp [iterate]
      apply Nat.le_trans (ih (f s))
      exact h s

/-- Stability is preserved under composition with length-preserving maps. -/
theorem stable_under_composition
    (op1 op2 : List Nat → List Nat)
    (h1 : ∀ s, (op1 s).length ≤ s.length)
    (h2 : ∀ s, (op2 s).length ≤ s.length)
    (n m : Nat) :
    SpectralStable (op1 ∘ op2) (n + m) := by
  unfold SpectralStable
  intro s
  apply spectral_stable_of_length_non_increasing (op1 ∘ op2) _ (n + m) s
  intro t
  calc
    ((op1 ∘ op2) t).length = (op1 (op2 t)).length := rfl
    _ ≤ (op2 t).length := h1 (op2 t)
    _ ≤ t.length := h2 t

end prime_tensors.Stability
