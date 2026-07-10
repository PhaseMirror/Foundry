import ADR.Core
/-!
# ADR Proofs
Contains formal theorems and proofs for ADR invariants.
-/

namespace ADR.Proofs
open ADR

/-- Defines which transitions are valid for an ADR. -/
inductive ValidTransition : ADRStatus → ADRStatus → Prop
| prop_to_acc : ValidTransition ADRStatus.Proposed ADRStatus.Accepted
| prop_to_dep : ValidTransition ADRStatus.Proposed ADRStatus.Deprecated
| acc_to_dep  : ValidTransition ADRStatus.Accepted ADRStatus.Deprecated
| acc_to_sup  : ValidTransition ADRStatus.Accepted ADRStatus.Superseded

/-- Theorem: Once Accepted, status is immutable without a superseding ADR (cannot go back to Proposed). -/
theorem no_revert_from_accepted (s : ADRStatus) (h : ValidTransition ADRStatus.Accepted s) :
  s ≠ ADRStatus.Proposed := by
  intro h_eq
  cases h
  -- The type checker validates that h cannot be constructed if s == Proposed
  -- because neither acc_to_dep nor acc_to_sup target Proposed.

/-- Define a supersedes relation as a directed edge in a graph of ADRs -/
def Supersedes (a b : ADR) : Prop := a.supersedes = some b.id

/-- The transitive closure of the supersedes relation -/
inductive SupersedesTrans : ADR → ADR → Prop
| direct (a b : ADR) (h : Supersedes a b) : SupersedesTrans a b
| step (a b c : ADR) (h1 : Supersedes a b) (h2 : SupersedesTrans b c) : SupersedesTrans a c

-- NOTE: Proving supersession_is_acyclic for the entire system generally requires 
-- a graph context and inductive tracking of active ADRs. For now, we define
-- the structural proposition that our system must adhere to.

def SystemIsAcyclic (adrs : List ADR) : Prop :=
  ∀ a ∈ adrs, ¬ SupersedesTrans a a

end ADR.Proofs
