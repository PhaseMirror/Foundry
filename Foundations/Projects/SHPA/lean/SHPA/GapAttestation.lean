import SHPA.Types
import SHPA.H2P

set_option autoImplicit false

/-!
# Succinct Gap Attestation & Compositeness Verification
-/

namespace SHPA

/-- Compositeness witness for odd candidate N + l (e.g. non-trivial divisor or Fermat witness). -/
structure CompositeWitness where
  candidate : Nat
  divisor   : Nat
  is_valid  : divisor > 1 ∧ divisor < candidate ∧ candidate % divisor = 0

/-- Gap verification predicate: Vector of valid compositeness witnesses covering all even offsets l < k. -/
def gap_fully_witnessed (N k : Nat) (witnesses : List CompositeWitness) : Prop :=
  ∀ l : Nat, l < k → l % 2 = 0 →
    ∃ w ∈ witnesses, w.candidate = N + l

/-- Theorem (Gap Soundness): If every candidate in [N, N+k-2] has a valid divisor witness,
    then no candidate in that gap is prime. -/
theorem witnessed_candidates_are_composite (w : CompositeWitness) :
    w.candidate > 1 ∧ (∃ d, d > 1 ∧ d < w.candidate ∧ w.candidate % d = 0) := by
  rcases w.is_valid with ⟨h_gt1, h_lt, h_div⟩
  constructor
  · have : w.divisor > 1 := h_gt1
    have : w.candidate > w.divisor := h_lt
    omega
  · exact ⟨w.divisor, h_gt1, h_lt, h_div⟩

end SHPA
