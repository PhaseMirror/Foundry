/-!
# Core ADR Definitions
This module defines the fundamental types and structures of our verified ADR system.
-/
namespace ADR

inductive ADRStatus where
  | Proposed
  | Accepted
  | Deprecated
  | Superseded
  deriving Repr, BEq

structure ArtifactLink where
  title : String
  url : String

structure ADR where
  id : Nat
  title : String
  status : ADRStatus
  context : String
  decision : String
  consequences : List String
  supersedes : Option Nat
  links : List ArtifactLink

-- A proposition stating that if an ADR is accepted, it must not be empty.
def IsValidContext (a : ADR) : Prop :=
  a.context ≠ "" ∧ a.decision ≠ ""

-- Simple embedding of logic for consequence entailment
-- In a production system, this could be a more complex DSL.
structure LogicalEntailment (a : ADR) : Prop where
  justified : a.status = ADRStatus.Accepted → (a.consequences.length > 0)

end ADR
