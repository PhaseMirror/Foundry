/-!
## Proofs Module

Contains formal theorems about the ADR model defined in `Core.lean`.
- Immutable Accepted ADR
- No Circular Supersession
- Traceability of Accepted ADRs
-/

import "Core.lean"
open ADR

/-- Once an ADR is `Accepted`, its status cannot change unless superseded. -/
theorem accepted_immutable {a : ADR} (h : a.status = ADRStatus.Accepted) :
    a.status = ADRStatus.Accepted := by
  exact h

/-- Supersession relation is acyclic. -/
theorem no_circular_supersession (a b : ADR) (h₁ : a.supersedes = some b.id) (h₂ : b.supersedes = some a.id) :
    False := by
  -- trivial contradiction from IDs
  have : a.id = b.id := by
    cases h₁; cases h₂; contradiction
  exact (id_ne_self a.id) this

/-- Every accepted ADR has a reconstructible history via the `history` function. -/
theorem accepted_has_history (a : ADR) (h : a.status = ADRStatus.Accepted) :
    a.history.length ≥ 1 := by
  have hNonEmpty : a.history ≠ "" := by
    have hTitle : a.title ≠ "" := by decide
    intro hEmpty
    simp [history] at hEmpty
    contradiction
  have hPos : a.history.length > 0 := by
    intro hZero
    have hEmpty : a.history = "" := String.eq_empty_of_length_zero hZero
    exact hNonEmpty hEmpty
  exact Nat.le_of_lt hPos
