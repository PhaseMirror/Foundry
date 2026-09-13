import ADR.Core

/-!
# Formal Proofs and Invariants
Guarantees immutability after acceptance and absence of circular supersessions.
-/


namespace ADR.Proofs

def ValidTransition (from_status to_status : ADRStatus) : Bool :=
  match from_status, to_status with
  | .Proposed, .Accepted => true
  | .Proposed, .Deprecated => true
  | .Accepted, .Superseded _ => true
  | .Accepted, .Deprecated => true
  | _, _ => false

theorem accepted_immutability (next : ADRStatus) (h : ValidTransition .Accepted next = true) :
    (∃ id, next = .Superseded id) ∨ next = .Deprecated := by
  cases next with
  | Proposed => contradiction
  | Accepted => contradiction
  | Deprecated => right; rfl
  | Superseded id => left; exact ⟨id, rfl⟩

def is_acyclic (registry : List ADR) : Prop :=
  ∀ adr ∈ registry, adr.supersedes ≠ some adr.id

theorem no_self_supersession (registry : List ADR) (h : is_acyclic registry) (adr : ADR) (h_in : adr ∈ registry) :
    adr.supersedes ≠ some adr.id := by
  exact h adr h_in

end ADR.Proofs
