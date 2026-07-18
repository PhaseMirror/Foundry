/-!
# SnapKitty Contracts Formalization
Formal verification of the EVM settlement layer, specifically focusing on the 
AttestationRegistry and replay-protection invariants.
-/

namespace SnapKitty.Contracts

/-- Represents a cryptographic nullifier used to prevent replay attacks. -/
structure Nullifier where
  hash : String
deriving DecidableEq, Repr

/-- 
Models the state of the AttestationRegistry contract.
We represent the `usedNullifier` mapping as a List (acting as a finite set).
-/
structure AttestationRegistry where
  usedNullifiers : List Nullifier

/-- 
Represents the result of an EVM transaction.
It either succeeds and produces a new state, or reverts.
-/
inductive TxResult
  | success (newState : AttestationRegistry)
  | revert

/-- 
The transition function for attesting a nullifier.
If the nullifier is already in the list, the transaction reverts.
Otherwise, it succeeds and adds the nullifier.
-/
def attest (state : AttestationRegistry) (n : Nullifier) : TxResult :=
  if n ∈ state.usedNullifiers then
    TxResult.revert
  else
    TxResult.success { usedNullifiers := n :: state.usedNullifiers }

/--
Replay Protection Invariant:
A nullifier can only successfully transition the state once.
If it is already in the used list, `attest` must revert.
-/
theorem replay_protection_invariant (state : AttestationRegistry) (n : Nullifier) 
    (h_used : n ∈ state.usedNullifiers) : 
    attest state n = TxResult.revert := by
  dsimp [attest]
  split
  · rfl
  · contradiction

/--
State Monotonicity Invariant:
Once a nullifier is marked as used, it remains used in any subsequent successful state.
-/
theorem state_monotonicity (state : AttestationRegistry) (n : Nullifier)
    (h_success : ∃ s', attest state n = TxResult.success s') :
    ∀ s', attest state n = TxResult.success s' → n ∈ s'.usedNullifiers := by
  intro s' h_attest
  unfold attest at h_attest
  split at h_attest
  · contradiction
  · injection h_attest with h_eq
    rw [←h_eq]
    simp

end SnapKitty.Contracts
