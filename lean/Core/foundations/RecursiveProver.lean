namespace Core.foundations.RecursiveProver

structure ProofObject where
  circuit_id : Nat
  public_inputs : List Int
  proof_bytes : List UInt8
  deriving Repr

structure RecursiveProof where
  inner_proof : ProofObject
  wrapper_circuit_id : Nat
  deriving Repr

structure APO where
  aggregated_proofs : List RecursiveProof
  root_hash : String
  deriving Repr

def is_valid_proof (p : ProofObject) : Bool :=
  -- In full formalization, this invokes the verifier circuit
  true  -- placeholder

def verify_apo (apo : APO) : Bool :=
  apo.aggregated_proofs.all (fun p => is_valid_proof p.inner_proof)

theorem aggregation_preserves_validity (proofs : List RecursiveProof)
  (h_all_valid : ∀ p, p ∈ proofs → is_valid_proof p.inner_proof) :
  verify_apo { aggregated_proofs := proofs, root_hash := "" } := by
  unfold verify_apo
  rw [List.all_eq_true]
  exact h_all_valid

theorem aggregation_is_sound (proofs : List RecursiveProof)
  (h_invalid : ∃ p, p ∈ proofs ∧ ¬ is_valid_proof p.inner_proof) :
  ¬ verify_apo { aggregated_proofs := proofs, root_hash := "" } := by
  unfold verify_apo
  rw [List.all_eq_true]
  intro h_all
  match h_invalid with
  | ⟨p, ⟨hp, h_not_valid⟩⟩ =>
    have h_valid := h_all p hp
    contradiction

end Core.foundations.RecursiveProver
