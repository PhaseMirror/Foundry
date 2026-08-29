/-!
# Foundations.Archivum.Core — Immutable Ledger & Tamper Evidence

Formalizes append-only witness ledgers, uniqueness invariants, and tamper-evident proofs.
-/

namespace Foundations.Archivum

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

/-- Append a witness only if its state hash has not appeared before. -/
def append (ledger : ArchivumLedger) (w : Witness) : Option ArchivumLedger :=
  if ledger.witnesses.any (fun x => x.state_hash == w.state_hash) then none
  else some {
    witnesses := ledger.witnesses ++ [w],
    chain_valid := ledger.chain_valid
  }

/-- In-place modification marks chain validity as false. -/
def modify_witness (ledger : ArchivumLedger) (i : Nat) (w : Witness) : Option ArchivumLedger :=
  if i < ledger.witnesses.length then
    some { witnesses := ledger.witnesses.set i w, chain_valid := false }
  else none

/-- Theorem: Appending to the ledger preserves all prior witnesses. -/
theorem ledger_append_only (ledger : ArchivumLedger) (w : Witness) (ledger' : ArchivumLedger)
    (h_append : append ledger w = some ledger') :
    ∀ w', w' ∈ ledger.witnesses → w' ∈ ledger'.witnesses := by
  dsimp [append] at h_append
  split at h_append
  · contradiction
  · injection h_append with h_eq
    subst h_eq
    intro w' h_w'
    simp [List.mem_append]
    left
    exact h_w'

/-- Theorem: Tamper evidence — in-place modification invalidates chain status. -/
theorem ledger_tamper_evident (ledger : ArchivumLedger) (w : Witness) (i : Nat) (ledger' : ArchivumLedger)
    (h_in : i < ledger.witnesses.length)
    (h_modify : modify_witness ledger i w = some ledger') :
    ledger.chain_valid = true → ledger'.chain_valid = false := by
  dsimp [modify_witness] at h_modify
  split at h_modify
  · injection h_modify with h_eq
    subst h_eq
    intro _
    rfl
  · contradiction

end Foundations.Archivum
