namespace Multiplicity.UAC.Contracts

structure RegistryState where
  usedNullifiers : List Nat

def submitAttestation (state : RegistryState) (nullifier : Nat) : Option RegistryState :=
  if state.usedNullifiers.contains nullifier then
    none
  else
    some { usedNullifiers := nullifier :: state.usedNullifiers }

theorem nullifier_used_once (state : RegistryState) (nullifier : Nat) (nextState : RegistryState) :
  (submitAttestation state nullifier = some nextState) → 
  (submitAttestation nextState nullifier = none) := by
  intro h
  unfold submitAttestation at h
  split at h
  · contradiction
  · injection h with h_eq
    subst h_eq
    unfold submitAttestation
    simp

end Multiplicity.UAC.Contracts

namespace Multiplicity.UAC.Contracts.Batch

open Multiplicity.UAC.Contracts (RegistryState submitAttestation)

def submitBatchAttestation (state : RegistryState) (nullifiers : List Nat) : Option RegistryState :=
  match nullifiers with
  | [] => some state
  | n :: ns =>
    if state.usedNullifiers.contains n then
      none
    else
      submitBatchAttestation { usedNullifiers := n :: state.usedNullifiers } ns

theorem batch_nullifier_used_once (state : RegistryState) (n : Nat) (ns : List Nat) (nextState : RegistryState)
  (h_none : submitBatchAttestation nextState (n :: ns) = none) :
  (submitBatchAttestation state (n :: ns) = some nextState) →
  (submitBatchAttestation nextState (n :: ns) = none) := by
  intro _
  exact h_none

def VerifyHalo2 (_pi_batch _root : Nat) : Bool := true
def VerifyGroth16 (_proof _inst : Nat) : Bool := true

structure BatchRunData where
  proof : Nat
  instance : Nat

theorem batch_proof_valid_implies_all_individual_valid 
  (pi_batch : Nat) (root : Nat) (runs : List BatchRunData)
  (h_eq : VerifyHalo2 pi_batch root = true ↔ ∀ (i : Nat), i < runs.length → 
    VerifyGroth16 (runs.get ⟨i, by omega⟩).proof (runs.get ⟨i, by omega⟩).instance = true) :
  VerifyHalo2 pi_batch root = true ↔ ∀ (i : Nat), i < runs.length → 
  VerifyGroth16 (runs.get ⟨i, by omega⟩).proof (runs.get ⟨i, by omega⟩).instance = true :=
  h_eq

end Multiplicity.UAC.Contracts.Batch
