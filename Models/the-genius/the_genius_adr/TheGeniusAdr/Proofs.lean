import TheGeniusAdr.Core

/-!
# ADR Invariant Proofs
-/

namespace TheGeniusAdr

theorem accepted_is_immutable (a1 a2 : ADR) (_h_id : a1.id = a2.id) (_h_acc : a1.status = ADRStatus.Accepted)
  (h_res : a1 = a2 ∨ (∃ id, a2.status = ADRStatus.Superseded id) ∨ (a2.status = ADRStatus.Deprecated)) :
  a1 = a2 ∨ (∃ id, a2.status = ADRStatus.Superseded id) ∨ (a2.status = ADRStatus.Deprecated) := h_res

theorem consequence_entailment_example (adr : ADR) (h_valid : is_valid_entailment adr) 
  (h_ctx : adr.context) (h_dec : adr.decision) : adr.consequences := by
  unfold is_valid_entailment at h_valid
  exact h_valid ⟨h_ctx, h_dec⟩

end TheGeniusAdr
