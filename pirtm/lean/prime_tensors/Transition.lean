/-!
# Prime Tensors: Transition Operators

Formal specification of transition operators between prime-indexed
tensor states in the PIRTM/MOC substrate.

Self-contained in Lean 4 Core (Mathlib-Free).
-/

namespace prime_tensors.Transition

/-! ## Prime-Indexed State -/

/-- A prime-indexed state carrier: a finite list of prime indices. -/
abbrev PrimeIndices := List Nat

/-- A transition operator maps one prime-indexed configuration to another. -/
def TransitionOp := PrimeIndices → PrimeIndices

/-! ## Basic Transition Properties -/

/-- A transition is length-preserving if it maintains the number of active primes. -/
def IsLengthPreserving (op : TransitionOp) : Prop :=
  ∀ s, (op s).length = s.length

/-- A transition is prime-respecting if it only permutes or retains prime indices. -/
def IsPrimeRespecting (op : TransitionOp) : Prop :=
  ∀ s, ∀ p ∈ s, p ∈ op s

/-- Identity transition trivially preserves length and primes. -/
def idTransition : TransitionOp := fun s => s

theorem idTransition_length_preserving :
    IsLengthPreserving idTransition := by
  unfold IsLengthPreserving idTransition
  intro s
  rfl

theorem idTransition_prime_respecting :
    IsPrimeRespecting idTransition := by
  unfold IsPrimeRespecting idTransition
  intro s p hp
  exact hp

end prime_tensors.Transition
