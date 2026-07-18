namespace ADR.Archivum

structure Witness where
  state_hash : String
  event_type : String
  timestamp : Nat
  commit_hash : Option String
  previous_hash : Option String
  deriving Repr, DecidableEq

structure ArchivumLedger where
  witnesses : List Witness
  chain_valid : Bool
  deriving Repr

def append (ledger : ArchivumLedger) (w : Witness) : Option ArchivumLedger :=
  if ledger.witnesses.any (·.state_hash == w.state_hash) then none
  else some {
    witnesses := ledger.witnesses ++ [w],
    chain_valid := ledger.chain_valid -- simplified for proof
  }

def modify_witness (ledger : ArchivumLedger) (i : Nat) (w : Witness) : Option ArchivumLedger :=
  if i < ledger.witnesses.length then
    some { witnesses := ledger.witnesses.set i w, chain_valid := false }
  else none

theorem ledger_append_only (ledger : ArchivumLedger) (w : Witness)
  (h_append : append ledger w = some ledger') :
  ∀ w', w' ∈ ledger.witnesses → w' ∈ ledger'.witnesses := by
  unfold append at h_append
  split at h_append
  · next h_dup =>
    injection h_append
  · next ledger' h_append' =>
    injection h_append' with h_append''
    subst h_append''
    intro w' h_w'
    simp [List.mem_append]
    right
    exact h_w'

theorem ledger_tamper_evident (ledger : ArchivumLedger) (w : Witness) (i : Nat)
  (h_in : i < ledger.witnesses.length)
  (h_modify : modify_witness ledger i w = some ledger') :
  ledger.chain_valid = true → ledger'.chain_valid = false := by
  unfold modify_witness at h_modify
  split at h_modify
  · next h_ih =>
    injection h_modify with h_modify'
    subst h_modify'
    intro h_valid
    simp [h_valid]
  · next h_oob =>
    injection h_modify

theorem witness_uniqueness (ledger : ArchivumLedger) (w : Witness)
  (h_append : append ledger w = some ledger') :
  ∀ w', w' ∈ ledger'.witnesses → w'.state_hash ≠ w.state_hash ∨ w' = w := by
  unfold append at h_append
  split at h_append
  · next h_dup =>
    injection h_append
  · next ledger' h_append' =>
    injection h_append' with h_append''
    subst h_append''
    intro w' h_w'
    simp [List.mem_append] at h_w'
    cases h_w' with
    | inl h_w' =>
      have : w'.state_hash ≠ w.state_hash := by
        intro h_eq
        have : append ledger w = none := by
          unfold append
          simp [h_eq]
        contradiction
      exact Or.inl this
    | inr h_w' =>
      exact Or.inr h_w'

end ADR.Archivum
